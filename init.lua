lua_async = {
	poll_functions = {},
}

function lua_async.clock()
	return lua_async.socket and lua_async.socket.gettime() or os.clock()
end

function lua_async.step(dtime)
	-- timers phase
	lua_async.timeouts.step(dtime)
	lua_async.intervals.step(dtime)

	-- pending callbacks phase is obsolete

	-- idle & prepare phase are obsolete

	-- poll phase
	for func in pairs(lua_async.poll_functions) do
		func()
	end

	-- check phase
	lua_async.immediates.step(dtime)

	-- close phase is obsolete
end

return function(path, no_socket)
	if not no_socket then
		lua_async.socket = require("socket")
	end

	for _, f in ipairs {
		"timeouts",
		"intervals",
		"immediates",
		"promises",
		"async_await",
		"util",
		"limiting",
		"events",
	} do
		dofile(path .. "/" .. f .. ".lua")
	end
end
