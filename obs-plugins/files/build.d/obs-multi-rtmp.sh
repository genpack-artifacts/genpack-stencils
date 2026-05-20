#!/bin/sh
# ref: obs-plugins/files/build.d/obs-multi-rtmp.sh
set -e

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  printf 'Unsupported architecture (%s). Skipping obs-multi-rtmp.\n' "$arch" >&2
  exit 0
fi

echo "Installing obs-multi-rtmp..."
# get-github-download-url は GitHub の "Latest release" を取得する。
# プレリリース等で最新版が Latest に昇格していない場合は代わりに直接 URL を指定する:
#   download 'https://github.com/sorayuki/obs-multi-rtmp/releases/download/0.7.4/obs-multi-rtmp-0.7.4.0-x86_64-linux-gnu.deb' > /tmp/obs-multi-rtmp.deb
download $(get-github-download-url sorayuki obs-multi-rtmp 'obs-multi-rtmp-.*x86_64-linux-gnu\.deb$') > /tmp/obs-multi-rtmp.deb
deb2targz /tmp/obs-multi-rtmp.deb
mkdir /tmp/obs-multi-rtmp
tar xvf /tmp/obs-multi-rtmp.tar.gz -C /tmp/obs-multi-rtmp
mv /tmp/obs-multi-rtmp/usr/lib/x86_64-linux-gnu/obs-plugins/*.so /usr/lib64/obs-plugins/
mv /tmp/obs-multi-rtmp/usr/share/obs/obs-plugins/* /usr/share/obs/obs-plugins/
