defmodule Explorer.Chain.CommittedSentEvent do
  use Ecto.Schema
  alias Explorer.Chain.Hash

  @committed_sent_tx_event "0x19174d5bf96bc3561d84a8307a854b80c386010d63e03c18e709d470b507f0c1"

  @primary_key false
  schema "committed_send_event" do
    field(:btc_dapp_tx, Hash.Full, primary_key: true)
    field(:committed_event_tx, Hash.Full)
    field(:btc_result_tx, Hash.Full)
    field(:receiver, Hash.Address)

    timestamps()
  end

  @required_fields ~w(btc_dapp_tx committed_event_tx btc_result_tx receiver)a
  @optional_fields []

  def committed_sent_tx_event, do: @committed_sent_tx_event

  def changeset(committed_send_event, attrs) do
    committed_send_event
    |> Ecto.Changeset.cast(attrs, @required_fields ++ @optional_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.unique_constraint(:btc_dapp_tx, name: :midl_btc_dapp_tx_index)
    |> Ecto.Changeset.unique_constraint(:committed_event_tx, name: :midl_committed_event_tx_index)
    |> Ecto.Changeset.unique_constraint(:btc_result_tx, name: :midl_btc_result_tx_index)
  end
end
