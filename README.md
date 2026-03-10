# k-orchestrator

한국어 중심의 Claude Code 프로젝트 운영 플러그인입니다.
OMC를 대체하지 않고, OMC 위에 올라가는 운영 스위트입니다.

## 목적

- Foundation Pack 생성 (blueprint, PRD, schema, api-spec 등)
- repo 운영 정렬 + 상태 부트스트랩
- batch 기반 실행 오케스트레이션 (상태머신 전환 규칙 포함)
- 세션 재개
- 신규 기능/새 개발 요청 영향 분석 (Type A/B/C 판정)
- PROJECT EXTENSION BLOCK 생성
- 선택형 memory bootstrap (recall/Obsidian/QMD)

## 설치

### Claude Code 세션 안에서 설치 (권장)

```bash
# 1. marketplace 등록
/plugin marketplace add kookOh/k-orchestrator

# 2. 플러그인 설치 (interactive)
/plugin
# → Discover 탭 → k-orchestrator 선택 → Install
```

### CLI에서 설치

```bash
# plugin-dir 플래그로 직접 실행
claude --plugin-dir /path/to/k-orchestrator
```

### install.sh로 수동 설치

```bash
git clone https://github.com/kookOh/k-orchestrator.git
cd k-orchestrator
./install.sh /path/to/your-project
```

설치 후 `/k-orchestrator:setup-project-suite` 로 프로젝트 부트스트랩을 시작하세요.

## 핵심 원칙

- OMC는 주 실행 엔진으로 유지
- `.omc/*`는 내부 상태/보조 메모리, 공식 실행 원장은 `tasks/` + `docs/EXECUTION_STATUS.md`
- 기존 OMC `CLAUDE.md`는 덮어쓰지 않고 `@path` import 방식으로만 확장
- OMC agent 역할명 중복 정의 금지 (planner/architect/executor/verifier 및 OMC가 제공하는 모든 agent)
- commands는 실행 명령, skills는 정책 강제, hooks는 lightweight guardrail

## 아키텍처

