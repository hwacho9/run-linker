# RunLinker iOS

RunLinker is a native iOS application built using SwiftUI and a strict Feature-based MVVM architecture. The project does **not** check in an `.xcodeproj` file. Instead, it is generated locally via `XcodeGen` to prevent merge conflicts.

Firebase production-data implementation and operations are documented in Korean and Japanese:

- `../docs/RUNLINKER_FIREBASE_IMPLEMENTATION_KO.md`
- `../docs/RUNLINKER_FIREBASE_IMPLEMENTATION_JA.md`

## 📁 Architecture & Folder Structure

We follow a strict separation of concerns to ensure scalability and testability (especially for Phase 2 Android Jetpack Compose parity).

```text
run-linker/
├── project.yml          # XcodeGen config (Replaces .xcodeproj)
├── App/                 # App Lifecycle & Global Routing
│   ├── RunLinkerApp.swift
│   └── RootTabView.swift
├── Core/                # Shared Business Logic & UI Foundations
│   ├── Components/      # Reusable SwiftUI Atoms (Buttons, Cards, Chips)
│   ├── Models/          # Pure Data Structs (User, Session, MatchRequest)
│   ├── Services/        # SDK / device services (Auth, location tracking)
│   ├── Repositories/    # Data access protocols & Firebase implementations
│   └── Theme/           # Global Design System (Colors, Fonts)
└── Features/            # Independent Feature Modules (MVVM)
    ├── Auth/
    ├── Home/
    ├── Activity/
    ├── Friends/
    ├── My/
    └── RunSession/      # Friend/random/solo running session flow
        ├── Views/       # SwiftUI screens
        ├── ViewModels/  # Presentation state and actions
        └── Components/  # Feature-scoped reusable views
```

Each feature follows the same internal layout. `Views/` and `ViewModels/` are always
separated; add `Components/` when a feature has reusable UI pieces.

```text
Features/RunSession/
        ├── Views/
        │   ├── MatchSetupView.swift
        │   ├── FriendSelectionView.swift
        │   ├── MatchingView.swift
        │   ├── ReadyRoomView.swift
        │   ├── LiveRunView.swift
        │   ├── ResultsView.swift
        │   └── SoloRunSetupView.swift
        ├── ViewModels/SessionFlowViewModel.swift
        └── Components/RunRouteMapView.swift
```

### 🧠 MVVM Pattern Rules
1. **Views (`.swift`)**: Only define the UI layout. NO direct Firebase calls. They observe states via `@StateObject` or `@EnvironmentObject`.
2. **ViewModels (`.swift`)**: Define all business logic. They fetch data via protocols (e.g., `SessionRepositoryProtocol`) and publish state changes.
3. **Services**: Own SDK/device behavior such as Firebase Auth and CoreLocation tracking.
4. **Repositories**: Abstract Firebase access. Production screens use `FirebaseSessionRepository`, `FirebaseSocialRepository`, and `FirebaseUserSettingsRepository`; no mock repository drives the app UI.

## 🚀 Getting Started

1. **Install XcodeGen**  
   Ensure you have XcodeGen installed:
   ```bash
   brew install xcodegen
   ```

2. **Generate the Xcode Project**  
   At the root of the `./run-linker` directory, run:
   ```bash
   xcodegen generate
   ```

3. **Open & Run**  
   Open `RunLinker.xcodeproj` and build the project (`Cmd + R`). The Firebase SPM dependencies will resolve automatically on the first build.
