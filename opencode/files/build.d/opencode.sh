#!/bin/sh
# ref: opencode/files/build.d/opencode.sh
set -e

# 更新時はこの3行を書き換える。
# sha256はリリースアセット opencode-linux-<TARGET>.tar.gz のもので、
#   curl -sS https://api.github.com/repos/anomalyco/opencode/releases/latest \
#     | jq -r '.assets[]|select(.name|startswith("opencode-linux"))|"\(.name)\t\(.digest)"'
# で取得できる。
VERSION=1.18.18
SHA256_x64=0cddc222418b8553669905a8980c0cda7088f00da24d83d6ac76b01c9fdb2aaf
SHA256_arm64=dcb1b5ec5687b43f87749560021f9203f3809e0ce5ae44ff9be8ae17083fe4ba

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        TARGET=x64
        SHA256=$SHA256_x64
        ;;
    aarch64)
        TARGET=arm64
        SHA256=$SHA256_arm64
        ;;
    *)
        echo "Unsupported architecture: $ARCH. Skipping opencode installation."
        exit 0
        ;;
esac

# バージョン固定。latestを追う場合は下記URLを
#   URL=$(get-github-download-url anomalyco opencode "opencode-linux-${TARGET}\.tar\.gz\$")
# に置き換え、sha256sumの検証行を削除する(opencodeはほぼ毎日リリースされるため
# 追従するとアーティファクトの再現性が失われる点に注意)。
URL="https://github.com/anomalyco/opencode/releases/download/v${VERSION}/opencode-linux-${TARGET}.tar.gz"

echo "Downloading opencode ${VERSION} (linux-${TARGET})..."
download "$URL" > /tmp/opencode.tar.gz
echo "${SHA256}  /tmp/opencode.tar.gz" | sha256sum -c -
tar zxf /tmp/opencode.tar.gz -C /usr/bin opencode
rm -f /tmp/opencode.tar.gz
chmod 755 /usr/bin/opencode
