
local M = {
	message = "",
	strippedMessage = "",
	actions = {},
	textObject = nil,
	animationTime = 600,
}
M.__index = M

local actionStartTag = "{|"
local actionEndTag = "|}"
local actionMatchTag = "%b{}"
local pauseActionTag = "pause"
local speedActionTag = "speed"
local defaultSpeed = 25

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)

	return fields
end

function string:countSpacesUpTo(delimiter, startPos)
	local stopPos = self:find(delimiter, startPos)
	local numSpaces = 0

	if (stopPos ~= nil) then
		for i = startPos, stopPos - 1 do
			local char = self:sub(i, i)

			if (char == " ") then
				numSpaces = numSpaces + 1
			end
		end
	end

	return numSpaces
end

function M:new(providerName)
	local object = {}
	setmetatable(object, self)

	return object
end

local function parseActions(options)
	local targetMessage = options.message
	local stripActions = options.stripActions or false
	local parseSpaces = options.parseSpaces or false
	local parsedActions = {}
	local actionPosition = nil
	local startPos = 1

	repeat
		actionPosition = targetMessage:find(actionStartTag, startPos)
		
		if (actionPosition ~= nil) then
			if (parseSpaces) then			
				parsedActions[#parsedActions + 1] = targetMessage:countSpacesUpTo(actionStartTag, startPos)
			else
				parsedActions[#parsedActions + 1] = stripActions and actionPosition - 1 or actionPosition
			end

			if (stripActions) then
				local endPos = targetMessage:find(actionEndTag, actionPosition)

				if (endPos ~= nil) then
					local actionsString = targetMessage:sub(actionPosition, endPos + 1)
					targetMessage = targetMessage:gsub(actionsString, "", 1)
				end
			end

			startPos = actionPosition + 1
		end
	until
		actionPosition == nil

	return parsedActions
end

function M:setMessage(message)
	local spaces = parseActions({message = message, parseSpaces = true})
	local realSpecials = parseActions({message = message, stripActions = true})
	local specials = parseActions({message = message})

	for i = 1, #specials do
		local endPos = message:find(actionEndTag, specials[i])
		local actionStartPos = specials[i] + 2
		local actionsString = message:sub(actionStartPos, endPos - 1)
		local actions = actionsString:split(",")
		local totalSpaces = spaces[i]

		self.actions[i] = {}

		if (i > 1) then
			totalSpaces = 0

			for k = 1, i do
				totalSpaces = totalSpaces + spaces[k]
			end
		end

		if (#actions > 1) then
			for j = 1, #actions do
				self.actions[i][j] = {
					type = actions[j]:split(":")[1],
					value = tonumber(actions[j]:split(":")[2]),
					startPos = realSpecials[i] - totalSpaces + 1
				}
			end
		else
			self.actions[i][1] = {
				type = actions[1]:split(":")[1],
				value = tonumber(actions[1]:split(":")[2]),
				startPos = realSpecials[i] - totalSpaces + 1
			}
		end
	end

	self.message = message
	self.strippedMessage = message:gsub(actionMatchTag, "")
end

function M:setTextObject(textObject)
	self.textObject = textObject
end

function M:setAnimationTime(animTime)
	self.animationTime = animTime
end

function M:play(effect)
	local delay = (defaultSpeed * 2)
	local pausePositions = {}
	local pauseAmount = {}
	local speed = {}
	local actions = {}
	local maintainSpeed = false
	local speed = 0
	local pauseAmount = 0
	local ticks = 0

	for i = 1, #self.actions do
		local currentAction = self.actions[i]
		actions[i] = {
			position = 0,
			pauseAmount = nil,
			speedAmount = nil,
		}
		
		if (#currentAction == 1) then				
			if (currentAction[1].type == pauseActionTag) then
				actions[i].position = currentAction[1].startPos
				actions[i].pauseAmount = (currentAction[1].value * 1000)
			elseif (currentAction[1].type == speedActionTag) then
				actions[i].position = currentAction[1].startPos
				actions[i].speedAmount = (currentAction[1].value)
			end
		else			
			for j = 1, #currentAction do
				if (currentAction[j].type == pauseActionTag) then
					actions[i].position = currentAction[j].startPos
					actions[i].pauseAmount = (currentAction[j].value * 1000)
				elseif (currentAction[j].type == speedActionTag) then
					actions[i].position = currentAction[j].startPos
					actions[i].speedAmount = (currentAction[j].value)
				end
			end
		end
	end

	for i = 1, self.textObject.numChildren do
		local extraDelay = defaultSpeed

		for j = 1, #actions do
			local currentAction = actions[j]

			if (i == currentAction.position) then
				if (currentAction.pauseAmount ~= nil) then
					extraDelay = currentAction.pauseAmount
					pauseAmount = currentAction.pauseAmount

					if (j < #actions and actions[j].speedAmount ~= nil) then
						extraDelay = currentAction.pauseAmount * 3
					end

					maintainSpeed = false
					ticks = 0
				end
				
				if (currentAction.speedAmount ~= nil) then
					maintainSpeed = true
					speed = currentAction.speedAmount
				end
			end

			if (maintainSpeed) then
				extraDelay = pauseAmount

				if (ticks >= 5) then
					extraDelay = (defaultSpeed * speed)
				end
				
				ticks = ticks + 1
			end
		end

		delay = (delay + extraDelay)
		transition.from(self.textObject[i], {delay = delay, time = self.animationTime, xScale = 1, yScale = 1, alpha = 0, transition = easing.outBounce})
	end	
end

return M
