# lua_async
This project aims to provide an API similar to the Node.js Event loop - for Lua, fully written in Lua itself. It works with Lua 5.1, but will be ported to work with 5.3.3 in the future.
Note that the goal is not to clone the Node Event loop exactly.
This is already fully usable, but some features are missing (Events, EventTargets, some Promise methods) and will be implemented in the near future.
It also provides a few useful extra methods.

## Current features
Current features are: timeouts, intervals, immediates, promises, async-await.

## Using this in your project

If you want to use this with minetest, a wrapper exists speficially for this purpose: https://github.com/EliasFleckenstein03/lua_async_mt

If you want to integrate this into your own project, note these things:
- lua_async does not take over the main thread. Rather, you have to call `lua_async.step(dtime)` everytime you want the event loop to execute, with `dtime` being the time in seconds since `lua_async.step` has been called the last time. If you want lua_async to take over the main thread, simply call `lua_async.run()`. This will execute the event loop in a `while true` loop.
- To initialize lua_async, require / dofile the init.lua. This returns a function; call this function with the path where the lua_async source code is located.

## API

### The loop

The event loop is pretty simple:
1. Execute timeouts
2. Execute intervals
3. Execute immediates

### Important notice
You will often see the symbol `...` which stands for Lua varargs. Note that even tho these can technically include `nil`, when using this API they never should, since the API does not support it. The same goes for things passed to Promise resolve functions, then or catch return values, or things returned or handed to async functions. There is just no good way to handle it in plain Lua (or at least I don't know one).

### Timeouts

Timeouts are the first thing to be processed every step. After registered, they execute once their time is elapsed, and only one time.

#### `id = setTimeout(callback, [ms, ...])`
Registers a new timeout that will execute after `ms` milliseconds. If `ms` is not specified or `nil`, the timeout executes after 0 milliseconds, meaning it will execute in the next step. If a timeout is registered while timeouts are processing, it will be processed in the next step. The timer starts in the step the timeout was registered, meaning that it will execute not exactly `ms` milliseconds after registration, but rather `ms` milliseconds after the step in which it was registered started. `...` are the arguments passed to the `callback` function that is called when the timeout executes. `setTimeout` returns an unique numeric timeout ID that can be passed to `clearTimeout`. If `ms` is not numeric, an error is raised. `ms` being negative has the same effect as it being zero. If `callback` is not a function, an error is raised when the timeout elapses.

#### `clearTimeout(id)`
This function takes an ID of an existing timeout that has not executed yet and cancels it, meaning it will not execute. If `id` is not numeric, not a valid timeout id or the associated timeout has expired or already been cleared, `clearTimeout` does nothing. `id` may however not be `nil`. `clearTimeout` may be called on any timeout at any time, if timeouts are currently processing the cleared timeout is removed from the list of timeouts to process.

### Interval

Intervals are processed every step after timeouts have been processed. An interval is called every time a certain time elapsed, or every step.

#### `id = setInterval(callback, [ms, ...])`
Registers a new interval that will execute every `ms` milliseconds. If `ms` is not specified or `nil`, the timeout every after 0 milliseconds, meaning it will execute every step. If an interval is registered while intervals are processing, it will be executed in the next step. However, if an interval is registered by a timeout callback, the interval _will_ process in the same step in which it was registered. The timer starts in the step the interval was registered, meaning that it will execute not exactly `ms` milliseconds after registration for the first time, but rather `ms` milliseconds after the step in which it was registered started. `...` are the arguments passed to the `callback` function that is called every time the interval executes. `setInterval` returns an unique numeric interval ID that can be passed to `clearInterval`. If `ms` is not numeric, an error is raised. `ms` being negative has the same effect as it being zero. If `callback` is not a function, an error is raised every time the interval is executed. There is no sort of "catch up" mechanic. If an interval is set to 50ms and a step takes 100ms, it is will still execute only once in the next step.

#### `clearInterval(id)`
This function takes an ID of an existing interval and removes it, meaning it will not execute anymore. If `id` is not numeric, not a valid interval id or the associated interval has already been cleared, `clearInterval` does nothing. `id` may however not be `nil`. `clearInterval` may be called on any interval at any time, including the callback of the interval itself, if intervals are currently processing the cleared interval is removed from the list of intervals to process.

### Immediates

Immediates are processed every step after timeouts and intervals have been processed. An immediated is executed only once.

#### `id = setImmediate(callback, [...])`
Registers a new interval that will execute once in the current or the next step, depending on when it is registered. If an immediate is registered while immediates are processing, it will be executed in the next step. However, if an interval is registered by a timeout or interval callback, the immediate _will_ process in the same step in which it was registered. `...` are the arguments passed to the `callback` function that is called when the immediate executes. `setImmediate` returns an unique numeric immediate ID that can be passed to `clearImmediate`. If `callback` is not a function, an error is raised when the immediate is executed.

#### `clearImmediate(id)`
This function takes an ID of an existing immediate and cancels it, meaning it will not execute. If `id` is not numeric, not a valid immediate id or the associated immediate has already executed or been cleared, `clearImmediate` does nothing. `id` may however not be `nil`. `clearImmediate` may be called on any immediate at any time, if immediates are currently processing the cleared immediate is removed from the list of immediates to process.
