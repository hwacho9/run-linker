# RunLinker Firebase 実データ実装ドキュメント

- 作成日: 2026-08-30
- 対象: RunLinker iOS と RunLinker 専用 Firebase プロジェクト
- 対象外: GymLinker アプリ／リポジトリの変更

## 1. 実装結果

RunLinker の画面用モックデータと未実装の保存処理を、実際の Firebase フローへ置き換えた。

- Home: 最近のラン、今週の距離、平均ペース、最近のパートナーを `run_sessions` から取得する。
- Activity: 実レコードと実統計のみを表示し、すべて・一緒・ソロ・最近のフィルターが動作する。
- Friends: 公開プロフィール検索、友だち申請、承認／拒否、お気に入り、オンライン推定、最近のパートナーを Firestore で管理する。
- My: プライバシー・通知・音声設定と週間目標を `user_settings` に保存し、実際のラン統計を表示する。
- Friend/Random Run: `match_requests` を作成し、Cloud Function が互換性のある2件をトランザクションで接続する。
- Live Run: 全モードで Core Location により実際の距離・時間・ペース・ルートを計測する。一緒に走る場合は3秒間隔で進捗を同期する。
- Reaction: 相手への応援を `live_sessions/{id}/reactions` に記録する。
- Results: 完了記録とルートを保存し、失敗時は再試行できる。
- パスワード再設定: Firebase Auth の再設定メールを送信する。

プロダクション画面から `MockSessionRepository` は削除した。データがない場合はサンプル数値ではなく、0・`--`・空状態を表示する。

## 2. Firebase コレクション

| コレクション | 書き込み主体 | 読み取り範囲 | 用途 |
|---|---|---|---|
| `users/{uid}` | 本人のアプリ | 本人 | 認証アカウントの内部情報 |
| `profiles/{uid}` | 本人のアプリ | 本人 | 非公開プロフィール |
| `public_profiles/{uid}` | 本人のアプリ＋集計関数 | ログインユーザー | メール・正確な位置を含まない検索用プロフィール |
| `user_settings/{uid}` | 本人のアプリ | 本人 | プライバシー、通知、音声、週間目標 |
| `friendships/{pairId}` | 申請者／受信者 | 関係当事者 | 申請・承認・拒否・ブロック・お気に入り |
| `match_requests/{id}` | 申請者アプリ＋マッチング関数 | 申請・招待・マッチ当事者 | 友だち／ランダムマッチ要求 |
| `live_sessions/{id}` | マッチング関数 | 参加者 | 共同ランのルームと目標 |
| `live_sessions/{id}/participants/{uid}` | 各参加者 | 参加者 | 実距離・時間・ペース・一時停止状態 |
| `live_sessions/{id}/reactions/{id}` | 参加者 | 参加者 | クイック応援 |
| `run_sessions/{id}` | 記録所有者 | 所有者 | 完了したランの要約 |
| `run_sessions/{id}/route_points/{seq}` | 記録所有者 | 所有者 | GPS ルート |
| `activity_stats/{uid}` | 集計関数 | 本人 | サーバー集計統計 |
| `fitnessActivities/{id}` | 投影関数 | 本人 | 連携アプリ向け最小運動要約 |

`run_sessions` はユーザーごとのコピーとして保存する。2人が同じ `liveSessionId` を使っても、完了ドキュメント ID に各 UID を付けるため上書きしない。

## 3. 主なフロー

### 友だち

1. ログイン時に `FirebaseUserRepository` が非公開プロフィールと最小公開プロフィールを更新する。
2. ユーザー検索は `public_profiles` を利用する。
3. 友だち申請は2つの UID から作った決定的な `pairId` に `pending` として保存する。
4. 受信者が承認すると `accepted` になり、双方の友だち一覧に表示される。
5. 拒否・キャンセル・ブロック済みの同じ組み合わせには自動で再申請しない。現時点のスパム防止方針である。

### 友だちラン

1. 招待者が友だちを選び、`mode=friend` と `invitedUid` を持つ要求を作る。
2. 受信者の Friends 画面にラン招待が表示される。
3. 受信者が承認すると逆方向の要求を作る。
4. `assignRunMatch` が相互招待を確認し、1つの `live_session` を作る。

### ランダムラン

1. アプリが目標距離と目標ペースを含む `finding` 要求を作る。
2. マッチング関数は状態、モード、有効期限、距離差、ペース差を検証する。
3. 現在の許容範囲は、距離差が2kmまたは大きい目標の40%以内、ペース差が120秒/km以内である。
4. トランザクションで2件を `matched` にし、参加者専用 `live_session` を作る。

### 実ランと保存

1. Ready Room の3秒カウントダウン後、`SoloRunTracker` が全モードの実 GPS を計測する。
2. 共同ランでは座標を相手に送信せず、距離・時間・ペースのみ送信する。
3. Sync Score は目標距離に対する2人の進捗差から算出する。
4. 終了時に要約と所有者専用 GPS ルートを保存する。
5. `aggregateRunnerStats` が全体／週間統計を更新し、`projectRunSessionActivity` が連携アプリ用の最小要約を生成する。

## 4. セキュリティとプライバシー

- 公開プロフィールにはメールと正確な位置を保存しない。
- ランダム／友だちのライブ同期では現在、正確な座標を共有しない。
- GPS 生ルートは記録所有者だけが読める。
- マッチ確定と統計集計は Admin SDK の関数だけが書き込める。
- クライアントは自分のマッチ要求のキャンセルと、自分のライブ進捗だけを書き込める。
- 設定ドキュメントは UID 所有者だけが読み書きできる。

## 5. デプロイ手順

RunLinker Firebase プロジェクトを選択した状態で、リポジトリのルートから実行する。

```bash
cd functions
npm ci
npm test
cd ..
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

新規デプロイ関数:

- `assignRunMatch`
- `aggregateRunnerStats`

既存関数:

- `projectRunSessionActivity`
- `createGymLinkerAuthorization`
- `exchangeGymLinkerAuthorization`
- `getRunLinkerActivities`

## 6. 既存ユーザーの移行

- 既存ユーザーはログイン、または My の DEBUG プロフィール同期を一度実行し、`public_profiles` を作成する必要がある。
- 既存 `run_sessions` に `participants` スナップショットがない場合、アプリは本人だけを復元する。新規記録からパートナー名とアバターのスナップショットを保存する。
- 既存記録のサーバー統計が必要な場合は、対象ドキュメントを更新するか、別途バックフィルを行い `aggregateRunnerStats` を起動する。

## 7. 検証結果

- iOS Simulator arm64 Debug ビルド成功。
- 全 Swift ファイルの構文検査成功。
- Cloud Functions の Node 単体テスト12件成功。
- Firestore Emulator が `firestore.rules` をエラーなしで読み込み。
- `firestore.indexes.json` と `Localizable.xcstrings` の JSON 検証成功。

## 8. 現在の制限と次の運用作業

- Push 通知は未接続。友だち申請とラン招待は Friends 画面の更新時に確認する。
- マッチ状態は1.5秒ポーリング、ライブ進捗は3秒ポーリング。利用規模が増えたら Firestore snapshot listener へ変更できる。
- 長時間のバックグラウンド位置収集は、別途権限とバッテリー方針を確認してから有効化する。
- ブロック／通報ドキュメントと画面は設計段階であり、今回の範囲では管理 UI を実装していない。
- 要望どおり GymLinker アプリは変更していない。GymLinker 連携フラグは既定で `false` であり、GymLinker 側の承認実装まではアプリ間記録交換は有効にならない。
