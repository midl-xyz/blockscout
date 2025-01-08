defmodule Indexer.Util.BtcAddressUtil do
  @moduledoc """
  Provides functions to compute BTC addresses (p2wpkh or p2tr)
  using the latest bitcoinex Segwit API.
  """

  alias Bitcoinex.{Segwit}

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

  def compress_65_byte(<<4, x::binary-size(32), y::binary-size(32)>>) do
    prefix = if rem(:binary.decode_unsigned(y), 2) == 0, do: <<2>>, else: <<3>>
    <<prefix::binary, x::binary>>
  end

  def compress_65_byte(_), do: {:error, "Invalid uncompressed public key"}

  def decode_point(<<prefix, x::binary-size(32)>>) when prefix in [2, 3] do
    {:ok, {x, calculate_y(x, prefix == 3)}}
  end

  def decode_point(<<4, x::binary-size(32), y::binary-size(32)>>), do: {:ok, {x, y}}

  def decode_point(_), do: {:error, "Invalid public key format"}

  def encode_point({x, y}, :compressed) do
    prefix = if rem(:binary.decode_unsigned(y), 2) == 0, do: <<2>>, else: <<3>>
    <<prefix::binary, x::binary>>
  end

  def encode_point({x, y}, :uncompressed) do
    <<4::integer, x::binary, y::binary>>
  end

  def encode_point(_, _), do: {:error, "Unsupported format"}

  defp calculate_y(x, odd?) do
    p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
    a = 0
    b = 7

    # Compute y^2 = (x^3 + a*x + b) mod p
    x_int = :binary.decode_unsigned(x)
    y_squared = rem(x_int * x_int * x_int + a * x_int + b, p)

    # Modular square root
    y = modular_sqrt(y_squared, p)

    # Ensure correct parity
    if odd? == odd?(y), do: :binary.encode_unsigned(y), else: :binary.encode_unsigned(p - y)
  end

  defp modular_sqrt(value, p) do
    # Uses exponentiation for modular square root: value^((p+1)/4) mod p
    :math.pow(value, (p + 1) / 4) |> trunc() |> rem(p)
  end

  defp odd?(n), do: rem(n, 2) == 1

  defp hash160(data) do
    sha = :crypto.hash(:sha256, data)
    :crypto.hash(:ripemd160, sha)
  end

end
