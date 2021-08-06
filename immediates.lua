lua_async.immediates = {
	pool = {},
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
end

function lua_async.immediates.step(dtime)
	for id, immediate in pairs(lua_async.immediates.pool) do
		immediate.callback(unpack(immediate.args))
		clearImmediate(id)
	end
end

