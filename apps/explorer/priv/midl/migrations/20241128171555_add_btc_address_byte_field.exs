defmodule Explorer.Repo.Midl.Migrations.AddBtcAddressByteField do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:btc_address_byte, :integer)
    end
  end
end
