defmodule Explorer.Chain.CompletionTransaction do
  use Ecto.Schema
  alias Explorer.Chain.Hash

  @completed_event "0x0ff4e839cbfd887bcd0e0fd700af3c5162e18165fade4938de2ea2eb9de369f4"

  @primary_key false
  schema "completion_transaction" do
    field(:btc_dapp_tx, Hash.Full, primary_key: true)
    field(:completion_tx, Hash.Full)
    field(:sender, Hash.Address)

    timestamps()
  end

  @required_fields ~w(btc_dapp_tx completion_tx sender)a
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
