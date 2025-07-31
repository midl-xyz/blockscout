defmodule Indexer.Util.MempoolClient do
  @moduledoc """
  Client for interacting with Mempool API to fetch Bitcoin transaction details
  and extract BTC addresses from transaction inputs.
  """

  require Logger

  @doc """
  Fetches BTC address from mempool API by looking up the transaction
  and extracting the scriptpubkey_address from the first input's prevout.

  Returns the BTC address string or nil if not found/error occurs.
  """
  def get_btc_address_from_mempool(btc_tx_hash) when is_binary(btc_tx_hash) do
    Logger.info("MempoolClient: Fetching BTC address for tx_hash: #{btc_tx_hash}")

    case fetch_transaction_from_mempool(btc_tx_hash) do
      {:ok, transaction_data} ->
        Logger.debug("MempoolClient: Successfully fetched transaction data for #{btc_tx_hash}")
        result = extract_btc_address_from_transaction(transaction_data)
        Logger.info("MempoolClient: Extracted BTC address: #{inspect(result)} for tx_hash: #{btc_tx_hash}")
        result

      {:error, reason} ->
        Logger.warning("MempoolClient: Failed to fetch transaction #{btc_tx_hash} from mempool: #{inspect(reason)}")
        nil
    end
  end

  def get_btc_address_from_mempool(_), do: nil

  @doc """
  Fetches transaction data from mempool API.
  """
  defp fetch_transaction_from_mempool(btc_tx_hash) do
    base_url = mempool_base_url()
    url = "#{base_url}/api/tx/#{btc_tx_hash}"
    Logger.debug("MempoolClient: Making HTTP request to: #{url}")

    headers = [
      {"Content-Type", "application/json"}
    ]

    http_adapter = Application.get_env(:explorer, :http_adapter, HTTPoison)

    case http_adapter.get(url, headers, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.debug("MempoolClient: Received 200 response, body length: #{String.length(body)}")
        case Jason.decode(body) do
          {:ok, transaction_data} ->
            Logger.debug("MempoolClient: Successfully decoded JSON response")
            # Log the transaction structure for debugging
            Logger.debug("MempoolClient: Transaction vin count: #{length(Map.get(transaction_data, "vin", []))}")
            if length(Map.get(transaction_data, "vin", [])) > 0 do
              first_vin = List.first(Map.get(transaction_data, "vin", []))
              Logger.debug("MempoolClient: First vin structure: #{inspect(Map.keys(first_vin))}")
              if Map.has_key?(first_vin, "prevout") do
                prevout = Map.get(first_vin, "prevout")
                Logger.debug("MempoolClient: Prevout structure: #{inspect(Map.keys(prevout))}")
                if Map.has_key?(prevout, "scriptpubkey_address") do
                  address = Map.get(prevout, "scriptpubkey_address")
                  Logger.debug("MempoolClient: Found scriptpubkey_address: #{address}")
                else
                  Logger.warning("MempoolClient: No scriptpubkey_address in prevout")
                end
              else
                Logger.warning("MempoolClient: No prevout in first vin")
              end
            end
            {:ok, transaction_data}
          {:error, decode_error} ->
            Logger.error("MempoolClient: Failed to decode JSON response: #{inspect(decode_error)}")
            {:error, "Failed to decode JSON response: #{inspect(decode_error)}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.warning("MempoolClient: HTTP error #{status_code}, body: #{String.slice(body, 0, 200)}")
        {:error, "HTTP #{status_code}: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("MempoolClient: HTTP request failed: #{inspect(reason)}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Extracts BTC address from transaction data by looking at the first input's prevout.scriptpubkey_address.
  """
  defp extract_btc_address_from_transaction(%{"vin" => [first_input | _]}) do
    Logger.debug("MempoolClient: Extracting address from first input: #{inspect(first_input)}")
    case first_input do
      %{"prevout" => %{"scriptpubkey_address" => address}} when is_binary(address) ->
        Logger.info("MempoolClient: Successfully extracted BTC address: #{address}")
        address
      %{"prevout" => prevout} ->
        Logger.warning("MempoolClient: No scriptpubkey_address found in prevout. Available keys: #{inspect(Map.keys(prevout))}")
        nil
      _ ->
        Logger.warning("MempoolClient: No prevout found in first input. Available keys: #{inspect(Map.keys(first_input))}")
        nil
    end
  end

  defp extract_btc_address_from_transaction(%{"vin" => []}) do
    Logger.warning("MempoolClient: Transaction has no inputs")
    nil
  end

  defp extract_btc_address_from_transaction(transaction_data) do
    Logger.warning("MempoolClient: Invalid transaction data format. Available keys: #{inspect(Map.keys(transaction_data))}")
    nil
  end

  @doc """
  Gets the mempool base URL from environment configuration.
  Raises an error if MEMPOOL_BASE_URL environment variable is not set.
  """
  defp mempool_base_url do
    case Application.get_env(:indexer, :mempool_base_url) do
      nil ->
        raise """
        MEMPOOL_BASE_URL environment variable is required but not set.
        Please set MEMPOOL_BASE_URL to your mempool API base URL (e.g., https://mempool.regtest.midl.xyz)
        """
      "" ->
        raise """
        MEMPOOL_BASE_URL environment variable is empty.
        Please set MEMPOOL_BASE_URL to your mempool API base URL (e.g., https://mempool.regtest.midl.xyz)
        """
      url ->
        url
    end
  end
end
