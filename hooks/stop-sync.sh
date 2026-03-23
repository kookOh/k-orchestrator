#!/usr/bin/env bash
# k-orchestrator Stop hook — persist a session summary into an Obsidian vault.
# Non-blocking by design.

set +e -uo pipefail

# 환경변수 sanitize — 영숫자, '.', '_', '-'만 허용 (path traversal 방지)
sanitize() { printf '%s' "$1" | tr -cd 'a-zA-Z0-9._-'; }

VAULT_DIR="${VAULT_DIR:-}"
CLAUDEBOX_PROFILE="${CLAUDEBOX_PROFILE:-}"
SAFE_USER="$(sanitize "${CLAUDEBOX_USER:-unknown}")"
SAFE_WORKTREE="$(sanitize "${CLAUDEBOX_WORKTREE_ID:-unknown}")"
SAFE_BRANCH="$(sanitize "${CLAUDEBOX_BASE_BRANCH:-unknown}")"
# Claude Code hooks는 프로젝트 루트에서 실행됨 — Docker 환경에서는 WORKDIR이 프로젝트 루트여야 함
STATUS_FILE="${K_ORCHESTRATOR_STATUS_FILE:-docs/EXECUTION_STATUS.md}"
# STATUS_FILE 경로 제한 — 절대경로/path traversal 차단
case "$STATUS_FILE" in
  /*|*../*)
    echo "[k-orchestrator] STATUS_FILE에 절대경로 또는 '..'이 포함됨 — 기본값 사용"
    STATUS_FILE="docs/EXECUTION_STATUS.md"
    ;;
esac

echo "[k-orchestrator] Stop: batch 상태 및 EXECUTION_STATUS.md 업데이트 확인"

if [ -z "$VAULT_DIR" ] || [ ! -d "$VAULT_DIR" ]; then
  echo "[k-orchestrator] VAULT_DIR 미설정 또는 디렉토리 없음 — vault 동기화 스킵"
  exit 0
fi
# VAULT_DIR canonicalization + 시스템 디렉토리 blocklist
VAULT_DIR="$(cd "$VAULT_DIR" 2>/dev/null && pwd -P)" || { echo "[k-orchestrator] VAULT_DIR 해소 실패"; exit 0; }
case "$VAULT_DIR" in
  /|/etc*|/usr*|/bin*|/sbin*|/var*|/tmp*|/proc*|/sys*|/dev*|/System*|/Library*)
    echo "[k-orchestrator] VAULT_DIR이 시스템 디렉토리 — 거부: $VAULT_DIR"
    exit 0;;
esac

if [ ! -r "$STATUS_FILE" ]; then
  echo "[k-orchestrator] $STATUS_FILE 없음 또는 읽기 불가 — 최소 메타데이터만 기록합니다"
  STATUS_CONTENT="- EXECUTION_STATUS.md unavailable"
else
  STATUS_CONTENT="$(cat "$STATUS_FILE")"
fi

SAFE_PROFILE="$(sanitize "${CLAUDEBOX_PROFILE:-unknown}")"

if [ -n "$CLAUDEBOX_PROFILE" ]; then
  SESSION_DIR="$VAULT_DIR/projects/$SAFE_PROFILE/sessions"
else
  SESSION_DIR="$VAULT_DIR/sessions"
fi

if ! mkdir -p "$SESSION_DIR" 2>/dev/null; then
  echo "[k-orchestrator] 세션 디렉토리 생성 실패 — vault 동기화 스킵"
  exit 0
fi

TIMESTAMP="$(date -u +"%Y%m%d_%H%M%S")"
ISO_NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DATE_DISPLAY="$(date -u +"%Y-%m-%d %H:%M UTC")"
FILE_BASENAME="${TIMESTAMP}_${SAFE_USER}_${SAFE_WORKTREE}.md"
FILEPATH="$SESSION_DIR/$FILE_BASENAME"

# Quoted heredoc (<<'EOF') — shell 확장 비활성화로 $STATUS_CONTENT 내 $ 문자 보호
# 변수는 heredoc 외부에서 sed로 삽입
if ! cat > "$FILEPATH" <<'EOF_DOC'
---
type: session-summary
profile: "__PROFILE__"
user: "__USER__"
worktree: "__WORKTREE__"
branch: "__BRANCH__"
date: "__ISO_NOW__"
tags:
  - session
  - "__PROFILE__"
---

# 세션 요약

## 메타데이터
- 프로필: __PROFILE__
- 사용자: __USER__
- Worktree: __WORKTREE__
- Branch: __BRANCH__
- 시각: __DATE_DISPLAY__

## 실행 상태
__STATUS_CONTENT__
EOF_DOC
then
  echo "[k-orchestrator] 세션 요약 쓰기 실패 — vault 동기화 스킵"
  exit 0
fi

# placeholder를 실제 값으로 치환 (sed 구분자에 | 사용 — 값에 / 포함 가능)
# STATUS_CONTENT는 여러 줄이므로 임시 파일 기반 치환
{
  sed -e "s|__PROFILE__|${SAFE_PROFILE}|g" \
      -e "s|__USER__|${SAFE_USER}|g" \
      -e "s|__WORKTREE__|${SAFE_WORKTREE}|g" \
      -e "s|__BRANCH__|${SAFE_BRANCH}|g" \
      -e "s|__ISO_NOW__|${ISO_NOW}|g" \
      -e "s|__DATE_DISPLAY__|${DATE_DISPLAY}|g" \
      "$FILEPATH"
} > "${FILEPATH}.tmp" 2>/dev/null

# STATUS_CONTENT 여러 줄 치환 — ENVIRON으로 escape 해석 없이 전달
STATUS_CONTENT="$STATUS_CONTENT" awk '{
  if ($0 == "__STATUS_CONTENT__") print ENVIRON["STATUS_CONTENT"]
  else print
}' "${FILEPATH}.tmp" > "$FILEPATH" 2>/dev/null
rm -f "${FILEPATH}.tmp"

echo "[k-orchestrator] 세션 요약 저장: $FILEPATH"

if [ -d "$VAULT_DIR/.git" ]; then
  git_state="success"
  (
    cd "$VAULT_DIR" || exit 11
    git_output="$(git add "$FILEPATH" 2>&1)" || { echo "[k-orchestrator] git add: $git_output" >&2; exit 12; }
    # --no-verify: Stop hook 내부에서 Git pre-commit hook 재귀 실행 방지
    git_output="$(git commit -m "k-orchestrator: session summary ${SAFE_USER}/${SAFE_WORKTREE}" --no-verify 2>&1)" || { echo "[k-orchestrator] git commit: $git_output" >&2; exit 13; }
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
