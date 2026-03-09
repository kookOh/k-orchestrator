# MIGRATION.md — 기존 프로젝트에 k-orchestrator 적용하기

## 원칙
- 기존 `CLAUDE.md`는 절대 덮어쓰지 않는다
- `.omc/*`는 건드리지 않는다
- `tasks/`와 `docs/EXECUTION_STATUS.md`를 공식 실행 원장으로 승격한다

## 단계별 적용

### 1. install.sh 실행
```bash
/path/to/k-orchestrator/install.sh [target-project-dir]
```
기존 파일이 있는 경우 모두 스킵됩니다. 덮어쓰기는 발생하지 않습니다.

설치 후 생성되는 구조:
- `docs/` — CC_ORCHESTRATOR.md, EXECUTION_STATUS.md, PROJECT_FOUNDATION.md
- `tasks/` — BATCH_TEMPLATE.md (batch 작성용 템플릿)
- `qa/` — BATCH_TEMPLATE_QA.md (QA 작성용 템플릿)
- `.claude/commands/k-orchestrator/` — 12개 command
- `.claude/skills/k-orchestrator/` — 2개 policy skill

### 2. CLAUDE.md에 import 추가
기존 `CLAUDE.md` 맨 아래에 아래 두 줄만 추가합니다.
```md
@docs/CC_ORCHESTRATOR.md
@docs/PROJECT_FOUNDATION.md
```

### 3. docs/EXECUTION_STATUS.md 작성
현재 프로젝트 상태를 기준으로 템플릿을 채워 넣습니다.
- 현재 STATE 판정 (STATE_0 ~ STATE_5)
- 기존 batch가 있으면 batch 상태 요약 테이블에 반영
- 작업 상태 분류: READY / BLOCKED / DEFERRED / OPTIONAL

### 4. tasks/ 구조 확인
기존에 다른 이름으로 관리하던 작업 문서가 있다면, `tasks/BATCH_XX.md` 형식으로 옮기거나 링크를 `EXECUTION_STATUS.md`에 명시합니다.

### 5. `/k-orchestrator:setup-project-suite` 실행
전체 구조 감사 및 누락 파일 생성을 자동으로 수행합니다.

### 5-1. `/k-orchestrator:normalize-repo` (선택)
설치 후 파일 정합성을 검증하고 불일치를 교정합니다.

### .omc/* 역할 분리 확인
- `.omc/notepad.md`에는 active batch, blocker, next action만 유지
- 긴 로그나 기록은 `tasks/`와 `docs/`로 이관
- `.omc/plans/`와 `tasks/`가 공존해도 되지만 공식 원장은 `tasks/`

## skills 설치 확인
install.sh는 policy skills를 `.claude/skills/k-orchestrator/`에 자동 설치합니다.
수동 설치한 경우 아래 경로를 확인하십시오:
- `.claude/skills/k-orchestrator/batch-execution-policy/SKILL.md`
- `.claude/skills/k-orchestrator/memory-layer-policy/SKILL.md`

## 주의사항
- `planner/architect/executor/verifier` 이름의 agent를 `.claude/agents/`에 두지 않는다
- hooks를 새로 넣을 경우 `minimal-hooks.json` 형식(matcher 포함)만 사용한다
- 이전 버전에서 `docs/BATCH_TEMPLATE.md`에 있던 파일은 `tasks/BATCH_TEMPLATE.md`로 이동 필요
