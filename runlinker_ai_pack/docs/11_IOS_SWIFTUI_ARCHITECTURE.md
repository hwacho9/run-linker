# RunLinker iOS SwiftUI 아키텍처

> **최종 업데이트**: 2026-04-26 (Stitch 디자인 시스템 반영 이후 현행화)

---

## 1. 목표
- SwiftUI로 빠르게 MVP를 구현하되, 나중에 Android가 따라오기 쉬운 구조 유지
- 화면 계층은 SwiftUI답게 단순하게 유지
- 비즈니스 로직은 View에 흩어지지 않게 repository/service 계층으로 분리

---

## 2. 실제 파일 구조 (현행)

```text
run-linker/                          ← Xcode 프로젝트 루트
  project.yml                        ← XcodeGen 설정
  run-linker/
    App/
      RunLinkerApp.swift             ← @main 엔트리, Firebase 초기화
      RootTabView.swift              ← 탭 라우팅 + Auth 상태 분기
      Info.plist

    Core/
      Theme/
        Theme.swift                  ← AppTheme (색상·폰트·간격·radius·그라디언트)
      Components/
        UIComponents.swift           ← 공용 SwiftUI 컴포넌트 22개
      Models/
        Models.swift                 ← User, RunSession, MatchRequest, enum
      Services/
        AuthServiceProtocol.swift    ← Firebase Auth 인증 계약
        FirebaseAuthService.swift    ← Email/Google/Apple Firebase Auth 구현체
        SoloRunTracker.swift         ← CoreLocation 위치 추적, 거리/페이스 계산
      Repositories/
        SessionRepositoryProtocol.swift   ← 데이터 계층 인터페이스
        UserRepositoryProtocol.swift      ← 유저/프로필 저장 계약
        MockSessionService.swift          ← 개발용 Mock 구현체
        FirebaseSessionService.swift      ← Firebase 실제 구현체 (WIP)
        FirebaseUserRepository.swift      ← Auth 이후 Firestore 유저 저장 구현체

    Features/
      Auth/
        AuthViewModel.swift          ← Google/Apple/Email 인증 상태 + Repository 호출
        LoginView.swift
        SignUpView.swift
        OnboardingView.swift
      Home/
        HomeView.swift               ← Hero CTA, Quick Actions, 러닝 리포트, Stat Bento
        HomeViewModel.swift          ← 세션 데이터 fetch
      Activity/
        ActivityView.swift           ← 세션 히스토리 + ActivityViewModel 인라인
      Friends/
        FriendsView.swift            ← 검색·필터·Available카드·RecentPartner·InviteBanner
                                       + FriendsViewModel 인라인
      My/
        MyView.swift                 ← 프로필·목표·StatChip 그리드·설정 섹션
                                       + MyViewModel 인라인
      RunSession/
        Views/
          SessionFlowView.swift      ← RunSession 전체 라우팅
          MatchSetupView.swift
          FriendSelectionView.swift  ← 친구와 달리기 대상 선택
          MatchingView.swift
          ReadyRoomView.swift
          LiveRunView.swift
          ResultsView.swift
          SoloRunSetupView.swift
        ViewModels/
          SessionFlowViewModel.swift
        Components/
          RunRouteMapView.swift

    Assets.xcassets/
    Resources/
      Localizable.xcstrings          ← ko/en/ja 문자열 카탈로그
    GoogleService-Info.plist
    run-linker.entitlements
```

---

## 3. 레이어 책임 분리

| 레이어 | 파일 위치 | 책임 |
|--------|-----------|------|
| **View** | `Features/*/View.swift` | UI 렌더링만. Firebase·비즈니스 로직 금지 |
| **ViewModel** | `Features/*/ViewModel.swift` | 화면 상태 보유, service/repository 조합, async 작업 |
| **Service Protocol** | `Core/Services/*Protocol.swift` | 외부 SDK·유스케이스 계약 정의 |
| **Firebase Service** | `Core/Services/Firebase*.swift` | Firebase Auth, OAuth credential 같은 SDK 작업 구현 |
| **Device Service** | `Core/Services/SoloRunTracker.swift` | CoreLocation 위치 추적, 거리/페이스 계산 |
| **Repository Protocol** | `Core/Repositories/*Protocol.swift` | 플랫폼 중립 인터페이스 정의 |
| **Mock** | `Core/Repositories/Mock*.swift` | 개발·테스트용 구현체 |
| **Firebase Repository** | `Core/Repositories/Firebase*.swift` | Firestore/RTDB 컬렉션·문서 저장 구현 |
| **Models** | `Core/Models/Models.swift` | 순수 Swift 도메인 타입 |
| **Theme** | `Core/Theme/Theme.swift` | Stitch 디자인 토큰 (색상·폰트·간격) |
| **Components** | `Core/Components/UIComponents.swift`, `Features/*/Components/*.swift` | 공용 또는 feature 전용 재사용 SwiftUI 뷰 |
| **Resources** | `Resources/Localizable.xcstrings` | ko/en/ja 다국어 문자열 |

