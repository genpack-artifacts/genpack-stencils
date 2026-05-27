# theme: llama-cpp

llama.cpp（Vulkan バックエンド）を **artifact-local Portage overlay** 経由で導入するステンシルです。

## 構成

```
llama-cpp/
  genpack.json5                              # packages / use の断片
  overlay/
    sci-ml/llama-cpp/
      llama-cpp-0_p9354.ebuild               # タグ固定ebuild (Manifestは自動生成のため不要)
  README.md
```

## アーティファクトへの適用

1. `overlay/sci-ml/llama-cpp/llama-cpp-*.ebuild` を対象アーティファクトの `overlay/sci-ml/llama-cpp/` にコピーする。
2. `genpack.json5` の以下を対象アーティファクトの該当キーへマージする：
   - `packages` に `sci-ml/llama-cpp`
   - （Intel/AMD/ソフトウェアの場合）`use` に `media-libs/mesa: "vulkan"`

   ビルド依存（cmake, シェーダツール, vulkan-headers 等）は ebuild の BDEPEND/DEPEND が
   宣言しており emerge が自動で引くため、`buildtime_packages` への列挙は不要
   （ebuild を単一の真実源とし二重管理を避ける）。詳細は後述「依存の振り分け」を参照。
3. `media-libs/mesa` の `VIDEO_CARDS` はアーティファクトのハードウェアに合わせて設定する
   （例: Intel → `VIDEO_CARDS: intel` / 汎用 → `virgl zink` など）。本ステンシルでは指定しない。
4. マージ箇所には出典コメントを残す: `// ref: llama-cpp/genpack.json5`

Manifest はコミット不要。`SRC_URI` を持つ ebuild に対し genpack が Lower フェーズで
`ebuild ... manifest` を自動実行する（`/var/cache/distfiles` への書き込みは Lower コンテナ内で可能）。

## vulkan はデフォルト ON

ebuild は `IUSE="+vulkan"` とし **Vulkan バックエンドをデフォルトで有効**にしています。
Vulkan 対応ハードウェアの裾野は非常に広く（Intel/AMD は mesa、NVIDIA は nvidia-drivers が
ICD を提供）、`GGML_BACKEND_DL=ON` により Vulkan ICD が無い環境では `libggml-vulkan.so` が
ロードされず **CPU バックエンドへ自動フォールバック**するため、デフォルト ON の不利益は
ほぼありません。プロファイルでグローバル `vulkan` USE が立っているか否かに依存しません。

CPU 専用にしたい場合のみ、アーティファクト側で `sci-ml/llama-cpp: "-vulkan"` を指定します。

### ランタイム ICD（実行環境側の用意）

llama.cpp は `media-libs/vulkan-loader` を RDEPEND で引きますが、ローダが呼び出す
**ICD（実ドライバ）は GPU ベンダのパッケージが提供**します：

| GPU | ICD 提供元 |
|---|---|
| Intel / AMD | `media-libs/mesa[vulkan]`（本ステンシルの `use` 既定） |
| NVIDIA | `x11-drivers/nvidia-drivers`（mesa の vulkan は不要） |
| ソフトウェア | `media-libs/mesa[vulkan]` の lavapipe |

実機での有効確認は `llama-cli --list-devices` で `Vulkan0: <GPU名>` が出るかを見るのが
手軽で確実です（CPU 専用なら Vulkan デバイスは出ません）。

## 依存の振り分け（EAPI 8）

ビルド専用のツールが**ランタイムイメージに混入しない**よう、依存を厳密に分けています：

| 種別 | 内容 | 理由 |
|---|---|---|
| BDEPEND | shaderc(glslc), glslang, spirv-tools, spirv-headers | GLSL→SPIR-V のシェーダコンパイルはビルドホストで実行。実行時不要 |
| DEPEND | vulkan-headers, vulkan-loader | ターゲット向けコンパイル/リンクに必要 |
| RDEPEND | **vulkan-loader のみ** | `libggml-vulkan.so` が実行時に `libvulkan.so.1` 経由でロード（binpkg の NEEDED/REQUIRES で確認済み） |

`dev-build/cmake` は **記述しません** — `cmake.eclass` が BDEPEND に自動追加するためです。

これにより、アーティファクト側の `buildtime_packages` に cmake / vulkan-headers / shaderc を
重ねて書く必要もなくなります（ebuild が単一の真実源）。

## バージョニング方針（重要）

`9999` ライブ ebuild は **使いません**。代わりに上流のリリースタグ（`bXXXX`）に固定し、
Portage 準拠のバージョン文字列 `0_pXXXX` を用います（Gentoo のバージョンは数字始まり必須のため）。

### 理由
- binpkg / Lower 層のキャッシュが効きやすい
- 再現性・安定性が高い
- ライブ ebuild の「Lower のたびに必ず再ビルド」問題を避けられる

以前は `files/build.d/llama-cpp` スクリプトで導入していたが、これは Upper フェーズの
たびにフルリコンパイルを引き起こしていた。overlay + タグ固定 ebuild 化でこれを解消している。

### 新しい上流リリースへの更新手順

1. https://github.com/ggml-org/llama.cpp/releases で新しいタグを確認する
2. ebuild ファイルをリネームする（例）:
   ```sh
   mv llama-cpp-0_p9354.ebuild llama-cpp-0_p9500.ebuild
   ```
3. （まれに）ebuild 内の `UPSTREAM_TAG`・フラグ・パッチを調整する
4. Manifest は手動生成不要（Lower フェーズで自動生成）。手元で確認したい場合のみ:
   ```sh
   ebuild /path/to/llama-cpp-0_p9500.ebuild manifest
   ```
5. Lower 再ビルドをトリガーする:
   ```sh
   genpack lower
   ```

Lower 層が更新されれば、以降の `genpack upper` は再び高速になる。

## UI（WebUI）について

npm を使わず、GitHub リリースに添付された UI tarball（`llama-<tag>-ui.tar.gz`）を
`src_prepare` で `tools/ui/dist/` に展開する。これによりビルド時の npm 実行と
HuggingFace ダウンロードを回避している（network-sandbox で npm はブロックされるため）。

`llama-server` 起動例:

```sh
llama-server -m /path/to/model.gguf --public-path /usr/share/llama.cpp/server
```

## 取り込み済みアーティファクト

このステンシルは以下から切り出した（切り出し時点では両者の ebuild は同一だった）:

- `genpack-artifacts/gnome`
- `genpack-artifacts/vkcompute`

ステンシル化にあたり ebuild を `IUSE="vulkan"` → `IUSE="+vulkan"`（デフォルト ON）に変更した。
gnome/vkcompute はプロファイルのグローバル `vulkan` USE で既に Vulkan 有効になっており、
このステンシルを適用し直しても挙動は変わらないが、ebuild の同期は追って行うこと。

影響範囲の確認は `rg 'ref: llama-cpp'` で行う。
