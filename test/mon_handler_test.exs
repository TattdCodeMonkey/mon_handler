defmodule MonHandlerTest do
  use ExUnit.Case

  import Mock

  test "start_link/2" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      MonHandler.start_link(mgr, handler)

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        handler_args: [],
        opts: []
      ], [])
    end
  end

  test "start_link/3" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]
      MonHandler.start_link(mgr, handler, args)

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        handler_args: args,
        opts: []
      ], [])
    end
  end

  test "start_link/4" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]
      opts = [name: HandlerMonitor]
      MonHandler.start_link(mgr, handler, args, opts)

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        handler_args: args,
        opts: opts
      ], opts)
    end
  end

  test "init/1" do
    with_mock GenEvent, [add_mon_handler: fn(_mgr, _hnd, _args) -> :ok end] do
      mgr = :a_manager
      handler = AnEventHandler
      args = [an_arg: :test]

      config = [
        manager: mgr,
        handler: handler,
        handler_args: args,
        opts: []
      ]
      MonHandler.init([
        manager: mgr,
        handler: handler,
        handler_args: args,
        opts: []
      ])

      assert called GenEvent.add_mon_handler(mgr, handler, args)
    end
  end

  test "handle_info - normal" do
    result = MonHandler.handle_info({:gen_event_EXIT, AnEventHandler, :normal},[])

    assert result == {:stop, :normal, []}
  end

  test "handle_info - shutdown" do
    result = MonHandler.handle_info({:gen_event_EXIT, AnEventHandler, :shutdown},[])

    assert result == {:stop, :shutdown, []}
  end

  test "handle_info - swapped" do
    result = MonHandler.handle_info({:gen_event_EXIT, AnEventHandler, {:swapped, NewHandler, :mock_pid}},[])

    assert result == {:stop, :handler_swapped, []}
  end

  test "handle_info - error" do
    with_mock GenEvent, [add_mon_handler: fn(_mgr, _hnd, _args) -> :ok end] do
      mgr = :a_manager
      handler = AnEventHandler
      args = [an_arg: :test]

      config = [
        manager: mgr,
        handler: handler,
        handler_args: args,
        opts: []
      ]

      result = MonHandler.handle_info({:gen_event_EXIT, AnEventHandler, {{:an_error, "1234"}, []}}, config)

      assert result == {:noreply, config}

      assert called GenEvent.add_mon_handler(mgr, handler, args)
    end
  end
end
