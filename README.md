MonHandler - Monitored Event Handler
==========

This is a minimal `GenServer` module that is used to monitor an event handler.

To use simply call `add_mon_handler` or `start_link` with the `GenEvent` event manager, event handler and args for your event handler. Optionally you can also pass arguments for the `MonHandler` `GenServer`.

`MonHanlder` will handle messages from the event manager if the event handler terminates. For normal terminations `MonHandler` will stop. For terminations due to errors `MonHandler` will re-add the event handler to the event manager.

### Use Cases

Basic:
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
Starting with a supervisor
```elixir
mon_handler_config = MonHandler.get_config(manager, YourEventHandler, event_handler_args)
supervise([worker(MonHandler, [mon_handler_config, []])], [strategy: :one_for_one])
```

If you want to use MonHandler for multiple handlers within a single app you will need to give each an `id` when adding them to the supervisor.
```elixir
supervise(
  [
    worker(
      MonHandler,
      [
        MonHandler.get_config(:manager_one, YourEventHandler, []),
        []
      ],
      [id: :first_handler]
    ),
    worker(
      MonHandler,
      [
        MonHandler.get_config(:manager_two, YourSecondEventHandler, []),
        []
      ],
      [id: :second_handler]
    )
  ],
  [strategy: :one_for_one]
)
```
