defmodule Explorer.Repo.Midl.Migrations.AddIndexToBtcTxHash do
  use Ecto.Migration

  def change do
    create index(:transactions, [:btc_tx_hash], name: :index_transactions_on_btc_tx_hash)
  end

end