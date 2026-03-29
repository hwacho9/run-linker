# RunLinker 데이터 모델

## 1. 핵심 엔티티 목록
- User
- Profile
- PrivacySettings
- Friendship
- MatchRequest
- RunSession
- SessionParticipant
- LiveLocation
- RouteTracePoint
- Reaction
- SessionSummary
- GoalSummary
- ActivityStats

## 2. User
```ts
type User = {
  id: string;
  authProvider: "email" | "apple" | "google";
  createdAt: string;
  updatedAt: string;
  lastActiveAt: string;
  status: "active" | "suspended";
};
```

## 3. Profile
```ts
type Profile = {
  userId: string;
  nickname: string;
  avatarUrl?: string;
  bio?: string;
  averagePaceSecPerKm?: number;
  preferredRunMode?: "friend" | "random" | "solo";
  cityApprox?: string;
};
```

## 4. PrivacySettings
```ts
type PrivacySettings = {
  userId: string;
  friendExactLocationDefault: boolean;
  randomApproxLocationOnly: boolean;
  blurStartEndPoints: boolean;
  shareRunHistoryWithFriends: boolean;
  showProfileToRandomMatches: boolean;
  updatedAt: string;
};
```

## 5. Friendship
```ts
type Friendship = {
  id: string;
  requesterUserId: string;
  addresseeUserId: string;
  status: "pending" | "accepted" | "declined" | "blocked";
  favorite: boolean;
  createdAt: string;
  updatedAt: string;
};
```

## 6. MatchRequest
```ts
type MatchRequest = {
  id: string;
  requesterUserId: string;
  mode: "friend" | "random" | "solo";
  invitedUserId?: string;
  targetDistanceKm?: number;
  targetDurationMin?: number;
  targetPaceSecPerKm?: number;
  voiceEnabled: boolean;
  cheerEnabled: boolean;
  locationShareLevel: "exact" | "approx" | "hidden";
  status: "open" | "matched" | "cancelled" | "expired";
  createdAt: string;
  expiresAt: string;
};
```

## 7. RunSession
```ts
type RunSession = {
  id: string;
  sourceMatchRequestId?: string;
  mode: "friend" | "random" | "solo";
  status: "waiting" | "countdown" | "live" | "paused" | "completed" | "cancelled";
  targetDistanceKm?: number;
  targetDurationMin?: number;
  startedAt?: string;
  endedAt?: string;
  createdAt: string;
};
```

## 8. SessionParticipant
```ts
type SessionParticipant = {
  sessionId: string;
  userId: string;
  role: "host" | "guest" | "solo";
  readyStatus: "waiting" | "ready" | "not_ready";
  distanceMeters: number;
  durationSec: number;
  currentPaceSecPerKm?: number;
  averagePaceSecPerKm?: number;
  isPaused: boolean;
  finishStatus: "active" | "finished" | "dropped";
  locationVisibility: "exact" | "approx" | "hidden";
};
```

## 9. LiveLocation
```ts
type LiveLocation = {
  sessionId: string;
  userId: string;
  capturedAt: string;
  lat?: number;
  lng?: number;
  approxRegion?: string;
  accuracyMeters?: number;
  sharePrecision: "exact" | "approx" | "hidden";
};
```

## 10. RouteTracePoint
```ts
type RouteTracePoint = {
  sessionId: string;
  userId: string;
  capturedAt: string;
  lat: number;
  lng: number;
  cumulativeDistanceMeters: number;
};
```

## 11. Reaction
```ts
type Reaction = {
  id: string;
  sessionId: string;
  senderUserId: string;
  receiverUserId: string;
  type: "fight" | "nice" | "keep_going" | "together";
  createdAt: string;
};
```

## 12. SyncScore
```ts
type SyncScore = {
  sessionId: string;
  value: number; // 0-100
  paceAlignment: number;
  progressAlignment: number;
  simultaneousRunRatio: number;
  finishAlignment: number;
  summaryText: string;
};
```

## 13. SessionSummary
```ts
type SessionSummary = {
  sessionId: string;
  mode: "friend" | "random" | "solo";
  participants: Array<{
    userId: string;
    distanceMeters: number;
    durationSec: number;
    avgPaceSecPerKm?: number;
  }>;
  totalDurationSec: number;
  createdAt: string;
  syncScore?: SyncScore;
};
```

## 14. GoalSummary
```ts
type GoalSummary = {
  userId: string;
  weeklyDistanceGoalKm?: number;
  monthlyDistanceGoalKm?: number;
  weeklyDistanceProgressKm: number;
  monthlyDistanceProgressKm: number;
  updatedAt: string;
};
```

## 15. ActivityStats
```ts
type ActivityStats = {
  userId: string;
  totalDistanceMeters: number;
  totalDurationSec: number;
  totalSessions: number;
  averagePaceSecPerKm?: number;
  bestPaceSecPerKm?: number;
  averageSyncScore?: number;
  soloSessionCount: number;
  togetherSessionCount: number;
  topPartnerUserId?: string;
  last7DaysDistanceMeters: number;
  last30DaysDistanceMeters: number;
  updatedAt: string;
};
```

## 16. 권장 Firestore 컬렉션
- users
- profiles
- privacy_settings
- friendships
- match_requests
- run_sessions
  - participants
  - reactions
  - route_points
- session_summaries
- goal_summaries
- activity_stats