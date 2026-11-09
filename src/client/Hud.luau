--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants") :: ModuleScript)
local GameClock = require(Shared:WaitForChild("GameClock") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig") :: ModuleScript)

local BAR_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local WHITE = Color3.new(1, 1, 1)
local PANEL = Color3.fromRGB(22, 16, 42)
local STROKE_DARK = Color3.fromRGB(8, 5, 18)

local SHOWCASE_MONSTERS = {
	{ kind = "PlagueSlime", label = "🟢 Plague Slime" },
	{ kind = "InfernalImp", label = "🔥 Infernal Imp" },
	{ kind = "FrostWyrm", label = "❄️ Frost Wyrm" },
	{ kind = "DeathKnight", label = "⚔️ Death Knight" },
	{ kind = "AbyssalWatcher", label = "👁️ Abyssal Eye" },
	{ kind = "BoneHound", label = "🐺 Bone Hound" },
	{ kind = "BansheeShrieker", label = "👻 Banshee" },
	{ kind = "CandelabraMimic", label = "🕯️ Candelabra" },
}

local Hud = {}

local function create(className: string, properties: { [string]: any }, parent: Instance): any
	local instance = Instance.new(className)
	if className == "TextLabel" or className == "TextButton" then
		if properties.TextStrokeColor3 == nil then
			properties.TextStrokeColor3 = STROKE_DARK
		end
		if properties.TextStrokeTransparency == nil then
			properties.TextStrokeTransparency = 0.12
		end
	end
	for key, value in properties do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function addGradient(parent: Instance, c0: Color3, c1: Color3, rot: number?)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c0),
			ColorSequenceKeypoint.new(1, c1),
		}),
		Rotation = rot or 0,
	}, parent)
end

local function createLabel(parent: Instance, properties: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = WHITE,
		TextStrokeTransparency = 0.25,
		TextStrokeColor3 = Color3.fromRGB(12, 8, 24),
	}
	for key, value in properties do
		defaults[key] = value
	end
	return create("TextLabel", defaults, parent)
end

local function createBar(
	parent: Instance,
	properties: { [string]: any },
	c0: Color3,
	c1: Color3,
	strokeColor: Color3
): (Frame, TextLabel)
	properties.BackgroundColor3 = PANEL
	properties.BackgroundTransparency = 0.12
	properties.BorderSizePixel = 0
	local back = create("Frame", properties, parent)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, back)
	create("UIStroke", { Color = strokeColor, Thickness = 2, Transparency = 0.15 }, back)
	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, back)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, fill)
	addGradient(fill, c0, c1, 0)
	local label = createLabel(back, { Size = UDim2.fromScale(1, 1), ZIndex = 2, TextSize = 15 })
	return fill, label
end

local function formatTime(seconds: number): string
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

local function nextBossText(elapsed: number): string
	if elapsed < 180 then
		return string.format("⚡ NEXT BOSS: %s (Grave Reaper)", formatTime(180 - elapsed))
	elseif elapsed < 360 then
		return string.format("🛡️ NEXT BOSS: %s (Hollow Dreadnought)", formatTime(360 - elapsed))
	elseif elapsed < 540 then
		return string.format("🦴 NEXT BOSS: %s (Ossuary Behemoth)", formatTime(540 - elapsed))
	elseif elapsed < 600 then
		return string.format("👑 FINAL BOSS: %s (The Lich Lord)", formatTime(600 - elapsed))
	end
	return "🔥 ENDLESS BLOOD MOON OVERDRIVE!"
end

