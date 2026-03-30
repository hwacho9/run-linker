# AI 프롬프트 07 — Android Kotlin 2차 개발

이제 RunLinker Android 앱 개발을 시작한다.

전제:
- iOS SwiftUI MVP 구조와 문서가 이미 존재한다
- 제품 용어, 도메인 모델, API 계약, privacy 규칙은 문서 기준으로 확정되었다
- Android는 그 계약을 따르되, UI 구현은 Android 네이티브에 맞게 새로 작성한다

우선 읽을 문서:
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
- docs/12_ANDROID_PHASE2_PLAN.md
- docs/runlinker_ai_context.yaml

권장 구현 방향:
- Kotlin
- Jetpack Compose
- Navigation Compose
- Coroutines + Flow
- Firebase Android SDK

목표:
1. Android 앱 skeleton 생성
2. Home / Activity / Friends / My 탭 구현
3. Match Setup / Matching / Ready Room / Live Run / Results 구현
4. Session Detail 구현
5. iOS와 동일한 domain naming / enum values / privacy rules 유지
6. shared/contracts 기준으로 DTO 매핑 구현

꼭 지켜야 할 UX 원칙:
- Activity는 Records가 아니다
- Friends는 social feed가 아니다
- Live Run은 Pair View + Split Live Maps 구조를 유지한다
- random 모드 exact location 기본 비공개

원하는 결과:
- Android 네이티브에 맞는 구조
- iOS와 기능 parity를 지향하되 플랫폼 관례를 존중
- mock mode와 firebase mode 전환 가능
- 문서와 코드 naming 일치
