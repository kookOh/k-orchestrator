# AI Team Infrastructure — 최종 계획안 v4

> 1단계: Obsidian vault + Git | 1.5단계: QMD/Quarto | 2단계: OpenViking 선택적 도입
> 실코드 분석 완료 + GPT 피드백 3회 반영
> 작성일: 2026-03-15

---

## 1. 한줄 요약

doubleT의 haimdall 개발팀이 Slack과 CLI 어디서든 AI 작업을 시작할 수 있고, 코드 실행·문서 학습·이미지 기반 대화가 가능하며, Obsidian vault에 팀 지식이 자동 축적되는 사내 AI 개발 인프라를 구축한다. 외부 API 과금 없음.

---

## 2. 단계별 로드맵

| 단계 | 핵심 | 지식 레이어 | 검색 방식 |
|------|------|------------|-----------|
| **1단계 (이번)** | Obsidian vault + Git | 마크다운 폴더, Claude Code 직접 읽기/쓰기 | 파일명/폴더/frontmatter/ripgrep |
| **1.5단계** | QMD/Quarto 추가 | vault 기반 문서 포털/사이트 출판 | 동일 |
| **2단계 (필요 시)** | OpenViking 추가 | vault를 인덱싱하는 캐시 레이어 | 시맨틱 벡터 검색 + L0/L1/L2 |

**1단계에서 하지 않는 것:**
- 시맨틱 벡터 검색
- VLM/embedding provider 연동
- OpenViking 구축
- QMD/Quarto 문서 포털

**2단계 도입 조건:**
- 문서가 수천 건을 넘어가서 ripgrep만으로 찾기 어려울 때
- 다국어 문서 검색이 필요할 때 (의미 기반)
- 이때 vault의 마크다운을 `add_resource()`로 넣기만 하면 되므로 구조적 충돌 없음

---

## 3. 비용 구조

| 항목 | 비용 |
|------|------|
| 지식 레이어 | Obsidian vault = 마크다운 폴더. 0원 |
| 코드 실행 | Claude Code 구독. 0원 |
| VLM/Embedding | 1단계에서 불필요. 0원 |
| 외부 API 키 | ANTHROPIC_API_KEY (Claude Code용) + GH_TOKEN만 |

---

## 4. 아키텍처 (1단계)

```
Entry Layer
├── Slack (팀 협업 진입)
├── Claude Code CLI (개발자 직접)
└── OMC CLI (개발자 직접)
    ↓ 동일한 세션 규약
Orchestration Layer
└── ClaudeBox
    ├── 작업 유형 판별 (Type A/B/C)
    ├── Slack 파일 다운로드 (Type B/C)
    ├── Git worktree 생성
    └── Docker 2-컨테이너 생성
         ├── MCP Sidecar (git-tools, respond_to_user)
         └── Claude 컨테이너 (+ vault 볼륨 마운트)

Execution Layer
├── Claude Code (핵심)
└── OMC (보조)

Governance Layer
└── k-orchestrator
    ├── CLAUDE.md 규칙 주입
    ├── Stop 훅 → vault에 세션 요약 저장
    └── SessionStart 훅 → vault 컨텍스트 안내

Knowledge Layer (1단계)
└── Obsidian vault (Git 레포)
    ├── team/ (컨벤션, 정책)
    ├── projects/<PROFILE>/ (아키텍처, 기획, 인시던트) ← CLAUDEBOX_PROFILE로 결정
    ├── projects/<PROFILE>/sessions/ (세션 요약 자동 축적)
    └── unsorted/ (미분류 임시)
```

### 작업 유형 3가지

**Type A: 코드 실행** — 텍스트 → worktree → 코드 수정 → PR
**Type B: 문서 Ingestion** — 파일 + "학습/저장" → Claude Code가 마크다운 변환 → vault 저장
**Type C: 이미지/파일 기반 대화** — 파일 + 일반 요청 → 비전/분석 → 코드 수정

---

## 5. 코드 분석 결과 (Gate 1~3)

### k-orchestrator v1.4.1 (marketplace: kor)
- 훅: SessionStart / PreCompact / Stop (echo 기반). SessionEnd 없음.
- memory-layer-policy: Obsidian/QMD 언급하지만 실제 구현 없음 → **이번에 구축**
- install.sh: Docker 래퍼(install-in-docker.sh) 필요
- CCG 계획 승인됨: BATCH_01 (ClaudeBox Docker + Obsidian vault 통합)
- 의존: BATCH_01 완료 → feat/claudebox-integration 브랜치 → ai-team-stack 실행 가능