function Hud.mount(playerGui: PlayerGui)
	local player = Players.LocalPlayer
	local sessionAction = Remotes.get("SessionAction")

	local gui = create("ScreenGui", {
		Name = "SurvivorHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1,
	}, playerGui)

	-- Vibrant Rainbow-Cyan-to-Gold XP Bar at Top
	local xpFill, xpLabel = createBar(gui, {
		Name = "XpBar",
		Size = UDim2.new(1, -24, 0, 28),
		Position = UDim2.fromOffset(12, 8),
	}, Color3.fromRGB(0, 229, 255), Color3.fromRGB(185, 85, 255), Color3.fromRGB(255, 215, 64))

	-- Arcane Ward Shield Bar (Electric Cyan)
	local wardFill, wardLabel = createBar(gui, {
		Name = "WardBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(0.5, 0, 0, 20),
		Position = UDim2.new(0.5, 0, 1, -52),
		Visible = false,
	}, Color3.fromRGB(0, 176, 255), Color3.fromRGB(24, 255, 255), Color3.fromRGB(120, 245, 255))
	create("UISizeConstraint", { MaxSize = Vector2.new(400, 20) }, wardFill.Parent)

	-- Player Health Bar (Lush Emerald-to-Lime Gradient)
	local healthFill, healthLabel = createBar(gui, {
		Name = "HealthBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(0.5, 0, 0, 30),
		Position = UDim2.new(0.5, 0, 1, -16),
	}, Color3.fromRGB(0, 215, 95), Color3.fromRGB(135, 255, 55), Color3.fromRGB(255, 235, 110))
	create("UISizeConstraint", { MaxSize = Vector2.new(400, 30) }, healthFill.Parent)

	-- Raid Boss Health Bar (Blazing Crimson-to-Orange with Golden Crown Border)
	local bossFill, bossLabel = createBar(gui, {
		Name = "BossBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(480, 32),
		Position = UDim2.new(0.5, 0, 0, 96),
		Visible = false,
	}, Color3.fromRGB(255, 25, 75), Color3.fromRGB(255, 155, 0), Color3.fromRGB(255, 215, 0))

	-- Left Hero & Souls Pill
	local heroPill = create("Frame", {
		Name = "HeroPill",
		Position = UDim2.fromOffset(14, 44),
		Size = UDim2.fromOffset(355, 34),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, heroPill)
	addGradient(heroPill, Color3.fromRGB(58, 24, 115), Color3.fromRGB(24, 65, 135), 15)
	create("UIStroke", { Color = Color3.fromRGB(120, 235, 255), Thickness = 2 }, heroPill)

	local soulsLabel = createLabel(heroPill, {
		Name = "Souls",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -20, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(130, 255, 235),
		Text = "🟣 Souls 0  •  ⭐ Hero Lv.1 (iLvl 0)",
	})

	local buffsLabel = createLabel(gui, {
		Name = "Buffs",
		Position = UDim2.fromOffset(18, 82),
		Size = UDim2.fromOffset(390, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 230, 80),
		Text = "",
	})

	local controlsHintLabel = createLabel(gui, {
		Name = "ControlsHint",
		Position = UDim2.fromOffset(18, 102),
		Size = UDim2.fromOffset(420, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(185, 235, 255),
		Text = "🕹️ Auto-Attack  •  [Space/Shift] Spectral Dash  •  Ignite Soul Braziers  •  [H] Guide",
	})

	local bountyLabel = createLabel(gui, {
		Name = "WaveBounty",
		Position = UDim2.fromOffset(18, 122),
		Size = UDim2.fromOffset(440, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 215, 75),
		Visible = false,
		Text = "",
	})

	-- 3-Slot Active Arsenal & Evolution Bar above Health/Ward Bars
	local arsenalRow = create("Frame", {
		Name = "ArsenalRow",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -78),
		Size = UDim2.fromOffset(420, 30),
		BackgroundTransparency = 1,
	}, gui)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, arsenalRow)

	type ArsenalSlotUi = {
		frame: Frame,
		stroke: UIStroke,
		label: TextLabel,
	}
	local arsenalSlots: { ArsenalSlotUi } = {}
	for i = 1, 3 do
		local slotFrame = create("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromOffset(134, 28),
			BackgroundColor3 = PANEL,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
		}, arsenalRow)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, slotFrame)
		local slotStroke = create("UIStroke", {
			Color = Color3.fromRGB(95, 220, 255),
			Thickness = 1.6,
		}, slotFrame)
		local slotLbl = createLabel(slotFrame, {
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = WHITE,
			Text = string.format("🔒 Slot %d (Lv.%d+)", i, if i == 2 then 4 else 8),
		})
		table.insert(arsenalSlots, {
			frame = slotFrame,
			stroke = slotStroke,
			label = slotLbl,
		})
	end

	-- Crowd-Control / Movement Impairment Alert Bar above Arsenal Row
	local ccBarFrame = create("Frame", {
		Name = "CcAlertBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -114),
		Size = UDim2.fromOffset(420, 28),
		BackgroundColor3 = Color3.fromRGB(22, 14, 38),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, ccBarFrame)
	local ccBarStroke = create("UIStroke", { Color = Color3.fromRGB(115, 240, 255), Thickness = 2 }, ccBarFrame)
	local ccBarFill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(25, 145, 215),
		BorderSizePixel = 0,
	}, ccBarFrame)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, ccBarFill)
	local ccBarLabel = createLabel(ccBarFrame, {
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = WHITE,
		Text = "",
	})

	-- Center Clock Pill
	local timerPill = create("Frame", {
		Name = "TimerPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 42),
		Size = UDim2.fromOffset(145, 32),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, timerPill)
	addGradient(timerPill, Color3.fromRGB(45, 22, 85), Color3.fromRGB(95, 28, 145), 90)
	create("UIStroke", { Color = Color3.fromRGB(255, 215, 64), Thickness = 2 }, timerPill)

	local timerLabel = createLabel(timerPill, {
		Name = "Timer",
		Size = UDim2.fromScale(1, 1),
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 245, 155),
		Text = "00:00",
	})

	local milestoneLabel = createLabel(gui, {
		Name = "Milestone",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 76),
		Size = UDim2.fromOffset(360, 18),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 195, 95),
		Text = "⚡ NEXT BOSS: 03:00 (Grave Reaper)",
	})

	local compassLabel = createLabel(gui, {
		Name = "ObjectiveCompass",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 94),
		Size = UDim2.fromOffset(380, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(115, 255, 225),
		Text = "🧭 Explore the Crypts to Ignite 4 Soul Braziers",
	})

	-- Celebratory Field Event Banner (Brazier Ignited / Reliquary Chest Opened / Wave Bounty)
	local eventBanner = create("Frame", {
		Name = "FieldEventBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 134),
		Size = UDim2.fromOffset(520, 36),
		BackgroundColor3 = Color3.fromRGB(24, 18, 52),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, eventBanner)
	addGradient(eventBanner, Color3.fromRGB(128, 58, 14), Color3.fromRGB(72, 22, 98), 0)
	create("UIStroke", { Color = Color3.fromRGB(255, 220, 75), Thickness = 2 }, eventBanner)
	local eventBannerLabel = createLabel(eventBanner, {
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 245, 165),
		Text = "",
	})

	-- Interactive Spectral Dash Button & Cooldown Bar (PC [Space/Shift] + Mobile Tap)
	local dashBtn = create("TextButton", {
		Name = "DashButton",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, 218, 1, -16),
		Size = UDim2.fromOffset(156, 44),
		BackgroundColor3 = PANEL,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Text = "",
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, dashBtn)
	local dashStroke = create("UIStroke", { Color = Color3.fromRGB(85, 240, 255), Thickness = 2 }, dashBtn)
	local dashFill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, dashBtn)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, dashFill)
	addGradient(dashFill, Color3.fromRGB(16, 115, 165), Color3.fromRGB(48, 38, 135), 0)
	local dashLabel = createLabel(dashBtn, {
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = WHITE,
		Text = "💨 DASH [Space]",
	})

	local function triggerDash()
		local phase = player:GetAttribute("Phase")
		if (phase ~= "InRun" and phase ~= "Lobby") or player:GetAttribute("Dead") == true then
			return
		end
		sessionAction:FireServer("Dash")
	end

	dashBtn.Activated:Connect(triggerDash)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.KeyCode == Enum.KeyCode.Space
			or input.KeyCode == Enum.KeyCode.LeftShift
			or input.KeyCode == Enum.KeyCode.E
		then
			triggerDash()
		end
	end)

	-- Right Kills Pill
	local killsPill = create("Frame", {
		Name = "KillsPill",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 44),
		Size = UDim2.fromOffset(175, 32),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, killsPill)
	addGradient(killsPill, Color3.fromRGB(145, 22, 65), Color3.fromRGB(75, 18, 95), 0)
	create("UIStroke", { Color = Color3.fromRGB(255, 120, 165), Thickness = 2 }, killsPill)

	local killsLabel = createLabel(killsPill, {
		Name = "Kills",
		Size = UDim2.fromScale(1, 1),
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 235, 245),
		Text = "💀 KILLS: 0",
	})

	-- Exciting Tester Buttons (Summon Boss + Spawn Monster Pack)
	local summonBossBtn = create("TextButton", {
		Name = "SummonBossButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 82),
		Size = UDim2.fromOffset(205, 34),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = WHITE,
		Text = "👹 SUMMON BOSS WAVE!",
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, summonBossBtn)
	addGradient(summonBossBtn, Color3.fromRGB(145, 22, 95), Color3.fromRGB(78, 18, 152), 0)
	create("UIStroke", { Color = Color3.fromRGB(255, 215, 65), Thickness = 2 }, summonBossBtn)

	summonBossBtn.Activated:Connect(function()
		sessionAction:FireServer("SummonBoss")
	end)

	local monsterIdx = 1
	local spawnPackBtn = create("TextButton", {
		Name = "SpawnMonsterButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 122),
		Size = UDim2.fromOffset(205, 34),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = WHITE,
		Text = "👾 SPAWN: 🟢 Plague Slime",
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, spawnPackBtn)
	addGradient(spawnPackBtn, Color3.fromRGB(14, 125, 78), Color3.fromRGB(14, 88, 155), 0)
	create("UIStroke", { Color = Color3.fromRGB(145, 255, 195), Thickness = 2 }, spawnPackBtn)

	spawnPackBtn.Activated:Connect(function()
		local entry = SHOWCASE_MONSTERS[monsterIdx]
		sessionAction:FireServer("SummonMonster", entry.kind)
		monsterIdx = monsterIdx % #SHOWCASE_MONSTERS + 1
		local nextEntry = SHOWCASE_MONSTERS[monsterIdx]
		spawnPackBtn.Text = "👾 SPAWN: " .. nextEntry.label
	end)

	-- Arcade Kill Streak Combo Banner
	local comboBanner = create("Frame", {
		Name = "ComboBanner",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 164),
		Size = UDim2.fromOffset(220, 40),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, comboBanner)
	addGradient(comboBanner, Color3.fromRGB(255, 145, 0), Color3.fromRGB(255, 35, 95), 15)
	create("UIStroke", { Color = Color3.fromRGB(255, 245, 120), Thickness = 2.5 }, comboBanner)
	local comboScale = create("UIScale", { Scale = 1 }, comboBanner)
	local comboLabel = createLabel(comboBanner, {
		Size = UDim2.fromScale(1, 1),
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 190),
		Text = "🔥 COMBO x2!",
	})

	local lastKills = 0
	local streakCount = 0
	local lastKillClock = 0

	local function attribute(name: string, fallback: number): number
		local value = player:GetAttribute(name)
		return if typeof(value) == "number" then value else fallback
	end

	local function setFill(fill: Frame, ratio: number)
		TweenService:Create(fill, BAR_TWEEN, { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) }):Play()
	end

	local function refreshBossBar()
		local bossName = Workspace:GetAttribute("ActiveBossName")
		local bossPct = Workspace:GetAttribute("ActiveBossHpPct")
		local back = bossFill.Parent :: Frame
		if typeof(bossName) == "string" and bossName ~= "" and typeof(bossPct) == "number" and bossPct > 0 then
			back.Visible = true
			setFill(bossFill, bossPct)
			bossLabel.Text = string.format("👹 %s  (%d%%)", bossName, math.ceil(bossPct * 100))
		else
			back.Visible = false
		end
	end

	local function refresh()
		local phase = player:GetAttribute("Phase")
		gui.Enabled = (phase == "InRun" or phase == "Downed")

		local health = attribute("Health", 0)
		local maxHealth = math.max(attribute("MaxHealth", 1), 1)
		setFill(healthFill, health / maxHealth)
		healthLabel.Text = string.format("💚 HP: %d / %d", health, maxHealth)

		local ward = attribute("ArcaneWard", 0)
		local wardMax = attribute("ArcaneWardMax", 0)
		local wardFrame = wardFill.Parent :: Frame
		if wardMax > 0 then
			wardFrame.Visible = true
			setFill(wardFill, ward / wardMax)
			wardLabel.Text = string.format("🛡️ SHIELD: %d / %d", ward, wardMax)
		else
			wardFrame.Visible = false
		end

		local xpToNext = math.max(attribute("XpToNext", 1), 1)
		setFill(xpFill, attribute("Xp", 0) / xpToNext)
		xpLabel.Text =
			string.format("⭐ LEVEL %d   •   🎲 %d BONUS ROLLS", attribute("Level", 1), attribute("RerollDice", 0))

		local heroLvl = attribute("HeroLevel", 1)
		local avgIlvl = attribute("AvgIlvl", 0)
		local keystone = attribute("SelectedKeystone", 0)
		local keyTag = if keystone > 0 then string.format(" • 🗝️ M+%d", keystone) else ""
		soulsLabel.Text = string.format(
			"🟣 Souls %d  •  ⭐ Hero Lv.%d (iLvl %d)%s",
			attribute("Souls", 0),
			heroLvl,
			avgIlvl,
			keyTag
		)

		local friendPct = attribute("FriendBoostPct", 0)
		local bloodMoonRem = attribute("BloodMoonRemaining", 0)
		local rested = attribute("RestedXp", 0)
		local critPct = attribute("CritChance", 8)
		local critDmgPct = attribute("CritDamage", 200)
		local tags: { string } = {
			string.format("🎯 CRIT: %d%% (%d%% DMG)", critPct, critDmgPct),
		}
		if rested > 0 then
			table.insert(tags, "🟦 RESTED 200% XP!")
		end
		if friendPct > 0 then
			table.insert(tags, string.format("🤝 PARTY +%d%%", friendPct))
		end
		if bloodMoonRem > 0 then
			table.insert(tags, "🩸 BLOOD MOON 2x SOULS!")
		end
		buffsLabel.Text = table.concat(tags, "  •  ")

		-- Update 3-Slot Active Arsenal & Evolution Status
		local equippedRaw = player:GetAttribute("EquippedWeapons")
		local equippedStr = if typeof(equippedRaw) == "string" and equippedRaw ~= ""
			then equippedRaw
			else ((player:GetAttribute("SelectedWeapon") :: string?) or "ArcanistStaff")
		local equippedList = string.split(equippedStr, ",")

		local evolvedRaw = player:GetAttribute("EvolvedWeapons")
		local evolvedStr = if typeof(evolvedRaw) == "string" then evolvedRaw else ""
		local evolvedSet: { [string]: boolean } = {}
		for _, ew in ipairs(string.split(evolvedStr, ",")) do
			if ew ~= "" then
				evolvedSet[ew] = true
			end
		end

		for i = 1, 3 do
			local slotUi = arsenalSlots[i]
			local wId = equippedList[i]
			local meta = if wId and wId ~= "" then WeaponConfig.get(wId :: any) else nil
			if meta then
				local isEvolved = evolvedSet[wId] == true
				if isEvolved then
					slotUi.stroke.Color = Color3.fromRGB(255, 215, 55)
					slotUi.frame.BackgroundColor3 = Color3.fromRGB(58, 34, 14)
					slotUi.label.TextColor3 = Color3.fromRGB(255, 235, 115)
					slotUi.label.Text = string.format("🌟 %s %s", meta.icon, meta.name)
				else
					slotUi.stroke.Color = Color3.fromRGB(85, 235, 255)
					slotUi.frame.BackgroundColor3 = PANEL
					slotUi.label.TextColor3 = WHITE
					slotUi.label.Text = string.format("%s %s", meta.icon, meta.name)
				end
			else
				slotUi.stroke.Color = Color3.fromRGB(72, 68, 110)
				slotUi.frame.BackgroundColor3 = Color3.fromRGB(16, 12, 32)
				slotUi.label.TextColor3 = Color3.fromRGB(165, 175, 205)
				slotUi.label.Text = string.format("🔒 Slot %d (Lv.%d+)", i, if i == 2 then 4 else 8)
			end
		end

		local hasCleaver = table.find(equippedList, "CryptCleaver") ~= nil
		controlsHintLabel.Text = if hasCleaver
			then "🪓 Cleaver Aims Ahead of You!  •  [Space/Shift] Spectral Dash  •  Ignite Soul Braziers  •  [H] Guide"
			else "🕹️ Auto-Attack Active  •  [Space/Shift] Spectral Dash  •  Ignite Soul Braziers  •  [H] Guide"

		local kills = attribute("Kills", 0)
		killsLabel.Text = string.format("💀 KILLS: %d", kills)

		if kills > lastKills and phase == "InRun" then
			local now = os.clock()
			local diff = kills - lastKills
			if now - lastKillClock <= 4.0 then
				streakCount += diff
			else
				streakCount = diff
			end
			lastKillClock = now
			if streakCount >= 3 then
				comboBanner.Visible = true
				local title = if streakCount >= 20
					then "👑 GODLIKE STREAK"
					elseif streakCount >= 10 then "💥 MEGA FRENZY"
					elseif streakCount >= 5 then "⚡ ULTRA COMBO"
					else "🔥 MULTI-KILL"
				comboLabel.Text = string.format("%s x%d!", title, streakCount)
				comboScale.Scale = 1.25
				TweenService:Create(comboScale, POP_TWEEN, { Scale = 1.0 }):Play()
			end
		elseif kills == 0 then
			streakCount = 0
			comboBanner.Visible = false
		end
		lastKills = kills

		local compassAttr = player:GetAttribute("ObjectiveCompass")
		if typeof(compassAttr) == "string" and compassAttr ~= "" then
			compassLabel.Text = compassAttr
		end

		refreshBossBar()
	end

	local lastBannerRaw = ""
	local bannerHideAt = 0
	player:GetAttributeChangedSignal("FieldEventBanner"):Connect(function()
		local raw = player:GetAttribute("FieldEventBanner")
		if typeof(raw) == "string" and raw ~= "" and raw ~= lastBannerRaw then
			lastBannerRaw = raw
			local cleanText = string.gsub(raw, "%s*%(%d+%)$", "")
			eventBannerLabel.Text = cleanText
			eventBanner.Visible = true
			bannerHideAt = os.clock() + 4.2
		end
	end)

	player.AttributeChanged:Connect(refresh)
	Workspace:GetAttributeChangedSignal("ActiveBossName"):Connect(refreshBossBar)
	Workspace:GetAttributeChangedSignal("ActiveBossHpPct"):Connect(refreshBossBar)
	refresh()

	local shownSeconds = -1
	RunService.Heartbeat:Connect(function()
		local nowClock = os.clock()
		if comboBanner.Visible and nowClock - lastKillClock > 4.2 then
			comboBanner.Visible = false
		end
		if eventBanner.Visible and nowClock >= bannerHideAt then
			eventBanner.Visible = false
		end

		local runStart = player:GetAttribute("RunStart")
		if typeof(runStart) ~= "number" or player:GetAttribute("Phase") ~= "InRun" then
			return
		end
		local gameNow = GameClock.now()
		local dashReadyClock = attribute("DashReadyClock", 0)
		local dashRem = math.max(0, dashReadyClock - gameNow)
		if dashRem <= 0.05 then
			dashFill.Size = UDim2.fromScale(1, 1)
			dashStroke.Color = Color3.fromRGB(85, 240, 255)
			dashLabel.TextColor3 = Color3.fromRGB(220, 255, 250)
			dashLabel.Text = "💨 DASH [Space]"
		else
			local pct = math.clamp(1 - (dashRem / Constants.DASH_COOLDOWN), 0, 1)
			dashFill.Size = UDim2.fromScale(pct, 1)
			dashStroke.Color = Color3.fromRGB(95, 105, 145)
			dashLabel.TextColor3 = Color3.fromRGB(195, 205, 225)
			dashLabel.Text = string.format("⏳ DASH %.1fs", dashRem)
		end

		local seconds = math.max(0, math.floor(gameNow - runStart))
		if seconds ~= shownSeconds then
			shownSeconds = seconds
			timerLabel.Text = formatTime(seconds)
			milestoneLabel.Text = nextBossText(seconds)
		end

		local bTarget = attribute("BountyTarget", 0)
		local bExpires = attribute("BountyExpiresClock", 0)
		local bRem = math.max(0, math.ceil(bExpires - gameNow))
		if bTarget > 0 and bRem > 0 then
			local bKills = attribute("BountyKills", 0)
			bountyLabel.Visible = true
			bountyLabel.Text = string.format(
				"⚔️ WAVE BOUNTY: Slay %d Foes (%d / %d)  •  %ds Left  [+25🔮 +1🎲 +Chest]",
				bTarget,
				bKills,
				bTarget,
				bRem
			)
		else
			bountyLabel.Visible = false
		end

		local ccKindRaw = player:GetAttribute("CcKind")
		local ccKind = if typeof(ccKindRaw) == "string" then ccKindRaw else ""
		local ccExp = attribute("CcExpiresClock", 0)
		local ccRem = ccExp - gameNow
		if ccKind ~= "" and ccRem > 0.05 then
			ccBarFrame.Visible = true
			local maxDur = if ccKind == "Snare"
				then Constants.CC_SNARE_DURATION
				elseif ccKind == "Freeze" then Constants.CC_FREEZE_DURATION
				elseif ccKind == "Confuse" then Constants.CC_CONFUSE_DURATION
				else Constants.CC_CHARM_DURATION
			ccBarFill.Size = UDim2.fromScale(math.clamp(ccRem / math.max(0.5, maxDur), 0, 1), 1)
			if ccKind == "Freeze" then
				ccBarStroke.Color = Color3.fromRGB(115, 240, 255)
				ccBarFill.BackgroundColor3 = Color3.fromRGB(18, 138, 210)
				ccBarLabel.Text =
					string.format("❄️ FROZEN IN ICE (%.1fs) — Press [Space] DASH to Break Free!", ccRem)
			elseif ccKind == "Confuse" then
				ccBarStroke.Color = Color3.fromRGB(220, 125, 255)
				ccBarFill.BackgroundColor3 = Color3.fromRGB(115, 32, 175)
				ccBarLabel.Text =
					string.format("🌀 MIND CONFUSED (%.1fs) — Controls Scrambled! [Space] DASH to Cleanse!", ccRem)
			elseif ccKind == "Charm" then
				ccBarStroke.Color = Color3.fromRGB(255, 115, 205)
				ccBarFill.BackgroundColor3 = Color3.fromRGB(165, 24, 110)
				ccBarLabel.Text =
					string.format("💜 SIREN CHARMED (%.1fs) — Lured Toward Foe! [Space] DASH to Break!", ccRem)
			else
				ccBarStroke.Color = Color3.fromRGB(115, 255, 145)
				ccBarFill.BackgroundColor3 = Color3.fromRGB(22, 130, 68)
				ccBarLabel.Text =
					string.format("🕸️ WEB SNARED (%.1fs) — -48%% Speed! [Space] DASH to Cleanse!", ccRem)
			end
		else
			ccBarFrame.Visible = false
		end
	end)
end

return Hud
