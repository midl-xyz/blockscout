defmodule Explorer.Repo do
  use Ecto.Repo,
    otp_app: :explorer,
    adapter: Ecto.Adapters.Postgres

  require Logger

  alias Explorer.Repo.ConfigHelper

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    ConfigHelper.init_repo_module(__MODULE__, opts)
  end

  def logged_transaction(fun_or_multi, opts \\ []) do
    transaction_id = :erlang.unique_integer([:positive])

    Explorer.Logger.metadata(
      fn ->
        {microseconds, value} = :timer.tc(__MODULE__, :transaction, [fun_or_multi, opts])

        milliseconds = div(microseconds, 100) / 10.0
        Logger.debug(["transaction_time=", :io_lib_format.fwrite_g(milliseconds), ?m, ?s])

        value
      end,
      transaction_id: transaction_id
    )
  end

  @doc """
  Chunks elements into multiple `insert_all`'s to avoid DB driver param limits.

  *Note:* Should always be run within a transaction as multiple inserts may occur.
  """
  def safe_insert_all(kind, elements, opts) do
    returning = opts[:returning]

    elements
    |> Enum.chunk_every(500)
    |> Enum.reduce({0, []}, fn chunk, {total_count, acc} ->
      {count, inserted} =
        try do
          insert_all(kind, chunk, opts)
        rescue
          exception ->
            old_truncate = Application.get_env(:logger, :truncate)
            Logger.configure(truncate: :infinity)

            Logger.error(fn ->
              [
                "Could not insert all of chunk into ",
                to_string(kind),
                " using options because of error.\n",
                "\n",
                "Chunk Size: ",
                chunk |> length() |> to_string(),
                "\n",
                "Chunk:\n",
                "\n",
                inspect(chunk, limit: :infinity, printable_limit: :infinity),
                "\n",
                "\n",
                "Options:\n",
                "\n",
                inspect(opts),
                "\n",
                "\n",
                "Exception:\n",
                "\n",
                Exception.format(:error, exception, __STACKTRACE__)
              ]
            end)

            Logger.configure(truncate: old_truncate)

            # reraise to kill caller
            reraise exception, __STACKTRACE__
        end

      if returning do
        {count + total_count, acc ++ inserted}
      else
        {count + total_count, nil}
      end
    end)
  end

  def stream_in_transaction(query, fun) when is_function(fun, 1) do
    transaction(
      fn ->
        query
        |> stream(timeout: :infinity)
        |> fun.()
      end,
      timeout: :infinity
    )
  end

  def stream_each(query, fun) when is_function(fun, 1) do
    stream_in_transaction(query, &Enum.each(&1, fun))
  end

  def stream_reduce(query, initial, reducer) when is_function(reducer, 2) do
    stream_in_transaction(query, &Enum.reduce(&1, initial, reducer))
  end

  if Mix.env() == :test do
    def replica, do: __MODULE__
  else
    def replica, do: Explorer.Repo.Replica1
  end

  def account_repo, do: Explorer.Repo.Account

  defmodule Replica1 do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres,
      read_only: true

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Account do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Midl do
    use Ecto.Repo,
        otp_app: :explorer,
        adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Optimism do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule PolygonEdge do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule PolygonZkevm do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule ZkSync do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Celo do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule RSK do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Shibarium do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Suave do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Beacon do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Arbitrum do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule BridgedTokens do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Filecoin do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Stability do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule Mud do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end

  defmodule ShrunkInternalTransactions do
    use Ecto.Repo,
      otp_app: :explorer,
      adapter: Ecto.Adapters.Postgres

    def init(_, opts) do
      ConfigHelper.init_repo_module(__MODULE__, opts)
    end
  end
end
