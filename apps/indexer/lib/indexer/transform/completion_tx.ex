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
    # Completed(bytes32,address,bytes32,bytes32,uint256,bytes32[],uint256[])
    case decode_data(log.data, [
          #  {:bytes, 32},
          #  :address,
           {:bytes, 32},
           {:bytes, 32},
           {:uint, 256},
           {:array, {:bytes, 32}},
           {:array, {:uint, 256}}
         ]) do
      [receiver, receiver_btc, btc_amount, assets, amounts] ->

        tx_hash = if Map.has_key?(log, :second_topic) and not is_nil(log.second_topic), do: log.second_topic, else: nil

        if tx_hash do
          parse_data = %{
            btc_dapp_tx: tx_hash,
            completion_tx: log.transaction_hash
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
