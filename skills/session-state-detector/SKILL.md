---
name: session-state-detector
description: 세션 시작 시 프로젝트 오케스트레이션 상태를 자동 감지하여 구조화된 요약을 제공. resume-run 수동 호출을 대체.
---

세션이 시작되거나 프로젝트 상태 파악이 필요할 때:

1. `docs/EXECUTION_STATUS.md`를 읽고 현재 상태를 파악한다
2. 현재 OPEN 상태인 `tasks/BATCH_*.md` 파일을 확인한다
3. 아래 구조화된 요약을 한국어로 제공한다
4. 필요하면 `CLAUDEBOX_*`, `VAULT_DIR` 환경과 vault 상태를 추가로 안내한다

## 상태 요약 형식

```text
── k-orchestrator 상태 감지 ──
프로젝트 상태: [STATE_0~STATE_5]
활성 batch: [batch명 또는 "없음"]
Batch 상태: [NOT STARTED / OPEN / REVIEW / HARDENING / BLOCKED]
Launch-critical 진척: [CLOSED 수]/[전체 수]
마지막 종료 판정: [Primary termination status]
다음 권장 액션: [구체적 명령 또는 작업]
```

## ClaudeBox 환경 감지
환경변수를 확인하여 ClaudeBox 팀 환경 여부를 판단한다:
- `CLAUDEBOX_PROFILE` 존재 → ClaudeBox 팀 환경 → 아래 정보를 상태 요약에 추가
- `CLAUDEBOX_PROFILE` 미존재 → 로컬 개인 환경 → **이 섹션과 Vault 상태 감지를 건너뛴다**

ClaudeBox 팀 환경이면 아래 정보를 상태 요약에 추가한다:

```text
── ClaudeBox 환경 정보 ──
프로필: $CLAUDEBOX_PROFILE
사용자: $CLAUDEBOX_USER
Worktree: $CLAUDEBOX_WORKTREE_ID
Base Branch: $CLAUDEBOX_BASE_BRANCH
Vault: $VAULT_DIR (활성/미설정)
```

## Vault 상태 감지
`VAULT_DIR` 환경변수가 미설정이면 이 섹션을 건너뛴다.
`VAULT_DIR`이 설정되어 있으면:
- vault 디렉토리 존재 여부 확인
- 최근 세션 요약 파일 수 표시
- 프로젝트 관련 문서 수 표시
- "vault에서 관련 문서를 읽어서 컨텍스트로 활용할 수 있습니다"를 안내한다

경로 규칙:
- `CLAUDEBOX_PROFILE`가 있으면 `projects/$CLAUDEBOX_PROFILE/`를 우선 탐색한다
- 없으면 generic `sessions/`를 본다
- read-only/누락 상태는 정보로만 보고하고 에러로 승격하지 않는다

## 판정 규칙
- `docs/EXECUTION_STATUS.md`가 없으면 → "k-orchestrator 미설정. `/k-orchestrator:setup-project-suite` 실행 권장"
- OPEN batch 있으면 → "활성 batch 계속: `/k-orchestrator:orchestrate-run`"
- OPEN batch 없고 NOT STARTED 있으면 → "다음 batch 시작: `/k-orchestrator:next-batch`"
- 모든 launch-critical CLOSED → "launch-critical 완료. non-critical 또는 DEFERRED 작업 확인"
- BLOCKED 항목 있으면 → blocker 내용 함께 표시

## 제약
- 읽기 전용: 어떤 파일도 수정하지 않는다
- `docs/EXECUTION_STATUS.md`와 `tasks/`가 상태 판정의 primary source of truth다
- 환경 변수와 vault 상태는 힌트/메타데이터로만 추가한다
- `.omc/*`는 source-of-truth 우선순위를 넘어서지 않는다
