# RunLinker Firebase 설정

> 최종 업데이트: 2026-04-26

## 1. Firebase 프로젝트
- Project ID: `runlinker-d8b2e`
- iOS bundle ID: `com.valetudo.run-linker`
- 설정 파일: `run-linker/GoogleService-Info.plist`

## 2. Firestore Database 필수 생성
회원가입 후 `users/{uid}`와 `profiles/{uid}` 저장이 동작하려면 Firebase Console에서 Firestore Database의 `(default)` 데이터베이스가 먼저 생성되어 있어야 한다.

확인 순서:
1. Firebase Console에서 `runlinker-d8b2e` 프로젝트 선택
2. `Firestore Database` 메뉴 진입
3. `(default)` database 생성
4. 초기 개발 중에는 rules 적용 전까지 test mode로 저장 동작을 먼저 확인할 수 있다

## 3. Firestore Rules
로컬 rules 파일:

```text
firestore.rules
```

배포:

```sh
firebase deploy --only firestore:rules
```

현재 rules는 로그인한 사용자가 본인 문서에만 접근하도록 제한한다.

```text
users/{uid}
profiles/{uid}
```

Firebase Console의 `(default)` DB Security 탭이 계속 `allow false`를 보여주면 `cloud.firestore/default` 릴리즈가 초기 ruleset을 가리키는지 확인한다.

```sh
TOKEN=$(gcloud auth print-access-token)
curl -H "Authorization: Bearer $TOKEN" \
  -H "x-goog-user-project: runlinker-d8b2e" \
  "https://firebaserules.googleapis.com/v1/projects/runlinker-d8b2e/releases"
```

`projects/runlinker-d8b2e/releases/cloud.firestore/default`가 최신 ruleset을 가리켜야 한다.

## 4. App Check
시뮬레이터에서는 `AppCheckDebugProviderFactory`를 사용한다.

App Check enforcement가 켜져 있으면 Xcode console에 출력되는 debug token을 Firebase Console의 App Check debug token에 등록해야 Firestore write가 통과한다.

## 5. 앱 저장 흐름
회원가입/로그인 성공 후:

```text
AuthViewModel
→ FirebaseAuthService
→ FirebaseUserRepository
→ Firestore batch write
  - users/{uid}
  - profiles/{uid}
```

Firestore write는 무기한 대기하지 않도록 timeout을 둔다. timeout이 발생하면 Firebase Console에서 `(default)` DB, rules, App Check, 네트워크를 우선 확인한다.

Xcode 콘솔에서는 `[RunLinker]` prefix로 회원가입 버튼 탭, Firebase Auth 생성, Firestore batch write 요청/성공/실패를 확인한다.
