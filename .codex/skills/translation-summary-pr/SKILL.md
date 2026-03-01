---
name: translation-summary-pr
description: angular-ja で指定されたファイルを CONTRIBUTING.md の翻訳ガイドラインに沿って日本語で要約し、summary ファイル作成から branch 作成、commit、push、PR 作成まで一括実行するときに使う。ファイルパスだけ渡して要約PRを作りたい依頼で起動する。
---

# translation-summary-pr

## Goal

- 入力された 1 つのファイルパスをもとに、`*.summary.md` を作成または更新する。
- `fix(docs): {file name} translations` 形式で commit と PR を作成する。

## Input

- 引数は対象ファイルパス 1 つのみ（相対/絶対のどちらでも可）。
- 対象はリポジトリ配下のテキストファイルを想定し、要約は日本語で作成する。

## Commands

- 事前確認:
  - `test -e "$TARGET_PATH"`
  - `git rev-parse --is-inside-work-tree`
  - `gh auth status`
  - `gh api rate_limit`
- 派生情報の計算:
  - `eval "$(.codex/skills/translation-summary-pr/scripts/prepare_summary_pr.sh "$TARGET_PATH")"`
- lint（日本語文面を追加/更新した場合）:
  - `pnpm run lint`
- Git/PR:
  - `git switch -c "$BRANCH_NAME"`（同名 branch がなければ）
  - `git add "$SUMMARY_REL"`
  - `git status --short`
  - `git diff --cached --name-only`
  - `git commit -m "$PR_TITLE"`
  - `git push -u origin "$BRANCH_NAME"`
  - `gh pr create --base main --head "$BRANCH_NAME" --title "$PR_TITLE" --body "$PR_BODY"`

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

- `CONTRIBUTING.md` の方針に従い、原文のニュアンスを保ち、過度な意訳を避ける。
- 技術文書として簡潔に書き、曖昧な主観を入れない。
- 対象ファイル本体は変更せず、要約ファイルのみを変更する。
- 要約で日本語を変更した場合は `pnpm run lint` を必ず実行する。
- PRタイトルは必ず `fix(docs): {file name} translations` とする。

## Workflow

1. 対象ファイルの存在、Git 管理下、GitHub 疎通を確認する。
2. `prepare_summary_pr.sh` を実行して `SUMMARY_REL`、`BRANCH_NAME`、`PR_TITLE` を取得する。
3. 対象ファイルを読んで要約を作成し、`$SUMMARY_REL` を上書きする。
4. 日本語変更があるため `pnpm run lint` を実行し、失敗時は修正して再実行する。
5. `git add` から `gh pr create` まで実行して PR を作る。
6. 最終報告では `summary ファイルパス`、`実行コマンド`、`PR URL` を短く提示する。

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
