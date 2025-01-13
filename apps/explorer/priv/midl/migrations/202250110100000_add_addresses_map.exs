defmodule Explorer.Repo.Midl.Migrations.CreateAddressesMap do
  use Ecto.Migration

  def change do
    create table(:addresses_map, primary_key: false) do
      add :public_key, :bytea, null: false, primary_key: true
      add :btc_address, :text, null: false
      add :eth_address, :bytea, null: false

      timestamps()
    end

    create(unique_index(:addresses_map, [:public_key], name: :midl_addresses_map_public_key_index))
    create(unique_index(:addresses_map, [:btc_address], name: :midl_addresses_map_btc_address_index))
    create(unique_index(:addresses_map, [:eth_address], name: :midl_addresses_map_eth_address_index))
  end
end