```
┌─────────────────────────────────────────────┐
│  Claude Code Runtime                         │
│  ┌───────────┐  ┌────────────────────────┐  │
│  │    OMC    │  │    k-orchestrator      │  │
│  │ (engine)  │  │  commands / skills     │  │
│  │           │  │  templates             │  │
│  └─────┬─────┘  └──────────┬─────────────┘  │
│        │                    │                │
│        ▼                    ▼                │
│  ┌──────────────────────────────────────┐   │
│  │  Project Repo                        │   │
│  │  CLAUDE.md → @docs/CC_ORCHESTRATOR   │   │
│  │  docs/ tasks/ qa/                    │   │
│  │  .omc/ (secondary memory)            │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │  Optional Memory Layer               │   │
│  │  recall / sync / Obsidian / QMD      │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### source of truth hierarchy

1. 실제 코드/DB/repo
2. `docs/EXECUTION_STATUS.md`
3. `tasks/BATCH_*.md` + `qa/`
4. PRD / BLUEPRINT / ARCHITECTURE / API / SCHEMA 문서
5. `.omc/*` / recall 결과 (보조)

### commands vs skills vs hooks 역할

| 구분 | 역할 | 호출 방식 |
|---|---|---|
| commands (13개) | 실행 명령 — batch 관리, 분석, 생성, 도움말, 업데이트, 대시보드 | 사용자가 `/k-orchestrator:name` 으로 명시 호출 |
| skills (3개) | 정책 강제 — batch 규칙, memory 규칙, 상태 감지 | Claude가 맥락상 자동 로드 |
| hooks (3개) | lightweight guardrail — 세션 시작/종료 리마인더 | 이벤트 기반 자동 실행 |

## 포함 명령

| 호출 | 역할 |
|---|---|
| `/k-orchestrator:setup-project-suite` | 저장소 감사 + 전체 구조 bootstrap |
| `/k-orchestrator:foundation-pack` | foundation 문서 세트 생성 |
| `/k-orchestrator:bootstrap-ops` | 운영 구조 정렬 |
| `/k-orchestrator:orchestrate-run` | batch 기반 자동 실행 |
| `/k-orchestrator:resume-run` | 세션 재개 |
| `/k-orchestrator:change-impact` | 신규 기능 영향 분석 |
| `/k-orchestrator:make-extension-block` | extension block 생성 |
| `/k-orchestrator:setup-memory-layer` | memory 계층 설정 (선택) |
| `/k-orchestrator:next-batch` | 다음 batch 식별 및 OPEN 준비 |
| `/k-orchestrator:normalize-repo` | 파일 구조 정합성 검증 및 교정 |
| `/k-orchestrator:help` | 상황별 명령 가이드 |
| `/k-orchestrator:update` | 플러그인 자체 업데이트 |
| `/k-orchestrator:dashboard` | batch 진행 현황 대시보드 |

## 설치 후 프로젝트에 생성되는 파일

```
project/
├── CLAUDE.md                            ← import 추가 (또는 신규 생성)
├── docs/
│   ├── CC_ORCHESTRATOR.md               ← 운영 정책
│   ├── EXECUTION_STATUS.md              ← 실행 상태 원장
│   ├── PROJECT_FOUNDATION.md            ← foundation 요약
│   ├── PLUGIN_DIAGNOSTIC.md             ← 진단 기록
│   └── CLAUDE_MEMORY_SETUP.md           ← memory 설정 (선택)
├── tasks/
│   └── BATCH_TEMPLATE.md                ← batch 작성 템플릿
├── qa/
│   └── BATCH_TEMPLATE_QA.md             ← QA 작성 템플릿
└── .claude/
    ├── commands/k-orchestrator/         ← 13개 command
    ├── skills/k-orchestrator/           ← 3개 skill (2 policy + 1 감지)
    │   ├── batch-execution-policy/SKILL.md
    │   ├── memory-layer-policy/SKILL.md
    │   └── session-state-detector/SKILL.md
    ├── settings.json                    ← 프로젝트 권한
    └── settings.local.json              ← hooks
```

## 권장 시작 순서

### 새 프로젝트
1. OMC 준비 (`npx oh-my-claudecode@latest init`)
2. `./install.sh [target-dir]`
3. `/k-orchestrator:setup-project-suite`
4. `/k-orchestrator:foundation-pack`
5. `/k-orchestrator:bootstrap-ops`
6. `/k-orchestrator:orchestrate-run`

### 진행 중 프로젝트
1. `./install.sh [target-dir]`
2. `/k-orchestrator:setup-project-suite`
3. `/k-orchestrator:bootstrap-ops`
4. `/k-orchestrator:orchestrate-run`

### 세션 재개
- `/k-orchestrator:resume-run`

### 신규 기능/변경 요청
1. `/k-orchestrator:change-impact`
2. 필요 시 `/k-orchestrator:make-extension-block`
3. `/k-orchestrator:orchestrate-run`

### 단일 batch 착수
- `/k-orchestrator:next-batch`

### 구조 검증
- `/k-orchestrator:normalize-repo`

### 진행 현황 확인
- `/k-orchestrator:dashboard`
- `/k-orchestrator:dashboard launch-critical` (launch-critical만 필터)

### memory layer가 정말 필요할 때만
- `/k-orchestrator:setup-memory-layer`

### 도움이 필요할 때
- `/k-orchestrator:help`
- `/k-orchestrator:help 시작` (특정 상황 키워드로 필터)

### 플러그인 업데이트
- `/k-orchestrator:update` (확인 + 적용)
- `/k-orchestrator:update --check` (확인만)

## 작업 상태 분류

| 상태 | 의미 |
|---|---|
| READY | 즉시 실행 가능, 외부 의존 없음 |
| BLOCKED | 저장소 밖 이유로 진행 불가 |
| DEFERRED | 의도적으로 뒤로 미룸 |
| OPTIONAL | nice-to-have, launch 필수 아님 |

큰 작업(L effort)이라는 이유만으로 BLOCKED로 분류하지 않습니다.

## 종료 판정 (Termination Status)

2단 구조로 선언합니다:
- Primary: ALL_LAUNCH_CRITICAL_DONE / BLOCKED_ON_CRITICAL_PATH / OPEN_BATCH_REMAINS / NEXT_BATCH_READY
- Secondary: NON_CRITICAL_BATCHES_READY / DEFERRED_WORK_REMAINS / SOME_FEATURES_BLOCKED_EXTERNALLY / EXTERNAL_TASKS_PENDING / HANDOFF_READY / SAFE_PARALLEL_WORK_REMAINS

## 이 플러그인이 하지 않는 것

- OMC 강제 설치
- personal-os-skills 강제 설치
- Obsidian GUI 자동 설치
- per-prompt 자동 sync hooks
- OMC agent 역할명(planner/architect/executor/verifier 등) 재정의
