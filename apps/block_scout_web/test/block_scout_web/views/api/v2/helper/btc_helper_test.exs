# File: test/my_btc_test.exs
defmodule MyBTCTest do
  use ExUnit.Case, async: true
  doctest MyBTC

  alias MyBTC

  @p2wpkh_pubkey "03a8bec023ccf39986fb5feabc9d3c2ed426b3b7d3df663b4577c7f79cefb56232"
  @p2wpkh_expected "bcrt1q36d3dcs65e28xqp3vpgcd0hgfzdaqctf438zk7"

  @taproot_pubkey "e3a6aedbedea55703355b6ed25c7e8e2ed5864e3fec671e036531e4423420016"
  @taproot_expected "bcrt1puwn2akldaf2hqv64kmkjt3lgutk4se8rlmr8rcpk2v0ygg6zqqtqzzjdq9"

  describe "MyBTC.compute_btc_address/2" do
    test "P2WPKH with compressed pubkey" do
      # This scenario => address_type != 0
      # We expect a P2WPKH result
      address = MyBTC.compute_btc_address(@p2wpkh_pubkey, 1)
      assert address == @p2wpkh_expected
    end

    test "Taproot with x-only pubkey" do
      # address_type == 0 => we treat it as taproot
      address = MyBTC.compute_btc_address(@taproot_pubkey, 0)
      assert address == @taproot_expected
    end
  end
end