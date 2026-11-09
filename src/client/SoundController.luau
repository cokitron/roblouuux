--!strict
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

export type CueName =
	"Bolt"
	| "Arrow"
	| "Bullet"
	| "Cleave"
	| "CleaveOvercharge"
	| "Cinder"
	| "Lightning"
	| "HitNormal"
	| "HitCrit"
	| "HitSuperCrit"
	| "EnemyKill"
	| "GemPickup"
	| "LevelUpOpen"
	| "UpgradePick"
	| "Dash"
	| "CrowdControl"
	| "ChurchBell"
	| "BossRoar"
	| "Shockwave"
	| "UiClick"

type CueSpec = {
	id: string,
	volume: number,
	minInterval: number,
	pitchMin: number,
	pitchMax: number,
	maxDuration: number?,
}

-- Official Roblox-licensed ProSoundEffects & APMOfficial Creator Store Audio Assets (globally whitelisted)
local CUES: { [CueName]: CueSpec } = {
	Bolt = {
		id = "rbxassetid://9120984892", -- Zap High Pitch Glassy Reversed Whoosh 9 (SFX) - ProSoundEffects
		volume = 0.28,
		minInterval = 0.09,
		pitchMin = 0.95,
		pitchMax = 1.08,
	},
	Arrow = {
		id = "rbxassetid://9113161406", -- Arrow In And Hit 13 (SFX) - ProSoundEffects
		volume = 0.34,
		minInterval = 0.08,
		pitchMin = 0.94,
		pitchMax = 1.08,
	},
	Bullet = {
		id = "rbxassetid://9117399569", -- Pistol Single Shots 1 (SFX) - ProSoundEffects
		volume = 0.30,
		minInterval = 0.06,
		pitchMin = 0.94,
		pitchMax = 1.06,
	},
	Cleave = {
		id = "rbxassetid://9120972321", -- Wood Whoosh Slicing Air Quick Swings 4 (SFX) - ProSoundEffects
		volume = 0.42,
		minInterval = 0.12,
		pitchMin = 0.90,
		pitchMax = 1.05,
	},
	CleaveOvercharge = {
		id = "rbxassetid://9119072660", -- Shield Clang As Hit Metal Sword Hubcap 1 (SFX) - ProSoundEffects
		volume = 0.48,
		minInterval = 0.15,
		pitchMin = 0.88,
		pitchMax = 1.02,
	},
	Cinder = {
		id = "rbxassetid://9114428740", -- Fireball Pass By 1 (SFX) - ProSoundEffects
		volume = 0.36,
		minInterval = 0.14,
		pitchMin = 0.92,
		pitchMax = 1.06,
		maxDuration = 1.4,
	},
	Lightning = {
		id = "rbxassetid://9116281189", -- Lightning Storm Zaps Sharp Hissing Bursts 2 (SFX) - ProSoundEffects
		volume = 0.38,
		minInterval = 0.12,
		pitchMin = 0.94,
		pitchMax = 1.08,
		maxDuration = 1.2,
	},
	HitNormal = {
		id = "rbxassetid://9113542363", -- Bone Cracks 10 (SFX) - ProSoundEffects
		volume = 0.22,
		minInterval = 0.055,
		pitchMin = 0.92,
		pitchMax = 1.12,
	},
	HitCrit = {
		id = "rbxassetid://9113500009", -- Body Hit Metal Impact 4 (SFX) - ProSoundEffects
		volume = 0.36,
		minInterval = 0.065,
		pitchMin = 0.96,
		pitchMax = 1.10,
	},
	HitSuperCrit = {
		id = "rbxassetid://9114360785", -- Explosion Impacts 1 (SFX) - ProSoundEffects
		volume = 0.46,
		minInterval = 0.08,
		pitchMin = 0.92,
		pitchMax = 1.04,
	},
	EnemyKill = {
		id = "rbxassetid://9119559518", -- Squishy Bone Cracks 5 (SFX) - ProSoundEffects
		volume = 0.30,
		minInterval = 0.06,
		pitchMin = 0.90,
		pitchMax = 1.10,
	},
	GemPickup = {
		id = "rbxassetid://9116394545", -- Magic Glows Soft Clusters Of Chiming Hits 1 (SFX) - ProSoundEffects
		volume = 0.34,
		minInterval = 0.045,
		pitchMin = 1.0,
		pitchMax = 1.0,
	},
	LevelUpOpen = {
		id = "rbxassetid://9119447936", -- Sparkle Bell Tree Wind Chimes 1 (SFX) - ProSoundEffects
		volume = 0.52,
		minInterval = 0.25,
		pitchMin = 1.0,
		pitchMax = 1.04,
		maxDuration = 2.6,
	},
	UpgradePick = {
		id = "rbxassetid://9116395089", -- Magic Glows Soft Clusters Of Chiming Hits 4 (SFX) - ProSoundEffects
		volume = 0.48,
		minInterval = 0.12,
		pitchMin = 0.98,
		pitchMax = 1.06,
	},
	Dash = {
		id = "rbxassetid://9119467553", -- Spirit Pass Bys Fast Overlapping Whooshes 4 (SFX) - ProSoundEffects
		volume = 0.45,
		minInterval = 0.15,
		pitchMin = 0.96,
		pitchMax = 1.06,
	},
	CrowdControl = {
		id = "rbxassetid://9125611419", -- Ice Freeze Large Piece Crackles Liquid Nitro (SFX) - ProSoundEffects
		volume = 0.44,
		minInterval = 0.25,
		pitchMin = 0.95,
		pitchMax = 1.05,
		maxDuration = 1.6,
	},
	ChurchBell = {
		id = "rbxassetid://9114352428", -- Evil Church Bell Twisted Bent Average 1 (SFX) - ProSoundEffects
		volume = 0.46,
		minInterval = 0.40,
		pitchMin = 0.96,
		pitchMax = 1.04,
		maxDuration = 3.5,
	},
	BossRoar = {
		id = "rbxassetid://9113980319", -- Creature Mix Giant Crab Monster Roar Growl 1 (SFX) - ProSoundEffects
		volume = 0.56,
		minInterval = 0.50,
		pitchMin = 0.85,
		pitchMax = 0.96,
	},
	Shockwave = {
		id = "rbxassetid://9120769331", -- Wind Whoosh Sonic Boom Low End Impact 1 (SFX) - ProSoundEffects
		volume = 0.40,
		minInterval = 0.18,
		pitchMin = 0.94,
		pitchMax = 1.06,
		maxDuration = 1.8,
	},
	UiClick = {
		id = "rbxassetid://9119717523", -- Switch Click On Or Off Toggle Button 2 (SFX) - ProSoundEffects
		volume = 0.32,
		minInterval = 0.04,
		pitchMin = 0.96,
		pitchMax = 1.05,
	},
}

