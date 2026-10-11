# AIエージェントへの指示

このリポジトリでは、人間が設計で決めた契約を、AIが実装とテストで守る。

## 在庫引当の契約（正本）

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
| CON-01 | 同時実行の契約 | 在庫1個への同時引当は1件だけ成功する | `spec/integration/inventory_concurrency_spec.rb` |

契約を変えるときは、この表を先に直し、人間の承認を得てからspecと実装を変える。

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

## HTTP APIの契約

| 要求 | 成功 | 失敗 |
|---|---|---|
| `GET /shipping_quote?order_amount=N` | 200 `{"shipping_fee"}` | 整数でない・0以下は422 |
| `POST /orders/:order_id/cancellation` | 200 `{"status":"cancelled"}` | キャンセルできなければ409（状態は変えない）、未存在は404 |
| `POST /products/:product_id/reservations` | 201 在庫の3つの値 | 在庫不足は409、数量不正は422（DBは変えない）、未存在は404 |

- コントローラには入力の変換、サービスの呼び出し、JSON化だけを書く。業務の規則はモデルとサービスに置く。
- APIを変えたら、`spec/e2e/` のE2Eを先に直し、実サーバーで失敗することを確かめてから実装する。
