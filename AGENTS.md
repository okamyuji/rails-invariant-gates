# AIエージェントへの指示

このリポジトリでは、人間が設計で決めた契約を、AIが実装とテストで守る。

## 契約の表（正本）

どのspecも、名前（`describe`、`context`、`it` のどれか）に、この表のIDを1つ以上入れる。specが落ちたときに実装とspecのどちらが正しいかは、この表で判定する。

### 在庫引当

| ID | 分類 | 契約 | 検証するspec |
|---|---|---|---|
| INV-01 | 不変条件 | 在庫数は負にならない | `InventoryPosition` の `.new`、`Product` のバリデーションとCHECK制約 |
| INV-02 | 不変条件 | 総在庫は引当可能在庫と引当済み在庫の合計と一致する | 同上 |
| INV-03 | 不変条件 | 在庫数は整数である | `InventoryPosition` の `.new`、`Product` のバリデーション |
| PRE-01 | 事前条件 | 引当数量は正の整数である | `InventoryPosition#reserve` |
| PRE-02 | 事前条件 | 引当数量は引当可能在庫以下である | `InventoryPosition#reserve` |
| POST-01 | 事後条件 | 引当可能在庫が指定数量だけ減る | `InventoryPosition#reserve` |
| POST-02 | 事後条件 | 引当済み在庫が指定数量だけ増える | `InventoryPosition#reserve` |
| POST-03 | 事後条件 | 元の値オブジェクトは変わらない | `InventoryPosition#reserve` |
| ERR-01 | 失敗時の契約 | 拒否した操作ではDBの状態が変わらない | `InventoryReservationService` |
| POST-04 | 事後条件 | 引当結果は、ロックを取って読み直した値をもとに計算し、DBに保存する | `InventoryReservationService` |
| ERR-02 | 失敗時の契約 | 保存に失敗したら、握りつぶさずに例外を伝える | `InventoryReservationService` |
| MAP-01 | 変換 | 商品の3つの在庫数から、同じ値の値オブジェクトを作る | `Product#inventory_position` |
| CON-01 | 同時実行の契約 | 在庫1個への同時引当は1件だけ成功する | `spec/integration/inventory_concurrency_spec.rb` |

### 成人判定

| ID | 契約 | 検証するspec |
|---|---|---|
| ADULT-01 | 18歳以上なら成人と判定する | `User#adult?` |
| ADULT-02 | 18歳未満なら成人ではないと判定する | `User#adult?` |

### 送料

| ID | 契約 | 検証するspec |
|---|---|---|
| SHIP-01 | 注文金額が5,000円以上なら送料は0円 | `ShippingCalculator#calculate` |
| SHIP-02 | 注文金額が1円以上5,000円未満なら送料は500円 | `ShippingCalculator#calculate` |
| SHIP-03 | 注文金額が0円以下なら `ArgumentError`（`"Invalid amount"`）を出す | `ShippingCalculator#calculate` |

### 注文のキャンセル

| ID | 契約 | 検証するspec |
|---|---|---|
| ORD-01 | 未払いと支払い済みの注文はキャンセルできる | `Order#cancellable?` |
| ORD-02 | 発送済みとキャンセル済みの注文はキャンセルできない | `Order#cancellable?` |
| CXL-01 | キャンセルできる注文は状態をcancelledにして保存し、trueを返す | `OrderCancellationService` |
| CXL-02 | キャンセルできない注文はfalseを返し、状態を変えない | `OrderCancellationService` |
| CXL-03 | 保存に失敗したら、握りつぶさずに例外を伝える | `OrderCancellationService` |

### 決済

| ID | 契約 | 検証するspec |
|---|---|---|
| PAY-01 | 指定した金額で決済ゲートウェイを呼び、trueを返す | `PaymentService#charge` |
| PAY-02 | 決済ゲートウェイの代役は、状態 `"succeeded"` と金額を返す | `PaymentGateway.charge` |

### CRAP値の計算