### ClaudeBox (423cb84)
- Profile: TS 인터페이스 완전 정의. 채널 ID 직접 바인딩.
- Docker: sidecar + claude 2-컨테이너 패턴
- Slack 파일 다운로드: **미구현 → 확장 필요**
- 환경변수: CLAUDEBOX_PROFILE, CLAUDEBOX_USER, CLAUDEBOX_WORKTREE_ID, CLAUDEBOX_BASE_BRANCH

### OpenViking (소스 분석 완료 — 2단계용 참고)
- Embedding: openai/volcengine/jina만 (litellm 없음)
- VLM: volcengine/openai/litellm (Ollama 포함)
- 리소스 입력: add_resource(path) 하나뿐, L0/L1/L2 직접 write API 없음
- 2단계에서 vault 마크다운을 add_resource()로 넣는 방식으로 연동 가능

---

## 6. 프로젝트 구조 (1단계)

```
ai-team-stack/
├── docker-compose.yml
├── .env.example
├── Makefile
├── README.md
├── .gitignore
│
├── claudebox/
│   ├── Dockerfile
│   ├── server-config/
│   └── profiles/
│       ├── haimdall-backend/
│       │   ├── plugin.ts
│       │   ├── mcp-sidecar.ts
│       │   └── CLAUDE.md
│       ├── haimdall-frontend/
│       │   ├── plugin.ts
│       │   ├── mcp-sidecar.ts
│       │   └── CLAUDE.md
│       └── shared-policy/
│           ├── k-orchestrator-base.md
│           ├── vault-rules.md
│           └── ingestion-workflow.md
│
├── agent-image/
│   ├── Dockerfile
│   ├── install-k-orchestrator.sh
│   └── install-omc.sh
│
├── knowledge-vault/                  ← Obsidian vault (Git 레포)
│   ├── team/
│   │   ├── coding-conventions.md
│   │   ├── onboarding.md
│   │   └── policies/
│   ├── projects/
│   │   └── haimdall/
│   │       ├── architecture.md
│   │       ├── planning/
│   │       ├── incidents/
│   │       └── sessions/             ← Stop 훅 자동 축적
│   ├── unsorted/
│   ├── .obsidian/                    ← Obsidian 앱 설정
│   └── README.md
│
└── data/
    └── claudebox/worktrees/
```

**1단계에서 없는 것:** openviking/, ollama/ 디렉토리 없음. docker-compose에 해당 서비스 없음.

---

## 7. 문서 Ingestion 플로우 (Type B)

```
[팀원] Slack에 기획서.pdf + 정책문서.docx 업로드
       "@봇 문서들은 기획,정책 등 문서이고 학습해서 저장해"
  ↓
[ClaudeBox]
  ├── Type B 판별 (파일 + "학습/저장" 키워드)
  ├── Slack API로 파일 다운로드 → /workspace/uploads/
  └── Docker 컨테이너 생성 (vault 볼륨 마운트)
       ↓
[Claude Code 컨테이너]
  ├── /workspace/uploads/ 파일 확인
  ├── PDF/DOCX → 텍스트 추출 → 마크다운 변환
  ├── ingestion-workflow.md 스킬에 따라:
  │   ├── 문서 유형 분류 (기획/정책/운영/회의록/ADR)
  │   ├── 프로젝트 소속 판별 (CLAUDEBOX_PROFILE)
  │   ├── frontmatter 생성 (type, project, tags, date)
  │   ├── vault 적절한 디렉토리에 마크다운 저장
  │   └── 분류 애매 → vault/unsorted/ + 사용자 확인 요청
  ├── vault Git 커밋
  └── respond_to_user → Slack 결과 보고
       ↓
[Slack 응답]
  "문서 2건 저장 완료:
   - 기획서.pdf → vault/projects/haimdall/planning/기획서.md (기획)
   - 정책문서.docx → vault/team/policies/정책문서.md (정책)
   이후 작업에서 자동 참조됩니다."
```

---

## 8. Phase 0: 최소 검증 (2~3일)

OpenViking PoC는 불필요하지만, 1단계에서도 아래는 검증 필요:

- [ ] **PDF/DOCX → 마크다운 변환**: Claude Code가 PDF를 직접 읽어서 마크다운으로 변환 가능한지, 아니면 pandoc 등 별도 도구가 agent-image에 필요한지
- [ ] **Docker 컨테이너 내 Git 커밋**: Stop 훅에서 vault에 파일 쓰고 git commit이 정상 동작하는지 (Git user 설정, 권한 문제)
- [ ] **frontmatter 기반 검색 충분성**: `grep -r "type: policy" vault/` 수준의 검색이 실제 워크플로우에 충분한지 간단한 시나리오 테스트

---

## 9. 구현 계획