local POOL_SIZE = 24
local sfxGroup: SoundGroup? = nil
local pool: { Sound } = {}
local poolIndex = 1
local lastPlayedAt: { [CueName]: number } = {}
local rng = Random.new()

local gemComboCount = 0
local lastGemAt = 0

local SoundController = {}

local function ensurePool(): SoundGroup
	if sfxGroup then
		return sfxGroup
	end
	local group = Instance.new("SoundGroup")
	group.Name = "CombatSfxGroup"
	group.Volume = 1.0
	group.Parent = SoundService
	sfxGroup = group

	for i = 1, POOL_SIZE do
		local s = Instance.new("Sound")
		s.Name = "SfxChannel_" .. tostring(i)
		s.SoundGroup = group
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.Parent = group
		table.insert(pool, s)
	end

	-- Preload all cue SoundIds asynchronously
	task.spawn(function()
		local preloadList: { Instance } = {}
		for _, spec in pairs(CUES) do
			local s = Instance.new("Sound")
			s.SoundId = spec.id
			table.insert(preloadList, s)
		end
		pcall(function()
			ContentProvider:PreloadAsync(preloadList)
		end)
		for _, s in ipairs(preloadList) do
			s:Destroy()
		end
	end)

	return group
end

function SoundController.play(cue: CueName, customPitch: number?)
	ensurePool()
	local spec = CUES[cue]
	if not spec then
		return
	end
	local now = os.clock()
	local prev = lastPlayedAt[cue] or 0
	if now - prev < spec.minInterval then
		return
	end
	lastPlayedAt[cue] = now

	local channel = pool[poolIndex]
	poolIndex = (poolIndex % #pool) + 1
	if not channel then
		return
	end

	channel:Stop()
	channel.SoundId = spec.id
	channel.Volume = spec.volume
	channel.TimePosition = 0
	if customPitch then
		channel.PlaybackSpeed = customPitch
	elseif spec.pitchMin == spec.pitchMax then
		channel.PlaybackSpeed = spec.pitchMin
	else
		channel.PlaybackSpeed = rng:NextNumber(spec.pitchMin, spec.pitchMax)
	end
	channel:Play()

	if spec.maxDuration then
		local dur = spec.maxDuration
		local playedSoundId = spec.id
		task.delay(dur, function()
			if channel.IsPlaying and channel.SoundId == playedSoundId then
				channel:Stop()
			end
		end)
	end
end

function SoundController.playGemPickup()
	local now = os.clock()
	if now - lastGemAt <= 1.35 then
		gemComboCount = math.min(12, gemComboCount + 1)
	else
		gemComboCount = 0
	end
	lastGemAt = now
	local pitch = 0.98 + gemComboCount * 0.04
	SoundController.play("GemPickup", pitch)
end

function SoundController.start()
	ensurePool()
	local player = Players.LocalPlayer

	-- Wire automatic attribute listeners for XP Gems, Dash, Crowd-Control, Objectives, Weapon Selection & Boss Spawns
	local lastXp = (player:GetAttribute("Xp") :: number?) or 0
	local lastLevel = (player:GetAttribute("Level") :: number?) or 1
	player:GetAttributeChangedSignal("Xp"):Connect(function()
		local phase = player:GetAttribute("Phase")
		local curXp = (player:GetAttribute("Xp") :: number?) or 0
		local curLevel = (player:GetAttribute("Level") :: number?) or 1
		if phase == "InRun" and (curXp > lastXp or curLevel > lastLevel) then
			SoundController.playGemPickup()
		end
		lastXp = curXp
		lastLevel = curLevel
	end)

	local lastDashClock = (player:GetAttribute("DashReadyClock") :: number?) or 0
	player:GetAttributeChangedSignal("DashReadyClock"):Connect(function()
		local cur = (player:GetAttribute("DashReadyClock") :: number?) or 0
		if cur > lastDashClock + 0.2 then
			SoundController.play("Dash")
		end
		lastDashClock = cur
	end)

	local lastCc = ""
	player:GetAttributeChangedSignal("CcKind"):Connect(function()
		local raw = player:GetAttribute("CcKind")
		local cur = if typeof(raw) == "string" then raw else ""
		if cur ~= "" and cur ~= lastCc then
			SoundController.play("CrowdControl")
		end
		lastCc = cur
	end)

	local lastBanner = ""
	player:GetAttributeChangedSignal("FieldEventBanner"):Connect(function()
		local raw = player:GetAttribute("FieldEventBanner")
		if typeof(raw) == "string" and raw ~= "" and raw ~= lastBanner then
			lastBanner = raw
			SoundController.play("ChurchBell")
		end
	end)

	local lastWeapon = (player:GetAttribute("SelectedWeapon") :: string?) or ""
	player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function()
		local cur = (player:GetAttribute("SelectedWeapon") :: string?) or ""
		if cur ~= "" and cur ~= lastWeapon then
			lastWeapon = cur
			SoundController.play("UpgradePick")
		end
	end)

	local lastModal = ""
	player:GetAttributeChangedSignal("OpenLobbyModal"):Connect(function()
		local raw = player:GetAttribute("OpenLobbyModal")
		if typeof(raw) == "string" and raw ~= "" and raw ~= lastModal then
			lastModal = raw
			SoundController.play("UiClick")
		end
	end)

	local lastBossName = ""
	Workspace:GetAttributeChangedSignal("ActiveBossName"):Connect(function()
		local raw = Workspace:GetAttribute("ActiveBossName")
		local cur = if typeof(raw) == "string" then raw else ""
		if cur ~= "" and cur ~= lastBossName then
			SoundController.play("BossRoar")
			SoundController.play("ChurchBell")
		end
		lastBossName = cur
	end)
end

return SoundController
