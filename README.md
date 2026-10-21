# AtCoder

AtCoder（2025年10月環境）に対応したRust環境です。

---

## acコマンド

```powershell
# コンテスト用ディレクトリの作成 (abcXXX/a.rs ~ g.rs の生成 & Cargo.toml 登録)
.\ac new abc400

# テスト実行 (input.txt を標準入力として渡して実行)
.\ac run abc400 a
.\ac run abc400/a.rs        # パス指定も可
.\ac run -r abc400 a        # リリースビルド実行

# 提出用コピー (dbg! マクロと dbg!(...) 呼び出しを除去してクリップボードへコピー)
.\ac copy abc400 a
```

---

## ノート検索

`notes/` ディレクトリ以下に保存されたメモをターミナルから一覧・検索できます。

```powershell
# ノート一覧をカテゴリ階層ごとに表示
.\ac note

# 特定のページを丸ごと表示
.\ac note proconio
.\ac note crates/ac-library

# キーワードで検索
.\ac note 配列
.\ac note input!
```

### ノートの追加・編集方法

`notes/` 以下に任意のフォルダ・`.md` ファイルを作成または編集するだけで自動的に検索対象になります。

````markdown
# ページのタイトル

tags: キーワード1, キーワード2

## セクション見出し (検索時の抽出単位)

説明文

```rust
// コード例
```
````
