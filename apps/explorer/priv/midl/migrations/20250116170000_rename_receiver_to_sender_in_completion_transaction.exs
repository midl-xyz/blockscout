defmodule Explorer.Repo.Midl.Migrations.RenameReceiverToSenderInCompletionTransaction do
  use Ecto.Migration

  def change do
    rename table(:completion_transaction), :receiver, to: :sender
  end
end
