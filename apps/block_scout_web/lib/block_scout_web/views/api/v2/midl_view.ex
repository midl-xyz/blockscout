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
    |> Map.put("btc_tx_hash", transaction.btc_tx_hash)
    |> Map.put("public_key", transaction.public_key)
    |> Map.put("btc_address_byte", transaction.btc_address_byte)
  end

end
