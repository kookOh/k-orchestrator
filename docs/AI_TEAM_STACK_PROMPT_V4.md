# ai-team-stack 구축 프롬프트 v4

> 1단계: Obsidian vault + Git 중심 | OpenViking/Ollama 없음 | QMD는 1.5단계
> CCG 검증 완료: 2026-03-15
> 사용법: 빈 디렉토리에서 `claude` 실행 후 이 프롬프트 전체를 붙여넣기

---

## 전제조건

- k-orchestrator v1.4.1 (marketplace: kor) feat/claudebox-integration 브랜치가 GitHub에 푸시되어 있어야 함
- 해당 브랜치에 install-in-docker.sh, hooks/stop-sync.sh, hooks/session-context-loader.sh 포함
- BATCH_01 완료 후 main 머지 시 Dockerfile 참조를 main으로 변경

---

## 프롬프트

```
너는 doubleT의 haimdall용 ai-team-stack 전체를 구축하는 시니어 DevOps/Platform 엔지니어야.

# 프로젝트 개요

doubleT는 haimdall(산업 사고 예방 AI 시스템)을 개발하는 회사야.
개발팀이 이미 Claude Code + OMC + k-orchestrator(v1.4.1)를 개인 환경에서 쓰고 있고,
이걸 팀 단위로 확장하는 인프라를 만드는 거야.

목표 3가지:
1. 팀 단위 AI 코드 실행: 요청 → 코드 수정 → 검증 → PR 생성
2. 팀 단위 지식 축적: 문서/정책/패턴을 Obsidian vault에 누적, 재사용
3. 이미지/파일 기반 대화: 에러 스크린샷, 디자인 시안 기반 작업

진입점 3개 (멀티 엔트리):
- Slack (팀 협업)
- Claude Code CLI (개발자 직접)
- OMC CLI (개발자 직접)

# 구현 전 검증 (Phase 0)

구현 시작 전 아래 3개를 먼저 검증하고 결과를 보고해:
- [ ] Claude Code가 PDF를 직접 읽어서 마크다운 변환 가능한지 테스트
- [ ] Docker 컨테이너 내 Git 커밋 정상 동작 확인 (user/email 설정)
- [ ] frontmatter 기반 grep 검색이 실제 워크플로우에 충분한지 확인

# 지식 레이어 전략 (매우 중요)

1단계(이번): Obsidian vault + Git
- 마크다운 파일 기반 팀 지식 저장소
- Claude Code가 vault를 직접 읽고 쓰기
- 검색은 파일명/폴더/frontmatter/ripgrep
- 별도 DB, 벡터 검색, VLM/embedding 없음
- 외부 API 과금 0원

1.5단계(나중): QMD/Quarto
- vault 기반 문서 포털/사이트 출판
- 1단계 필수는 아님

2단계(필요 시): OpenViking
- vault 마크다운을 인덱싱하는 캐시 레이어
- 시맨틱 벡터 검색 + L0/L1/L2 자동 생성
- 문서 수천 건 이상일 때 도입

# 절대 원칙

1. 먼저 이 프롬프트를 끝까지 읽고 전체 파일 목록을 제안해. 내가 승인하면 구현 시작.
2. 환경변수는 .env.example에 키만 정의. 하드코딩 금지.
3. Docker multi-stage build로 이미지 최소화.
4. 1단계에서 OpenViking, Ollama, 벡터 DB를 추가하지 마.
5. 1단계에서 QMD/Quarto를 필수로 넣지 마.
6. vault에 바이너리(PDF/DOCX 원본) 직접 저장 금지. 마크다운 변환만.
7. k-orchestrator는 governance pack이야. 독립 서버 아님.

# 작업 유형 3가지

## Type A: 코드 실행 (기본)
텍스트 요청 → worktree → 코드 수정 → PR → Slack 회신

## Type B: 문서 Ingestion
파일 + "학습/저장/인덱싱/등록" 키워드 → Claude Code가 마크다운 변환+분류 → vault 저장 → Git 커밋

## Type C: 이미지/파일 기반 대화
파일 + 일반 요청 → 이미지를 컨텍스트로 포함 → Claude Code 비전 → 코드 수정 → PR

판별: 파일+ingestion키워드→B, 파일+일반요청→C, 파일없음→A

# 디렉토리 구조

ai-team-stack/
├── docker-compose.yml
├── .env.example
├── Makefile
├── README.md
├── .gitignore
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
├── agent-image/
│   ├── Dockerfile
│   ├── install-k-orchestrator.sh
│   └── install-omc.sh
├── knowledge-vault/
│   ├── team/
│   │   ├── coding-conventions.md
│   │   ├── onboarding.md
│   │   └── policies/
│   ├── projects/
│   │   └── haimdall/
│   │       ├── architecture.md
│   │       ├── planning/
│   │       ├── incidents/
│   │       └── sessions/
│   ├── unsorted/
│   ├── .obsidian/
│   ├── .gitignore
│   └── README.md
└── data/
    └── claudebox/worktrees/

**openviking/, ollama/ 디렉토리 없음. 1단계에서 불필요.**

# 컴포넌트 상세

## 1. docker-compose.yml

서비스 3개 + 빌드 전용 1개:

### claudebox-haimdall-backend
- 빌드: claudebox/Dockerfile (AztecProtocol/claudebox 기반)
- /var/run/docker.sock 마운트
- Socket Mode → 외부 포트 없음
- 환경변수: SLACK_APP_TOKEN, SLACK_BOT_TOKEN, GH_TOKEN, ANTHROPIC_API_KEY
- 환경변수: CLAUDEBOX_DOCKER_IMAGE=ai-team-agent:latest
- 환경변수: CLAUDE_REPO_DIR
- 볼륨: ./claudebox/profiles:/opt/claudebox/profiles:rw
- 볼륨: ./knowledge-vault:/opt/knowledge-vault:rw
- 볼륨: ./data/claudebox/worktrees:/home/claude/.claudebox/worktrees
- 네트워크: default
- 커맨드: node --experimental-strip-types server.ts --profiles=haimdall-backend

### claudebox-haimdall-frontend
- 동일 구조, 별도 Slack 토큰/REPO_DIR
- --profiles=haimdall-frontend

### agent-builder (build profile)
- 빌드: agent-image/Dockerfile
- profiles: ["build"]
- 이미지 태그: ai-team-agent:latest

네트워크: 내부 전용 네트워크 불필요 (OpenViking 없으므로)

## 2. claudebox/Dockerfile

AztecProtocol/claudebox 기반:
- FROM node:22-bookworm
- git clone claudebox → npm install
- Aztec 특화(barretenberg, ci3) 주석/무시
- profiles/ 는 볼륨 마운트

### Slack 파일 다운로드 확장 (핵심)

slack/helpers.ts의 startNewSession 전:

```typescript
async function downloadSlackFiles(
  client: any, files: any[], workspaceDir: string
): Promise<string[]> {
  const uploadDir = join(workspaceDir, "uploads");
  mkdirSync(uploadDir, { recursive: true });
  const downloaded: string[] = [];
  for (const file of files) {
    const resp = await fetch(file.url_private_download, {
      headers: { Authorization: `Bearer ${process.env.SLACK_BOT_TOKEN}` }
    });
    const dest = join(uploadDir, file.name);
    writeFileSync(dest, Buffer.from(await resp.arrayBuffer()));
    downloaded.push(dest);
  }
  return downloaded;
}
```

프롬프트 구성:
- Type B: `프롬프트 + "\n\n첨부 파일:\n" + paths.join("\n")`
- Type C: `프롬프트 + "\n\n첨부 파일:\n" + paths.map(f => isImage(f) ? f+" [image]" : f).join("\n")`

## 3. agent-image/Dockerfile

```dockerfile
# NOTE: BATCH_01 완료 후 main 머지 시 -b feat/claudebox-integration → -b main 으로 변경
FROM node:22-bookworm AS k-orch-builder
RUN apt-get update && apt-get install -y git
RUN git clone -b feat/claudebox-integration \
    https://github.com/kookOh/k-orchestrator.git /tmp/k-orchestrator
