#!/bin/sh
# ref: lateral-hoihoi/files/build.d/lateral-hoihoi.sh
set -e

require-installed net-firewall/nftables

# リポジトリに release/tag がないため get-github-download-url @tarball は使えない。
# デフォルトブランチ(main)のソース tarball を直接取得する。
SRC=/tmp/lateral-hoihoi
mkdir -p "$SRC"
download https://codeload.github.com/shimarin/lateral-hoihoi/tar.gz/refs/heads/main | tar xzf - -C "$SRC" --strip-components=1

cp "$SRC/lateral_hoihoi.py" /usr/bin/lateral-hoihoi
chmod +x /usr/bin/lateral-hoihoi
cp "$SRC/lateral-hoihoi.conf.example" /etc/lateral-hoihoi.conf
chmod 600 /etc/lateral-hoihoi.conf

# 共有イメージ用ベースライン(汎用除外のみ)をリポジトリからそのまま置く。
# インスタンス固有のサービス除外は各インスタンスのデータパーティション上で
# 同ファイルを編集してカスタマイズする(ファイル内のコメントを参照)。
mkdir -p /etc/nftables/rules
cp "$SRC/nftables.coexist.example.nft" /etc/nftables/rules/lateral-hoihoi.nft
