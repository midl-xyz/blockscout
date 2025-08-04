defmodule Indexer.Transform.CompletionTransaction do
  require Logger

  import Explorer.Helper, only: [truncate_address_hash: 1, decode_data: 2]

  alias Explorer.{Helper, Repo}
  alias Explorer.Chain.{Hash, CompletionTransaction}
  alias Indexer.Fetcher.TokenTotalSupplyUpdater

  def parse(logs, transactions \\ []) do
    Logger.debug("CompletionTransaction.parse: Starting with #{length(logs)} logs and #{length(transactions)} transactions")

    result = logs
    |> Enum.filter(&(&1.first_topic == CompletionTransaction.completed_event()))
    |> Enum.map(&parse_event(&1, transactions))
    |> Enum.reject(&is_nil/1)

    Logger.debug("CompletionTransaction.parse: Returning #{length(result)} completion transactions")
    result
  end

  defp parse_event(log, transactions) do
    Logger.debug("CompletionTransaction.parse_event: Processing log for transaction #{inspect(log.transaction_hash)}")

    # Find the transaction that emitted this event
    source_transaction = Enum.find(transactions, &(&1.hash == log.transaction_hash))
    Logger.debug("CompletionTransaction.parse_event: Found source transaction: #{inspect(source_transaction != nil)}")

    if source_transaction do
      Logger.debug("CompletionTransaction.parse_event: Source transaction btc_tx_hash: #{inspect(source_transaction.btc_tx_hash)}")
    end
    # Completed(address,bytes32,bytes32,uint256,bytes32[],uint256[])
    case decode_data(log.data, [
           {:bytes, 32},
           {:bytes, 32},
           {:uint, 256},
           {:array, {:bytes, 32}},
           {:array, {:uint, 256}}
         ]) do
      [receiver, receiver_btc, btc_amount, assets, amounts] ->
        Logger.debug("CompletionTransaction.parse_event: Decoded event data successfully")

        sender = if Map.has_key?(log, :second_topic) and not is_nil(log.second_topic), do: log.second_topic, else: nil
        Logger.debug("CompletionTransaction.parse_event: Event sender from second_topic: #{inspect(sender)}")

        if source_transaction && source_transaction.btc_tx_hash && sender do
          # Use btc_tx_hash from the transaction that emitted this event
          btc_dapp_tx_from_transaction = source_transaction.btc_tx_hash
          Logger.debug("CompletionTransaction.parse_event: Using btc_tx_hash from transaction: #{inspect(btc_dapp_tx_from_transaction)}")

          # Extract sender address from topics (it's a padded hex string)
          sender_address_hex = extract_address_from_hex_string(sender)
          sender_address_binary = convert_hex_to_binary(sender_address_hex)

          Logger.debug("CompletionTransaction.parse_event: Sender address hex: #{inspect(sender_address_hex)}")
          Logger.debug("CompletionTransaction.parse_event: Sender address binary: #{inspect(sender_address_binary)}")

          parse_data = %{
            btc_dapp_tx: btc_dapp_tx_from_transaction,  # Using transaction's btc_tx_hash
            completion_tx: log.transaction_hash,
            sender: sender_address_binary  # Using sender from topics as address
          }

          parse_data
        else
          Logger.error("CompletionTransaction.parse_event: Missing source transaction, btc_tx_hash, or sender for log: #{inspect(log.transaction_hash)}")
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

  # Check if receiver is valid (not null and not all zeros)
  defp is_receiver_valid?(nil), do: false
  defp is_receiver_valid?(<<0::256>>), do: false
  defp is_receiver_valid?(receiver) when is_binary(receiver) and byte_size(receiver) == 32, do: true
  defp is_receiver_valid?(_), do: false

  # Extract 20-byte address from 32-byte value (last 20 bytes)
  defp extract_address_from_bytes32(receiver) when byte_size(receiver) == 32 do
    :binary.part(receiver, 12, 20)  # Skip first 12 bytes, take last 20 bytes
  end
  defp extract_address_from_bytes32(receiver), do: receiver

  # Extract address from hex string (like "0x000...000address")
  defp extract_address_from_hex_string("0x" <> hex_data) when byte_size(hex_data) == 64 do
    # Take last 40 characters (20 bytes) and add 0x prefix
    address_part = String.slice(hex_data, -40, 40)
    "0x" <> address_part
  end
  defp extract_address_from_hex_string(hex_string), do: hex_string

  # Convert hex string to binary
  defp convert_hex_to_binary("0x" <> hex_data) do
    Base.decode16!(hex_data, case: :mixed)
  end
  defp convert_hex_to_binary(data), do: data
end
