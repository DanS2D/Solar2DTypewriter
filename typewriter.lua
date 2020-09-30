
local M = {
	message = "",
	currentPos = 0,
	actions = {},
	textObject = nil,
}
M.__index = M

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)

	return fields
 end

function M:new(providerName)
	local object = {}
	setmetatable(object, self)

	return object
end

function M:setMessage(message)
	local specials = {}
	local specialPos = nil
	local startPos = 1

	repeat
		specialPos = message:find("%b{|", startPos)
		if (specialPos ~= nil) then
			specials[#specials + 1] = specialPos
			startPos = specialPos + 1
		end
	until
		specialPos == nil

	for i = 1, #specials do
		local endPos = message:find("|}", specials[i])
		local actionStartPos = specials[i] + 2
		local actionsString = message:sub(actionStartPos, endPos - 1)
		local actions = actionsString:split(",")

		self.actions[i] = {}

		if (#actions > 1) then
			for j = 1, #actions do
				self.actions[i][j] = {
					type = actions[j]:split(":")[1],
					value = actions[j]:split(":")[2],
					startPos = specials[i],
					endPos = endPos,
					length = endPos - startPos,
				}
				--print(self.actions[i][j].type)
			end
		else
			self.actions[i][1] = {
				type = actions[1]:split(":")[1],
				value = actions[1]:split(":")[2],
				startPos = specials[i],
				endPos = endPos,
				length = endPos - startPos,
			}

			--print(self.actions[i][1].type)
		end
	end

	self.message = message
end

function M:setTextObject(textObject)
	self.textObject = textObject
end

function M:play()
	local defaultSpeed = 100
	local speed = 100

	local function typeWriter(event)
		self.currentPos = self.currentPos + 1
		local action = nil

		for i = 1, #self.actions do
			for j = 1, #self.actions[i] do
				if (self.currentPos == self.actions[i][j].startPos) then
					action = self.actions[i]
					break
				end
			end
		end

		if (action ~= nil) then
			if (#action == 1) then
				print("action is a single action")
				self.currentPos = action[1].endPos + 2
				
				if (action[1].type == "pause") then
					local waitTime = action[1].value * 1000
					timer.cancel(event.source)

					timer.performWithDelay(waitTime, function()
						timer.performWithDelay(speed, typeWriter, 0)
					end)
				elseif (action[1].type == "speed") then
					print("SPEED ACTION")
					speed = action[1].value
					timer.cancel(event.source)

					timer.performWithDelay(1, function()
						timer.performWithDelay(speed, typeWriter, 0)
					end)
				end
			else
				print("action is a multi action")
				local restartDelay = 1
				speed = defaultSpeed
				self.currentPos = action[#action].endPos + 2
				
				for i = 1, #action do
					if (action[i].type == "pause") then
						restartDelay = action[i].value * 1000
					elseif (action[i].type == "speed") then
						speed = action[i].value
					end
				end

				timer.cancel(event.source)
				timer.performWithDelay(restartDelay, function()
					timer.performWithDelay(speed, typeWriter, 0)
				end)
			end
		end

		if (self.currentPos > self.message:len()) then
			timer.cancel(event.source)
		end

		self.textObject.text = self.textObject.text .. self.message:sub(self.currentPos, self.currentPos)
	end

	timer.performWithDelay(speed, typeWriter, 0)
end

return M
