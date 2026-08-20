# theme: opencode

opencode CLI を GitHub リリースから `/usr/bin/opencode` としてインストールするステンシルです。

Portage パッケージは存在せず、公式配布も deb/rpm ではありません（deb/rpm があるのは
Electron 製のデスクトップ版のみ）。CLI は tar.gz の中に **Bun でコンパイルされた
単一実行ファイルが1個入っているだけ**なので、ダウンロードして置くだけで済みます。

あわせて、システム全体（マシン全体）に効く指示文を `/etc/opencode/AGENTS.md` として配置します。

## 構成

```
opencode/
  genpack.json5                    # packages の断片 (必須の ripgrep + 推奨ツールの候補リスト)
  files/build.d/opencode.sh        # ダウンロード・sha256検証・設置
  files/etc/opencode/opencode.json # managed config: instructions で AGENTS.md を指す
  files/etc/opencode/AGENTS.md     # システム全体の指示文 (genpack環境の説明)
  README.md
```

## アーティファクトへの適用

1. `files/build.d/opencode.sh` を対象アーティファクトの `files/build.d/` にコピーする
   （冒頭の `# ref: opencode/files/build.d/opencode.sh` は残すこと）。
2. `files/etc/opencode/` の2ファイルを対象アーティファクトの `files/etc/opencode/` にコピーする。
   `AGENTS.md` はアーティファクト固有の事情（用途・触ってよい場所・運用上の注意）を
   追記して育てる前提。
3. `genpack.json5` の `packages` を対象アーティファクトの `packages` へマージし、
   出典コメント `// ref: opencode/genpack.json5` を残す。有効なのは `sys-apps/ripgrep`
   だけで、残りはコメントアウトされた候補リスト（後述）。必要なものを選んで有効化する。

## システム全体の指示文について

opencode には `/etc/claude-code/CLAUDE.md` に相当する「システム全体の AGENTS.md を
自動で読む場所」は**ありません**。読まれるルールファイルは

1. プロジェクトの `AGENTS.md` / `CLAUDE.md`（カレントから上方向に探索）
2. `~/.config/opencode/AGENTS.md`
3. `~/.claude/CLAUDE.md`（Claude Code 互換フォールバック）

の3系統だけで、いずれもユーザー単位です。

代わりに **managed config ディレクトリ**があり、Linux では `/etc/opencode/` です
（macOS は `/Library/Application Support/opencode/`、Windows は `%ProgramData%\opencode`）。
ここに置いた `opencode.json` / `opencode.jsonc` は最も高い優先度で読まれ、
ユーザーやプロジェクトの設定では上書きできません。この設定の `instructions` に
絶対パスを書くことで、システム全体の指示文を実現します。

```json title="/etc/opencode/opencode.json"
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["/etc/opencode/AGENTS.md"]
}
```

### 実測で確認済みの挙動 (v1.18.18)

- managed config の `instructions` に書いた絶対パスのファイルは、
  `Instructions from: <パス>` という見出しつきでシステムプロンプトに入る。
- `instructions` 配列は**置換ではなく和集合**でマージされる
  （`mergeConfigConcatArrays`）。ユーザーが自分の `~/.config/opencode/opencode.json` に
  `instructions` を書いていても、システム側のエントリは消えない。
- ユーザーの `~/.config/opencode/AGENTS.md` とも**併存**する（両方ともプロンプトに載る）。
- ベース名部分のグロブが使える。`"/etc/opencode/rules/*.md"` と書けばドロップイン
  ディレクトリになる（ディレクトリ部分にはグロブを使えない）。存在しないパスは黙って無視される。
- 検証方法: `opencode debug config` で解決後の設定を確認できる。
  実際にプロンプトへ載ったかは、ダミーの OpenAI 互換エンドポイントを立てて
  `opencode run -m <fake>/<model>` を実行し、受信リクエストの system メッセージを見るのが確実。

## バージョン更新

`opencode.sh` 冒頭の `VERSION` と `SHA256_*` を書き換えるだけです。sha256 は

```sh
curl -sS https://api.github.com/repos/anomalyco/opencode/releases/latest \
  | jq -r '.assets[]|select(.name|startswith("opencode-linux"))|"\(.name)\t\(.digest)"'
```

で取れます。

**latest を追わずバージョン固定にしている理由**: opencode はほぼ毎日（npm 上のバージョン数は
1万を超える）リリースされるため、`get-github-download-url` で latest を引くとビルドのたびに
中身が変わり、アーティファクトの再現性が失われます。固定 URL なら `download` の
`/var/cache/download` キャッシュも効きます。

## イメージサイズへの影響（v1.18.18 実測）

| | サイズ |
|---|---|
| 実行ファイル (raw) | 175.2 MiB |
| squashfs 既定 (gzip -1 / 128KiB ブロック) | **約 64.8 MiB** |
| squashfs `--compression xz` (1MiB ブロック) | 約 44.5 MiB |

`genpack-create-image` の既定は gzip なので、実際のイメージ増分は 175MiB ではなく
**約 65MiB** です。それでも大きいと感じる場合の選択肢は xz 圧縮への切り替え
（展開が遅くなる代わりに約 20MiB 減）くらいで、バイナリ側を削る余地はありません
（Bun ランタイム＋JS バンドルが一体化した単一ファイルのため）。

## エージェントに渡す調査ツールを選ぶ

genpack アーティファクトには通常の Gentoo にある調査系ツールがほとんど入っておらず、
しかも**実行時にパッケージを追加できません**。トラブルシューティングをエージェントに
任せるつもりなら、何を渡すかはビルド時に決め切っておく必要があります。

