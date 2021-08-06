lua_async.async_await = {}

function lua_async.resume(co)
	local status, err = coroutine.resume(co)

	if coroutine.status(co) == "dead" or err then
		lua_async.limiting.unset_limit(co)
	end

	if not status then
		error("Error (in async function): " .. err)
	end
end

function await(promise)
	local co = assert(coroutine.running(), "await called outside of an async function")

	if promise.state == "pending" then
		promise:then_(function()
			lua_async.resume(co)
		end)

		coroutine.yield()
	end

	return unpack(promise.values)
end

function async(func)
	return function(...)
		local promise = Promise()
		promise.__on_resolve = func

		local args = {...}

		lua_async.resume(coroutine.create(function()
			promise:resolve(unpack(args))
		end))

		return promise
	end
end

