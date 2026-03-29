# AI 프롬프트 01 — 프로젝트 셋업 + 기본 문서화

아래 문서들을 모두 읽고, 그 내용을 기준으로 RunLinker 저장소를 세팅해줘.

읽을 문서:
- docs/00_APP_OVERVIEW.md
- docs/01_INFORMATION_ARCHITECTURE.md
- docs/02_SCREEN_SPECS.md
- docs/03_USER_FLOWS.md
- docs/04_BUSINESS_LOGIC.md
- docs/05_DATA_MODEL.md
- docs/06_API_REALTIME_CONTRACTS.md
- docs/07_PRIVACY_AND_SAFETY.md
- docs/08_MVP_ROADMAP.md
- docs/10_TECH_STACK_AND_REPO_STRUCTURE.md
- docs/runlinker_ai_context.yaml

작업 목표:
1. Expo + React Native + TypeScript 기반 모바일 앱 저장소 초기화
2. Expo Router 적용
3. pnpm workspace 구조 생성
4. Firebase 연동을 위한 기본 골격 생성
5. mock data mode로 앱이 바로 실행되게 만들기
6. 문서와 코드의 용어를 일치시키기
7. 제품 탭 이름은 반드시 Activity를 사용하기
8. Records라는 이름은 최종 제품 표면에서 사용하지 않기

필수 탭:
- Home
- Activity
- Friends
- My

핵심 러닝 플로우:
Home -> Match Setup -> Matching -> Ready Room -> Live Run -> Results

기술 기본값:
- Expo
- React Native
- TypeScript
- Expo Router
- Zustand
- TanStack Query
- Firebase Auth / Firestore / Functions / Storage / Analytics
- ESLint / Prettier / Husky / lint-staged / GitHub Actions

산출물:
- 루트 README
- 앱 실행 스크립트
- 기본 폴더 구조
- 탭 네비게이션
- 화면 placeholder
- mock repositories / mock data
- 기본 theme/token
- 환경변수 예시 파일
- CI 파일

주의사항:
- 문서 내용을 우선 기준으로 삼아라
- 과한 추상화는 피하라
- compile 되지 않는 stub를 남기지 마라
- mock data만으로 첫 실행이 가능해야 한다
- 코드 내 명칭도 Activity로 통일하라

마지막에 다음 내용을 보고해줘:
- 생성한 폴더 구조
- 주요 의사결정
- 로컬 실행 방법
- 남은 TODO