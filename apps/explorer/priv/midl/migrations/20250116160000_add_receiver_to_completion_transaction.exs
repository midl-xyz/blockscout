defmodule Explorer.Repo.Midl.Migrations.AddReceiverToCompletionTransaction do
  use Ecto.Migration

  def change do
    alter table(:completion_transaction) do
      add(:receiver, :bytea, null: false)
    end
  end
end
