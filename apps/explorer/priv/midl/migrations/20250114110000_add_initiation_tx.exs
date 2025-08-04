defmodule Explorer.Repo.Midl.Migrations.CreateInitiationTransaction do
  use Ecto.Migration

  def change do
    create table(:initiation_transaction, primary_key: false) do
      add(:btc_dapp_tx, :bytea, null: false, primary_key: true)
      add(:initiation_tx, :bytea, null: false)

      timestamps()
    end

    create(unique_index(:initiation_transaction, [:btc_dapp_tx], name: :midl_init_tx_btc_dapp_tx_index))
    create(unique_index(:initiation_transaction, [:initiation_tx], name: :midl_init_tx_initiation_tx_index))
  end
end
