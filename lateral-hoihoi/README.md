# theme: lateral-hoihoi

[ラテラルムーヴメント(内部侵入者の横展開偵察)を検出する罠デーモン](https://github.com/shimarin/lateral-hoihoi)
を導入するステンシルです。nftables が NFLOG で拾った「自ホスト宛の想定外ユニキャスト」
(ポートスキャン・ARP スイープ等)を集約してメールで管理者に通知し、境界の内側で
早期警戒を行います。

最適な運用(セグメントごとに無サービス専用ホストを 1 台置く、除外ゼロ運用)は
upstream README を参照してください。

## 構成

```
lateral-hoihoi/
  genpack.json5                              # packages の断片 (nftables)
  files/
    build.d/lateral-hoihoi.sh                # ソース取得・デーモン/設定/nft ベースラインの配置
    usr/lib/systemd/system/lateral-hoihoi.service  # systemd unit
  README.md
```

## アーティファクトへの適用

1. `genpack.json5` の `packages` を対象アーティファクトへマージ。
   マージ箇所に `// ref: lateral-hoihoi/genpack.json5` を残す。
2. `files/build.d/lateral-hoihoi.sh` を `files/build.d/` にコピー。
3. `files/usr/lib/systemd/system/lateral-hoihoi.service` を `files/` にコピー。
4. インスタンス上で `/etc/lateral-hoihoi.conf` (SMTP 認証情報) と
   `/etc/nftables/rules/lateral-hoihoi.nft` (サービス除外) を編集する。
5. 自動起動したい場合のみ `genpack.json5` に `services: ["lateral-hoihoi"]` を追加。
   既定では起動せず、インスタンスごとに `systemctl enable --now lateral-hoihoi` も可。

影響範囲の確認は `rg 'ref: lateral-hoihoi'` で行う。

## 注意

- デーモンは Python 標準ライブラリのみ。Python パッケージの追加は不要。
- ソース取得はデフォルトブランチ(main)の codeload URL を `download` で直接取得する。
  リポジトリに release/tag がないため `get-github-download-url @tarball` は使えない。
- NFLOG グループの bind に CAP_NET_ADMIN(実質 root)が必要。既定で root 実行。
- 設定ファイルに SMTP パスワードを直書きするため root:root 0600 を維持すること
  (build スクリプトが chmod 600 する)。
- unit は同梱されるが既定では自動起動しない。

## 取り込み済みアーティファクト

- `genpack-artifacts/camera`（本ステンシルの素体）
