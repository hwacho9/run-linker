# RunLinker AI Handoff Pack

이 폴더는 **RunLinker** 앱을 AI 에이전트에게 넘겨서 **프로젝트 셋업, 문서화, 개발환경 구성, MVP 개발**을 진행시키기 위한 문서 묶음입니다.

## 제품명 규칙
- 최종 제품 용어는 **Activity** 입니다.
- 과거 Stitch 산출물에 `Records` 라는 이름이 있더라도, 최종 앱/문서/코드에서는 **Activity** 로 통일합니다.

## 권장 사용 순서
1. `docs/00_APP_OVERVIEW.md`
2. `docs/01_INFORMATION_ARCHITECTURE.md`
3. `docs/02_SCREEN_SPECS.md`
4. `docs/04_BUSINESS_LOGIC.md`
5. `docs/05_DATA_MODEL.md`
6. `docs/06_API_REALTIME_CONTRACTS.md`
7. `docs/07_PRIVACY_AND_SAFETY.md`
8. `docs/10_TECH_STACK_AND_REPO_STRUCTURE.md`
9. `docs/runlinker_ai_context.yaml`
10. `prompts/01_PROJECT_SETUP_PROMPT.md`

## 폴더 구성
- `docs/`: 제품/설계/비즈니스 로직 문서
- `prompts/`: AI 에이전트용 실행 프롬프트
- `docs/runlinker_ai_context.yaml`: AI 입력용 요약 컨텍스트

## 이 묶음의 목적
- RunLinker의 핵심 개념을 빠르게 전달
- 화면 구조와 사용자 흐름을 명확히 정의
- 실시간 매칭/러닝/결과 산출 로직을 문서화
- Expo + React Native + Firebase 기반 개발을 AI가 일관되게 시작할 수 있게 함

## 핵심 한 줄
**RunLinker는 친구 또는 매칭된 상대와 멀리 떨어져 있어도 함께 달리는 감각을 제공하는 실시간 소셜 러닝 앱이다.**

## AI 전달용 파일
- `prompts/00_AI_HANDOFF_INSTRUCTIONS.md`
- `prompts/06_ANTIGRAVITY_MASTER_PROMPT.md`
