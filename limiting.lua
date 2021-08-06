lua_async.limiting = {
	pool = {},
}

function lua_async.limiting.unset_limit(co)
	lua_async.limiting.pool[co] = nil
end

function lua_async.set_limit(ms)
	local co = assert(coroutine.running(), "set_limit called outside of an async function")

	local limit = ms / 1000

	lua_async.limiting.pool[co] = {
		limit = limit,
		next_yield = os.clock() + limit,
	}
end

function lua_async.unset_limit()
	local co = assert(coroutine.running(), "unset_limit called outside of an async function")
	lua_async.limiting.unset_limit(co)
end

function lua_async.check_limit()
	local co = assert(coroutine.running(), "check_limit called outside of an async function")
	local limit = lua_async.limiting.pool[co]

	if limit and os.clock() >= limit.next_yield then
		lua_async.yield()
		limit.next_yield = os.clock() + limit.limit
		return true
	end

	return false
end

