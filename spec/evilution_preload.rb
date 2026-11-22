# evilutionはvalidatesなどの宣言の変異を、親プロセスで読み込み済みのクラスでだけ元の宣言と差し替える。
# test環境はeager_loadしないので、ここでモデルを読み込まないと元の検証が残り、変異が生き残る。
require_relative "rails_helper"
Rails.application.eager_load!
