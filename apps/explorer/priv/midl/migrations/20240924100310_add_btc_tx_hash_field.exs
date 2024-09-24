defmodule Explorer.Repo.Midl.Migrations.AddBtcTxHashField do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:btc_tx_hash, :bytea)
    end
  end
end
