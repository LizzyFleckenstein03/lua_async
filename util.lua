function lua_async.yield()
	local co = assert(coroutine.running(), "yield called outside of an async function")

	setTimeout(lua_async.resume, 0, co)

	coroutine.yield()
end

function lua_async.sleep(ms)
	await(Promise(function(resolve)
		setTimeout(resolve, ms)
	end))
end
