---
name: translation-summary-pr
description: angular-ja で指定されたファイルを CONTRIBUTING.md の翻訳ガイドラインに沿って日本語化する作業で、英語から日本語への自然な翻訳以外の変更を禁止したうえで summary ファイル作成から branch 作成と commit まで一括実行するときに使う。ファイルパスだけ渡して要約作業を完了したい依頼で起動する。
---

# translation-summary-pr

## Goal

- 入力された 1 つのファイルパスをもとに、`*.summary.md` を作成または更新する。
- `fix(docs): {file name} translations` 形式で commit メッセージ（兼PRタイトル候補）を作成する。

## Input

- 引数は対象ファイルパス 1 つのみ（相対/絶対のどちらでも可）。
- 対象はリポジトリ配下のテキストファイルを想定し、要約は日本語で作成する。

## Commands

- 事前確認:
  - `test -e "$TARGET_PATH"`
  - `git rev-parse --is-inside-work-tree`
- 派生情報の計算:
  - `eval "$(.codex/skills/translation-summary-pr/scripts/prepare_summary_pr.sh "$TARGET_PATH")"`
- 用語平仄チェック:
  - `rg -n "Angularアニメーション|Angular Animations" adev-ja/src/content --glob '!**/*.en.md'`
  - 対象ドキュメントと同テーマの既存翻訳を読み、優先訳語を確定する。
- lint（日本語文面を追加/更新した場合）:
  - `pnpm run lint`
- Git（ローカルのみ）:
  - `git switch -c "$BRANCH_NAME"`（同名 branch がなければ）
  - `git add "$SUMMARY_REL"`
  - `git status --short`
  - `git diff --cached --name-only`
  - `git commit -m "$PR_TITLE"`

## Summary Format

`$SUMMARY_REL` は以下の構成で上書き作成する。

```md
# Summary: {file name}

## Source
- Path: `{target relative path}`

## 要点
- 主要ポイントを 5〜10 件で列挙する。

## 翻訳メモ
- 原文ニュアンス維持のための注意点を 3〜5 件で列挙する。
- Angular 固有用語の扱いと訳語の注意を入れる。

## 未解決・確認事項
- 推測が必要だった点、確認が必要な点を列挙する（なければ `- なし`）。
```

## Rules

- 最優先ルール: 英語から日本語への自然な翻訳以外の変更は絶対に行わない。
- 禁止事項: 要約による情報削減、意味追加、文の削除、段落や見出し順序の変更、見出しID/アンカーの追加削除、リンクURL変更、コードブロックや`<docs-code*>`タグの変更、`path`や識別子の変更。
- `CONTRIBUTING.md` の方針に従い、原文のニュアンスを保ち、過度な意訳を避ける。
- 技術文書として簡潔に書き、曖昧な主観を入れない。
- プロジェクト内の既存翻訳を正とし、用語の平仄を最優先で合わせる（例: `Angularアニメーション` を採用し、`Angular Animations` は使わない）。
- 表記ゆれが見つかった場合は、該当箇所を既存訳語へ翻訳し直す。
- 対象ファイル本体は変更せず、要約ファイルのみを変更する。
- 要約で日本語を変更した場合は `pnpm run lint` を必ず実行する。
- Git 操作は `git commit` までに限定し、`git push` や PR の作成・更新は実行しない。

## Workflow

1. 対象ファイルの存在と Git 管理下を確認する。
2. `prepare_summary_pr.sh` を実行して `SUMMARY_REL`、`BRANCH_NAME`、`PR_TITLE` を取得する。
3. 対象ファイルの主要用語を抽出し、同カテゴリの既存翻訳を検索して優先訳語を決める。
4. 翻訳対象外の要素（見出し構造、見出しID、リンクURL、コード、`<docs-code*>`タグ、`path`属性）を保持し、変更しない。
5. 優先訳語に合わせて英語文を自然な日本語へ翻訳し、`$SUMMARY_REL` を上書きする（要約による削除・追記・再構成はしない）。
6. 日本語変更があるため `pnpm run lint` を実行し、失敗時は修正して再実行する。
7. `git add` から `git commit` まで実行する。
8. 最終報告では `summary ファイルパス`、`正規化した用語`、`実行コマンド` を短く提示する。

## PR Body Template

`PR_BODY` は以下テンプレートを使う。

```md
## Summary
- Added summary file for `{file name}`.

## Source
- `{target relative path}`

## Output
- `{summary relative path}`
```
