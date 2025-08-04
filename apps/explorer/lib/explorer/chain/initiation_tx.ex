defmodule Explorer.Chain.InitiationTransaction do
  use Ecto.Schema
  alias Explorer.Chain.Hash

  @acknowledged_event "0x69eb79a5127eda93010aff3c3c3ccf8d001a18a7314dba2a7c70a7f489887b26"

  @primary_key false
  schema "initiation_transaction" do
    field(:btc_dapp_tx, Hash.Full, primary_key: true)
    field(:initiation_tx, Hash.Full)

    timestamps()
  end

  @required_fields ~w(btc_dapp_tx initiation_tx)a
  @optional_fields []

  def acknowledged_event, do: @acknowledged_event

  def changeset(initiation_transaction, attrs) do
    initiation_transaction
    |> Ecto.Changeset.cast(attrs, @required_fields ++ @optional_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.unique_constraint(:btc_dapp_tx, name: :midl_init_tx_btc_dapp_tx_index)
    |> Ecto.Changeset.unique_constraint(:initiation_tx, name: :midl_init_tx_initiation_tx_index)
  end
end
