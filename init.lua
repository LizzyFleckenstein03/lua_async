lua_async = {}

function lua_async.step(dtime)
	-- timers phase
	lua_async.timeouts.step(dtime)
	lua_async.intervals.step(dtime)

	-- pending callbacks phase is done by minetest

	-- idle & prepare phase are obsolete

	-- poll phase is obsolete

	-- check phase
	lua_async.immediates.step(dtime)

	-- close phase is obsolete
end

return function(path)
	for _, f in ipairs {
		"timeouts",
		"intervals",
		"immediates",
		"promises",
		"async_await",
		"util",
		"limiting",
	} do
		dofile(path .. f .. ".lua")
	end
end
