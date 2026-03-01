# Agent Instructions

- Git operations are allowed up to `git commit` (including staging and branch management). `git push` and remote operations (PR updates, review, merge) are not allowed.
- Keep using small, logical commits and verify staged files before each commit.
- Prefer Japanese for all responses unless the user explicitly requests another language.
- If you add or modify Japanese text in any file, run `pnpm run lint` before the final response and report results. If it cannot be run, state the reason.
