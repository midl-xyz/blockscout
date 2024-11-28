defmodule Explorer.Repo.Midl.Migrations.AddPublicKeyField do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:public_key, :bytea)
    end
  end
end
