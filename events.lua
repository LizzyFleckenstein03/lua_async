local EventPrototype = {}

function EventPrototype:preventDefault()
	self.defaultPrevented = true
end

function Event(type, data)
	return setmetatable({
		type = type,
		data = data,
		defaultPrevented = false,
		timeStamp = os.clock(),
	}, {__index = EventPrototype})
end

local EventTargetPrototype = {}

function EventTargetPrototype:dispatchEvent(event)
	event.target = self

	local callback = self["on" + event.type]

	if callback then
		callback(event)
	end

	local listeners = self.__eventListeners[type]

	if listeners then
		for i, callback in ipairs(listeners) do
			callback(event)
		end
	end

	return not event.defaultPrevented
end

function EventTargetPrototype:addEventListener(type, callback)
	local listeners = self.__eventListeners[type] or {}
	table.insert(listeners, callback)
	self.__eventListeners[type] = listeners
end

function EventTargetPrototype:removeEventListener(type, callback)
	local listeners = self.__eventListeners[type]

	if listeners then
		for k, v in pairs(listeners) do
			if v == callback then
				table.remove(listeners, k)
				break
			end
		end
	end
end

function EventTarget()
	return setmetatable({
		__eventListeners = {},
	}, {__index = EventTargetPrototype})
end
