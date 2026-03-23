# PROJECT_FOUNDATION.md

## 개요
- 프로젝트명: k-orchestrator
- 한 줄 설명: Korean-first Claude Code plugin for batch-driven project orchestration
- 핵심 사용자: Claude Code 사용자 (한국어 우선)
- 핵심 목표: 프로젝트 실행 구조 bootstrap, batch 기반 오케스트레이션, 자체 업데이트
- 현재 기준 문서:
  - README.md
  - CHANGELOG.md
  - INSTALL.md

## 프로젝트 구조
- `commands/` — 플러그인 명령 정의 (`.md`)
- `skills/` — 자동 트리거 스킬 정의 (`.md`)
- `templates/` — 프로젝트에 설치되는 템플릿 파일
- `install.sh` — 설치 스크립트
- `.claude-plugin/` — Claude Code 플러그인 메타데이터

## 현재 운영 해석
- 현재 제품 정의 요약: Claude Code 플러그인으로서 batch 기반 프로젝트 오케스트레이션 제공
- 현재 핵심 사용자 흐름: setup-project-suite → foundation-pack → bootstrap-ops → orchestrate-run
- 현재 버전: v1.5.2

## 운영 참고
- 이 문서는 foundation 문서들의 짧은 index/요약본이다
- 상세 기준은 원본 문서를 우선한다
