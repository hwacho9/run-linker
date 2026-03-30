# AI 프롬프트 02 — iOS SwiftUI UI/네비게이션 구현

아래 문서 기준으로 RunLinker iOS 앱의 SwiftUI skeleton을 구현해줘.

참조 문서:
- docs/01_INFORMATION_ARCHITECTURE.md
- docs/02_SCREEN_SPECS.md
- docs/03_USER_FLOWS.md
- docs/04_BUSINESS_LOGIC.md
- docs/07_PRIVACY_AND_SAFETY.md
- docs/11_IOS_SWIFTUI_ARCHITECTURE.md

구현 대상 화면:
- Onboarding 1
- Onboarding 2
- Onboarding 3
- Home
- Activity
  - Session History
  - My Stats
- Session Detail
- Friends
- My
- Match Setup
- Matching
- Ready Room
- Live Run
- Results

구현 규칙:
- SwiftUI 네이티브 느낌으로 유지
- Home은 실행 우선
- Activity는 데이터 허브
- Friends는 친구 선택/초대 중심
- My는 설정/목표/프라이버시 중심
- Live Run은 Pair View + Split Live Maps 구조를 따른다
- random 모드에서는 exact location 기본 비노출
- solo 모드에서는 partner UI를 적절히 비활성화한다
- TabView + NavigationStack을 사용한다
- Firebase 직접 호출은 View가 아니라 repository/service 계층을 통해 처리한다

필요 컴포넌트:
- ScreenContainer
- AppHeader
- AppCard
- SectionTitle
- PrimaryButton / SecondaryButton / GhostButton
- StatChip
- StatusBadge
- SyncScoreBadge
- PairViewPlaceholder
- MapPlaceholder
- EmptyState
- FriendListItem
- SessionHistoryItemCard

원하는 결과:
- 네비게이션이 실제로 동작하는 SwiftUI 앱 skeleton
- mock data 연결
- 상태는 최소한으로 유지하되 구조가 확장 가능할 것
- 실제 API 없이도 전체 흐름 데모 가능할 것