RUN bash /tmp/k-orchestrator/install-in-docker.sh /opt/k-orchestrator

FROM node:22-bookworm
RUN apt-get update && apt-get install -y python3 python3-pip git curl jq pandoc \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# OMC
RUN npm install -g oh-my-claudecode

# k-orchestrator + hooks
COPY --from=k-orch-builder /opt/k-orchestrator /opt/k-orchestrator

RUN git config --global --add safe.directory '*'
RUN useradd -m -s /bin/bash claude
USER claude
WORKDIR /home/claude
```

주의: pandoc 포함 — Type B ingestion에서 DOCX → 마크다운 변환에 사용.

## 4. knowledge-vault/ 초기 구조

knowledge-vault/
├── team/
│   ├── coding-conventions.md
│   ├── onboarding.md
│   └── policies/
│       └── .gitkeep
├── projects/
│   └── haimdall/
│       ├── architecture.md
│       ├── planning/
│       │   └── .gitkeep
│       ├── incidents/
│       │   └── .gitkeep
│       └── sessions/
│           └── .gitkeep
├── unsorted/
│   └── .gitkeep
├── .obsidian/
│   └── .gitkeep
├── .gitignore
└── README.md

.gitignore:
```
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.DS_Store
```

README.md:
```markdown
# Knowledge Vault

doubleT / haimdall 팀 공용 지식베이스.