---

## 4. 상태 관리 원칙

| 상황 | 방법 |
|------|------|
| 화면 로컬 상태 | `@State` |
| 하위 뷰 전달 | `@Binding` |
| 화면 단위 로직 | `@MainActor class ViewModel: ObservableObject` |
| Auth 전역 상태 | `AuthViewModel` → `@EnvironmentObject` |
| Repository 주입 | init parameter injection (`protocol? = nil` 패턴으로 @MainActor 호환) |

> **concurrency 패턴**: `@MainActor` 클래스의 `init`에서 `init(repo: Protocol? = nil) { self.repo = repo ?? MockService() }` 형태 사용 (Swift 6 strict concurrency 대응)

---

## 5. 네비게이션 구조

```
RunLinkerApp
└── RootTabView
    ├── [Auth 미완료] → OnboardingView → LoginView / SignUpView
    └── [Auth 완료]  → TabView
        ├── Tab 0: HomeView (홈)
        ├── Tab 1: ActivityView (기록)
        ├── Tab 2: FriendsView (친구)
        └── Tab 3: MyView (마이)
            
세션 플로우 (탭 외 Modal/FullScreen):
HomeView → SessionFlowView
  친구와 달리기: MatchSetupView → FriendSelectionView → ReadyRoomView → LiveRunView → ResultsView
  랜덤 매칭: MatchSetupView → MatchingView → ReadyRoomView → LiveRunView → ResultsView
  혼자 달리기: SoloRunSetupView → ReadyRoomView(카운트다운 버퍼) → LiveRunView → ResultsView
```

---

## 6. 디자인 시스템 (Stitch "Kinetic Connection")

`Core/Theme/Theme.swift` + `Core/Components/UIComponents.swift`에 전체 구현됨.

### 핵심 색상 토큰
| 토큰 | 값 | 용도 |
|------|----|------|
| `primary` | `#0051DF` | 브랜드 블루, CTA |
| `primaryContainer` | `#2F6BFF` | 버튼 그라디언트 end |
| `secondaryContainer` | `#AEF51D` | Accent Lime, Lime 버튼 |
| `secondaryFixed` | `#B1F722` | Stat 배경, 온라인 닷 |
| `surfaceContainerLow` | `#EEF4FB` | 카드 배경 (기본) |
| `inverseSurface` | `#2B3136` | InviteBanner 어두운 배경 |

### 폰트 규칙
| Role | Font | 용도 |
|------|------|------|
| headline | Plus Jakarta Sans | 제목, 섹션 헤더 |
| body | Be Vietnam Pro | 본문, 설명 |
| label/metric | Lexend | 숫자, 데이터 포인트 |

### No-Line Rule
- **구분선(Divider) 사용 금지**
- 섹션 구분: 배경색 차이(`surfaceContainerLow` 그룹) + 여백으로만

### 코너 반경
| 이름 | 값 | 용도 |
|------|-----|------|
| `Radius.lg` | 24pt | Quick Action 버튼 |
| `Radius.xl` | 32pt | 카드 (AppCard 기본) |
| `Radius.full` | 9999pt | 알약형 버튼, Chip |

### 공용 컴포넌트 목록 (UIComponents.swift)
```
TopAppBar / IconButton
HeroCTACard          ← kinetic-gradient Hero 배너
QuickActionButton    ← 홈 화면 2열+1열 액션 버튼
PrimaryButton        ← Capsule, gradient
SecondaryButton      ← Lime Capsule
AppCard              ← surface-container-low 카드
GlassCard            ← .ultraThinMaterial 블러 카드
StatChip             ← icon + 제목 + 값, 128px, neutral/accent variant
SectionHeader        ← 섹션 제목 + trailing 버튼
SettingsRow          ← 설정 항목 (chevron)
SettingsToggleRow    ← 설정 토글 항목
ThemedTextField      ← surface-container 배경 텍스트 입력
FitnessChip          ← 알약형 상태 레이블
FilterChip           ← 선택형 필터 칩 (active/inactive)
PartnerAvatar        ← 원형 아바타 + 이름, active border
ProgressRing         ← gradient stroke 원형 진행률
SyncBar              ← Sync Score 수평 진행바
GoogleSignInButton / AppleSignInButton
DividerWithText
PairViewPlaceholder
```

