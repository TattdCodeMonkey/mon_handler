MonHandler - Monitored Event Handler
==========

This is a minimal `GenServer` module that is used to monitor an event handler.

To use simply call `add_mon_handler` or `start_link` with the `GenEvent` event manager, event handler and args for your event handler. Optionally you can also pass arguments for the `MonHandler` `GenServer`.

```elixir
iex(x)> {:ok, manager} = GenEvent.start_link
{:ok, #PID<X.Y.Z>}
iex(x)> {:ok, mon_han} = MonHandler.start_link(manager, YourEventHandler, event_handler_args, gen_server_args)
{:ok, #PID<X.Y.Z>}
iex(x)> GenEvent.notify(manager, {:your_event, "some data"})
:ok
iex(x)> MonHandler.remove_handler(mon_han)
:ok  
```

`MonHanlder` will handle messages from the event manager if the event handler terminates. For normal terminations `MonHandler` will stop. For terminations due to errors `MonHandler` will re-add the event handler to the event manager.
