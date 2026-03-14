# k-orchestrator

Korean-first Claude Code plugin for batch-driven project orchestration.

## 프로젝트 성격
- 이 저장소는 Claude Code 플러그인 소스 코드이다
- 주요 구성: commands (`.md`), skills (`.md`), templates (`.md`), install script (`bash`)
- 빌드 시스템/테스트 프레임워크 없음 — 변경 검증은 install.sh 실행 + 실제 플러그인 로드 테스트로 수행

## 로컬 플러그인 실행
- 이 프로젝트에서 자체 플러그인을 테스트하려면: `claude --plugin-dir ./`
- 다른 프로젝트에서 GitHub 설치: `/install-plugin k-orchestrator@k-orchestrator`

@docs/CC_ORCHESTRATOR.md
@docs/PROJECT_FOUNDATION.md
