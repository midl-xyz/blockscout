defmodule Explorer.Chain.AddressesMap do
  @moduledoc """
  Stores a public key along with its corresponding BTC & ETH addresses.

  * `public_key`   - a unique, full-length hash (PRIMARY KEY)
  * `btc_address`  - a hashed representation of the BTC address
  * `eth_address`  - a hashed representation of the ETH address
  """

  use Ecto.Schema
  alias Explorer.Chain.Hash

  @primary_key false
  schema "addresses_map" do
    field :public_key,  Hash.Full, primary_key: true
    field :btc_address, :string
    field :eth_address, Hash.Address

    timestamps()
  end

  @required_fields ~w(public_key btc_address eth_address)a
  @optional_fields []

  @doc """
  Builds a changeset for creating/updating addresses_map.
  """
  def changeset(addresses_map, attrs) do
    addresses_map
    |> Ecto.Changeset.cast(attrs, @required_fields ++ @optional_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.unique_constraint(:public_key,  name: :midl_addresses_map_public_key_index)
    |> Ecto.Changeset.unique_constraint(:btc_address, name: :midl_addresses_map_btc_address_index)
    |> Ecto.Changeset.unique_constraint(:eth_address, name: :midl_addresses_map_eth_address_index)
  end
end
