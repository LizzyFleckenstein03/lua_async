# lua_async
This project aims to provide an API similar to the Node.js Event loop - for Lua, fully written in Lua itself. It is tested with Lua 5.1 and Lua 5.3.3, but should probably work with any Lua 5.x.
Note that the goal is not to clone the Node Event loop exactly.
This is already fully usable, but some features are missing (Events, EventTargets, some Promise methods) and will be implemented in the near future.
It also provides a few useful extra methods as well as basic scheduling.

## Current features
Current features are: timeouts, intervals, immediates, promises, async-await.

## Using this in your project

If you want to use this with minetest, a wrapper exists speficially for this purpose: https://github.com/EliasFleckenstein03/lua_async_mt

If you want to integrate this into your own project, note these things:
- lua_async does not take over the main thread. Rather, you have to call `lua_async.step(dtime)` everytime you want the event loop to execute, with `dtime` being the time in seconds since `lua_async.step` has been called the last time. If you want lua_async to take over the main thread, simply call `lua_async.run()`. This will execute the event loop in a `while true` loop.
- To initialize lua_async, require / dofile the init.lua. This returns a function; call this function with the path where the lua_async source code is located.

## API

To take advantage of this API, you should probably know some JavaScript. However this is not required; Timeouts, Intervals, Immediates, Utility functions and Limiting are explained in a way that they can be understood without any extra knowledge; for Promises and async-await links to JS docs are provided since async-await / promises are really not trivial.

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

#### Examples
```lua
function print_something(str, number)
	print(str .. " " .. number)
end

setTimeout(print_something, 2000, "hello", 5) -- will print "hello 5" in 2 seconds

setTimeout(function()
	print("a timeout without ms argument")
end) -- will print "a timeout without ms argument" in the next step

local to = setTimeout(function()
	print("i will never print")
end, 500)

clearTimeout(to) -- cancels the to timeout, nothing is printed
```

### Intervals

Intervals are processed every step after timeouts have been processed. An interval is called every time a certain time elapsed, or every step.

#### `id = setInterval(callback, [ms, ...])`
Registers a new interval that will execute every `ms` milliseconds. If `ms` is not specified or `nil`, the timeout every after 0 milliseconds, meaning it will execute every step. If an interval is registered while intervals are processing, it will be executed in the next step. However, if an interval is registered by a timeout callback, the interval _will_ process in the same step in which it was registered. The timer starts in the step the interval was registered, meaning that it will execute not exactly `ms` milliseconds after registration for the first time, but rather `ms` milliseconds after the step in which it was registered started. `...` are the arguments passed to the `callback` function that is called every time the interval executes. `setInterval` returns an unique numeric interval ID that can be passed to `clearInterval`. If `ms` is not numeric, an error is raised. `ms` being negative has the same effect as it being zero. If `callback` is not a function, an error is raised every time the interval is executed. There is no sort of "catch up" mechanic. If an interval is set to 50ms and a step takes 100ms, it is will still execute only once in the next step.

#### `clearInterval(id)`
This function takes an ID of an existing interval and removes it, meaning it will not execute anymore. If `id` is not numeric, not a valid interval id or the associated interval has already been cleared, `clearInterval` does nothing. `id` may however not be `nil`. `clearInterval` may be called on any interval at any time, including the callback of the interval itself, if intervals are currently processing the cleared interval is removed from the list of intervals to process.

### Immediates

Immediates are processed every step after timeouts and intervals have been processed. An immediate is executed only once.

#### `id = setImmediate(callback, [...])`
Registers a new immediate that will execute once in the current or the next step, depending on when it is registered. If an immediate is registered while immediates are processing, it will be executed in the next step. However, if an immediate is registered by a timeout or interval callback, the immediate _will_ process in the same step in which it was registered. `...` are the arguments passed to the `callback` function that is called when the immediate executes. `setImmediate` returns an unique numeric immediate ID that can be passed to `clearImmediate`. If `callback` is not a function, an error is raised when the immediate is executed.

