# RunLinker 기술 스택 및 저장소 구조

> **최종 업데이트**: 2026-04-26 (현행화)

---

## 1. 개발 전략
RunLinker는 **iOS를 SwiftUI로 먼저 개발**하고, 제품 흐름과 비즈니스 로직이 안정화된 다음 **Android를 Kotlin으로 2차 개발**한다.

핵심 원칙:
- 제품/도메인 용어는 문서와 코드에서 일관되게 유지
- 화면 구조와 실시간 계약은 플랫폼 중립적으로 정의
- UI 구현은 각 플랫폼 네이티브에 맞게 따로 개발
- 공유해야 할 것은 UI 코드가 아니라 **도메인 계약 / API 계약 / 데이터 모델 / 프라이버시 규칙**

---

## 2. 기술 스택

### iOS (1차 개발 — 진행 중)
| 항목 | 선택 |
|------|------|
| 언어 | Swift |
| UI 프레임워크 | SwiftUI |
| 프로젝트 관리 | XcodeGen (`project.yml`) |
| 패키지 매니저 | Swift Package Manager |
| 네비게이션 | NavigationStack + TabView |
| 비동기 | async/await |
| 아키텍처 | MVVM (View / ViewModel / Repository) |
| 지도 | MapKit (예정) |
| 위치 | CoreLocation (예정) |
| 백엔드 SDK | Firebase iOS SDK |
| 폰트 | Plus Jakarta Sans, Be Vietnam Pro, Lexend |
| 디자인 시스템 | Stitch "Kinetic Connection" |

### Backend
| 항목 | 선택 |
|------|------|
| 인증 | Firebase Auth (Google, Apple, Email) |
| 데이터베이스 | Firestore |
| 서버 로직 | Cloud Functions |
| 파일 저장 | Cloud Storage |
| 분석 | Firebase Analytics |

### iOS Tooling
- SwiftLint / SwiftFormat
- XCTest
- GitHub Actions (macOS runner)

### Android (2차 개발 — 문서/계약만 준비)
- Kotlin + Jetpack Compose
- Gradle
- Firebase Android SDK

---

## 3. 실제 저장소 구조 (현행)

```text
run-linker/                              ← Git 루트
  runlinker_ai_pack/                     ← AI 컨텍스트 팩 (코드 아님)
    docs/
      00_APP_OVERVIEW.md
      01_INFORMATION_ARCHITECTURE.md
      02_SCREEN_SPECS.md
      03_USER_FLOWS.md
      04_BUSINESS_LOGIC.md
      05_DATA_MODEL.md
      06_API_REALTIME_CONTRACTS.md
      07_PRIVACY_AND_SAFETY.md
      08_MVP_ROADMAP.md
      09_OPEN_QUESTIONS.md
      10_TECH_STACK_AND_REPO_STRUCTURE.md  ← 이 파일
      11_IOS_SWIFTUI_ARCHITECTURE.md       ← 아키텍처 상세
      12_ANDROID_PHASE2_PLAN.md
      runlinker_ai_context.yaml
    prompts/
    stitch_exports/                        ← Stitch HTML 다운로드본

  run-linker/                              ← Xcode 프로젝트
    project.yml                            ← XcodeGen 설정
    run-linker.xcodeproj/
    run-linker/
      App/
        RunLinkerApp.swift
        RootTabView.swift
        Info.plist
      Core/
        Theme/
          Theme.swift                      ← AppTheme (디자인 토큰)
        Components/
          UIComponents.swift               ← 공용 컴포넌트 22개
        Models/
          Models.swift                     ← User, RunSession, MatchRequest
        Repositories/
          SessionRepositoryProtocol.swift
          UserRepositoryProtocol.swift
          MockSessionService.swift
          FirebaseSessionService.swift
          FirebaseUserRepository.swift
      Features/
        Auth/
          AuthViewModel.swift
          LoginView.swift
          SignUpView.swift
          OnboardingView.swift
        Home/
          HomeView.swift
          HomeViewModel.swift
        Activity/
          ActivityView.swift               ← ViewModel 인라인
        Friends/
          FriendsView.swift                ← ViewModel 인라인
        My/
          MyView.swift                     ← ViewModel 인라인
        SessionFlow/
          SessionFlowView.swift            ← WIP
      Assets.xcassets/
      GoogleService-Info.plist

  plugins/                                 ← (기타 플러그인)
```

---

## 4. 공유 레이어 원칙

`runlinker_ai_pack/docs/` 에는 아래를 둔다:
- Firestore 문서 구조 설명
- API request/response 예시
- 실시간 이벤트 payload 예시
- enum/상태명 사전
- 화면과 도메인 용어 매핑

이 레이어는 iOS와 Android가 같은 의미를 쓰기 위한 **문서/스키마 중심 공유 레이어**다.

---

## 5. 개발 원칙
- **Mock first**: Firebase 의존성 없이 MockSessionService로 앱 실행 가능
- **Strong typing**: 모든 도메인 상태는 enum으로 표현
- **Stitch 디자인 시스템 준수**: Theme.swift + UIComponents.swift를 항상 사용
- **No-Line Rule**: Divider 사용 금지 → tonal layering + 여백으로 구분
- **XcodeGen**: `project.yml`로 프로젝트 재생성 가능하게 유지
- Android는 2차 개발 전까지 문서/계약만 준비
