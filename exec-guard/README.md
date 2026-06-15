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

## 動作検証

このテーマは exec-guard を**有効化する**ための部品のみを提供します。動作検証用のテストスクリプト
（ファイルレス実行や mmap→mprotect バイパス等の攻撃シミュレータ）は、それらが誤って本番
アーティファクトに紛れ込まないよう、ここには同梱していません。

exec-guard 専用のテストアーティファクト `genpack-artifacts/execguard` に回帰スイート
（`files/root/run-exec-guard-tests`）と攻撃シミュレータ（`files/usr/bin/test-memfd-exec`,
`test-mprotect-exec`）が収録されています。検証方法はそちらの README を参照してください。
