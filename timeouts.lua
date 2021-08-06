local unpack = unpack or table.unpack
lua_async.timeouts = {
	pool = {},
	executing = {},
	last_id = 0,
}

function setTimeout(callback, ms, ...)
	local id = lua_async.timeouts.last_id + 1
	lua_async.timeouts.last_id = id
	lua_async.timeouts.pool[id] = {
		time_left = (ms or 0) / 1000,
		callback = callback,
		args = {...},
	}
	return id
end

function clearTimeout(id)
	lua_async.timeouts.pool[id] = nil
	lua_async.timeouts.executing[id] = nil
end

function lua_async.timeouts.step(dtime)
	lua_async.timeouts.executing = lua_async.timeouts.pool
	lua_async.timeouts.pool = {}

	for id, timeout in pairs(lua_async.timeouts.executing) do
		timeout.time_left = timeout.time_left - dtime

		if timeout.time_left <= 0 then
			timeout.callback(unpack(timeout.args))
		else
			lua_async.timeouts.pool[id] = timeout
		end

		lua_async.timeouts.executing[id] = nil
	end
end
