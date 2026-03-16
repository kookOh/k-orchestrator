---
name: memory-layer-policy
description: Use when working with recall, sync-claude-sessions, Obsidian, or QMD. Enforce secondary-memory rules without overriding repo source of truth.
---

When dealing with memory integration:

## 기본 원칙
1. OMC remains the primary execution engine
2. recall / sync / Obsidian / QMD are secondary memory only
3. Never let recall results override code or repo docs
4. Only use `recall` when session state is genuinely unclear, a real blocker exists, or a context switch requires recovery
5. Do not call `recall` every phase
6. Prefer SessionEnd or batch-boundary sync
7. Do not enable per-prompt or per-phase auto-sync by default
8. `.omc/notepad.md` must stay short: active batch, current blocker, next action only
9. `VAULT_DIR` must point to the real Obsidian vault root absolute path, not the project docs folder
10. If memory integration is not clearly needed, do not add it
11. UserPromptSubmit-based auto-sync is prohibited
12. QMD/Obsidian index updates: SessionEnd or manual maintenance only
13. 1단계 구현 범위는 Obsidian vault + Git까지만이며 QMD/OpenViking은 이번 범위 밖이다

## Obsidian vault 구조
`VAULT_DIR`가 설정된 경우 아래 구조를 전제한다:

```text
$VAULT_DIR/
├── team/
│   ├── coding-conventions.md
│   ├── onboarding.md
│   └── policies/
├── projects/
│   └── <profile-or-project-slug>/
│       ├── architecture.md
│       ├── planning/
│       ├── incidents/
│       └── sessions/
├── unsorted/
└── .obsidian/
```

프로젝트 slug 규칙:
- `CLAUDEBOX_PROFILE`가 있으면 그 값을 사용한다
- 없으면 현재 프로젝트 slug 또는 `default-project`를 사용한다
- generic k-orchestrator 문서/명령에서 `haimdall`를 하드코딩하지 않는다

## 읽기 규칙
14. vault 내 마크다운은 Claude Code가 직접 읽어서 컨텍스트로 활용한다
15. 시맨틱 검색 대신 파일 경로 + ripgrep + frontmatter 태그 기반 탐색을 사용한다
16. 작업 시작 시 관련 디렉토리를 먼저 `ls`하고 필요한 문서를 선택적으로 읽는다
17. 전체 vault를 한 번에 로드하지 않는다 — 필요한 문서만 읽는다
18. source of truth 우선순위는 항상 코드/repo 문서 > `docs/EXECUTION_STATUS.md` > `.omc/*` > vault/recall 이다

## 쓰기 규칙
19. 세션 요약은 Stop hook이 자동으로 vault `projects/$CLAUDEBOX_PROFILE/sessions/` 또는 `sessions/`에 저장한다
20. 수동으로 지식을 추가할 때는 적절한 디렉토리에 마크다운 파일로 작성한다
21. 문서 작성 시 반드시 frontmatter를 포함한다:

```yaml
---
type: [policy|architecture|planning|incident|session-summary|convention]
project: <project-slug>
tags: [관련, 태그, 목록]
date: YYYY-MM-DD
---
```

22. 정책 문서는 기존 파일을 덮어쓰지 않고 버전을 분리하거나 변경 이력을 본문에 기록한다
23. transcript 전체를 vault에 저장하지 않는다 — 요약과 최소 메타데이터만 저장한다
24. vault Git 작업(`git add`, `git commit`)은 best-effort이며 실패해도 작업을 중단하지 않는다

## 문서 Ingestion (범위 밖)
25. Slack 파일 업로드 → vault 저장 등의 ingestion 워크플로우는 k-orchestrator 범위 밖이다
26. ingestion 규칙은 downstream 프로젝트(ai-team-stack 등)의 shared-policy/ingestion-workflow.md에서 정의한다
27. 원본 바이너리(PDF, DOCX 등)는 vault에 그대로 넣지 않고 markdown으로 변환한다 (일반 원칙으로 유지)

## 환경 분기
`VAULT_DIR` 환경변수가 설정되지 않은 환경에서는 위 23~27번의 vault 관련 규칙을 적용하지 않는다.
vault 구조, 읽기/쓰기 규칙, ingestion 규칙은 `VAULT_DIR`이 유효한 디렉토리를 가리킬 때만 활성화된다.

## ClaudeBox / Docker 환경
`CLAUDEBOX_PROFILE` 환경변수가 없으면 28~31번 ClaudeBox 규칙을 건너뛴다.

28. ClaudeBox 환경의 canonical runtime hook path는 `/opt/k-orchestrator/hooks/*.sh` 이다
29. `CLAUDEBOX_PROFILE`, `CLAUDEBOX_USER`, `CLAUDEBOX_WORKTREE_ID`, `CLAUDEBOX_BASE_BRANCH`는 메타데이터 및 profile-aware path 구성에만 사용한다
30. `VAULT_DIR`이 없거나 잘못되었거나 read-only여도 작업을 중단하지 않는다 (graceful degradation)
31. `install.sh`는 그대로 유지하고 Docker 전용 bundle staging은 `install-in-docker.sh`가 담당한다
