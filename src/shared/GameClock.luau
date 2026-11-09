--!strict
-- Game time is server time minus the total time spent paused, so everything timed by it (bolts, orbs,
-- enemy interpolation, spawn pacing, the run timer) freezes while a level-up offer is open. The server
-- owns it and publishes offset and pause moment as ONE string attribute on workspace, so a client can
-- never see a new offset with an old pause state (two attributes could replicate a frame apart).
local RunService = game:GetService("RunService")

local ATTRIBUTE = "GameClock"

local isServer = RunService:IsServer()
local offset = 0
local pausedAt: number? = nil
-- Client only: the pause attribute arrives one network trip late, so raw game time would jump back by
-- the latency when a pause lands and forward again on resume. Never going backwards hides both jumps.
local lastClientTime = -math.huge

local GameClock = {}

local function publish()
	workspace:SetAttribute(ATTRIBUTE, string.format("%.6f;%.6f", offset, pausedAt or -1))
end

local function read()
	local value = workspace:GetAttribute(ATTRIBUTE)
	if typeof(value) ~= "string" then
		return
	end
	local parts = string.split(value, ";")
	local newOffset = tonumber(parts[1])
	local newPausedAt = tonumber(parts[2])
	if newOffset and newPausedAt and math.isfinite(newOffset) and math.isfinite(newPausedAt) then
		offset = newOffset
		pausedAt = if newPausedAt >= 0 then newPausedAt else nil
	end
end

function GameClock.now(): number
	local time = (pausedAt or workspace:GetServerTimeNow()) - offset
	if isServer then
		return time
	end
	lastClientTime = math.max(lastClientTime, time)
	return lastClientTime
end

function GameClock.isPaused(): boolean
	return pausedAt ~= nil
end

function GameClock.pause()
	assert(isServer, "GameClock.pause is server-only")
	if pausedAt == nil then
		pausedAt = workspace:GetServerTimeNow()
		publish()
	end
end

function GameClock.resume()
	assert(isServer, "GameClock.resume is server-only")
	local at = pausedAt
	if at ~= nil then
		offset += workspace:GetServerTimeNow() - at
		pausedAt = nil
		publish()
	end
end

if isServer then
	publish()
else
	read()
	workspace:GetAttributeChangedSignal(ATTRIBUTE):Connect(read)
end

return GameClock
