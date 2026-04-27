# RunLinker iOS

RunLinker is a native iOS application built using SwiftUI and a strict Feature-based MVVM architecture. The project does **not** check in an `.xcodeproj` file. Instead, it is generated locally via `XcodeGen` to prevent merge conflicts.

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
│   ├── Repositories/    # Data Access Layer Protocols & Services (Firebase / Mock)
│   └── Theme/           # Global Design System (Colors, Fonts)
└── Features/            # Independent Feature Modules (MVVM)
    ├── Home/            # HomeView & HomeViewModel
    ├── Activity/        # ActivityView & ActivityViewModel
    ├── Friends/         # FriendsView & FriendsViewModel
    ├── My/              # MyView & MyViewModel
    └── RunSession/      # Match setup, live run, results
        ├── Views/
        ├── ViewModels/
        └── Components/
```

### 🧠 MVVM Pattern Rules
1. **Views (`.swift`)**: Only define the UI layout. NO direct Firebase calls. They observe states via `@StateObject` or `@EnvironmentObject`.
2. **ViewModels (`.swift`)**: Define all business logic. They fetch data via protocols (e.g., `SessionRepositoryProtocol`) and publish state changes.
3. **Repositories**: Abstract the data source. Currently, `MockSessionService` drives the UI. When ready, it will be swapped for `FirebaseSessionService`.

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
