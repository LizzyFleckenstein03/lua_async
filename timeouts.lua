lua_async.timeouts = {
	pool = {},
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
end

function lua_async.timeouts.step(dtime)
	for id, timeout in pairs(lua_async.timeouts.pool) do
		timeout.time_left = timeout.time_left - dtime

		if timeout.time_left <= 0 then
			timeout.callback(unpack(timeout.args))
			clearTimeout(id)
		end
	end
end
