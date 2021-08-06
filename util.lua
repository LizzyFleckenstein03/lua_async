function lua_async.yield()
	local co = assert(coroutine.running(), "yield called outside of an async function")

	setTimeout(lua_async.resume, 0, co)

	coroutine.yield()
end

function lua_async.kill_thread()
	coroutine.yield(true)
end

function lua_async.sleep(ms)
	await(Promise(function(resolve)
		setTimeout(resolve, ms)
	end))
end

function lua_async.run()
	local last_time = os.clock()

	while true do
		local current_time = os.clock()
		local dtime = current_time - last_time
		last_time = current_time

		lua_async.step(dtime)
	end
end
