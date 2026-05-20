#!/bin/sh
# ref: obs-plugins/files/build.d/advanced-scene-switcher.sh
set -e

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  printf 'Unsupported architecture (%s). Skipping advanced-scene-switcher.\n' "$arch" >&2
  exit 0
fi

echo "Installing advanced-scene-switcher..."
mkdir /tmp/advanced-scene-switcher
download $(get-github-download-url WarmUpTill SceneSwitcher 'advanced-scene-switcher-.*-x86_64-linux-gnu\.tar\.xz$') | tar Jxvf - -C /tmp/advanced-scene-switcher
mv /tmp/advanced-scene-switcher/share/obs/obs-plugins/advanced-scene-switcher /usr/share/obs/obs-plugins/
mv /tmp/advanced-scene-switcher/lib/x86_64-linux-gnu/obs-plugins/* /usr/lib64/obs-plugins/