`genpack.json5` に候補をコメントアウトで列挙してあるので、用途に応じて有効化してください。
サイズは Gentoo 実機で計測したインストール後の値です（squashfs の gzip では概ねこの 1/3 が
イメージ増分）。

| 用途 | パッケージ | サイズ | メモ |
|---|---|---|---|
| JSON | `app-misc/jq` | 0.5MiB | 設定・API 応答の確認に必須級 |
| 差分 | `sys-apps/diffutils` | 1.6MiB | 「正常な設定と何が違うか」を示せる |
| 採取 | `app-arch/tar` | 2.9MiB | ログ・ダンプの採取と展開 |
| 種別判定 | `sys-apps/file` | 12.3MiB | 大半は magic データベース |
| ページャ | `sys-apps/less` | 0.3MiB | エージェントは非対話なので主に人間用 |
| 占有調査 | `sys-process/lsof` | 0.4MiB | 「このポート/ファイルを誰が握っているか」 |
| プロセス | `sys-process/psmisc` | 0.8MiB | pstree / fuser / killall |
| 性能 | `app-admin/sysstat` | 未計測 | iostat / pidstat / sar |
| HTTP | `net-misc/curl` | 3.3MiB | base には python+requests はあるが CLI が無い |
| DNS | `net-dns/doggo` | 15.6MiB | 後述の理由で bind-tools の代わり |
| TCP | `net-misc/socat` | 1.0MiB | base の telnet シムが案内する先 |
| ハード | `pciutils` / `usbutils` / `dmidecode` / `smartmontools` | 0.2〜2.0MiB | baremetal では既に入っている |
| リポジトリ | `dev-vcs/git` | 39.7MiB | 単なる調査用途では不要 |
| ビルド | `genpack/devel` | gcc 335MiB + gdb 13.5MiB | ネイティブビルド／コアダンプ解析が要る場合のみ |

### base に既にあるもの（重複追加しないこと）

`genpack/base` の RDEPEND に入っているので、どのアーティファクトでも使えます。

- `dev-lang/python` + `dev-python/requests` — **エージェントがワンライナーを書ける**のは大きい
- `sys-apps/coreutils` / `sys-apps/grep` / `sys-apps/which` / `sys-process/procps`（ps, top）
- `sys-apps/iproute2`（ip, **ss**）/ `sys-apps/net-tools` / `net-misc/iputils` / `net-misc/rsync`
- `app-arch/gzip` / `app-arch/unzip` / `app-misc/ca-certificates`
- USE フラグで既定 ON: `app-editors/vim`(+vi) / `dev-debug/strace`(+strace) /
  `net-analyzer/tcpdump`(+tcpdump) / `sys-fs/btrfs-progs`(+btrfs)
- `/bin/sh` は `app-alternatives/sh` 経由で bash（opencode の bash ツールもこれを使う）

プロファイル由来で入るものもあります。

- `genpack/systemimg[baremetal]` — lsscsi, lshw, hwloc, usbutils, pciutils, dmidecode,
  lm-sensors, cpupower, smartmontools, nvme-cli, hdparm, ethtool（amd64 では msr-tools 等も）
- `genpack/paravirt` — qemu-guest-agent, **socat**, sock-forward

稼働中のイメージで確実に知りたい場合は `/.genpack/packages` を見てください。

### DNS ツールについての注意

`net-dns/bind-tools` は Gentoo から削除されています（bug #977172）。代わりに
`net-dns/doggo` を入れると、`genpack/base` の package-script が `dig` / `nslookup` の
シムを `/usr/bin` に置いてくれます。同様に `telnet` は base が意図的に本物を入れず、
socat または `bash /dev/tcp` に誘導するシムを置いています。

---

## 実装上の注意点

- **アーキ**: x86_64 / aarch64 のみ対応。それ以外はスキップして正常終了します。
- **baseline ビルドは不要**: リリースには `opencode-linux-x64-baseline.tar.gz` もありますが、
  v1.18.18 では中身の実行ファイルが通常版と **sha256 まで完全に一致** します
  （tar.gz の digest が違うのは gzip/tar のメタデータ差のみ）。したがって現状は
  どちらを選んでも同じで、AVX2 の有無を気にする必要はありません。
  ただし将来分岐する可能性はあるので、古い CPU を対象にする場合は都度確認すること。
- **ランタイム依存**: 動的リンクは libc / libm / libdl / libpthread のみ、要求 GLIBC は
  最大 2.17。base に無いものは何も要りません。
- **ripgrep**: opencode は `which("rg")` で **PATH 上の rg を最優先** し、見つからない場合だけ
  `github.com/BurntSushi/ripgrep/releases` から 15.1.0 を実行時ダウンロードして
  `$XDG_DATA_HOME/opencode/bin` 相当に展開します。`sys-apps/ripgrep` を同梱すれば
  この外部ダウンロードは発生しません（Portage の ripgrep も 15.1.0）。
- **書き込み先**: 設定・状態・キャッシュはすべて XDG 準拠で `$HOME` 配下
  （`~/.config/opencode`, `~/.local/share/opencode`, `~/.cache/opencode`）。
  イメージが read-only でも `$HOME` が書ける場所にあれば動きます。
- **その他の実行時ダウンロード**: MCP サーバや LSP サーバを使う設定にすると、
  npm レジストリや GitHub から実行時に取得します。閉域運用ではその点も要考慮。
