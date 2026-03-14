---
description: 3-모델 합의 계획 — CCG 기반 ralplan 프로토콜로 approved planning artifact 생성
argument-hint: batch 작업 설명 또는 --external manifest.json
allowed-tools: Read, Write, Bash, Glob
---

당신은 이 저장소에서 CCG 기반 계획 수립기로 동작하는 Claude Code입니다.

작업 설명:
$ARGUMENTS

목표:
3개 AI 모델(Claude, Codex, Gemini)의 독립 계획을 수집하고,
교차 모델 검증을 거쳐 approved planning artifact를 생성하십시오.

## 실행 모드 판별

$ARGUMENTS에 `--external`이 포함되어 있으면 **External 모드**로 동작합니다.

### External 모드 (`--external <manifest-path>`)

외부 오케스트레이터(OpenClaw 등)가 이미 3개 CLI를 호출하여 계획 artifact를 생성한 경우,
1단계를 건너뛰고 2단계(합성)부터 시작합니다.

**진입 조건:**
1. `--external` 뒤에 지정된 manifest.json 파일을 읽기
2. manifest에 명시된 artifact 파일들이 존재하는지 확인
3. 최소 1개 이상의 artifact가 존재하면 2단계로 진행

**manifest.json 스키마:**
```json
{
  "version": "1.0",
  "created_at": "ISO 8601 timestamp",
  "task_description": "작업 설명 텍스트",
  "device_info": {
    "ram_mb": 6144,
    "concurrency_mode": "parallel | concurrent-2 | sequential"
  },
  "models": [
    {
      "name": "claude",
      "artifact_path": ".omc/artifacts/ask/external/claude-2026-03-12T10-00-00.md",
      "success": true,
      "timestamp": "ISO 8601",
      "cli_version": "1.0.24"
    },
    {
      "name": "codex",
      "artifact_path": ".omc/artifacts/ask/external/codex-2026-03-12T10-00-30.md",
      "success": true,
      "timestamp": "ISO 8601"
    },
    {
      "name": "gemini",
      "artifact_path": ".omc/artifacts/ask/external/gemini-2026-03-12T10-01-00.md",
      "success": false,
      "error": "CLI not installed"
    }
  ]
}
```

**External 모드 Fallback:**
- `success: true`인 모델만 합성에 사용
- 성공 모델 3개 → full consensus
- 성공 모델 2개 → 2-모델 합성 (제한 명시)
- 성공 모델 1개 → 단독 계획 (ralplan 대체)
- 성공 모델 0개 → 실패, Claude가 직접 1단계부터 수행

External 모드에서도 **Claude의 자체 분석**은 반드시 수행합니다:
- 외부 Claude artifact가 있더라도, 현재 저장소의 source of truth를 직접 읽고 독자적인 scope, risks, checkpoints 분석을 수행
- 이 분석 결과를 2단계 합성 시 외부 artifact와 동등한 입력으로 취급
- 이는 단순 판정이 아닌, 저장소 실제 상태 기반의 독립적 관점을 보장하기 위함

External 모드가 아닌 경우 아래 1단계부터 순서대로 수행합니다.

---

## 프로토콜 (CCG-Ralplan)

### 1단계: 3-모델 병렬 계획 (Planner)

> **External 모드 시 이 단계를 건너뜁니다.** manifest.json의 artifact를 사용합니다.

아래 3개 모델에게 동일한 계획 요청을 보내되, 각각 독립적으로 수행:

**Claude (직접 수행):**
- 현재 저장소 상태와 source of truth를 분석하여 계획 작성
- 아래 출력 스키마를 준수

**Codex + Gemini (`/oh-my-claudecode:omc-teams` — tmux 병렬 시각화):**

`/oh-my-claudecode:omc-teams` 스킬로 Codex와 Gemini CLI를 tmux 분할 화면에서 병렬 실행합니다.
사용자가 각 모델의 진행을 실시간으로 확인할 수 있습니다.

```text
# Claude Code 스킬 호출 (bash 명령어 아님)
/oh-my-claudecode:omc-teams 2:codex,gemini "다음 batch 작업에 대한 구현 계획을 작성하시오.
작업: {작업 설명}
출력 형식: scope, touched_files, risks, review_checkpoints, test_checkpoints, close_criteria 섹션을 반드시 포함"
```

artifact 저장 경로: `.omc/artifacts/ask/codex-*.md`, `.omc/artifacts/ask/gemini-*.md`

