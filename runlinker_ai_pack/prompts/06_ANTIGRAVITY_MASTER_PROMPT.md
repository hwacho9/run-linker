# AI 프롬프트 06 — Antigravity용 통합 마스터 프롬프트

아래 문서들을 모두 읽고, 그 내용을 기준으로 RunLinker 프로젝트의 초기 셋업과 MVP skeleton 개발을 진행해줘.

문서:
- docs/00_APP_OVERVIEW.md
- docs/01_INFORMATION_ARCHITECTURE.md
- docs/02_SCREEN_SPECS.md
- docs/03_USER_FLOWS.md
- docs/04_BUSINESS_LOGIC.md
- docs/05_DATA_MODEL.md
- docs/06_API_REALTIME_CONTRACTS.md
- docs/07_PRIVACY_AND_SAFETY.md
- docs/08_MVP_ROADMAP.md
- docs/09_OPEN_QUESTIONS.md
- docs/10_TECH_STACK_AND_REPO_STRUCTURE.md
- docs/runlinker_ai_context.yaml

작업 방식:
- planning mode로 시작
- 먼저 구현 계획과 task list를 만든 뒤 실제 파일 편집 시작
- 작은 단위로 검토 가능한 변경을 진행
- mock data mode로 먼저 앱이 동작하게 만들기

제품 명칭 규칙:
- 최종 제품 탭명은 Activity
- Records 표기는 최종 앱 표면에서 사용 금지

목표:
1. Expo + React Native + TypeScript 저장소 생성
2. Expo Router 기반 탭/플로우 네비게이션 생성
3. Home / Activity / Friends / My 탭 구현
4. Match Setup / Matching / Ready Room / Live Run / Results 구현
5. Session Detail 구현
6. mock data와 typed domain model 구축
7. Firebase 연동 가능한 구조 마련
8. README / 환경변수 예시 / CI / lint / test 골격 구성

꼭 지켜야 할 UX 원칙:
- Home은 즉시 시작
- Activity는 데이터 허브
- Friends는 친구 선택/초대 중심
- My는 설정/프라이버시 중심
- Live Run은 Pair View + Split Live Maps
- random mode는 exact location 기본 비공개

마지막에 보고할 것:
- 생성한 파일 구조
- 주요 아키텍처 결정
- 로컬 실행 명령어
- 남은 오픈 질문
- 다음 개발 우선순위