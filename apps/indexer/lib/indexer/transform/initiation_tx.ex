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
    case decode_data(log.data, [{:bytes, 32}, :address, {:uint, 256}]) do
      [tx_hash, from, btc_amount] ->
        parse_data = %{
          btc_dapp_tx: encode_address_hash(tx_hash),
          initiation_tx: log.transaction_hash
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
