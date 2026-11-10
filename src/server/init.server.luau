--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Arena = require(script.Arena)
local DataService = require(script.DataService)
local Director = require(script.Director)
local EnemyCandidates = require(script.EnemyCandidates)
local EnemyService = require(script.EnemyService)
local GemService = require(script.GemService)
local MonetizationService = require(script.MonetizationService)
local PlayerState = require(script.PlayerState)
local RateLimiter = require(script.RateLimiter)
local Replication = require(script.Replication)
local WeaponService = require(script.WeaponService)
local Constants = require(ReplicatedStorage.Shared.Constants)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MAX_FRAME_TIME = 0.1
local MAX_OFFER_SEQ = 2 ^ 31
local MAX_ACTION_LENGTH = 28

local chooseUpgrade = Remotes.get("ChooseUpgrade")
local sessionAction = Remotes.get("SessionAction")
local chooseLimiter = RateLimiter.new(10, 5)
local sessionLimiter = RateLimiter.new(15, 8)

EnemyCandidates.syncEnemyModels()
DataService.init()
Arena.build()
MonetizationService.init()
Players.RespawnTime = Constants.RESPAWN_TIME
StarterPlayer.EnableMouseLockOption = true
StarterPlayer.CameraMode = Enum.CameraMode.Classic
StarterPlayer.CameraMinZoomDistance = Constants.CAMERA_MIN_ZOOM
StarterPlayer.CameraMaxZoomDistance = Constants.CAMERA_MAX_ZOOM
StarterPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom

local function onPlayerAdded(player: Player)
	DataService.loadPlayer(player)
	player.CharacterAdded:Connect(function(character)
		PlayerState.reset(player, character)
	end)
	if player.Character then
		PlayerState.reset(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerState.remove(player)
	WeaponService.removePlayer(player)
	chooseLimiter:remove(player)
	sessionLimiter:remove(player)
end)

local function isWholeNumber(value: unknown, min: number, max: number): boolean
	return typeof(value) == "number" and math.isfinite(value) and value % 1 == 0 and value >= min and value <= max
end

-- The client names only the offer it saw (seq) and a card slot; ids and rarities stay on the server.
chooseUpgrade.OnServerEvent:Connect(function(player: Player, seq: unknown, slot: unknown, ...: unknown)
	if select("#", ...) > 0 or not chooseLimiter:allow(player) then
		return
	end
	if not isWholeNumber(seq, 1, MAX_OFFER_SEQ) or not isWholeNumber(slot, 1, Constants.MAX_OFFER_COUNT) then
		return
	end
	local state = PlayerState.get(player)
	if state then
		PlayerState.chooseUpgrade(state, seq :: number, slot :: number)
	end
end)

-- SEC-1: Strict validation for Lobby / Downed / Summary / WoW RPG / Monetization actions.
sessionAction.OnServerEvent:Connect(function(player: Player, action: unknown, payload: unknown, ...: unknown)
	if select("#", ...) > 0 or not sessionLimiter:allow(player) then
		return
	end
	if typeof(action) ~= "string" or #action > MAX_ACTION_LENGTH then
		return
	end
	local state = PlayerState.get(player)
	if not state then
		return
	end

	if action == "StartRun" then
		PlayerState.startRun(state)
	elseif action == "Dash" then
		PlayerState.dash(state)
	elseif action == "SelectWeapon" then
		if typeof(payload) == "string" and #payload <= 32 then
			PlayerState.setWeapon(state, payload)
		end
	elseif action == "RequestRevive" then
		MonetizationService.requestRevive(state)
	elseif action == "RequestSoftRevive" then
		MonetizationService.requestSoftRevive(state)
	elseif action == "DeclineRevive" then
		PlayerState.declineRevive(state)
	elseif action == "ReturnToLobby" then
		PlayerState.returnToLobby(state)
	elseif action == "RerollOffer" then
		MonetizationService.requestReroll(state)
	elseif action == "ClaimAllOffer" then
		MonetizationService.requestClaimAll(state)
	elseif action == "SummonBoss" then
		if RunService:IsStudio() and state.phase == "InRun" and state.alive then
			local pos = PlayerState.getPosition(state) or Vector3.new(0, 0, 0)
			local profile = DataService.getProfile(player)
			local kLvl = if profile then profile.selectedKeystone else 0
			Director.summonNextBoss(pos, kLvl)
		end
	elseif action == "SummonMonster" then
		if
			RunService:IsStudio()
			and state.phase == "InRun"
			and state.alive
			and typeof(payload) == "string"
			and #payload <= 32
		then
			local pos = PlayerState.getPosition(state) or Vector3.new(0, 0, 0)
			local profile = DataService.getProfile(player)
			local kLvl = if profile then profile.selectedKeystone else 0
			Director.summonMonsterKind(pos, payload, kLvl)
		end
	elseif action == "BuyTalent" then
		if typeof(payload) == "string" and #payload <= 36 then
			DataService.buyTalent(player, payload)
		end
	elseif action == "RespecTalents" then
		DataService.respecTalents(player)
	elseif action == "EquipItem" then
		if typeof(payload) == "string" and #payload <= 48 then
			DataService.equipBagItem(player, payload)
		end
	elseif action == "DisenchantItem" then
		if typeof(payload) == "string" and #payload <= 48 then
			DataService.disenchantBagItem(player, payload)
		end
	elseif action == "DisenchantAll" then
		DataService.disenchantAllBag(player)
	elseif action == "EnchantSlot" then
		if typeof(payload) == "string" and #payload <= 24 then
			DataService.enchantSlot(player, payload)
		end
	elseif action == "SetKeystone" then
		if isWholeNumber(payload, 0, 15) then
			DataService.setKeystone(player, payload :: number)
		end
	elseif action == "ClaimDaily" then
		if typeof(payload) == "string" and #payload <= 32 then
			DataService.claimDailyQuest(player, payload)
		end
	elseif action == "ClaimVault" then
		DataService.claimGreatVault(player)
	elseif action == "BuyStarterPack" then
		MonetizationService.requestStarterPack(player)
	elseif action == "BuyGamePass" then
		if typeof(payload) == "string" and #payload <= 24 then
			MonetizationService.requestGamePass(player, payload)
		end
	elseif action == "BuyBloodMoon" then
		MonetizationService.requestBloodMoon(player)
	elseif action == "RequestSync" then
		DataService.sync(player)
	end
end)

local function updatePause(): boolean
	PlayerState.expireOffers()
	local paused = PlayerState.anyOfferOpen()
	if paused ~= GameClock.isPaused() then
		if paused then
			GameClock.pause()
		else
			GameClock.resume()
		end
		PlayerState.setFrozen(paused)
	end
	return paused
end

RunService.Heartbeat:Connect(function(rawDt)
	if updatePause() then
		Replication.step(0, EnemyService.getEnemies())
		return
	end
	local dt = math.min(rawDt, MAX_FRAME_TIME)
	PlayerState.step(dt)
	EnemyService.step(dt)
	WeaponService.step(dt)
	GemService.step(dt)
	Director.step(dt)
	Replication.step(dt, EnemyService.getEnemies())
end)
