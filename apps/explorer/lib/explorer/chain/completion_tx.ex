defmodule Explorer.Chain.CompletionTransaction do
  use Ecto.Schema
  alias Explorer.Chain.Hash

  @completed_event "0x4ea27a9203a3e9ef8d840e2c762c1992e973b331b11d04dcca08db9a25084ce2"

  @primary_key false
  schema "completion_transaction" do
    field(:btc_dapp_tx, Hash.Full, primary_key: true)
    field(:completion_tx, Hash.Full)

    timestamps()
  end

  @required_fields ~w(btc_dapp_tx completion_tx)a
  @optional_fields []

  def completed_event, do: @completed_event

  def changeset(completion_transaction, attrs) do
    completion_transaction
    |> Ecto.Changeset.cast(attrs, @required_fields ++ @optional_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.unique_constraint(:btc_dapp_tx, name: :midl_completion_tx_btc_dapp_tx_index)
    |> Ecto.Changeset.unique_constraint(:completion_tx, name: :midl_completion_tx_index)
  end
end