## 구조
- team/ — 팀 공통 컨벤션, 정책
- projects/<프로젝트명>/ — 프로젝트별 문서 (CLAUDEBOX_PROFILE로 결정)
- projects/<프로젝트명>/sessions/ — AI 세션 요약 (자동 생성)
- unsorted/ — 분류 전 임시 저장

## 사용법
- Obsidian 앱으로 열어서 탐색/편집
- Claude Code/OMC에서 직접 읽기/쓰기
- Slack에서 파일 업로드 + "학습/저장/인덱싱/등록" → 자동 분류/저장
```

## 5. shared-policy/ingestion-workflow.md

```markdown
# 문서 Ingestion 워크플로우

Slack에서 문서 파일이 업로드되고 "학습/저장/인덱싱/등록" 요청이 들어왔을 때 적용.

## 절차

1. /workspace/uploads/ 에서 첨부 파일 확인
2. 파일 형식별 처리:
   - .md → 직접 읽기
   - .docx → pandoc으로 마크다운 변환 (pandoc -f docx -t markdown)
   - .pdf → Claude Code가 내용을 직접 읽고 마크다운으로 정리
   - .txt → 마크다운으로 래핑
3. 문서 유형 분류 (CLAUDEBOX_PROFILE 기반):
   - 기획 → vault/projects/${CLAUDEBOX_PROFILE}/planning/
   - 정책 → vault/team/policies/ 또는 vault/projects/${CLAUDEBOX_PROFILE}/policies/
   - 운영 → vault/projects/${CLAUDEBOX_PROFILE}/operations/
   - 회의록 → vault/projects/${CLAUDEBOX_PROFILE}/meetings/
   - ADR/아키텍처 → vault/projects/${CLAUDEBOX_PROFILE}/architecture/
   - 요구사항 → vault/projects/${CLAUDEBOX_PROFILE}/requirements/
4. frontmatter 생성:
   ```yaml
   ---
   type: [policy|architecture|planning|incident|convention|meeting]
   project: ${CLAUDEBOX_PROFILE}
   source: slack-upload
   original_file: 원본파일명.pdf
   tags: [관련, 태그]
   date: YYYY-MM-DD
   ---
   ```
5. vault 적절한 디렉토리에 마크다운 저장
6. 분류 애매 → vault/unsorted/ + Slack에서 사용자 확인 요청
7. vault Git 커밋 (자동)
8. respond_to_user로 Slack 결과 보고

## 결과 보고 형식

"문서 N건 저장 완료:
 - {파일명} → vault/{경로} ({유형})
 - ...
 이후 작업에서 자동 참조됩니다."

## 안전장치
- 정책 문서는 기존 파일 덮어쓰기 금지, 버전 접미사 추가
- 바이너리(PDF/DOCX 원본) vault에 직접 넣지 않음, 마크다운 변환만
- vault는 Git이므로 모든 변경 추적됨
```

## 6. shared-policy/vault-rules.md

```markdown
# Vault 사용 규칙

## 읽기
- Claude Code가 vault 마크다운을 직접 읽어서 컨텍스트로 활용
- 작업 시작 시 관련 디렉토리를 ls하고 필요한 문서만 선택적 읽기
- 전체 vault 한번에 로드 금지
- 검색: ripgrep + 파일명 + frontmatter 태그

## 쓰기
- Stop 훅이 자동으로 sessions/ 디렉토리에 세션 요약 저장
- 수동 추가 시 적절한 디렉토리에 frontmatter 포함 마크다운 작성
- 정책 문서 덮어쓰기 금지
- vault는 Git → 변경사항 자동 추적

## 구조
- vault/team/ — 팀 공통
- vault/projects/${CLAUDEBOX_PROFILE}/ — 프로젝트별
- vault/projects/${CLAUDEBOX_PROFILE}/sessions/ — 세션 요약 (자동)
- vault/unsorted/ — 미분류 임시
```

## 7. Profile plugin.ts (haimdall-backend)

```typescript
import type { Profile } from "../../packages/libclaudebox/profile.ts";

const profile = process.env.CLAUDEBOX_PROFILE || "haimdall-backend";

