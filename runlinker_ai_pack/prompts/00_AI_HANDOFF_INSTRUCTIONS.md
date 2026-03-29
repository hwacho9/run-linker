# AI 전달 방법

## 추천 순서
1. 먼저 `docs/` 문서 전체를 AI에게 컨텍스트로 제공한다.
2. 그 다음 `prompts/01_PROJECT_SETUP_PROMPT.md`를 실행한다.
3. 저장소가 만들어지면 `prompts/02_MOBILE_APP_IMPLEMENTATION_PROMPT.md`를 실행한다.
4. 이후 `prompts/03_FIREBASE_BACKEND_PROMPT.md`를 실행한다.
5. 마지막으로 `prompts/04_QA_REFACTOR_PROMPT.md`로 정합성을 맞춘다.
6. Stitch 산출물이 있으면 `prompts/05_STITCH_INTEGRATION_PROMPT.md`를 사용한다.

## 전달 포맷 권장
- 문서는 markdown 그대로 첨부
- YAML 파일도 함께 제공
- AI가 planning 모드를 지원하면 planning부터 시작
- 첫 응답에서 저장소 구조와 구현 순서를 먼저 제안하게 유도

## 꼭 강조할 것
- Records가 아니라 Activity
- Home은 시작 우선
- Friends는 피드가 아님
- My는 설정/목표 중심
- Live Run은 Pair View + Split Live Maps
- random 모드는 exact location 기본 비공개