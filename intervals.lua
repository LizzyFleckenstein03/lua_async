lua_async.intervals = {
	pool = {},
	last_id = 0,
}

function setInterval(callback, ms, ...)
	local id = lua_async.intervals.last_id + 1
	lua_async.intervals.last_id = id
	local step_time = (ms or 0) / 1000
	lua_async.intervals.pool[id] = {
		time_left = step_time,
		step_time = step_time,
		callback = callback,
		args = {...},
	}
	return id
end

function clearInterval(id)
	lua_async.intervals.pool[id] = nil
end

function lua_async.intervals.step(dtime)
	for id, interval in pairs(lua_async.intervals.pool) do
		interval.time_left = timeout.time_left - dtime

		if interval.time_left <= 0 then
			interval.callback(unpack(interval.args))
			interval.time_left = interval.step_time
		end
	end
end

