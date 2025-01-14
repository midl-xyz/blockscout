defmodule Explorer.Repo.Midl.Migrations.CreateCommittedSendEvent do
  use Ecto.Migration

  def change do
    create table(:committed_send_event, primary_key: false) do
      add(:btc_dapp_tx, :bytea, null: false, primary_key: true)
      add(:committed_event_tx, :bytea, null: false)
      add(:btc_result_tx, :bytea, null: false)

      timestamps()
    end

    create(unique_index(:committed_send_event, [:btc_dapp_tx], name: :midl_btc_dapp_tx_index))
    create(unique_index(:committed_send_event, [:committed_event_tx], name: :midl_committed_event_tx_index))
    create(unique_index(:committed_send_event, [:btc_result_tx], name: :midl_btc_result_tx_index))
  end
end
