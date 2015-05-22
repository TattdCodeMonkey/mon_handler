defmodule MonHandlerTest do
  use ExUnit.Case

  import Mock

  test "add_mon_handler/2" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      MonHandler.add_mon_handler(mgr, handler)

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        args: []
      ], [])
    end
  end

  test "add_mon_handler/3" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]
      MonHandler.add_mon_handler(mgr, handler, args)

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        args: args
      ], [])
    end
  end

  test "remove_handler/1" do
    with_mock GenServer, [call: fn(_pid, _msg) -> :ok end] do
      result =  MonHandler.remove_handler(:server)

      assert called GenServer.call(:server, {:remove_handler, []})
      assert result == :ok
    end
  end

  test "remove_handler/2" do
    with_mock GenServer, [call: fn(_pid, _msg) -> :ok end] do
      result =  MonHandler.remove_handler(:server, [val: "argument"])

      assert called GenServer.call(:server, {:remove_handler, [val: "argument"]})
      assert result == :ok
    end
  end

  test "get_config/2" do
    mgr = :a_manager
    handler = :a_event_handler
    config = MonHandler.get_config(mgr,handler)

    assert config[:manager] == mgr
    assert config[:handler] == handler
  end

  test "get_config/3" do
    mgr = :a_manager
    handler = :a_event_handler
    args = [an_arg: :test]
    config = MonHandler.get_config(mgr,handler, args)

    assert config[:manager] == mgr
    assert config[:handler] == handler
    assert config[:args] == args
  end

  test "get_config/3 -> start_link/1" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]
      MonHandler.get_config(mgr,handler, args)
      |> MonHandler.start_link

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        args: args
      ], [])
    end
  end

  test "get_config/3 -> start_link/2" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]
      opts = [name: HandlerMonitor]

      MonHandler.get_config(mgr,handler, args)
      |> MonHandler.start_link opts

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        args: args
      ], opts)
    end
  end

  test "start_link/1" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]

      MonHandler.start_link([
        manager: mgr,
        handler: handler,
        args: args
      ])

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        args: args
      ], [])
    end
  end

  test "start_link/2" do
    with_mock GenServer, [start_link: fn(_mod, _args, _opts) -> {:ok, :a_pid} end] do
      mgr = :a_manager
      handler = :a_event_handler
      args = [an_arg: :test]
      opts = [name: HandlerMonitor]

      MonHandler.start_link([
        manager: mgr,
        handler: handler,
        args: args
      ], opts)

      assert called GenServer.start_link(MonHandler, [
        manager: mgr,
        handler: handler,
        args: args
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
        args: args
      ]
      MonHandler.init([
        manager: mgr,
        handler: handler,
        args: args
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
        args: args
      ]

      result = MonHandler.handle_info({:gen_event_EXIT, AnEventHandler, {{:an_error, "1234"}, []}}, config)

      assert result == {:noreply, config}

      assert called GenEvent.add_mon_handler(mgr, handler, args)
    end
  end

  test "handle_call - remove_handler" do
    with_mock GenEvent, [remove_handler: fn(_mgr, _hnd, _args) -> :ok end] do
      mgr = :a_manager
      handler = AnEventHandler
      args = [an_arg: :test]

      config = [
        manager: mgr,
        handler: handler,
        args: []
      ]
      result = MonHandler.handle_call({:remove_handler, args},:a_pid, config)

      assert result == {:stop, :normal, :ok, config}

      assert called GenEvent.remove_handler(mgr, handler, args)
    end
  end
end
