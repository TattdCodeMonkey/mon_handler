defmodule MonHandler do
  use GenServer

  @moduledoc """
  A minimal GenServer that monitors a given GenEvent handler.

  This server will handle exits of the Handler and attempt to re-add it
  to the manager when unexpected exits occur.

  Exits for :normal, :shutdown or :swapped reasons will not attempt a re-add to
  the manager.
  """

  @doc """

  """
  @spec add_mon_handler(GenEvent.manager, GenEvent.handler, term) :: GenServer.on_start
  def add_mon_handler(manager, event_handler, args \\ []) do
    start_link(manager, event_handler, args, [])
  end

  @spec remove_handler(GenServer.server, term) :: term | {:error, term}
  def remove_handler(server, args \\ []) do
      GenServer.call(server, {:remove_handler, args})
  end

  @doc """

  """
  @spec start_link(GenEvent.manager, GenEvent.handler, term) :: GenServer.on_start
  def start_link(manager, event_handler, args \\ []) do
    start_link(manager, event_handler, args, [])
  end

  @doc """

  """
  @spec start_link(GenEvent.manager, GenEvent.handler, term, Keyword.t) :: GenServer.on_start
  def start_link(manager, event_handler, args, opts) do
    GenServer.start_link(__MODULE__, [manager: manager, handler: event_handler, handler_args: args, opts: opts], opts)
  end

  def init(config) do
    :ok = start_handler(config)
    {:ok, config}
  end

  def handle_info({:gen_event_EXIT, _handler, reason}, config)
    when reason in [:normal, :shutdown] do
    {:stop, reason, config}
  end

  def handle_info({:gen_event_EXIT, _handler, {:swapped, new_handler, pid}}, config) do
    {:stop, :handler_swapped, config}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, config) do
    :ok = start_handler(config)
    {:noreply, config}
  end

  def handle_call({:remove_handler, args}, _from, config) do
    result = GenEvent.remove_handler(config[:manager], config[:handler], args)
    
    {:stop, :normal, result, config}
  end

  defp start_handler(config) do
    GenEvent.add_mon_handler(config[:manager], config[:handler], config[:handler_args])
  end
end
