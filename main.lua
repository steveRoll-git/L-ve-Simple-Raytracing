local love = love
local lg = love.graphics

local function formatSeconds(sec)
  return math.floor(sec / 60) .. " minutes " .. math.floor(sec % 60) .. " seconds"
end

lg.setDefaultFilter("nearest", "nearest")

local scale = 1

local renderW, renderH = lg.getWidth() / scale, lg.getHeight() / scale

local thread = love.thread.newThread("rendering.lua")
thread:start(renderW, renderH)

local imgData
local img

local imgDataChannel = love.thread.getChannel("imageDataObject")
local frameCompleteChannel = love.thread.getChannel("frameComplete")
local renderInfoChannel = love.thread.getChannel("renderInfo")
local renderProgressChannel = love.thread.getChannel("renderProgress")

local frames

local currentFrame = 1

local str = "waiting for info..."

local lastTime = love.timer.getTime()

local progress = 0
local progressBar = {x = 0, y = lg.getFont():getHeight()*2, w = 200, h = 25, fillW = 0}

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
	
	local p
	repeat
		p = renderProgressChannel:pop()
		if p then
			progress = p
			progressBar.fillW = p / renderH * progressBar.w
		end
	until not p
end

function love.draw()
	lg.setColor(1,1,1)
	if img then
		lg.draw(img, 0, 0, 0, scale, scale)
	end
  lg.print(str)
	lg.setColor(1,1,1, 0.7)
	lg.rectangle("line", progressBar.x, progressBar.y, progressBar.w, progressBar.h)
	lg.rectangle("fill", progressBar.x, progressBar.y, progressBar.fillW, progressBar.h)
	--local y = progress / renderH * lg.getHeight()
	--lg.line(0, y, lg.getWidth(), y)
end