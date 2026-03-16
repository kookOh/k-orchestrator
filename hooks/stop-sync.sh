#!/usr/bin/env bash
# k-orchestrator Stop hook — persist a session summary into an Obsidian vault.
# Non-blocking by design.

set +e -uo pipefail

VAULT_DIR="${VAULT_DIR:-}"
CLAUDEBOX_PROFILE="${CLAUDEBOX_PROFILE:-}"
CLAUDEBOX_USER="${CLAUDEBOX_USER:-unknown}"
CLAUDEBOX_WORKTREE_ID="${CLAUDEBOX_WORKTREE_ID:-unknown}"
CLAUDEBOX_BASE_BRANCH="${CLAUDEBOX_BASE_BRANCH:-unknown}"
# Claude Code hooks는 프로젝트 루트에서 실행됨 — Docker 환경에서는 WORKDIR이 프로젝트 루트여야 함
STATUS_FILE="${K_ORCHESTRATOR_STATUS_FILE:-docs/EXECUTION_STATUS.md}"

echo "[k-orchestrator] Stop: batch 상태 및 EXECUTION_STATUS.md 업데이트 확인"

if [ -z "$VAULT_DIR" ] || [ ! -d "$VAULT_DIR" ]; then
  echo "[k-orchestrator] VAULT_DIR 미설정 또는 디렉토리 없음 — vault 동기화 스킵"
  exit 0
fi

if [ ! -r "$STATUS_FILE" ]; then
  echo "[k-orchestrator] $STATUS_FILE 없음 또는 읽기 불가 — 최소 메타데이터만 기록합니다"
  STATUS_CONTENT="- EXECUTION_STATUS.md unavailable"
else
  STATUS_CONTENT="$(cat "$STATUS_FILE")"
fi

if [ -n "$CLAUDEBOX_PROFILE" ]; then
  SESSION_DIR="$VAULT_DIR/projects/$CLAUDEBOX_PROFILE/sessions"
else
  SESSION_DIR="$VAULT_DIR/sessions"
fi

if ! mkdir -p "$SESSION_DIR" 2>/dev/null; then
  echo "[k-orchestrator] 세션 디렉토리 생성 실패 — vault 동기화 스킵"
  exit 0
fi

TIMESTAMP="$(date -u +"%Y%m%d_%H%M%S")"
ISO_NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
FILE_BASENAME="${TIMESTAMP}_${CLAUDEBOX_USER}_${CLAUDEBOX_WORKTREE_ID}.md"
FILEPATH="$SESSION_DIR/$FILE_BASENAME"
PROFILE_VALUE="${CLAUDEBOX_PROFILE:-unknown}"

if ! cat > "$FILEPATH" <<EOF_DOC
---
type: session-summary
profile: "$PROFILE_VALUE"
user: "$CLAUDEBOX_USER"
worktree: "$CLAUDEBOX_WORKTREE_ID"
branch: "$CLAUDEBOX_BASE_BRANCH"
date: "$ISO_NOW"
tags:
  - session
  - "$PROFILE_VALUE"
---

# 세션 요약

## 메타데이터
- 프로필: $PROFILE_VALUE
- 사용자: $CLAUDEBOX_USER
- Worktree: $CLAUDEBOX_WORKTREE_ID
- Branch: $CLAUDEBOX_BASE_BRANCH
- 시각: $(date -u +"%Y-%m-%d %H:%M UTC")

## 실행 상태
$STATUS_CONTENT
EOF_DOC
then
  echo "[k-orchestrator] 세션 요약 쓰기 실패 — vault 동기화 스킵"
  exit 0
fi

echo "[k-orchestrator] 세션 요약 저장: $FILEPATH"

if [ -d "$VAULT_DIR/.git" ]; then
  git_state="success"
  (
    cd "$VAULT_DIR" || exit 11
    git add "$FILEPATH" >/dev/null 2>&1 || exit 12
    # --no-verify: Stop hook 내부에서 Git pre-commit hook 재귀 실행 방지
    git commit -m "k-orchestrator: session summary ${CLAUDEBOX_USER}/${CLAUDEBOX_WORKTREE_ID}" --no-verify >/dev/null 2>&1 || exit 13
  ) || git_state="$?"

  case "$git_state" in
    success)
      echo "[k-orchestrator] vault Git 처리 완료"
      ;;
    12|13)
      echo "[k-orchestrator] vault Git 처리 실패(best-effort)"
      ;;
    *)
      echo "[k-orchestrator] vault Git 처리 스킵(best-effort)"
      ;;
  esac
else
  echo "[k-orchestrator] vault Git 레포 아님 — Git 처리 스킵"
fi

exit 0
