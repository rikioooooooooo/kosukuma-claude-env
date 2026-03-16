#!/bin/bash
# SessionEnd フック — プロンプトログがあれば自動commit+push
# 制限: 1.5秒以内に完了する必要がある

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

LOG_DIR="$REPO_ROOT/prompt-logs"
if [ ! -d "$LOG_DIR" ] || [ -z "$(ls -A "$LOG_DIR" 2>/dev/null)" ]; then
  exit 0
fi

cd "$REPO_ROOT" || exit 0

# git add + commit（高速化のためバックグラウンド）
{
  git add prompt-logs/ 2>/dev/null
  if ! git diff --cached --quiet 2>/dev/null; then
    git commit -m "auto: prompt-log $(date +%Y-%m-%d)" --no-verify 2>/dev/null
    git push origin HEAD --no-verify 2>/dev/null
  fi
} &

exit 0
