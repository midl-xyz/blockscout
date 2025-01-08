defmodule Indexer.Util.EthAddressUtil do
  @moduledoc """
  Utilities for generating Ethereum addresses and applying EIP-55 and EIP-1191 checksumming.

  This module provides methods to compute Ethereum addresses from public keys and format
  them with appropriate checksumming standards.

  ## Features
  - Compute Ethereum address from a public key.
  - Validate Ethereum addresses.
  - Apply EIP-55 or EIP-1191 checksum formatting.

  ## Examples
      iex> EthAddressUtil.get_evm_address("0x<public_key>")
      "0x5E5b88DEfa1A412C69644CB47E68107d97807E35"
  """

  import Bitwise

  alias ExKeccak

  @doc """
  Computes an Ethereum address from a given public key.

  ### Steps:
  1. Removes the `"0x"` prefix if present.
  2. Decodes the public key from hex to binary.
  3. Hashes the binary using Keccak-256.
  4. Extracts the last 20 bytes from the hash.
  5. Converts the result into an Ethereum address with checksum formatting.

  ## Parameters
  - `public_key`: A binary string representing the public key (with or without the `"0x"` prefix).

  ## Returns
  - The checksummed Ethereum address as a string.
  - `{:error, "Invalid public key format"}` if the public key is not in the correct format.

  ## Examples
      iex> EthAddressUtil.get_evm_address("0x<public_key>")
      "0x5E5b88DEfa1A412C69644CB47E68107d97807E35"
  """
  def get_evm_address(public_key) when is_binary(public_key) do
    public_key_hex =
      if String.starts_with?(public_key, "0x") do
        String.slice(public_key, 2..-1//1)
      else
        public_key
      end

    case Base.decode16(public_key_hex, case: :mixed) do
      {:ok, public_key_binary} ->
        public_key_hashed = ExKeccak.hash_256(public_key_binary)

        # Extract the last 20 bytes
        <<_::binary-size(12), address::binary-size(20)>> = public_key_hashed

        eth_address = Base.encode16(address, case: :lower)
        eth_address_with_checksum = get_address_with_checksum(eth_address, public_key_hashed)
        eth_address_with_checksum

      :error ->
        {:error, "Invalid public key format"}
    end
  end

  @doc """
  Applies EIP-55 checksum formatting to an Ethereum address.

  ## Parameters
  - `addr`: The lowercase Ethereum address.
  - `public_key_hashed`: The Keccak-256 hash of the address.

  ## Returns
  - The checksummed Ethereum address.

  ## Examples
      iex> EthAddressUtil.eip55_address("5e5b88defa1a412c69644cb47e68107d97807e35", public_key_hashed)
      "0x5E5b88DEfa1A412C69644CB47E68107d97807E35"
  """
  def eip55_address(addr, public_key_hashed) do
    lower_addr = String.downcase(addr)
    do_eip55ify("0x", lower_addr, public_key_hashed, _opts: false)
  end

  @doc """
  Applies EIP-1191 checksum formatting, including chain ID.

  ## Parameters
  - `addr`: The lowercase Ethereum address.
  - `public_key_hashed`: The Keccak-256 hash of the address.
  - `chain_id`: The chain ID to include in the checksum calculation.

  ## Returns
  - The checksummed Ethereum address.

  ## Examples
      iex> EthAddressUtil.eip1191_address("5e5b88defa1a412c69644cb47e68107d97807e35", public_key_hashed, 1)
      "0x5E5b88DEfa1A412C69644CB47E68107d97807E35"
  """
  def eip1191_address(addr, public_key_hashed, chain_id) when is_integer(chain_id) do
    lower_hex = String.downcase(remove_0x_prefix(addr))
    combined = Integer.to_string(chain_id) <> lower_hex
    do_eip55ify("0x", combined, public_key_hashed, _opts: true)
  end

  @doc """
  Generates a checksummed Ethereum address using EIP-55 or EIP-1191.

  ## Parameters
  - `addr`: A lowercase Ethereum address without checksum formatting.
  - `public_key_hashed`: The Keccak-256 hash of the address.
  - `chain_id` (optional): If provided, applies EIP-1191 formatting.

  ## Returns
  - The Ethereum address with the appropriate checksum.

  ## Examples
      iex> EthAddressUtil.get_address_with_checksum("5e5b88defa1a412c69644cb47e68107d97807e35")
      "0x5E5b88DEfa1A412C69644CB47E68107d97807E35"
  """
  def get_address_with_checksum(addr, public_key_hashed, chain_id \\ nil) do
    unless valid_hex_address?(addr), do: raise "Invalid address: #{inspect addr}"

    if is_nil(chain_id) do
      eip55_address(addr, public_key_hashed)
    else
      eip1191_address(addr, public_key_hashed, chain_id)
    end
  end

  defp do_eip55ify(prefix, lower_hex, hash, _opts) do
    hash_hex = Base.encode16(hash, case: :lower)
    charlist = String.to_charlist(lower_hex)
    eip55_chars =
      Enum.with_index(charlist)
      |> Enum.map(fn {char, i} ->
        hash_byte =
          String.at(hash_hex, div(i, 1))
          |> hex_val()
        nibble = if rem(i, 2) == 0 do
          hash_byte >>> 4
        else
          hash_byte &&& 0x0f
        end

        if nibble >= 8 do
          to_upper(char)
        else
          char
        end
      end)

    prefix <> List.to_string(eip55_chars)
  end

  defp valid_hex_address?(addr) do
    clean = remove_0x_prefix(addr)
    String.length(clean) == 40 and String.match?(clean, ~r/^[A-Fa-f0-9]+$/)
  end

  defp remove_0x_prefix(str) do
    if String.starts_with?(str, "0x"), do: String.slice(str, 2..-1//1), else: str
  end

  # convert single hex digit => integer
  defp hex_val(nil), do: 0
  defp hex_val(<<digit>>) when digit in ?0..?9, do: digit - ?0
  defp hex_val(<<digit>>) when digit in ?a..?f, do: 10 + (digit - ?a)
  defp hex_val(<<digit>>) when digit in ?A..?F, do: 10 + (digit - ?A)
  defp hex_val(_), do: 0

  defp to_upper(ch) when ch in ?a..?z, do: ch - 32
  defp to_upper(ch), do: ch
end