---

## 7. 현재 구현 완성도

| Feature | View | ViewModel | Notes |
|---------|------|-----------|-------|
| Auth (Login/SignUp/Onboarding) | ✅ | ✅ | GoogleSignIn SPM 연결 필요 |
| Home | ✅ Stitch 완성 | ✅ | Mock 데이터 연결됨 |
| Activity (기록) | ✅ 기본 | ✅ 인라인 | 차트 플레이스홀더 |
| Friends (친구) | ✅ Stitch 완성 | ✅ 인라인 | 실제 친구 데이터 연결 필요 |
| My (마이) | ✅ Stitch 완성 | ✅ 인라인 | 실제 유저 데이터 연결 필요 |
| RunSession | ✅ 기본 플로우 구현 | ✅ 분리 | 친구 선택, 랜덤 매칭, 솔로 카운트다운 버퍼, 라이브 지도/결과 |
| Firebase Repository | ⚠️ Stub | - | MockSessionService로 대체 중 |

---

## 8. AI 코드 생성 시 금지사항
- View 안에 Firebase 로직 직접 작성 금지
- Firestore document key를 View에서 직접 다루지 말 것
- ViewModel에서 Firestore 컬렉션/문서 구조를 직접 만들지 말 것. Repository로 분리할 것
- ViewModel에서 Firebase Auth SDK 호출을 직접 작성하지 말 것. AuthService로 분리할 것
- Firestore write completion을 무기한 기다리지 말 것. 사용자 플로우에는 명시적 timeout/error 상태를 둘 것
- 사용자 노출 문자열은 `Localizable.xcstrings` 키를 먼저 추가하고 사용한다
- 큰 singleton 남발 금지
- `AppTheme.*`을 public init의 default argument 값으로 사용 금지 (internal 타입이므로 컴파일 에러 발생)
- `@MainActor` 클래스 init에서 `@MainActor` 타입 직접 인스턴스화 금지 (optional + nil coalescing 패턴 사용)
- Divider 사용 금지 (No-Line Rule)
- 1px border 카드 사용 금지 (tonal layering으로 대체)

---

## 9. 구현 전 필수 확인 순서
새 기능을 구현하거나 기존 기능을 수정하기 전에는 아래 문서를 먼저 확인한다.

1. `00_APP_OVERVIEW.md`: 제품 목표와 핵심 탭/플로우 확인
2. `01_INFORMATION_ARCHITECTURE.md`: 화면 위치와 정보 구조 확인
3. `02_SCREEN_SPECS.md`: 화면별 필요한 데이터와 UI 요구사항 확인
4. `03_USER_FLOWS.md`: 사용자가 실제로 이동하는 경로 확인
5. `04_BUSINESS_LOGIC.md`: 상태 전이와 예외 처리 확인
6. `05_DATA_MODEL.md`: Firestore 컬렉션, 필드, enum 값 확인
7. `06_API_REALTIME_CONTRACTS.md`: 실시간/서버 계약 확인
8. `07_PRIVACY_AND_SAFETY.md`: 위치/개인정보 노출 규칙 확인
9. `10_TECH_STACK_AND_REPO_STRUCTURE.md`: 저장소 위치와 기술 선택 확인
10. `11_IOS_SWIFTUI_ARCHITECTURE.md`: View/ViewModel/Repository 분리 기준 확인

구현 기준:
- 화면은 `Features/*/Views/*View.swift`에 둔다.
- 화면 상태와 사용자 액션 처리는 `Features/*/ViewModels/*ViewModel.swift`에 둔다.
- feature 전용 재사용 UI는 `Features/*/Components/*.swift`에 둔다.
- Firebase Auth, Google/Apple credential, App Check 같은 인증 SDK 세부 구현은 `Core/Services/Firebase*.swift`에 둔다.
- Firestore, Storage, Cloud Functions 같은 데이터 저장/조회 구현은 `Core/Repositories/Firebase*.swift`에 둔다.
- ViewModel은 Service/Repository protocol에 의존하고, Firestore 컬렉션명/문서 키/필드명은 알지 않는다.
- 데이터 모델이나 enum 값이 문서와 다르면 코드보다 문서를 먼저 갱신하고, 그 다음 구현한다.
