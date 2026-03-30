# RunLinker 기술 스택 및 저장소 구조

## 1. 개발 전략
RunLinker는 **iOS를 SwiftUI로 먼저 개발**하고, 제품 흐름과 비즈니스 로직이 안정화된 다음 **Android를 Kotlin으로 2차 개발**한다.

핵심 원칙:
- 제품/도메인 용어는 문서와 코드에서 일관되게 유지
- 화면 구조와 실시간 계약은 플랫폼 중립적으로 정의
- UI 구현은 각 플랫폼 네이티브에 맞게 따로 개발
- 공유해야 할 것은 UI 코드가 아니라 **도메인 계약 / API 계약 / 데이터 모델 / 프라이버시 규칙**

## 2. 추천 기술 스택
### iOS (1차 개발)
- Swift
- SwiftUI
- XcodeGen (프로젝트 생성 자동화 권장)
- Swift Package Manager
- NavigationStack + TabView
- async/await
- MVVM-like architecture
- MapKit
- CoreLocation
- Firebase iOS SDK

### Backend
- Firebase Auth
- Firestore
- Cloud Functions
- Cloud Storage
- Firebase Analytics

### iOS Tooling
- SwiftLint
- SwiftFormat
- XCTest
- GitHub Actions (macOS runner)

### Android (2차 개발)
- Kotlin
- 권장: Jetpack Compose
- Gradle
- Firebase Android SDK

## 3. 추천 저장소 구조
```text
runlinker/
  apps/
    ios/
      project.yml
      RunLinker/
        App/
        Features/
        Core/
        Mocks/
        Resources/
      RunLinkerTests/
      RunLinkerUITests/
    android/
      README_PHASE2.md
  services/
    functions/
  shared/
    contracts/
  docs/
  .github/
```

## 4. iOS 내부 권장 구조
```text
apps/ios/RunLinker/
  App/
    RunLinkerApp.swift
    AppRouter.swift
    RootTabView.swift
  Features/
    Onboarding/
    Home/
    Activity/
    Friends/
    My/
    Match/
    Session/
  Core/
    DesignSystem/
    Models/
    DTOs/
    Repositories/
    Services/
    Firebase/
    Mapping/
    Utilities/
  Mocks/
  Resources/
```

## 5. 공유 레이어 원칙
`shared/contracts/`에는 아래를 둔다.
- Firestore 문서 구조 설명
- API request/response JSON 예시
- 실시간 이벤트 payload 예시
- enum/상태명 사전
- 화면과 도메인 용어 매핑

이 레이어는 iOS와 Android가 같은 의미를 쓰기 위한 **문서/스키마 중심 공유 레이어**다.

## 6. 초기 개발 원칙
- mock data first
- strong typing first
- 화면보다 도메인 명칭부터 고정
- Xcode project는 XcodeGen으로 생성해 AI가 다루기 쉽게 유지
- Firebase 의존성 없이도 mock mode로 앱이 실행되게 만들기
- Android는 2차 개발 전까지 문서/계약/리소스만 준비
