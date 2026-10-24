#!/bin/sh
# ref: xmrig/files/build.d/xmrig.sh
set -e

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_STR="x64"
else
    echo "Unsupported architecture: $ARCH. Skipping xmrig installation."
    exit 0
fi

echo 'Downloading xmrig...'
rm -rf /tmp/xmrig-*
download $(get-github-download-url xmrig xmrig "xmrig-.*-jammy-${ARCH_STR}\.tar\.gz$") | tar zxvf - -C /tmp

# Portage 外ソフトウェアなのでバージョンを /.genpack/ に記録する。
# リリース tarball のトップレベルディレクトリ名 (xmrig-<ver>) がリリースバージョン。
#
# 代替案: 導入したバイナリ自身に版を申告させる方法もある (xmrig は --version で
# "XMRig 6.26.0" を印字して終了する)。
#   XMRIG_VERSION=$(/usr/bin/xmrig --version | sed -n '1{s/^XMRig //;p}')
# 配布物名と実体の版が食い違う余地を残さない利点がある一方、ビルド環境で第三者
# バイナリを実行することになるため、ビルド環境の glibc/CPU 要求を理由に起動失敗
# すると記録できないというトレードオフがある。ソフトウェア自身が持つ版情報を
# 取り出す方式は owncloud の /.genpack/owncloud-version でも採用している
# (同梱の version.php を php で評価して読む)。
set -- /tmp/xmrig-*
XMRIG_DIR=$1
XMRIG_VERSION=${XMRIG_DIR##*/}
XMRIG_VERSION=${XMRIG_VERSION#xmrig-}
echo "xmrig ${XMRIG_VERSION}"

mv "$XMRIG_DIR/xmrig" /usr/bin/
mkdir -p /.genpack
echo "$XMRIG_VERSION" > /.genpack/xmrig-version