const plugin: Profile = {
  name: "haimdall-backend",
  channels: [process.env.SLACK_CHANNEL_BACKEND || ""],
  docker: {
    image: process.env.CLAUDEBOX_DOCKER_IMAGE || "ai-team-agent:latest",
    extraEnv: [
      `CLAUDEBOX_PROFILE=${profile}`,
      `VAULT_DIR=/workspace/vault`,
    ],
    extraBinds: [
      `${process.env.KNOWLEDGE_VAULT_PATH || "./knowledge-vault"}:/workspace/vault:rw`,
    ],
  },
  branchOverrides: {
    [process.env.SLACK_CHANNEL_BACKEND || ""]: "develop",
  },
  promptSuffix: `## 작업 규칙
- k-orchestrator 스킬을 준수하세요
- 작업 시작 전 /workspace/vault/ 에서 관련 문서를 검색하세요
- 정책 참조: vault/team/policies/ 확인
- 기획 참조: vault/projects/${profile}/planning/ 확인
- 파일 첨부 + ingestion 요청이면 shared-policy/ingestion-workflow.md를 따르세요
- 작업 완료 후 GitHub PR을 생성하세요
- PR 제목은 한국어로`,
  summaryPrompt: `세션 요약을 한국어로 작성하세요.
respond_to_user로 Slack에 1-2문장 요약을 보내세요.`,
  setup() {},
};

export default plugin;
```

## 8. .env.example

```bash
# Slack (백엔드 봇)
SLACK_APP_TOKEN_BACKEND=xapp-...
SLACK_BOT_TOKEN_BACKEND=xoxb-...
SLACK_CHANNEL_BACKEND=C0XXXBACKEND

# Slack (프론트엔드 봇)
SLACK_APP_TOKEN_FRONTEND=xapp-...
SLACK_BOT_TOKEN_FRONTEND=xoxb-...
SLACK_CHANNEL_FRONTEND=C0XXXFRONTEND

# API Keys
ANTHROPIC_API_KEY=sk-ant-...
GH_TOKEN=ghp_...

# Repos
HAIMDALL_BACKEND_REPO_DIR=/path/to/haimdall-backend
HAIMDALL_FRONTEND_REPO_DIR=/path/to/haimdall-frontend
CLAUDE_REPO_DIR_BACKEND=/path/to/haimdall-backend
CLAUDE_REPO_DIR_FRONTEND=/path/to/haimdall-frontend

# Docker
CLAUDEBOX_DOCKER_IMAGE=ai-team-agent:latest

# Vault
KNOWLEDGE_VAULT_PATH=./knowledge-vault
```

**OPENAI_API_KEY: 불필요. OPENVIKING_URL: 불필요.**

## 9. Makefile

```makefile
.PHONY: setup build up down logs status init-vault

setup:
	cp -n .env.example .env
	@echo ">>> .env 파일에 실제 값을 입력하세요"

build:
	docker compose --profile build build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

status:
	docker compose ps

init-vault:
	cd knowledge-vault && git init && git add -A && git commit -m "Initial vault structure"
	@echo "✅ knowledge-vault Git 초기화 완료"
```

## 10. .gitignore

```
data/
.env
node_modules/
*.log
knowledge-vault/.obsidian/workspace.json
knowledge-vault/.obsidian/workspace-mobile.json
```

# 실행 순서

1. 전체 파일 목록 정리해서 보여줘
2. 내가 "진행"이라고 하면 파일 생성 시작
3. 각 파일 생성 후 검증
4. 완료 후: make init-vault → make build → make up
```

---

## 사전 준비물

- [ ] Slack 앱 2개 (backend/frontend) — Socket Mode, Bot Token + App Token
- [ ] Slack 채널 2개 — 채널 ID
- [ ] Anthropic API 키 (Claude Code 실행용)
- [ ] GitHub Personal Access Token
- [ ] haimdall 백엔드/프론트엔드 Git 레포 로컬 클론
- [ ] k-orchestrator feat/claudebox-integration 브랜치 푸시 완료

**불필요: OPENAI_API_KEY, Ollama, OpenViking**

## Fortigate 방화벽

SSL Deep Inspection 예외:
- `wss-primary.slack.com` (Slack Socket Mode)
- `api.anthropic.com` (Claude Code)
- `api.github.com` (GitHub)
- `*.githubusercontent.com` (k-orchestrator git clone)

**불필요: api.openai.com**

---

## v4 수정 이력 (CCG 검증 결과 반영)

| 수정 | 이유 |
|---|---|
| k-orchestrator v1.3.2 → v1.4.1 | 현재 버전 반영 |
| 전제조건 섹션 추가 | BATCH_01 의존성 명시 |
| Phase 0 검증 체크리스트 추가 | AI_TEAM_STACK_FINAL.md 섹션 8 반영 |
| `project: haimdall` → `project: ${CLAUDEBOX_PROFILE}` | 파라미터화 (CCG 합의) |
| `vault/projects/haimdall/` → `vault/projects/${CLAUDEBOX_PROFILE}/` | 동일 |
| `.env.example`에 CLAUDE_REPO_DIR_* 추가 | docker-compose 참조 누락 보완 |
| Fortigate에 `*.githubusercontent.com` 추가 | git clone 시 필요 |
| Dockerfile에 브랜치 변경 주석 추가 | main 머지 후 가이드 |
| Type B 키워드 동기화 | `학습/저장/인덱싱/등록` 통일 |
