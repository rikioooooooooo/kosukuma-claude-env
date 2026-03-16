#!/bin/bash
# UserPromptSubmit フック — 各プロンプトをJSONL形式でローカルに記録
# stdin: { session_id, prompt, cwd, ... }

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ユーザー名取得（OS別）
if command -v whoami &>/dev/null; then
  USER_NAME=$(whoami)
else
  USER_NAME="${USER:-unknown}"
fi

# 空プロンプトはスキップ
if [ -z "$PROMPT" ]; then
  exit 0
fi

# プロジェクトルートの prompt-logs/ に保存
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="${CLAUDE_PROJECT_DIR:-.}"
fi

LOG_DIR="$REPO_ROOT/prompt-logs"
mkdir -p "$LOG_DIR"

# 機密情報の簡易マスク（APIキー、トークン等）
MASKED_PROMPT=$(echo "$PROMPT" | sed -E \
  -e 's/(sk-ant-[a-zA-Z0-9_-]{8})[a-zA-Z0-9_-]*/\1[REDACTED]/g' \
  -e 's/(sk-[a-zA-Z0-9]{8})[a-zA-Z0-9]*/\1[REDACTED]/g' \
  -e 's/(ghp_[a-zA-Z0-9]{8})[a-zA-Z0-9]*/\1[REDACTED]/g' \
  -e 's/(xoxb-[a-zA-Z0-9]{8})[a-zA-Z0-9-]*/\1[REDACTED]/g' \
  -e 's/([A-Za-z0-9+\/]{40,}={0,2})/[BASE64_REDACTED]/g')

# JSONL形式で追記
jq -nc \
  --arg user "$USER_NAME" \
  --arg sid "$SESSION_ID" \
  --arg ts "$TIMESTAMP" \
  --arg prompt "$MASKED_PROMPT" \
  --arg cwd "$(echo "$INPUT" | jq -r '.cwd // empty')" \
  '{user: $user, session_id: $sid, timestamp: $ts, prompt: $prompt, project_dir: $cwd}' \
  >> "$LOG_DIR/${USER_NAME}-prompts.jsonl" 2>/dev/null

exit 0
