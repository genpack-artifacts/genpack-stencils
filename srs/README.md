# theme: srs

SRS (Simple Realtime Server) を **Gentoo 公式 `media-video/srs`** で導入するステンシルです。
RTMP 取込・SRT 取込・HLS 出力に対応したストリーミングサーバーを提供します。

> 旧版は `files/build.d/srs.sh` でソースを取得して `./configure && make` していました。
> 2026-05 に `media-video/srs` が公式ツリーへ入ったため、ビルドを Portage に寄せる形へ移行しました。
> ソースビルドを伴うので（バイナリ展開だけの xmrig 等と違い）ebuild 化の恩恵が大きく、
> binpkg / Lower キャッシュが効いて再現性も上がります。

## 構成

```
srs/
  genpack.json5                              # packages / accept_keywords / use の断片
  files/
    build.d/srs-ipv6.sh                      # listen を dual-stack 化 (任意)
    usr/lib/systemd/system/srs.service       # systemd unit (公式は OpenRC のみのため自前)
    usr/lib/tmpfiles.d/srs.conf              # HLS 出力先 /var/spool/srs を生成
  README.md
```

## アーティファクトへの適用

1. `genpack.json5` の `packages` / `accept_keywords` / `use` を対象アーティファクトへマージ。
   - システム ffmpeg が前提（`--sys-ffmpeg=on`）。対象に `media-video/ffmpeg` が無ければ追加する。
   - マージ箇所に `// ref: srs/genpack.json5` を残す。
2. `files/usr/lib/systemd/system/srs.service` と `files/usr/lib/tmpfiles.d/srs.conf` をコピー。
3. dual-stack で待ち受けたい場合は `files/build.d/srs-ipv6.sh` もコピー。
4. 自動起動したい場合のみ `genpack.json5` に `services: ["srs"]` を追加。
   unit は同梱されるので、既定は起動せずインスタンスごとに `systemctl enable --now srs` も可。

影響範囲の確認は `rg 'ref: srs'` で行う。

## 公式 ebuild 採用に伴う注意

- **バイナリ名は `/usr/bin/srs-media`**（公式 ebuild の `newbin objs/srs srs-media`）。
  旧 `srs.sh` は `/usr/bin/srs` だったので、パス参照があれば修正する。
- **設定は公式同梱の `/etc/srs/srs.conf` をそのまま使用**。`daemon off;` 前提なので systemd は
  `Type=simple`（foreground）。RTMP 1935 / http_api 1985 / SRT 10080(UDP)、HLS は `/var/spool/srs`。
- **`dev-lang/tcl` / `net-libs/libsrtp` は不要**。公式は `--rtc=off` のため SRTP を使わず、
  `ldd /usr/bin/srs-media` でも libsrtp は非リンク（`libsrt`/`libssl`/`libcrypto` のみ）。
- **サービス管理は systemd unit を自前提供**。公式 ebuild は OpenRC の init.d/conf.d のみ同梱で、
  genpack は systemd ベースのため。

## IPv6 (dual-stack) と SRT の制約

`srs-ipv6.sh` は `/etc/srs/srs.conf` の TCP リスナーを `listen [::]:<port>;` に書き換えて
dual-stack 化します（RTMP 1935 / http_api 1985）。

**SRT(10080) は対象外**。SRS の `srt_server.listen` はポート番号（整数）のみを受け付ける仕様で、
`[::]:10080` を与えると整数パースに失敗し port 0 → ランダムな ephemeral ポートを IPv4 で
bind してしまう（実測で確認）。よって SRT は IPv4 の `listen 10080;` のまま残します。
この listen 指定では SRT の IPv6 は実質非対応と割り切ってください。

適用後の期待状態（`netstat -apn | grep srs-media`）:

```
tcp6  :::1935   LISTEN   srs-media   # RTMP (dual-stack, IPv4 も受かる)
tcp6  :::1985   LISTEN   srs-media   # http_api (dual-stack)
udp   0.0.0.0:10080      srs-media   # SRT (IPv4)
```

## 取り込み済みアーティファクト

- `genpack-artifacts/camera`（本ステンシルの素体）

バージョン更新は Portage 任せ（`media-video/srs` のツリー更新に追随）。
