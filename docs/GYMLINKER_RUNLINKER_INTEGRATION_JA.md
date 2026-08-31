# GymLinker × RunLinker Firebase分離連携ガイド — RunLinker側

RunLinker 内部の実データ実装とデプロイ手順は [RUNLINKER_FIREBASE_IMPLEMENTATION_JA.md](./RUNLINKER_FIREBASE_IMPLEMENTATION_JA.md)も参照する。

最終更新: 2026-08-30

> 現在の状態: 本ドキュメントと実装はRunLinkerリポジトリ内にのみ存在する。GymLinkerリポジトリのアプリ、Functions、画面は変更せず、別途承認されるまで連携機能を有効化しない。RunLinkerの`GymLinkerIntegrationEnabled`の初期値は`false`である。

## 1. 方針

GymLinkerとRunLinkerは、それぞれ独立したFirebaseプロジェクトを維持する。

| 区分 | GymLinker | RunLinker |
|---|---|---|
| Firebase Project ID | `gymroutine-b7b6c` | `runlinker-d8b2e` |
| Bundle ID | `com.siproject.gymroutine-mobile` | `com.valetudo.run-linker` |
| Authentication | GymLinker会員の基準 | 独立Auth + GymLinker SSO |
| Firestore | 筋力トレーニングの原本 | ランニング・ルートの原本 |
| Analytics | GymLinker専用GA4 | RunLinker専用GA4 |

プロジェクト間でFirestoreを直接参照しない。アカウント連携と運動サマリーの取得はHTTPS API経由に限定する。

## 2. 全体構成

```text
GymLinker iOS（将来実装）                RunLinker iOS
    │                                      │
    │ GymLinker Firebase ID Token          │ ワンタイムcode + state + PKCE verifier
    ▼                                      ▼
createGymLinkerAuthorization ─Deep Link─> exchangeGymLinkerAuthorization
      (RunLinker Functions)                  (RunLinker Functions)
                                                │
                                                ▼
                                      RunLinker Custom Token

GymLinker Firestore                    RunLinker Firestore
Result/{uid}/{month}/{id}              run_sessions/{sessionId}
        │                                      │
        ▼ 最小サマリーAPI                       ▼ サーバー投影
getGymLinkerActivities                 fitnessActivities/{activityId}
                                               │
                                               ▼ 最小サマリーAPI
                                      getRunLinkerActivities
```

## 3. 目標とするアカウント連携フロー

1. RunLinkerのログイン画面で「GymLinkerで続ける」を選択する。
2. RunLinkerが256ビットのランダムな`state`とPKCE `code_verifier`を生成し、端末内に一時保存する。
3. SHA-256で作成した`code_challenge`とともに`gymlinker://runlinker-auth/authorize?...`を開く。
4. GymLinkerは現在ユーザーのFirebase ID TokenをHTTPS AuthorizationヘッダーでRunLinker Functionsへ送信する。
5. サーバーが署名、発行者、対象プロジェクトを検証し、`code_challenge`に紐付く5分間有効なワンタイムコードを保存する。
6. GymLinkerはトークンではなくコードだけを`runlinker://gymlinker-auth/callback`へ返す。
7. RunLinkerが保存済みの`state`を検証し、サーバーが`code_verifier`をS256方式で定数時間比較してからコードを一度だけ消費する。
8. RunLinker FunctionsがGymLinker UIDと同一UIDのRunLinker Custom Tokenを発行する。
9. 連携状態をサーバー専用の`accountLinks/{uid}`へ保存する。

Firebase ID Token、Custom Token、PKCE `code_verifier`をURL query、ログ、Firestoreドキュメントへ保存してはならない。PKCEにより、カスタムURLスキームのコールバックが横取りされても、別アプリからワンタイムコードを交換できない。

現在はRunLinker側の処理のみ準備済みである。上記4と6を実行するGymLinker側のDeep Link処理は実装していない。

## 4. 実装状況

すべて`asia-northeast1`リージョンへデプロイする。

### RunLinkerプロジェクト

| Function | 認証 | 目的 |
|---|---|---|
| `createGymLinkerAuthorization` | GymLinker Bearer ID Token | ワンタイム連携コードの発行 |
| `exchangeGymLinkerAuthorization` | ワンタイムcode + state | RunLinker Custom Tokenへの交換 |
| `getRunLinkerActivities` | GymLinker Bearer ID Token | 本人のランニングサマリー取得 |
| `projectRunSessionActivity` | Firestore第2世代Trigger | ランニング原本を共有サマリーへ投影 |

### GymLinkerプロジェクト — 未実装

| Function | 認証 | 目的 |
|---|---|---|
| `getGymLinkerActivities` | 連携済みRunLinker Bearer ID Token | 将来、本人の筋トレサマリーを取得 |

上記FunctionおよびGymLinkerの画面・Deep LinkコードはGymLinkerリポジトリへ追加していない。将来実装する際は、RunLinker ID Tokenの`gymLinkerLinked`と`identitySource` claimを検証する。

## 5. 共有データの範囲

### RunLinker → GymLinker

共有する項目:

- 開始・終了時刻
- ランニング時間
- 距離
- 平均ペース
- ランニングモード
- Sync Score

共有しない項目:

