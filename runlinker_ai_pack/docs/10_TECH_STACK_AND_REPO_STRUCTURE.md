# RunLinker 기술 스택 및 저장소 구조

## 1. 추천 기술 스택
### Mobile
- Expo
- React Native
- TypeScript
- Expo Router

### State / Data
- Zustand
- TanStack Query

### Backend
- Firebase Auth
- Firestore
- Cloud Functions
- Cloud Storage
- Firebase Analytics

### Tooling
- pnpm
- ESLint
- Prettier
- Husky
- lint-staged
- Vitest / Jest + React Native Testing Library
- GitHub Actions

## 2. 추천 저장소 구조
```text
runlinker/
  apps/
    mobile/
  services/
    functions/
  packages/
    ui/
    domain/
    config/
  docs/
  .github/
```

## 3. Mobile 내부 권장 구조
```text
apps/mobile/
  app/
    (tabs)/
      home.tsx
      activity.tsx
      friends.tsx
      my.tsx
    onboarding/
    match/
    session/
  src/
    components/
    features/
    services/
    stores/
    hooks/
    theme/
    mocks/
    lib/
```

## 4. 초기 개발 원칙
- mock data first
- strong typing first
- feature folder 과도하게 쪼개지 않기
- design token을 먼저 고정
- Firestore 구조는 단순하고 추적 가능하게 유지