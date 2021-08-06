local unpack = unpack or table.unpack
local PromisePrototype = {}

function PromisePrototype:__run_handler(func, ...)
	local values = {pcall(func, ...)}

	if table.remove(values, 1) then
		self:__resolve_raw(unpack(values))
	else
		self:__reject_raw(values[1])
	end
end

function PromisePrototype:__add_child(promise)
	if self.state == "resolved" then
		promise:__resolve(unpack(self.values))
	elseif self.state == "rejected" then
		promise:__reject(self.reason)
	else
		table.insert(self.__children, promise)
	end
end

function PromisePrototype:__resolve_raw(...)
	self.state = "resolved"
	self.values = {...}
	self.reason = nil

	for _, child in ipairs(self.__children) do
		child:resolve(...)
	end
end

function PromisePrototype:__reject_raw(reason)
	self.state = "rejected"
	self.values = nil
	self.reason = reason

	local any_child = false

	for _, child in ipairs(self.__children) do
		child:reject(reason)
	end

	assert(any_child, "Uncaught (in promise): " .. reason)
end

function PromisePrototype:then_(on_resolve, on_reject)
	local promise = Promise()
	promise.__on_resolve = on_resolve
	promise.__on_reject = on_reject

	self:__add_child(promise)

	return promise
end

function PromisePrototype:catch(func)
	local promise = Promise(function() end)
	promise.__on_reject = func

	self:__add_child(promise)

	return promise
end

function PromisePrototype:resolve(...)
	assert(self.state == "pending")

	if self.__on_resolve then
		self:__run_handler(self.__on_resolve, ...)
	else
		self:__resolve_raw(...)
	end
end

function PromisePrototype:reject(reason)
	assert(self.state == "pending")

	if self.__on_reject then
		self:__run_handler(self.__on_reject, reason)
	else
		self:__reject_raw(reason)
	end
end

Promise = setmetatable({}, {
	__call = function(_, resolver)
		local promise = {
			state = "pending",
			__children = {},
		}

		setmetatable(promise, {__index = PromisePrototype})

		if resolver then
			resolver(
				function(...)
					promise:resolve(...)
				end,
				function(...)
					promise:reject(...)
				end
			)
		end

		return promise
	end
})

function Promise.resolve(...)
	local args = {...}
	return Promise(function(resolve)
		resolve(unpack(args))
	end)
end
