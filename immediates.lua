local unpack = unpack or table.unpack
lua_async.immediates = {
	pool = {},
	executing = {},
	last_id = 0,
}

function setImmediate(callback, ...)
	local id = lua_async.immediates.last_id + 1
	lua_async.immediates.last_id = id
	lua_async.immediates.pool[id] = {
		callback = callback,
		args = {...},
	}
	return id
end

function clearImmediate(id)
	lua_async.immediates.pool[id] = nil
	lua_async.immediates.executing[id] = nil
end

function lua_async.immediates.step(dtime)
	lua_async.immediates.executing = lua_async.immediates.pool
	lua_async.immediates.pool = {}

	for id, immediate in pairs(lua_async.immediates.executing) do
		immediate.callback(unpack(immediate.args))
	end
end

