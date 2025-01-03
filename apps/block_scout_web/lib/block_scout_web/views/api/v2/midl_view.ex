defmodule BlockScoutWeb.API.V2.MidlView do
  use BlockScoutWeb, :view

  import Ecto.Query, only: [from: 2]

  alias BlockScoutWeb.API.V2.Helper
  alias Explorer.{Chain, Repo}
  alias Explorer.Helper, as: ExplorerHelper
  alias Explorer.Chain.{Block, Transaction}
  alias Explorer.Chain.Optimism.{FrameSequence, FrameSequenceBlob, Withdrawal}

  @doc """
    Extends the json output for a transaction adding MIDL-related info to the output.

    ## Parameters
    - `out_json`: A map defining output json which will be extended.
    - `transaction`: transaction structure containing extra MIDL-related info.

    ## Returns
    An extended map containing `l1_*` and `op_withdrawals` items related to Optimism.
  """
  @spec extend_transaction_json_response(map(), %{
          :__struct__ => Explorer.Chain.Transaction,
          optional(any()) => any()
        }) :: map()
  def extend_transaction_json_response(out_json, %Transaction{} = transaction) do
    pubkey_hex = remove_0x_prefix_if_any(transaction.public_key)
    address_type_str = remove_0x_prefix_if_any(transaction.btc_address_byte) || "0"

    address_type =
      case Integer.parse(address_type_str) do
        {val, _} -> val
        :error -> 0
      end

    btc_address =
      if is_nil(pubkey_hex) or is_zero_64?(pubkey_hex) do
        nil
      else
        MyBTC.compute_btc_address(pubkey_hex, address_type)
      end

    out_json
    |> Map.put("btc_tx_hash", remove_0x_prefix_if_any(transaction.btc_tx_hash))
    |> Map.put("public_key", pubkey_hex)
    |> Map.put("btc_address_byte", address_type_str)
    |> Map.put("btc_address", btc_address)
    |> Map.put("intents", map_intents(transaction.intents))
  end

  @doc """
  Checks if a 64-char hex string consists entirely of '0'.
  E.g. "0000000000000000000000000000000000000000000000000000000000000000"
  """
  defp is_zero_64?(str) when is_binary(str) do
    String.length(str) == 64 and String.match?(str, ~r/^[0]+$/)
  end

  defp map_intents(nil), do: []
  defp map_intents(intents) when is_list(intents) do
    Enum.map(intents, &map_intent_transaction/1)
  end

  defp map_intent_transaction(%Transaction{} = intent_tx) do
    [decoded_input] = Transaction.decode_transactions([intent_tx], true, [api?: true])
    %{
      "method" => Transaction.method_name(intent_tx, decoded_input),
      "hash" => intent_tx.hash,
      "status" => intent_tx.status
    }
  end

  def remove_0x_prefix_if_any(nil), do: nil

  @doc """
    Midl RPC returns BTC parameters: `btc_tx_hash`, `public_key`, `btc_address_byte` with 0x prefix.
    That is not consistent with the rest of the system, so we remove the prefix here.

    The solution is temporary. Prefix should be cleaned on the RPC side or saving to DB side.
  """
  def remove_0x_prefix_if_any(%Explorer.Chain.Hash{} = hash_struct) do
    # Convert the hash struct to a string, e.g. "0x9e48a19b..."
    hashed_string = Explorer.Chain.Hash.to_string(hash_struct)

    # If it starts with "0x", remove that prefix
    case hashed_string do
      "0x" <> rest -> rest
      other -> other
    end
  end

end
