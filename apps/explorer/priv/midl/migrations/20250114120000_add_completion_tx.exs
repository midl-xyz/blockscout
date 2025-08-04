defmodule Explorer.Repo.Midl.Migrations.CreateCompletionTransaction do
  use Ecto.Migration

  def change do
    create table(:completion_transaction, primary_key: false) do
      add(:btc_dapp_tx, :bytea, null: false, primary_key: true)
      add(:completion_tx, :bytea, null: false)

      timestamps()
    end

    create(unique_index(:completion_transaction, [:btc_dapp_tx], name: :midl_completion_tx_btc_dapp_tx_index))
    create(unique_index(:completion_transaction, [:completion_tx], name: :midl_completion_tx_index))
  end
end
