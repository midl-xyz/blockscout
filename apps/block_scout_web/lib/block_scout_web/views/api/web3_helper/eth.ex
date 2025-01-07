defmodule MyETH do
  @moduledoc """
  Provides functions to compute Ethereum (EVM) addresses from a hex-encoded public key.
  Similar to MyBTC but for ETH addresses.
  """

  alias Bitcoinex.Secp256k1
  alias ExKeccak

  @doc """
  Given a hex-encoded public key `pubkey_hex`, returns the Ethereum address in "0x" + 40-hex format.

  Steps:
  - Strip "0x" from `pubkey_hex` if present
  - Decode hex to raw bytes
  - If 33 bytes (compressed), decompress to 65 bytes
  - If 65 bytes (uncompressed), remove `0x04` prefix → 64 bytes
  - keccak-256 → last 20 bytes → "0x" + encode in hex
  """
  def compute_eth_address(pubkey_hex) when is_binary(pubkey_hex) do
    # 1) Remove "0x" prefix if present
    pubkey_hex =
      if String.starts_with?(pubkey_hex, "0x") do
        String.slice(pubkey_hex, 2..-1//1)
      else
        pubkey_hex
      end

    # 2) Decode from hex
    case Base.decode16(pubkey_hex, case: :mixed) do
      {:ok, pubkey_bin} ->
        do_compute_eth_address(pubkey_bin)

      :error ->
        nil
    end
  end

  # We handle uncompressed & compressed public keys
  defp do_compute_eth_address(pubkey_bin) do
    case byte_size(pubkey_bin) do
      65 ->
        # Typically 0x04 + 64 bytes => uncompressed
        # Must start with 0x04
        if :binary.at(pubkey_bin, 0) == 0x04 do
          uncompressed_to_eth_address(pubkey_bin)
        else
          nil
        end

      33 ->
        # Compressed => 0x02/0x03 + 32 bytes
        decompress_and_compute(pubkey_bin)

      64 ->
        # Possibly raw x+y, missing the 0x04 prefix
        # We can prepend 0x04 to treat it as uncompressed
        uncompressed = <<0x04>> <> pubkey_bin
        uncompressed_to_eth_address(uncompressed)

      _ ->
        nil
    end
  end

  # Decompress a 33-byte compressed key to 65 bytes, then compute address
  defp decompress_and_compute(<<prefix, _rest::binary-size(32)>> = compressed) when prefix in [0x02, 0x03] do
    # Use secp256k1 from bitcoinex to decode, then re-encode as uncompressed
    case Secp256k1.point_decode(compressed) do
      {:ok, point} ->
        uncompressed = Secp256k1.point_encode(point, :uncompressed)
        uncompressed_to_eth_address(uncompressed)

      :error ->
        nil
    end
  end

  defp decompress_and_compute(_), do: nil

  # Convert 65-byte uncompressed pubkey -> ETH address
  # Steps:
  #   1) remove leading 0x04
  #   2) keccak256( x+y )
  #   3) last 20 bytes -> address
  defp uncompressed_to_eth_address(<<0x04, rest::binary-size(64)>>) do
    keccak = ExKeccak.hash_256(rest)
    # last 20 bytes
    <<_::binary-12, address_20::binary-20>> = keccak
    "0x" <> Base.encode16(address_20, case: :lower)
  end

  defp uncompressed_to_eth_address(_), do: nil
end
