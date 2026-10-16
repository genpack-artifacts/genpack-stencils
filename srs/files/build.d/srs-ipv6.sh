#!/bin/sh
# ref: srs/files/build.d/srs-ipv6.sh
# 公式 media-video/srs 同梱の /etc/srs/srs.conf は各 listen を IPv4 のみ
# ("listen <port>;") で待ち受ける。Linux の dual-stack で IPv6/IPv4 両方を
# 受けられるよう、listen を "listen [::]:<port>;" に書き換える。
#
# 対象: RTMP(1935) / http_api(1985) / srt_server(10080)。
# 注意: SRT の "[::]:10080" は patches/media-video/srs/srs-srt-ipv6-listen.patch
#       (listen 指令の IPv6 形式解釈修正) とセットでないと効かない。パッチ無しでは
#       整数パースに失敗し port 0 → ランダムな ephemeral ポートを IPv4 で bind する。
set -e

CONF=/etc/srs/srs.conf
[ -f "$CONF" ] || exit 0

sed -i -E 's/^([[:space:]]*)listen([[:space:]]+)(1935|1985|10080);/\1listen\2[::]:\3;/' "$CONF"
