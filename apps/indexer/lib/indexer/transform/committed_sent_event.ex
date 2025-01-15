defmodule Indexer.Transform.CommittedSentEvent do
  require Logger

  import Explorer.Helper, only: [truncate_address_hash: 1, decode_data: 2]

  alias Explorer.{Helper, Repo}
  alias Explorer.Chain.{Hash, CommittedSentEvent}
  alias Indexer.Fetcher.TokenTotalSupplyUpdater

  def parse(logs) do
    logs
    |> Enum.filter(&(&1.first_topic == CommittedSentEvent.committed_sent_tx_event()))
    |> Enum.map(&parse_event/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_event(log) do
    case decode_data(log.data, [{:uint, 256}, {:bytes, 32}, {:bytes, 32}, {:bytes, 32}]) do
      [block_num, tx_hash, sent_txs_batch_hash, receiver] ->
        parse_data = %{
          btc_dapp_tx: encode_address_hash(tx_hash),
          committed_event_tx: log.transaction_hash,
          btc_result_tx: encode_address_hash(sent_txs_batch_hash)
        }

        parse_data
      _ ->
        Logger.error("Failed to decode log data: #{inspect(log)}")
        nil
    end
  end

  defp encode_address_hash(binary) do
    "0x" <> Base.encode16(binary, case: :lower)
  end
end
