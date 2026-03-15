---
description: OMC + recall + sync-claude-sessions + Obsidian/QMD 보조 기억 계층을 감사하고 project-local 중심으로 설정
argument-hint: [optional notes]
allowed-tools: Read, Write, Bash
---

당신은 현재 이 프로젝트 저장소 안에서 작업하는 Claude Code입니다.

추가 메모:
$ARGUMENTS

목표:
OMC를 유지한 채 recall / sync-claude-sessions / Obsidian / QMD 기반 보조 기억 계층이
필요한지 감사하고, 필요한 경우 Obsidian vault 중심으로 실제 구조를 생성/정리하십시오.

역할 분리 원칙:
| 계층 | 역할 | 우선순위 |
|---|---|---|
| 코드/repo 문서 | Source of truth | 1 |
| `docs/EXECUTION_STATUS.md` | 실행 상태 원장 | 2 |
| `.omc/*` | OMC 보조 실행 메모리 | 3 |
| recall/sync-claude-sessions | 세션 경계 지속성 | 4 |
| Obsidian/QMD | 장기 기억/검색 보조 | 5 |

중요 원칙:
1. OMC는 계속 주 실행 엔진으로 유지
2. recall / sync / Obsidian / QMD는 보조 기억 계층으로만 사용
3. source of truth 우선순위를 절대 깨지 않는다
4. global `~/.claude`가 잘 동작하면 불필요하게 복제/덮어쓰지 않는다
5. hooks는 보수적으로 사용하고 per-prompt 자동화는 금지한다
6. SessionEnd/Stop 중심 sync를 선호하고 UserPromptSubmit 자동 sync는 금지한다
7. `VAULT_DIR`는 실제 Obsidian vault 루트 절대경로여야 한다 (`docs/` 금지)
8. 이번 단계는 Obsidian vault + Git까지만 구현한다 (QMD/OpenViking 제외)

작업 순서:
1. 현재 상태 감사 (global/local/hybrid 판정)
2. `VAULT_DIR` 검증/교정
3. `.omc/notepad.md` 점검 (active batch / blocker / next action만 유지)
4. hooks 정규화 (`templates/hooks/minimal-hooks.json` 기준)
5. Obsidian readiness 점검 및 **실제 구축**
6. `docs/CLAUDE_MEMORY_SETUP.md` 생성/업데이트
7. 최종 검증 및 한국어 보고

## 실제 구축 규칙
`VAULT_DIR`가 설정되어 있고 디렉토리가 비어 있거나 구조가 없으면 아래를 수행한다.

### 1. 프로젝트 slug 결정
- `CLAUDEBOX_PROFILE`가 있으면 그 값을 사용
- 없으면 현재 저장소명 또는 `default-project` 사용
- generic command에서 `haimdall`를 하드코딩하지 않는다

### 2. 기본 vault 구조 생성
```text
$VAULT_DIR/
├── team/
│   └── policies/
├── projects/
│   └── <project-slug>/
│       ├── planning/
│       ├── incidents/
│       └── sessions/
├── unsorted/
└── README.md
```

필수 동작:
- `mkdir -p`로 idempotent 하게 생성
- 빈 디렉토리는 `.gitkeep` 또는 starter markdown으로 유지
- 기존 내용이 있으면 덮어쓰지 않는다

### 3. vault README.md 생성
README가 없으면 아래 내용을 생성한다:

```markdown
# Knowledge Vault

팀 공용 지식베이스.

## 구조
- team/ — 팀 공통 컨벤션, 정책
- projects/<project-slug>/ — 프로젝트별 문서
- projects/<project-slug>/sessions/ — AI 세션 요약 (자동 생성)
- unsorted/ — 분류 전 임시 저장

## 사용법
- Obsidian 앱으로 열어서 탐색/편집
- Claude Code/OMC에서 직접 읽기
- 분류 애매한 문서는 unsorted/에 저장 후 정리
```

### 4. Git 초기화
- vault가 Git 레포가 아니면 `git init`
- `.gitignore`가 없으면 아래 항목을 추가:
  - `.obsidian/workspace.json`
  - `.obsidian/workspaces.json`
  - `.DS_Store`
- 가능하면 초기 커밋 수행
- Git 실패는 보고하되 작업 전체를 중단하지 않는다

### 5. 설정 문서 생성
`docs/CLAUDE_MEMORY_SETUP.md`가 없으면 템플릿에서 생성하고 아래를 실제 값으로 채운다:
- `VAULT_DIR`
- project slug
- hook 경로(`/opt/k-orchestrator/hooks/*.sh` 또는 fallback)
- 마지막 점검일

## 검증 요구사항
- `VAULT_DIR` 없을 때 non-fatal 종료
- 디렉토리 구조 재실행 시 중복/파괴 없음
- source of truth 우선순위 유지
- vault를 생성했더라도 QMD/OpenViking 관련 코드는 추가하지 않음
