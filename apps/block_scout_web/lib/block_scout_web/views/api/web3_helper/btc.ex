defmodule MyBTC do
  @moduledoc """
  Provides functions to compute BTC addresses (p2wpkh or p2tr)
  using the latest bitcoinex Segwit API.
  """

  alias Bitcoinex.{Key, Secp256k1, Segwit}
  alias Bitcoinex.Network

  @doc """
  Given a hex-encoded public key and an address type:
    * 0 -> p2tr (taproot)
    * otherwise -> p2wpkh (v0)

  Returns the appropriate BTC address string for the `:regtest` network.
  """
  def compute_btc_address(pubkey_hex, address_type) when is_binary(pubkey_hex) do
    pubkey_hex =
      if String.starts_with?(pubkey_hex, "0x") do
        String.slice(pubkey_hex, 2..-1)
      else
        pubkey_hex
      end

    case Base.decode16(pubkey_hex, case: :mixed) do
      {:ok, pubkey_bin} ->
        do_compute_address(pubkey_bin, address_type)

      :error ->
        nil
    end
  end

  defp do_compute_address(pubkey_bin, 0) do
    witness_version = 1
    witness_program = :binary.bin_to_list(pubkey_bin)

    network = :regtest  # or :mainnet, :testnet
    case Segwit.encode_address(network, witness_version, witness_program) do
      {:ok, address} -> address
      {:error, _} -> nil
    end
  end

  defp do_compute_address(pubkey_bin, _others) do
    compressed_pubkey =
      case byte_size(pubkey_bin) do
        65 ->
          compress_65_byte(pubkey_bin)

        33 ->
          pubkey_bin

        _ ->
          nil
      end

    if is_nil(compressed_pubkey) do
      nil
    else
      program_bin = hash160(compressed_pubkey)
      program_list = :binary.bin_to_list(program_bin)
      witness_version = 0
      network = :regtest  # or :mainnet, :testnet, etc.

      case Bitcoinex.Segwit.encode_address(network, witness_version, program_list) do
        {:ok, address} -> address
        {:error, _reason} -> nil
      end
    end
  end

  @doc """
  Compress a 65-byte uncompressed pubkey (0x04 prefix + 64 bytes).
  Returns a 33-byte compressed pubkey (0x02/0x03 + 32 bytes).
  """
  defp compress_65_byte(<<4, uncompressed_coords::binary-size(64)>>) do
    # parse x,y => compress => return
    case Bitcoinex.Secp256k1.point_decode(<<4>> <> uncompressed_coords) do
      {:ok, point} ->
        Bitcoinex.Secp256k1.point_encode(point, :compressed)

      :error ->
        nil
    end
  end

  defp compress_65_byte(_), do: nil

  @doc """
  Plain hash160: hash160(sha256(data)).
  Returns a binary (20 bytes).
  """
  defp hash160(data) do
    sha = :crypto.hash(:sha256, data)
    :crypto.hash(:ripemd160, sha)
  end
end