### Phase 1: k-orchestrator 확장 (1주)
- install-in-docker.sh
- hooks/stop-sync.sh (vault에 세션 요약 저장)
- hooks/session-context-loader.sh (SessionStart vault 안내)
- memory-layer-policy 전체 교체 (vault 구축 지침)
- session-state-detector 확장 (ClaudeBox 환경 감지)
- setup-memory-layer 강화 (vault 초기 구조 실제 생성)

### Phase 2: ai-team-stack 프로젝트 생성 (1주)
- docker-compose.yml (claudebox × 2 + agent-builder)
- agent-image Dockerfile
- ClaudeBox Dockerfile + Slack 파일 다운로드 확장
- Profile 3개 (haimdall-backend, haimdall-frontend, shared-policy)
- knowledge-vault/ 초기 구조 + Git init
- ingestion-workflow.md 스킬

### Phase 3: 통합 테스트 및 배포 (1주)
- Fortigate SSL 예외: wss-primary.slack.com, api.anthropic.com, api.github.com
- Type A: Slack → PR 생성
- Type B: 파일 업로드 → vault 저장 → grep 검색
- Type C: 이미지 → 비전 분석 → 코드 수정
- 동시 작업 + CLI 진입 테스트

### Phase 1.5: QMD/Quarto 추가 (선택)
- vault 기반 문서 포털/사이트 생성
- quarto render로 팀 문서 사이트 구축
- 사내 배포 방식 결정 (Quarto Pub은 공개 전제이므로 사내용 대안 필요)

### 장기 계획: OpenViking 선택적 도입 (필요 시)
- 도입 조건: 문서 수천 건 이상, 시맨틱 검색 필요성 체감
- vault 마크다운을 add_resource()로 인덱싱
- VLM/embedding provider 구성 (이 시점에 PoC)
- 기존 vault 구조 변경 없이 캐시 레이어로 추가

---

## 10. 환경변수 계약

| 변수 | 주입 주체 | 비고 |
|------|-----------|------|
| CLAUDEBOX_PROFILE | ClaudeBox → 컨테이너 | haimdall-backend / haimdall-frontend |
| CLAUDEBOX_USER | ClaudeBox → 컨테이너 | Slack 사용자명 |
| CLAUDEBOX_WORKTREE_ID | ClaudeBox → 컨테이너 | worktree 식별자 |
| CLAUDEBOX_BASE_BRANCH | ClaudeBox → 컨테이너 | develop 등 |
| VAULT_DIR | docker-compose → 컨테이너 | /workspace/vault |
| SLACK_APP_TOKEN | .env → ClaudeBox | Socket Mode |
| SLACK_BOT_TOKEN | .env → ClaudeBox | Slack API |
| ANTHROPIC_API_KEY | .env → ClaudeBox | Claude Code 실행 |
| GH_TOKEN | .env → ClaudeBox | GitHub PR |

**불필요: OPENAI_API_KEY, OPENVIKING_URL** (1단계)

---

## 11. 위험 요소

| 항목 | 수준 | 대안 |
|------|------|------|
| ClaudeBox Slack 파일 다운로드 미구현 | 🔴 필수 | slack/helpers.ts 확장 |
| PDF/DOCX 마크다운 변환 경로 | 🟡 Phase 0 검증 | Claude Code 직접 또는 pandoc |
| Docker 내 Git 커밋 권한 | 🟡 Phase 0 검증 | Git user 설정 + 볼륨 권한 |
| vault 문서량 증가 시 검색 한계 | 🟡 장기 | 2단계 OpenViking 도입 |
| ClaudeBox 단일 REPO_DIR | 🟡 주의 | 레포별 인스턴스 분리 |
| ClaudeBox Aztec 특화 코드 | 🟡 주의 | barretenberg, ci3 제거/무시 |

---

## 12. 금지사항

1. Claude Code를 다른 실행 엔진으로 대체하지 말 것
2. Slack을 유일한 진입점으로 설계하지 말 것
3. 1단계에서 OpenViking을 필수 핵심으로 묶지 말 것
4. 1단계에서 시맨틱 벡터 검색을 성공 조건으로 두지 말 것
5. vault에 바이너리 파일(PDF/DOCX 원본)을 직접 저장하지 말 것
6. k-orchestrator를 독립 서버로 바꾸지 말 것
7. OpenViking을 완전히 버리지 말 것 — 2단계 경로를 유지할 것

---

> 본 문서는 k-orchestrator v1.4.1 (marketplace: kor), ClaudeBox 423cb84, OpenViking 소스 분석, GPT 피드백 3회를 통합한 최종본입니다.
> 마지막 동기화: 2026-03-15 — CCG 계획 승인 반영, 버전 업데이트
