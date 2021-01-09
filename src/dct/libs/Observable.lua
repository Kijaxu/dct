--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Implements a Observable interface
--]]

local class  = require("libs.class")

local Observable = class()
function Observable:__init(logger)
	if self._logger == nil then
		self._logger = logger or dct.Logger.getByName("Observable")
	end
	self._observers = {}
	setmetatable(self._observers, { __mode = "k", })
end

function Observable:addObserver(func, ctx, name)
	assert(type(func) == "function", "func must be a function")
	-- ctx must be non-nil otherwise upon insertion the index which
	-- is the function address will be deleted.
	assert(ctx ~= nil, "ctx must be a non-nil value")
	name = name or "unknown"

	if self._observers[func] ~= nil then
		self._logger:error("func("..tostring(func)..
			") already set - skipping")
		return
	end
	self._logger:debug(string.format("adding handler(%s)", name))
	self._observers[func] = { ["ctx"] = ctx, ["name"] = name, }
end

function Observable:removeObserver(func)
	assert(type(func) == "function", "func must be a function")
	self._observers[func] = nil
end

function Observable:_notify(event)
	self._logger:debug(string.format("notify; event.id: %d", event.id))
	for handler, val in pairs(self._observers) do
		self._logger:debug("+ executing handler: "..val.name)
		handler(val.ctx, event)
	end
end

if dct.settings and dct.settings.server and
   dct.settings.server.profile then
	require("os")
	function Observable:notify(event)
		local tstart = os.clock()
		self:_notify(event)
		self._logger:warn(string.format("notify time: %5.2fms",
			(os.clock()-tstart)*1000))
	end
else
	function Observable:notify(event)
		self:_notify(event)
	end
end


return Observable