| ID | 契約 | 検証するspec |
|---|---|---|
| CRAP-01 | CRAP値は comp² × (1 − cov)³ + comp で計算する | `CrapMetrics.crap` |
| CRAP-02 | 循環的複雑度は分岐の数に1を足した値で、入れ子のdefは外側のメソッドに数えない | `CrapMetrics#rows` |
| CRAP-03 | カバレッジは、メソッド本体の実行対象の行のうち実行された行の割合で、複数の計測結果は行ごとに足し合わせる | `CrapMetrics#rows` |
| CRAP-04 | メソッドは、クラスやモジュールを含む名前と、ファイル・開始行・終了行で区別する | `CrapMetrics#rows` |
| CRAP-05 | 結果はCRAP値の大きい順に並べ、閾値以上のメソッドを返す | `CrapMetrics.report`、`CrapMetrics#rows` |
| CRAP-06 | 計測結果のファイルがなければ、場所と対処を示して止める | `CrapMetrics#rows` |
| CRAP-07 | flogのスコアを比較のために並べ、flogが数えないメソッドは0にする | `CrapMetrics#rows` |

契約を変えるときは、この表を先に直し、人間の承認を得てからspecと実装を変える。
表の行は、業務分析で決めた業務の決まりから作り、人間がレビューする。AIが行の下書きを作るときは、行ごとに根拠にした業務の資料を示す。今あるspecや実装から逆算した行は、そのことを明記し、人間が業務の決まりと照らすまで表に入れない。

## 完了条件

- `bin/rails quality` が成功するまで完了にしない。
- `pre-commit run --all-files` が成功するまで完了にしない。`--no-verify` でフックを飛ばさない。
- 実装より先にspecを書き、失敗することを確かめる。
- evilutionで生き残った変異は、次のどれかで解消する。
  - 契約を確かめるspecを足す。
  - 振る舞いを変えずに消せる実装を消す。
  - 振る舞いが変わらない等価ミュータントだけは、該当行の末尾に `# evilution:disable` を付け、直前の行に理由を書く。
- `--min-score` を下げない。`.evilution.yml` に除外を足さない。CRAP値の閾値を上げない。
- CRAP値が15以上になったら、分岐を減らすかテストを足す。
- アプリのコードで `update_columns` や `update_all` を使って不変条件の検証を飛ばさない。
- モデルとサービスのspecは `compose.yaml` のMySQLに対して実行し、ActiveRecordのメソッドをstubしない。テスト用のRepositoryやインメモリの代役も作らない。
- 例外は2つだけにする。実DBのどの状態からも起こせない保存の失敗を作るときと、テストから呼べない外部APIを差し替えるときで、どちらもspecの直前の行に理由を書く。
- 比較演算子を使う条件には、境界の1つ手前、境界ちょうど、境界の1つ後の3つの値のspecを置く。
- 既存のspecを書き換えてよいのは、次の2つの場合だけにする。それ以外の変更では、既存のspecの例・入力・期待値を消したり書き換えたりせず、specを足すだけにする。
  - 契約の表を変えて機能を改修するとき。
  - specの期待値が契約の表と食い違っていて、人間がspecの誤りだと認めたとき。
- specが落ちたら、実装とspecのどちらを直すかを契約の表で決める。実装が表と食い違っていれば実装を直す。specが表と食い違っているか、表に対応する行がなければ、specも実装も変えずに、契約のID、specのファイルと行、食い違いの内容を報告して人間の承認を待つ。
- 承認を得たspecの修正は、実装の変更と別のコミットにする。

## HTTP APIの契約

| ID | 要求 | 成功 | 失敗 |
|---|---|---|---|
| API-01 | `GET /shipping_quote?order_amount=N` | 200 `{"shipping_fee"}` | 整数でない・0以下は422 |
| API-02 | `POST /orders/:order_id/cancellation` | 200 `{"status":"cancelled"}` | キャンセルできなければ409（状態は変えない）、未存在は404 |
| API-03 | `POST /products/:product_id/reservations` | 201 在庫の3つの値 | 在庫不足は409、数量不正は422、壊れたJSONは400（どれもDBは変えない）、未存在は404 |
| API-04 | `GET /up` | 200 | なし |

- コントローラには入力の変換、サービスの呼び出し、JSON化だけを書く。業務の規則はモデルとサービスに置く。
- APIを変えたら、`spec/e2e/` のE2Eを先に直し、実サーバーで失敗することを確かめてから実装する。