- GPS座標および全ルート
- 正確な開始・終了地点
- 友達プロフィールの詳細
- 端末・位置情報の診断データ

### GymLinker → RunLinker

共有する項目:

- 実施日時
- ワークアウト名
- 運動時間
- 種目数
- セット数
- 総ボリューム
- 主な対象部位

共有しない項目:

- メモ
- 写真および写真ID
- セットごとの重量・回数の詳細
- 体重、生年月日、性別
- 友達・ソーシャル情報

## 6. Firestore構造と権限

RunLinkerプロジェクト:

```text
users/{uid}
profiles/{uid}
run_sessions/{sessionId}
  route_points/{sequence}
fitnessActivities/runlinker_{sessionId}
accountLinks/{uid}
accountLinkAuthorizations/{sha256(code)}
accountLinkRateLimits/{uid}
```

- `run_sessions`: 所有者のみ読み書き可能
- `route_points`: 親セッションの所有者のみ読み書き可能
- `fitnessActivities`: 所有者は読み取り可能、クライアント書き込みは禁止
- `accountLinks`、認証コード、rate limit: Admin SDKのみ書き込み可能

Firebase Consoleで`accountLinkAuthorizations.expiresAt`にFirestore TTLポリシーを設定する。TTLがなくても期限切れコードは交換できないが、自動削除のため設定を推奨する。

## 7. デプロイ手順

### RunLinker

```sh
cd /Users/chosunghwa/Desktop/workspace/run-linker
npm --prefix functions install
npm --prefix functions test
firebase deploy \
  --project runlinker-d8b2e \
  --only functions,firestore:rules,firestore:indexes
```

ローカルテストにはNode.js 22.12以上を使用し、デプロイ前にFunctionsランタイムとローカルNodeのバージョンを合わせる。

Custom Token署名権限のエラーが発生した場合は、Functionsランタイムのサービスアカウントへ`iam.serviceAccounts.signBlob`権限を付与する。サービスアカウントキーJSONをアプリやリポジトリへ追加しない。

### GymLinker

現在デプロイ対象はない。GymLinkerリポジトリには本連携用のコードや設定を追加しない。

### iOS設定確認

- RunLinkerは`runlinker-d8b2e`用`GoogleService-Info.plist`を継続利用する。
- GymLinkerは`gymroutine-b7b6c`用`GoogleService-Info.plist`を継続利用する。
- GymLinker URL scheme: `gymlinker`
- RunLinker callback URL scheme: `runlinker`
- GA4、Crashlytics、Remote Config、App Checkはプロジェクトごとに独立設定する。

## 8. 既存ユーザーの移行

GymLinker SSOで新規ログインしたユーザーは、GymLinker UIDと同一のRunLinker UIDを使用する。

既存RunLinkerアカウントがある場合、メールアドレスだけで自動統合しない。

1. 既存RunLinkerアカウントとGymLinkerアカウントをそれぞれ再認証する。
2. サーバーで両方のトークンを検証する。
3. 既存ランニングデータの`ownerUid`をGymLinker基準UIDへバックフィルする。
4. 重複データとソーシャル関係を確認する。
5. 監査ログを保存してから旧RunLinker Authアカウントを無効化する。

Appleの非公開メールリレーおよび未確認メールを、自動的な同一人物判定に使用しない。

## 9. 運用チェックリスト

- [ ] 両FirebaseプロジェクトにBlazeプランと予算アラートを設定
- [ ] 両方のID Tokenについて`aud`と`iss`を対象プロジェクトと照合
- [ ] 認証コードの5分失効と一回利用をテスト
- [ ] `state`不一致、再利用、期限切れ、およびPKCE verifier不一致をテスト
- [ ] Firestore Rules Emulatorテストを追加
- [ ] 認証・活動APIのrate limitを監視
- [ ] GPS、写真、メモがAPIレスポンスに含まれないことを回帰テスト
- [ ] 連携解除・共有停止APIを実装するまで一般公開しない
- [ ] プライバシーポリシーにアプリ間共有の目的と保存期間を明記
- [ ] 一般公開前にカスタムURLスキームからUniversal Linkベースのコールバックへの移行を検討

## 10. 現在の実装範囲

RunLinkerリポジトリには、次の基盤のみを準備している。

- RunLinkerのランニング原本保存と共有用最小サマリーへの投影
- GymLinkerトークン検証、ワンタイムコード、PKCEベースの認証ブリッジサーバー
- GymLinkerから呼び出すRunLinkerランニングサマリーAPI
- 将来GymLinker筋トレサマリーを受け取るRunLinkerクライアント・画面基盤
- `GymLinkerIntegrationEnabled=false`によりログインボタンと外部データ要求を無効化

GymLinkerリポジトリには関連コード、Functions、画面は存在しない。そのため、現在の状態では実際のアカウント連携と双方向記録参照は動作しない。

運用公開前に次を追加する。

- 連携解除および共有停止のUI/API
- 既存RunLinkerアカウントの統合ツール
- Emulatorベースの統合テスト
- GymLinkerがログアウト状態のとき、ログイン後に連携要求を再開するUX
- 別途承認後、GymLinker側のDeep Link、最小サマリーAPI、記録画面を実装
