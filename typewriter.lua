
local M = {
	
}
M.__index = M

function M:new(providerName)
	local object = {}
	setmetatable(object, self)

	return object
end

return M