#### `clearImmediate(id)`
This function takes an ID of an existing immediate and cancels it, meaning it will not execute. If `id` is not numeric, not a valid immediate id or the associated immediate has already executed or been cleared, `clearImmediate` does nothing. `id` may however not be `nil`. `clearImmediate` may be called on any immediate at any time, if immediates are currently processing the cleared immediate is removed from the list of immediates to process.

### Promises

For an understanding of what promises are, please read https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise .
The promise API differs a bit from JavaScript, but the concept is the same.
If you look at the implementation of promises, you'll notice some methods and attributes in PromisePrototype that start with `__` and are not documented here. This is because they are internal methods / attributes and should not be used directly.

#### `promise = Promise([function(resolve, reject)])`
Equivalent of JS `new Promise()`. Returns a new pending promise. Unlike in JavaScript, the Promise resolver (argument passed to Promise()) may be nil and you can pass multiple values to `resolve(...)`.

#### `promise.state`
The current state of the promise ("pending" | "resolved" | "rejected")

#### `promise.values`
Only present in resolved promises. The arguments passed to the `resolve` function.

#### `promise.reason`
Only present in rejected promises. The argument passed to the `reject` function or the error that caused the promise to fail.

#### `promise:then_(success, [fail])`
Equivalent of JS `promise.then()`. Since `then` is a reserved keyword in Lua the underscore was added. Returns a new Promise that calls `fail` if the parent is rejected without the error being caught and `success` if the parent resolves. Unlike JavaScript, the `success` callback can recieve and return multiple values. `fail` is optional. No error is thrown if `success` is not omitted, so technically that is optional as well.

#### `promise:catch(fail)`
Equivalent of JS `promise.catch()`. Same as `promise:then_()` but only with the `fail` callback.

#### `promise:resolve(...)`
May only be called on pending promises.
This is a method not present in JavaScript that has the same effect as calling the `resolve` function that is passed to the Promise resolver (Promise resolver = argument passed to Promise())

#### `promise:reject(reason)`
May only be called on pending promises.
This is a method not present in JavaScript that has the same effect as calling the `reject` function that is passed to the Promise resolver (Promise resolver = argument passed to Promise())

#### `promise = Promise.resolve(...)`
Returns a new promise that is resolved with `...` as values.

### Utility functions

#### `lua_async.yield()`
Must be called from an async function.
Yields the current thread and resumes its execution in the next (if called by an immediate) or current step (if called by an timeout or interval). This uses an immediate internally.

#### `lua_async.sleep(ms)`
Must be called from an async function.
Sleeps for `ms` milliseconds and then resumes execution of the current thread. This uses a timeout internally.

#### `lua_async.kill_thread()`
Must be called from an async function.
Kills the current thread. This function _never returns_.

#### `lua_async.resume(thread)`
This function should only be used internally.
Resumes execution of the thread `thread` and cleans up limiting data once finished. Also makes sure that if an error occurs it is thrown in the parent thread.

#### `lua_async.run()`
Takes over the current thread and runs the event loop in a `while true` loop. It is highly recommended to only call this from the main thread, since async-old code being called from non-async functions cannot be detected otherwise.

### Limiting

Limiting can be used for basic scheduling. The way it works is that you can set a limit (in milliseconds) for the maximum time the current thread should get during each step. This way you can have a `while true` loop in your thread (or anything else that blocks for a longer time or ever forever) without disturbing the event loop. **Please note:** limits estimate the CPU time of the program, not the time the current thread was actually busy. If you `await` something or `sleep` / `yield`, the time that passed during the pause still counts.

#### lua_async.set_limit(ms)
Must be called from an async function.
Sets the limit (in milliseconds) for the current thread.

#### lua_async.unset_limit()
Must be called from an async function.
Removes the limit from the current thread.

#### lua_async.check_limit()
This function must be called every time you are ready for being interrupted. Only when this function is called the current thread may pause due to an exceeded limit, if you never call it, setting a limit is pretty much useless.