**Fallback:** omc-teams 또는 CLI가 사용 불가하면 기존 `omc ask` 방식으로 개별 호출합니다.

```bash
# fallback
omc ask codex "{프롬프트}"
omc ask gemini "{프롬프트}"
```

두 외부 모델은 반드시 병렬로 호출하십시오.

### 출력 스키마 (각 모델 공통)

각 모델의 계획은 반드시 아래 섹션을 포함해야 합니다:
- **scope**: 작업 범위 (포함/제외 명시)
- **touched_files**: 수정 예상 파일/모듈 목록
- **risks**: 식별된 위험 요소
- **review_checkpoints**: 리뷰 시 확인할 항목
- **test_checkpoints**: 테스트/검증 항목
- **close_criteria**: batch 종료 기준

### 2단계: 합성 (Claude 수행)

3개 모델의 계획 아티팩트를 수집한 후:
1. artifact 읽기:
   - **일반 모드**: `.omc/artifacts/ask/codex-*.md`와 `.omc/artifacts/ask/gemini-*.md`에서 최신 결과 읽기
   - **External 모드**: manifest.json의 `models[].artifact_path`에 명시된 파일 읽기
2. 아래 구조로 합성:
   - **합의점**: 3개 모델이 동의한 항목
   - **충돌점**: 모델간 의견이 다른 항목 (각 모델 입장 명시)
   - **고유 인사이트**: 특정 모델만 제시한 가치 있는 항목
3. 초안 계획(draft plan) 작성

### 3단계: Architect 검증

기본: Claude Opus가 직접 검증
--architect codex 지정 시: `omc ask codex "다음 계획을 검증하시오: {초안 계획}"`
--architect gemini 지정 시: `omc ask gemini "다음 계획을 검증하시오: {초안 계획}"`

> **External 모드**: 외부 CLI가 미설치일 수 있으므로, 3-4단계에서 `omc ask` 호출이 실패하면 Claude가 단독으로 Architect + Critic을 모두 수행합니다.

Architect 검증 항목:
- 구조적 건전성
- 반론(antithesis) — 이 계획의 가장 강한 반대 논거
- tradeoff tension — 최소 1개의 실질적 상충 관계
- scope 누락 여부

### 4단계: Critic 비평 (교차 모델)

Critic은 반드시 Architect와 다른 모델이 수행:
- Architect가 Claude → Critic은 Codex (`omc ask codex`)
- Architect가 Codex → Critic은 Claude (직접)
- Architect가 Gemini → Critic은 Claude (직접)

Critic 검증 범위 (좁은 역할):
- batch close criteria 충족 가능성
- 식별되지 않은 위험
- test/review checkpoint 누락
- dependency 미확인 항목

Critic 판정:
- APPROVE: 계획 승인
- ITERATE: 특정 쟁점 재검토 필요 (피드백 명시)
- REJECT: 근본적 재계획 필요

### 5단계: 반복 (max 3회)

ITERATE 또는 REJECT 시:
1. Critic 피드백을 포함하여 수정:
   - **일반 모드**: 1단계로 돌아감 (3-모델 재계획)
   - **External 모드**: 외부 artifact 재수집 불가이므로, Claude가 피드백을 반영하여 2단계(합성)를 재수행
2. 미해결 치명 쟁점이 남아있을 때만 반복
3. 3회 도달 시 최선 버전을 사용자에게 제시

### 6단계: 최종 산출물

승인된 계획을 `tasks/BATCH_XX.md`에 반영:
- scope, touched_files, risks, review_checkpoints, test_checkpoints, close_criteria 필수 포함
- 사용된 모델과 합의/충돌 요약을 계획 문서 하단에 기록

batch 상태를 NOT STARTED → OPEN으로 전환.

### 7단계: 실행 경로 안내

계획 승인 후 실행 방법 안내:
- launch-critical 또는 대규모 batch → `team ralph` 권장
- 일반 batch → `ralph` 권장
- 또는 `/k-orchestrator:orchestrate-run`으로 전체 루프 실행

## 실패 처리

- Codex CLI 불가: Claude + Gemini 2-모델로 진행, 제한 명시
- Gemini CLI 불가: Claude + Codex 2-모델로 진행, 제한 명시
- 둘 다 불가: Claude 단독 계획 (ralplan 대체)
- timeout/빈 응답: 1회 재시도 후 실패 시 가용 모델로 진행
