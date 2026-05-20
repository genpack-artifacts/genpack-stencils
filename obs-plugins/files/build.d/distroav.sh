#!/bin/sh
# ref: obs-plugins/files/build.d/distroav.sh
set -e

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  printf 'Unsupported architecture (%s). Skipping distroav.\n' "$arch" >&2
  exit 0
fi

echo "Installing distroav..."
download $(get-github-download-url DistroAV DistroAV '.*-x86_64-linux-gnu\.deb$') > /tmp/distroav.deb
deb2targz /tmp/distroav.deb
mkdir /tmp/distroav
tar xvf /tmp/distroav.tar.gz -C /tmp/distroav
mv /tmp/distroav/usr/lib/x86_64-linux-gnu/obs-plugins/*.so /usr/lib64/obs-plugins/
mv /tmp/distroav/usr/share/obs/obs-plugins/* /usr/share/obs/obs-plugins/
