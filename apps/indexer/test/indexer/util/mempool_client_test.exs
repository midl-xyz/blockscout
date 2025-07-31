defmodule Indexer.Util.MempoolClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias Indexer.Util.MempoolClient

  setup :verify_on_exit!

  # Set up mock HTTP adapter for testing
  setup do
    # Store original adapter
    original_adapter = Application.get_env(:explorer, :http_adapter)

    # Set test adapter
    Application.put_env(:explorer, :http_adapter, Explorer.Mox.HTTPoison)

    # Restore original adapter after test
    on_exit(fn ->
      if original_adapter do
        Application.put_env(:explorer, :http_adapter, original_adapter)
      else
        Application.delete_env(:explorer, :http_adapter)
      end
    end)

    :ok
  end

  describe "get_btc_address_from_mempool/1" do
    test "returns nil for invalid tx hash" do
      assert MempoolClient.get_btc_address_from_mempool("invalid_hash") == nil
    end

    test "returns nil for nil input" do
      assert MempoolClient.get_btc_address_from_mempool(nil) == nil
    end

    test "successfully parses mempool response and extracts BTC address" do
      # Mock successful mempool API response with real transaction data
      tx_hash = "2553e613f8caa0e0aab0f2769998437682812e440d6daabbc6d64ce47a47950f"
      expected_address = "bcrt1qarjm3c8stzh748498wcu6qk0qzfsn7s86qs4nk"

      mempool_response = %{
        "txid" => "2553e613f8caa0e0aab0f2769998437682812e440d6daabbc6d64ce47a47950f",
        "version" => 2,
        "locktime" => 0,
        "vin" => [
          %{
            "txid" => "2a3b0aba7d282aec466b7079477f861d5b75cfab311115ef4aa09a5bab877118",
            "vout" => 0,
            "prevout" => %{
              "scriptpubkey" => "0014e8e5b8e0f058afea9ea53bb1cd02cf009309fa07",
              "scriptpubkey_asm" => "OP_0 OP_PUSHBYTES_20 e8e5b8e0f058afea9ea53bb1cd02cf009309fa07",
              "scriptpubkey_type" => "v0_p2wpkh",
              "scriptpubkey_address" => expected_address,
              "value" => 24000
            },
            "scriptsig" => "",
            "scriptsig_asm" => "",
            "witness" => [
              "304402207fa1f710b8d28ba0c9dc1916d9ed1f0d796517af5622d276ba15311286fe7d6a0220378f979d77da451054c9df20c0db23cad96388550d4e6e284bdc0cfd5719bc0301",
              "0225c757e139e37b46769e45fed93d361587492c2fb8b70c70877772b8a4028751"
            ],
            "is_coinbase" => false,
            "sequence" => 4294967295
          }
        ],
        "vout" => [
          %{
            "scriptpubkey" => "0014d53b4f2bfa9f9800040164c783060753e89e0b09",
            "scriptpubkey_asm" => "OP_0 OP_PUSHBYTES_20 d53b4f2bfa9f9800040164c783060753e89e0b09",
            "scriptpubkey_type" => "v0_p2wpkh",
            "scriptpubkey_address" => "bcrt1q65a572l6n7vqqpqpvnrcxps8205fuzcfr0gmew",
            "value" => 3656
          },
          %{
            "scriptpubkey" => "0014e8e5b8e0f058afea9ea53bb1cd02cf009309fa07",
            "scriptpubkey_asm" => "OP_0 OP_PUSHBYTES_20 e8e5b8e0f058afea9ea53bb1cd02cf009309fa07",
            "scriptpubkey_type" => "v0_p2wpkh",
            "scriptpubkey_address" => expected_address,
            "value" => 19892
          }
        ],
        "size" => 222,
        "weight" => 561,
        "sigops" => 1,
        "fee" => 452,
        "status" => %{
          "confirmed" => true,
          "block_height" => 26517,
          "block_hash" => "16146fad542731fc2bd93d899f26c16770f6b828ee66ec9db628c9f376080e4a",
          "block_time" => 1753894235
        }
      }

      # Set up mock expectation for HTTP call
      Explorer.Mox.HTTPoison
      |> expect(:get, fn url, headers, opts ->
        # Verify the URL is constructed correctly
        assert String.contains?(url, "/api/tx/#{tx_hash}")
        assert headers == [{"Content-Type", "application/json"}]
        assert opts == [recv_timeout: 30_000]

        {:ok, %HTTPoison.Response{
          status_code: 200,
          body: Jason.encode!(mempool_response)
        }}
      end)

      # Test the function
      result = MempoolClient.get_btc_address_from_mempool(tx_hash)

      # Verify correct BTC address is extracted
      assert result == expected_address
    end

    test "returns nil when mempool API returns 404" do
      tx_hash = "nonexistent_hash"

      Explorer.Mox.HTTPoison
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %HTTPoison.Response{
          status_code: 404,
          body: "Transaction not found"
        }}
      end)

      result = MempoolClient.get_btc_address_from_mempool(tx_hash)
      assert result == nil
    end

    test "returns nil when mempool API returns invalid JSON" do
      tx_hash = "some_hash"

      Explorer.Mox.HTTPoison
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %HTTPoison.Response{
          status_code: 200,
          body: "invalid json response"
        }}
      end)

      result = MempoolClient.get_btc_address_from_mempool(tx_hash)
      assert result == nil
    end

    test "returns nil when transaction has no inputs" do
      tx_hash = "coinbase_tx_hash"

      mempool_response = %{
        "txid" => tx_hash,
        "vin" => [],
        "vout" => []
      }

      Explorer.Mox.HTTPoison
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %HTTPoison.Response{
          status_code: 200,
          body: Jason.encode!(mempool_response)
        }}
      end)

      result = MempoolClient.get_btc_address_from_mempool(tx_hash)
      assert result == nil
    end

    test "returns nil when first input has no prevout" do
      tx_hash = "malformed_tx_hash"

      mempool_response = %{
        "txid" => tx_hash,
        "vin" => [
          %{
            "txid" => "some_hash",
            "vout" => 0
            # Missing prevout
          }
        ],
        "vout" => []
      }

      Explorer.Mox.HTTPoison
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %HTTPoison.Response{
          status_code: 200,
          body: Jason.encode!(mempool_response)
        }}
      end)

      result = MempoolClient.get_btc_address_from_mempool(tx_hash)
      assert result == nil
    end

    test "returns nil when prevout has no scriptpubkey_address" do
      tx_hash = "incomplete_tx_hash"

      mempool_response = %{
        "txid" => tx_hash,
        "vin" => [
          %{
            "txid" => "some_hash",
            "vout" => 0,
            "prevout" => %{
              "scriptpubkey" => "0014e8e5b8e0f058afea9ea53bb1cd02cf009309fa07",
              "value" => 24000
              # Missing scriptpubkey_address
            }
          }
        ],
        "vout" => []
      }

      Explorer.Mox.HTTPoison
      |> expect(:get, fn _url, _headers, _opts ->
        {:ok, %HTTPoison.Response{
          status_code: 200,
          body: Jason.encode!(mempool_response)
        }}
      end)

      result = MempoolClient.get_btc_address_from_mempool(tx_hash)
      assert result == nil
    end

    test "returns nil when HTTP request fails" do
      tx_hash = "network_error_hash"

      Explorer.Mox.HTTPoison
      |> expect(:get, fn _url, _headers, _opts ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      result = MempoolClient.get_btc_address_from_mempool(tx_hash)
      assert result == nil
    end
  end
end
