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
    out_json
    |> Map.put("btc_tx_hash", remove_0x_prefix_if_any(transaction.btc_tx_hash))
    |> Map.put("public_key", remove_0x_prefix_if_any(transaction.public_key))
    |> Map.put("btc_address_byte", remove_0x_prefix_if_any(transaction.btc_address_byte))
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
