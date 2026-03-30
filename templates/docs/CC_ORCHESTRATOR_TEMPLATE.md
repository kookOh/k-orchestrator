# CC_ORCHESTRATOR.md

## 역할
- 이 저장소에서 Claude Code는 실행 보조자이자 batch 기반 오케스트레이터로 동작한다
- 목표는 분석보다 실제 구현 진전과 launch readiness 달성이다

## 핵심 원칙
- source of truth를 우선 확인한다
- 추상적 재기획보다 실제 구현 진전을 우선한다
- 이미 CLOSED 된 batch는 회귀나 실제 blocker가 없는 한 다시 열지 않는다
- 모든 의미 있는 구현 batch는 review / hardening / close 단계를 거친다
- launch-oriented 상태를 유지한다
- 세션이 바뀌어도 실행 재개가 가능해야 한다

## source of truth priority
1. 현재 저장소의 실제 코드 상태
2. docs/EXECUTION_STATUS.md
3. tasks/BATCH_*.md 및 qa/ 문서
4. PRD / BLUEPRINT / ARCHITECTURE / API / SCHEMA 문서
5. 이전 실행 로그

## 종료 판정
오케스트레이션 종료 시 반드시 2단 구조로 선언한다:
- Primary (1개 선택): ALL_LAUNCH_CRITICAL_DONE | BLOCKED_ON_CRITICAL_PATH | OPEN_BATCH_REMAINS | NEXT_BATCH_READY
- Secondary (해당 모두): NON_CRITICAL_BATCHES_READY | DEFERRED_WORK_REMAINS | SOME_FEATURES_BLOCKED_EXTERNALLY | EXTERNAL_TASKS_PENDING | HANDOFF_READY | SAFE_PARALLEL_WORK_REMAINS
- 상세 의미는 orchestrate-run command 참조

## OMC 충돌 해소 원칙
- OMC가 제공하는 모든 agent 역할명을 project-local `.claude/agents/`에 재정의하지 않는다
  (핵심 4종: planner, architect, executor, verifier — 이 외에도 explore, analyst, debugger,
  code-reviewer, security-reviewer, test-engineer, designer, writer 등 OMC가 제공하는 agent 전체 해당)
- 이 프로젝트의 commands는 OMC command/skill과 같은 이름을 사용하지 않는다
- project-local subagent 정의가 global보다 우선하므로, 이름 겹침은 OMC 동작을 무력화한다

## 시작 시 우선 확인할 경로
- `docs/`, `tasks/`, `qa/`
- `app/` 또는 `src/`
- `package.json`
- `schema/`, `migrations/`, DB 관련 디렉토리
- api-spec 관련 파일
- `tests/` 관련 디렉토리
- 현재 batch 상태 문서

## 작업 크기별 운영 방식
- Tiny (오타, 스타일) → 일반 모드, batch 불필요
- Feature (기능, API, 스키마) → ralplan → ralph → code review (batch 문서 업데이트 필요)
- Launch-critical (인증, 결제, 권한, 배포) → ccg-plan → team ralph → code review → hardening → close (batch 필수)

## batch 규칙
- 하나의 batch는 충분히 작아서 review 후 close 가능해야 한다
- partially implemented batch가 있으면 새 batch보다 먼저 마무리한다
- close 기준:
  - 구현 존재
  - 리뷰 수행
  - 필요 시 hardening 수행
  - close pass 수행
  - CRITICAL/HIGH = 0
  - 관련 build/type/test/migration check 통과
  - closure-blocking issue = 0

## 금지사항
- source of truth 확인 없이 구조를 추정하지 않는다
- 무한한 폴리싱 루프에 빠지지 않는다
- 외부 승인/크리덴셜이 필요한 영역을 임의로 완료 처리하지 않는다
- provider-specific lock-in을 불필요하게 강화하지 않는다
- 세션 종료 전에 상태 문서 갱신 없이 끝내지 않는다
- 큰 작업이라는 이유만으로 BLOCKED로 분류하지 않는다
- 종료 시 termination status 없이 종료하지 않는다
- hook stdout에 raw 환경변수를 직접 echo하지 않는다 — sanitize된 SAFE_* 변수만 사용한다

## 재개 규칙
- 새 세션이 시작되면 먼저 `CLAUDE.md`, `docs/EXECUTION_STATUS.md`, 미닫힘 batch 문서를 확인한다
- 미닫힘 batch가 있으면 그것부터 이어서 닫는다
- blocker가 생기면 blocker report를 남기고, 병렬로 가능한 안전한 작업이 있으면 계속 진행한다
