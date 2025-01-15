defmodule Indexer.Transform.CompletionTransaction do
  require Logger

  import Explorer.Helper, only: [truncate_address_hash: 1, decode_data: 2]

  alias Explorer.{Helper, Repo}
  alias Explorer.Chain.{Hash, CompletionTransaction}
  alias Indexer.Fetcher.TokenTotalSupplyUpdater

  def parse(logs) do
    logs
    |> Enum.filter(&(&1.first_topic == CompletionTransaction.completed_event()))
    |> Enum.map(&parse_event/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_event(log) do
    # Completed(uint256,bytes32,address,bytes32,uint256,bytes32[],uint256[])
    case decode_data(log.data, [
           {:uint, 256},
           {:bytes, 32},
           :address,
           {:bytes, 32},
           {:uint, 256},
           {:array, {:bytes, 32}},
           {:array, {:uint, 256}}
         ]) do
      [block_num, tx_hash, sender, receiver, btc_amount, assets, amounts] ->
        parse_data = %{
          btc_dapp_tx: encode_address_hash(tx_hash),
          completion_tx: log.transaction_hash
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
