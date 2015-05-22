defmodule MonHandler do
  use GenServer

  @moduledoc """
  A minimal GenServer that monitors a given GenEvent handler.

  This server will handle exits of the Handler and attempt to re-add it
  to the manager when unexpected exits occur.

  Exits for :normal, :shutdown or :swapped reasons will not attempt a re-add to
  the manager.

  ## Usage
  ```elixir
  iex(x)> {:ok, manager} = GenEvent.start_link
  {:ok, #PID<X.X.X>}
  iex(x)> {:ok, mon_han} = MonHandler.add_mon_handler(manager, YourEventHandler, event_handler_args)
  {:ok, #PID<X.X.X>}
  ```

  With start_link

  ```elixir
  iex(x)> {:ok, manager} = GenEvent.start_link
  {:ok, #PID<X.X.X>}
  iex(x)> event_handler_args = []
  []
  iex(x)> config = MonHandler.get_config(manager, YourEventHandler, event_handler_args)
  [manager: #PID<X.X.X>, handler: YourEventHandler, args: []]
  iex(x)> {:ok, mon_han} = MonHandler.start_link(config, gen_server_opts)
  {:ok, #PID<X.X.X>}
  ```

  Within Supervisor
  ```elixir
  mgr_name = :event_manager
  config = MonHandler.get_config(mgr_name, YourEventHandler)

  children = [
    worker(GenEvent, [[name: mgr_name]]),
    worker(MonHandler, [config])
  ]

  opts = [strategy: :one_for_one, name: __MODULE__]

  supervise children, opts
  ```
  """

  @type config :: [manager: GenEvent.manager,
                   handler: GenEvent.handler,
                   args: term]

  @doc """
  Starts GenServer and adds event handler to the provided GenEvet event manager.

  This expects the same arguments as `GenEvent.add_mon_handler/3` and returns the
  same values as `GenServer.start_link/3`

  See `GenEvent.add_handler/3` and `GenEvent.add_mon_handler/3` for more information

  ## Usage
  ```elixir
  iex(x)> {:ok, manager} = GenEvent.start_link
  {:ok, #PID<X.X.X>}
  iex(x)> {:ok, mon_han} = MonHandler.add_mon_handler(manager, YourEventHandler, event_handler_args)
  {:ok, #PID<X.X.X>}
  ```
  """
  @spec add_mon_handler(GenEvent.manager, GenEvent.handler, term) :: GenServer.on_start
  def add_mon_handler(manager, event_handler, args \\ []) do
    start_link(get_config(manager, event_handler, args), [])
  end

  @doc """
  Given the #PID of an active `MonHandler` this will remove the monitored event handler
  from the event manager and stop the `MonHandler` `GenServer`. Arguments given in
  the second term will be passed to `GenEvent.remove_handler/3`

  ## Usage
  ```elixir
  iex(x)> {:ok, manager} = GenEvent.start_link
  {:ok, #PID<X.X.X>}
  iex(x)> {:ok, mon_han} = MonHandler.add_mon_handler(manager, YourEventHandler, event_handler_args)
  {:ok, #PID<X.X.X>}
  iex(x)> MonHandler.remove_handler(mon_han)
  :ok
  ```
  """
  @spec remove_handler(GenServer.server, term) :: term | {:error, term}
  def remove_handler(server, args \\ []) do
      GenServer.call(server, {:remove_handler, args})
  end

  @doc """
  Starts GenServer and adds event handler to the provided GenEvet event manager.

  This expects the same arguments as `GenEvent.add_mon_handler/3` plus options
  for the `GenServer` and returns the same values as `GenServer.start_link/3`

  See `GenEvent.add_handler/3` and `GenEvent.add_mon_handler/3` for more information

  ## Usage
  ```elixir
  iex(x)> {:ok, manager} = GenEvent.start_link
  {:ok, #PID<X.X.X>}
  iex(x)> event_handler_args = []
  []
  iex(x)> config = MonHandler.get_config(manager, YourEventHandler, event_handler_args)
  [manager: #PID<X.X.X>, handler: YourEventHandler, args: []]
  iex(x)> {:ok, mon_han} = MonHandler.start_link(config, gen_server_opts)
  {:ok, #PID<X.X.X>}
  ```
  """
  @spec start_link(config, GenServer.options) :: GenServer.on_start
  def start_link(config, opts \\ []) do
    GenServer.start_link(__MODULE__, config, opts)
  end

  @doc """
  Returns a config list from given values.

  ##Usage
  ```elixir
  iex(x)> config = MonHandler.get_config(manager, YourEventHandler)
  [manager: #PID<X.X.X>, handler: YourEventHandler, args: []]
  ```
  Or
  ```elixir
  iex(x)> config = MonHandler.get_config(manager, YourEventHandler, event_handler_args)
  [manager: #PID<X.X.X>, handler: YourEventHandler, args: []]
  ```
  """
  @spec get_config(GenEvent.manager, GenEvent.handler, term) :: config
  def get_config(manager, event_handler, args \\ []) do
    [manager: manager, handler: event_handler, args: args]
  end

  @doc false
  def init(config) do
    :ok = start_handler(config)
    {:ok, config}
  end

  @doc false
  def handle_info({:gen_event_EXIT, _handler, reason}, config)
    when reason in [:normal, :shutdown] do
    {:stop, reason, config}
  end

  @doc false
  def handle_info({:gen_event_EXIT, _handler, {:swapped, _new_handler, _pid}}, config) do
    {:stop, :handler_swapped, config}
  end

  @doc false
  def handle_info({:gen_event_EXIT, _handler, _reason}, config) do
    :ok = start_handler(config)
    {:noreply, config}
  end

  @doc false
  def handle_call({:remove_handler, args}, _from, config) do
    result = GenEvent.remove_handler(config[:manager], config[:handler], args)

    {:stop, :normal, result, config}
  end

  defp start_handler(config) do
    GenEvent.add_mon_handler(config[:manager], config[:handler], config[:args])
  end
end
