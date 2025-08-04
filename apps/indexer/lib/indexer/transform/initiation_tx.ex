defmodule Indexer.Transform.InitiationTransaction do
  require Logger

  import Explorer.Helper, only: [truncate_address_hash: 1, decode_data: 2]

  alias Explorer.{Helper, Repo}
  alias Explorer.Chain.{Hash, InitiationTransaction}
  alias Indexer.Fetcher.TokenTotalSupplyUpdater

  def parse(logs) do
    logs
    |> Enum.filter(&(&1.first_topic == InitiationTransaction.acknowledged_event()))
    |> Enum.map(&parse_event/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_event(log) do
    # Acknowledged(bytes32 txHash, address from, uint256 btcAmount)
    case decode_data(log.data, [{:uint, 256}]) do
      [btc_amount] ->

        tx_hash = if Map.has_key?(log, :second_topic) and not is_nil(log.second_topic), do: log.second_topic, else: nil

        if tx_hash do
          parse_data = %{
            btc_dapp_tx: tx_hash,
            initiation_tx: log.transaction_hash
          }

          parse_data
        else
          Logger.error("Missing txHash in topics: #{inspect(log)}")
          nil
        end

      _ ->
        Logger.error("Failed to decode log data: #{inspect(log)}")
        nil
    end
  end

  defp encode_address_hash(binary) do
    "0x" <> Base.encode16(binary, case: :lower)
  end
end
