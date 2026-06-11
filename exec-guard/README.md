# exec-guard

genpack-init の **exec-guard**（eBPF LSM による実行保護）を有効化するテーマです。

overlayfs の upper layer（書き込み可能層）に持ち込まれた ELF バイナリ・共有ライブラリの
実行を、署名検証なしにカーネルレベルでブロックします。仕組み・適用条件・リカバリー方法は
`genpack/docs/exec-guard.md` を参照してください。

## 適用

`genpack.json5` の `use` に以下を追加します（フラグメント参照）。

```json5
use: {
  "sys-apps/genpack-init": "exec-guard",
}
```

ビルド時に必要な clang / bpftool は genpack-overlay の ebuild が依存関係として自動追加するため、
明示指定は不要です。無効化はブートパーティション上の `system.ini` に `exec_guard = false`。

## 検証スクリプト: `test-memfd-exec`

`files/usr/bin/test-memfd-exec` は、exec-guard が **ファイルレス実行**
（`memfd_create` でディスクに痕跡を残さず ELF を実行する、攻撃ツールが検知回避に好む手法）を
ブロックすることを実機で確認するための Python スクリプトです。python3 と ctypes を前提とします。

2 つのテストを実行します。

1. **陰性対照**: ディスク上（lower layer）の信頼バイナリを `fexecve` → 成功するはず
2. **本命**: 同じバイナリを `memfd` にコピーして `fexecve` → `EPERM` でブロックされるはず

exec-guard 有効のイメージ内で `test-memfd-exec` を実行し、[2] が
`errno=1 (EPERM)` でブロックされれば期待通り（exit 0）。exec-guard 非適用のホストで実行すると
[2] が素通りするため exit 1 になります（テスト機構自体の動作確認に使えます）。

このスクリプト自体は Python スクリプト（非 ELF）なのでインタプリタ経由で実行でき、
exec-guard の制約は受けません。

### 取り込み時の注意

`files/usr/bin/test-memfd-exec` をアーティファクトにコピーする際は、スクリプト冒頭の
出典コメント（`# ref: exec-guard/files/usr/bin/test-memfd-exec`）を残してください。
これは恒久的に同梱するものではなく、新規イメージで exec-guard の動作を確認したい場合に
一時的に入れる用途を想定しています。本番イメージでは取り除いて構いません。
