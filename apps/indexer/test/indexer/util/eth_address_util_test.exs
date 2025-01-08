# File: test/my_btc_test.exs
defmodule EthAddressUtilTest do
  use ExUnit.Case, async: true
  doctest EthAddressUtil

  alias EthAddressUtil

  @pubkey "03a8bec023ccf39986fb5feabc9d3c2ed426b3b7d3df663b4577c7f79cefb56232"
  @eth_address_expected "0x5e5b88defa1a412c69644cb47e68107d97807e35"

  describe "EthAddressUtil.get_evm_address/2" do
    test "get ETH address frompublic key" do
      address = EthAddressUtil.get_evm_address(@p2wpkh_pubkey, 1)
      assert address == @p2wpkh_expected
    end
  end
end
