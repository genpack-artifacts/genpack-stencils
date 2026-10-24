#!/bin/sh
# ref: obs-plugins/files/build.d/advanced-scene-switcher.sh
# OBS 33.0 からの新ロケーション (obs-modules/plugins) へ設置する。
# リリースアセット名が ubuntu フレーバー込み (advanced-scene-switcher-<ver>-x86_64-ubuntu24.04-linux-gnu.tar.xz)
# になった。旧 LTS ビルドのほうが glibc 要求が低く他ディストリビューションで扱いやすい。
# advanced-scene-switcher-plugins/ 配下は本体が実行時に読む補助モジュールで OBS 自身は
# スキャンしない (新ロケーションは *.so のフラットスキャン)。本体 .so と同じ相対配置を保つ。
# 補助モジュールのうち opencv 系は app-text/tesseract (libtesseract.so.5) を要求する
# (無い場合はその補助モジュールだけが読み込み失敗し本体は動作する)。
set -e

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  printf 'Unsupported architecture (%s). Skipping advanced-scene-switcher.\n' "$arch" >&2
  exit 0
fi

plugin_module_dir=/usr/lib64/obs-modules/plugins
plugin_data_dir=/usr/share/obs/obs-modules/plugins

echo "Installing advanced-scene-switcher..."
mkdir -p /tmp/advanced-scene-switcher
download $(get-github-download-url WarmUpTill SceneSwitcher 'advanced-scene-switcher-.*-x86_64-ubuntu24\.04-linux-gnu\.tar\.xz$') | tar Jxf - -C /tmp/advanced-scene-switcher
mkdir -p "$plugin_module_dir" "$plugin_data_dir"
mv /tmp/advanced-scene-switcher/lib/*/obs-plugins/* "$plugin_module_dir"/
mv /tmp/advanced-scene-switcher/share/obs/obs-plugins/advanced-scene-switcher "$plugin_data_dir"/
