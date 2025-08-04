defmodule Explorer.Repo.Midl.Migrations.AddReceiverToCommittedSendEvent do
  use Ecto.Migration

  def change do
    alter table(:committed_send_event) do
      add(:receiver, :bytea, null: false)
    end
  end
end
