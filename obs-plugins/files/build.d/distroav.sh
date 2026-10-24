#!/bin/sh
# ref: obs-plugins/files/build.d/distroav.sh
# OBS 33.0 からの新ロケーション (obs-modules/plugins) へ設置する。
# 注意: distroav 6.2.2 以降は NDI SDK >= 6.3.0 を要求する (6.2.0 までだと
#   "NDI minimum version not met" で読み込み失敗する)。NDI SDK を更新できない
#   環境では 6.1.x 系を明示的に選ぶこと。
set -e

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  printf 'Unsupported architecture (%s). Skipping distroav.\n' "$arch" >&2
  exit 0
fi

plugin_module_dir=/usr/lib64/obs-modules/plugins
plugin_data_dir=/usr/share/obs/obs-modules/plugins

echo "Installing distroav..."
download $(get-github-download-url DistroAV DistroAV '.*-x86_64-linux-gnu\.deb$') > /tmp/distroav.deb
deb2targz /tmp/distroav.deb
mkdir -p /tmp/distroav
tar xf /tmp/distroav.tar.gz -C /tmp/distroav
mkdir -p "$plugin_module_dir" "$plugin_data_dir"
find /tmp/distroav/usr/lib -path '*/obs-plugins/*' -name '*.so' -exec mv -t "$plugin_module_dir" {} +
mv /tmp/distroav/usr/share/obs/obs-plugins/* "$plugin_data_dir"/
