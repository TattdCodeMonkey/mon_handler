defmodule MonHandler do
  require Logger
  use GenServer

  @moduledoc """
  A minimal GenServer that monitors a given GenEvent handler.

  This server will handle exits of the Handler and attempt to readd it
  to the manager when unexpected exits occur.

  Exits for :normal, :shutdown and :swapped reasons will not attempt readds to
  the manager.
  """

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
    Logger.warn("Stopping MonHandler for #{inspect config[:handler]}, handler has been swapped on manager for #{inspect new_handler} @ #{inspect pid}")
    {:stop, :handler_swapped, config}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, config) do
    Logger.info("MonHandler restarting handler #{inspect config[:handler]} on manager #{inspect config[:manager]} due to handler exit for error")
    :ok = start_handler(config)
    {:noreply, config}
  end

  defp start_handler(config) do
    GenEvent.add_mon_handler(config[:manager], config[:handler], config[:handler_args])
  end
end
