local love = love
local lg = love.graphics

local function formatSeconds(sec)
  return math.floor(sec / 60) .. " minutes " .. math.floor(sec % 60) .. " seconds"
end

lg.setDefaultFilter("nearest", "nearest")

local scale = 1

local screenW, screenH = lg.getWidth() / scale, lg.getHeight() / scale

local thread = love.thread.newThread("rendering.lua")
thread:start(screenW, screenH)

local imgData
local img

local imgDataChannel = love.thread.getChannel("imageDataObject")
local frameCompleteChannel = love.thread.getChannel("frameComplete")
local renderInfoChannel = love.thread.getChannel("renderInfo")

local frames

local currentFrame = 1

local str = "waiting for info..."

local lastTime = love.timer.getTime()

function love.update(dt)
	if not imgData then
		local data = imgDataChannel:pop()
		if data then
			imgData = data
		end
	end
	
	if not frames then
		local renderInfo = renderInfoChannel:pop()
		if renderInfo then
			frames = renderInfo.frames
			str = "rendering " .. currentFrame .. "/" .. frames
		end
	end
	
	local frameComplete = frameCompleteChannel:pop()
	if frameComplete then
		if img then
			img:replacePixels(imgData)
		else
			img = lg.newImage(imgData)
		end
		currentFrame = currentFrame + 1
		str = "rendering " .. currentFrame .. "/" .. frames .. "\nest. remaining: " .. formatSeconds((love.timer.getTime() - lastTime) * (frames - currentFrame - 1))
		lastTime = love.timer.getTime()
	end
end

function love.draw()
	if img then
		lg.draw(img, 0, 0, 0, scale, scale)
	end
  lg.print(str)
end