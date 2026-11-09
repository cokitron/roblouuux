--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local RpgConfig = require(Shared:WaitForChild("RpgConfig") :: ModuleScript)
local WeaponConfig = require(Shared:WaitForChild("WeaponConfig") :: ModuleScript)

type RpgSyncPayload = RpgConfig.RpgSyncPayload
type GearItem = RpgConfig.GearItem

local BG_DARK = Color3.fromRGB(18, 14, 36)
local BG_CARD = Color3.fromRGB(28, 22, 56)
local BG_SLOT = Color3.fromRGB(22, 18, 44)
local BORDER_GOLD = Color3.fromRGB(255, 212, 68)
local BORDER_CYAN = Color3.fromRGB(65, 238, 255)
local BORDER_PURPLE = Color3.fromRGB(210, 105, 255)
local TEXT_WHITE = Color3.fromRGB(252, 253, 255)
local TEXT_MUTED = Color3.fromRGB(205, 216, 240)
local TEXT_GOLD = Color3.fromRGB(255, 228, 88)
local TEXT_CYAN = Color3.fromRGB(110, 250, 245)
local TEXT_GREEN = Color3.fromRGB(95, 255, 135)
local BTN_EMERALD = Color3.fromRGB(16, 138, 82)
local BTN_GOLD = Color3.fromRGB(178, 102, 14)
local BTN_PURPLE = Color3.fromRGB(108, 32, 175)
local BTN_SLATE = Color3.fromRGB(48, 44, 78)
local BTN_RED = Color3.fromRGB(168, 28, 52)
local WOW_RESTED_BLUE = Color3.fromRGB(0, 152, 235)
local WOW_XP_PURPLE = Color3.fromRGB(155, 48, 225)
local STROKE_DARK = Color3.fromRGB(8, 5, 18)

local LobbyAndDeathUi = {}

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
		Rotation = rot or 90,
	}, parent)
end

local function formatTime(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", whole // 60, whole % 60)
end

local function numAttr(player: Player, name: string, fallback: number): number
	local v = player:GetAttribute(name)
	return if typeof(v) == "number" and math.isfinite(v) then v else fallback
end

local function formatGearStats(item: GearItem): string
	local parts: { string } = {}
	if item.hp > 0 then
		table.insert(parts, string.format("+%d HP", item.hp))
	end
	if item.damagePct > 0 then
		table.insert(parts, string.format("+%d%% DMG", item.damagePct))
	end
	if item.critPct > 0 then
		table.insert(parts, string.format("+%d%% Crit", item.critPct))
	end
	if item.hastePct > 0 then
		table.insert(parts, string.format("+%d%% Haste", item.hastePct))
	end
	if item.armor > 0 then
		table.insert(parts, string.format("+%d Armor", item.armor))
	end
	if item.ward > 0 then
		table.insert(parts, string.format("+%d Ward", item.ward))
	end
	if item.magnetPct > 0 then
		table.insert(parts, string.format("+%d%% Magnet", item.magnetPct))
	end
	if item.xpPct > 0 then
		table.insert(parts, string.format("+%d%% XP", item.xpPct))
	end
	return table.concat(parts, " • ")
end

local function buildModalShell(gui: ScreenGui, name: string, titleText: string, subtitleText: string): (Frame, Frame)
	local overlay = create("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(14, 10, 32),
		BackgroundTransparency = 0.32,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)

	local card = create("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(920, 540),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, overlay)
	create("UICorner", { CornerRadius = UDim.new(0, 16) }, card)
	addGradient(card, Color3.fromRGB(48, 28, 98), Color3.fromRGB(22, 16, 48), 90)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 2.5 }, card)

	create("TextLabel", {
		Position = UDim2.fromOffset(22, 14),
		Size = UDim2.new(1, -90, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 23,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GOLD,
		Text = titleText,
	}, card)

	create("TextLabel", {
		Position = UDim2.fromOffset(22, 42),
		Size = UDim2.new(1, -90, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_MUTED,
		Text = subtitleText,
	}, card)

	local closeBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = BTN_RED,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = TEXT_WHITE,
		Text = "✕",
	}, card)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, closeBtn)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 1.5 }, closeBtn)
	closeBtn.Activated:Connect(function()
		overlay.Visible = false
	end)

	return overlay, card
end

function LobbyAndDeathUi.mount(playerGui: PlayerGui)
	local player = Players.LocalPlayer
	local sessionAction = Remotes.get("SessionAction")
	local rpgSyncRemote = Remotes.get("RpgSync")

	local latestRpg: RpgSyncPayload? = nil
	local lastSeenLootUid = ""

	local gui = create("ScreenGui", {
		Name = "WrapperUi",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 15,
	}, playerGui)

	-- =========================================================================
	-- FLOATING WOW LOOT TOAST BANNER (Shows on Boss Kill / Vault Claim)
	-- =========================================================================
	local lootToast = create("Frame", {
		Name = "LootToast",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 126),
		Size = UDim2.fromOffset(420, 66),
		BackgroundColor3 = BG_DARK,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, lootToast)
	local lootToastStroke = create("UIStroke", { Color = BORDER_PURPLE, Thickness = 2 }, lootToast)
	local lootToastTitle = create("TextLabel", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GOLD,
		Text = "🎁 LOOT ACQUIRED!",
		ZIndex = 31,
	}, lootToast)
	local lootToastBody = create("TextLabel", {
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		RichText = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = "",
		ZIndex = 31,
	}, lootToast)

	local function showLootToast(item: GearItem)
		local rInfo = RpgConfig.RARITY_INFO[item.rarity] or RpgConfig.RARITY_INFO[1]
		lootToastStroke.Color = rInfo.color
		lootToastTitle.Text = string.format("🎁 [%s] (iLvl %d)", item.name, item.ilvl)
		lootToastTitle.TextColor3 = rInfo.color
		lootToastBody.Text = string.format(
			'<font color="#%s">%s %s</font>  •  %s',
			rInfo.hex,
			rInfo.name,
			item.slot,
			formatGearStats(item)
		)
		lootToast.Visible = true
		local uid = item.uid
		task.delay(4.5, function()
			if lastSeenLootUid == uid then
				lootToast.Visible = false
			end
		end)
	end

	-- =========================================================================
	-- 1. SANCTUARY LOBBY HUD (Phase == "Lobby")
	-- =========================================================================
	local lobbyFrame = create("Frame", {
		Name = "LobbyView",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui)

	-- Hero Character & Rested XP Card (Top-Left)
	local walletCard = create("Frame", {
		Name = "SanctuaryHeader",
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.fromOffset(450, 96),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, lobbyFrame)
	create("UICorner", { CornerRadius = UDim.new(0, 14) }, walletCard)
	addGradient(walletCard, Color3.fromRGB(58, 28, 125), Color3.fromRGB(22, 48, 115), 25)
	create("UIStroke", { Color = BORDER_CYAN, Thickness = 2.2 }, walletCard)

	local heroHeaderLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GOLD,
		Text = "🏛️ Lv. 1 Initiate of the Sanctuary  •  iLvl 2",
	}, walletCard)

	local lobbyStatsLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -28, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		RichText = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = "🔮 Souls: 60  •  ✨ Dust: 10  •  🎲 Coins: 2  •  ⚜️ Neutral",
	}, walletCard)

	local heroXpBack = create("Frame", {
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 0, 26),
		BackgroundColor3 = BG_SLOT,
		BorderSizePixel = 0,
	}, walletCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, heroXpBack)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 1.2, Transparency = 0.25 }, heroXpBack)

	local heroXpFill = create("Frame", {
		Size = UDim2.fromScale(0.2, 1),
		BackgroundColor3 = WOW_RESTED_BLUE,
		BorderSizePixel = 0,
	}, heroXpBack)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, heroXpFill)

	local heroXpText = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = TEXT_WHITE,
		ZIndex = 2,
		Text = "Hero XP: 0 / 66 (🟦 RESTED: 200% XP!)",
	}, heroXpBack)

	-- Top Navigation Row Buttons (Weapon Arsenal, Armory [C], Talents [N], Mythic+/Vault [J], Treasury [M])
	local navRow = create("Frame", {
		Name = "NavRow",
		Position = UDim2.fromOffset(478, 14),
		Size = UDim2.new(1, -494, 0, 96),
		BackgroundTransparency = 1,
	}, lobbyFrame)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
	}, navRow)

	local function makeNavButton(
		title: string,
		sub: string,
		borderColor: Color3,
		gradTop: Color3,
		gradBot: Color3
	): (TextButton, TextLabel)
		local btn = create("TextButton", {
			Size = UDim2.new(0.2, -8, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AutoButtonColor = true,
			Text = "",
		}, navRow)
		create("UICorner", { CornerRadius = UDim.new(0, 14) }, btn)
		addGradient(btn, gradTop, gradBot, 90)
		create("UIStroke", { Color = borderColor, Thickness = 2.2 }, btn)

		create("TextLabel", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.new(1, -20, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 252, 242),
			TextStrokeColor3 = STROKE_DARK,
			TextStrokeTransparency = 0.05,
			Text = title,
		}, btn)

		local subLbl = create("TextLabel", {
			Position = UDim2.fromOffset(10, 38),
			Size = UDim2.new(1, -20, 0, 48),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextWrapped = true,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(228, 240, 255),
			TextStrokeColor3 = STROKE_DARK,
			TextStrokeTransparency = 0.10,
			Text = sub,
		}, btn)
		return btn, subLbl
	end

	local arsenalButton, arsenalEquippedLabel = makeNavButton(
		"🗡️ WEAPONS [G]",
		"🔮 Arcanist's Staff\nMastery Rank 1",
		BORDER_GOLD,
		Color3.fromRGB(20, 68, 152),
		Color3.fromRGB(12, 30, 82)
	)
	local armoryButton, armorySubLabel = makeNavButton(
		"🛡️ ARMORY [C]",
		"6-Slot Gear & Forge\nAvg iLvl 2",
		Color3.fromRGB(225, 135, 255),
		Color3.fromRGB(88, 22, 138),
		Color3.fromRGB(40, 12, 72)
	)
	local talentButton, talentSubLabel = makeNavButton(
		"🌟 TALENTS [N]",
		"Sanctuary Altar Tree\n0 Points Spent",
		BORDER_GOLD,
		Color3.fromRGB(145, 76, 14),
		Color3.fromRGB(74, 30, 10)
	)
	local keystoneButton, keystoneSubLabel = makeNavButton(
		"🗝️ MYTHIC+ [J]",
		"Keystones & Vault\nNormal Crypt",
		TEXT_GREEN,
		Color3.fromRGB(14, 105, 66),
		Color3.fromRGB(10, 46, 34)
	)
	local shopButton, shopSubLabel = makeNavButton(
		"👑 TREASURY [M]",
		"Heirlooms & Passes\n+10% Party Invite",
		BORDER_GOLD,
		Color3.fromRGB(148, 24, 68),
		Color3.fromRGB(66, 12, 36)
	)

	-- =========================================================================
	-- MODAL A: STARTING WEAPON ARSENAL
	-- =========================================================================
	local arsenalOverlay, arsenalCard = buildModalShell(
		gui,
		"ArsenalModal",
		"🗡️ CHOOSE YOUR STARTING WEAPON & ARTIFACT",
		"Level up your Weapon Artifact Mastery (Ranks 1–20) on every run to unlock permanent damage & bonus projectiles."
	)

	local weaponCardsContainer = create("Frame", {
		Position = UDim2.fromOffset(20, 68),
		Size = UDim2.new(1, -40, 1, -82),
		BackgroundTransparency = 1,
	}, arsenalCard)
	create("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -10, 0.5, -7),
		CellPadding = UDim2.fromOffset(12, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, weaponCardsContainer)

	local weaponEquipButtons: { [string]: TextButton } = {}
	local weaponMasteryLabels: { [string]: TextLabel } = {}

	for idx, weapon in WeaponConfig.getAll() do
		local col = create("Frame", {
			Name = weapon.id,
			LayoutOrder = idx,
			BackgroundColor3 = BG_DARK,
			BorderSizePixel = 0,
		}, weaponCardsContainer)
		create("UICorner", { CornerRadius = UDim.new(0, 10) }, col)
		create("UIStroke", { Color = BORDER_CYAN, Thickness = 1.4, Transparency = 0.25 }, col)

		create("TextLabel", {
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -20, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Merriweather,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_GOLD,
			Text = weapon.icon .. " " .. weapon.name,
		}, col)

		local masteryLbl = create("TextLabel", {
			Position = UDim2.fromOffset(10, 25),
			Size = UDim2.new(1, -20, 0, 15),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_CYAN,
			Text = "Artifact Mastery: Rank 1 / 20 (+0% DMG)",
		}, col)
		weaponMasteryLabels[weapon.id] = masteryLbl

		local atkBox = create("Frame", {
			Position = UDim2.fromOffset(10, 44),
			Size = UDim2.new(1, -20, 0, 66),
			BackgroundColor3 = BG_CARD,
			BorderSizePixel = 0,
		}, col)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, atkBox)
		create("TextLabel", {
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(1, -16, 1, -8),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			RichText = true,
			TextWrapped = true,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_WHITE,
			Text = string.format(
				'<b>⚔️ %s</b>  <font color="#ffd878">(%s)</font>\n<font color="#a5aebc">%s</font>',
				weapon.attackName,
				weapon.attackStats,
				weapon.attackDesc
			),
		}, atkBox)

		local auraBox = create("Frame", {
			Position = UDim2.fromOffset(10, 114),
			Size = UDim2.new(1, -20, 0, 56),
			BackgroundColor3 = BG_CARD,
			BorderSizePixel = 0,
		}, col)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, auraBox)
		create("TextLabel", {
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(1, -16, 1, -8),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			RichText = true,
			TextWrapped = true,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_WHITE,
			Text = string.format(
				'<b>🌀 %s</b>  <font color="#6effe1">(%s)</font>\n<font color="#a5aebc">%s</font>',
				weapon.auraName,
				weapon.auraStats,
				weapon.auraDesc
			),
		}, auraBox)

		local equipBtn = create("TextButton", {
			Name = "EquipButton",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -20, 0, 32),
			BackgroundColor3 = BTN_GOLD,
			BorderSizePixel = 0,
			AutoButtonColor = true,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = TEXT_WHITE,
			Text = "⚡ EQUIP WEAPON",
		}, col)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, equipBtn)
		weaponEquipButtons[weapon.id] = equipBtn

		equipBtn.Activated:Connect(function()
			sessionAction:FireServer("SelectWeapon", weapon.id)
			arsenalOverlay.Visible = false
		end)
	end

	-- =========================================================================
	-- MODAL B: 6-SLOT WOW ARMORY, TIER SETS & ENCHANTING FORGE [C]
	-- =========================================================================
	local armoryOverlay, armoryCard = buildModalShell(
		gui,
		"ArmoryModal",
		"🛡️ CHARACTER ARMORY & ENCHANTING FORGE [C]",
		"Equip WoW-Rarity Relics from Bosses & Runs. Disenchant spare loot into Arcane Dust to Enchant your 6 Slots (+1 to +10)."
	)

	local equippedColumn = create("Frame", {
		Position = UDim2.fromOffset(20, 70),
		Size = UDim2.fromOffset(430, 450),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, armoryCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, equippedColumn)

	local setStatusLabel = create("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		RichText = true,
		TextWrapped = true,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GREEN,
		Text = "Equip 2 or 4 matching Set pieces for Tier Set Bonuses!",
	}, equippedColumn)

	local slotRowsContainer = create("Frame", {
		Position = UDim2.fromOffset(10, 46),
		Size = UDim2.new(1, -20, 1, -54),
		BackgroundTransparency = 1,
	}, equippedColumn)
	create("UIListLayout", { Padding = UDim.new(0, 6) }, slotRowsContainer)

	local slotUiMap: { [string]: { stroke: UIStroke, title: TextLabel, sub: TextLabel, enchantBtn: TextButton } } = {}
	for _, slot in RpgConfig.GEAR_SLOTS do
		local meta = RpgConfig.SLOT_LABELS[slot]
		local row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundColor3 = BG_SLOT,
			BorderSizePixel = 0,
		}, slotRowsContainer)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
		local stroke = create("UIStroke", { Color = BTN_SLATE, Thickness = 1.4 }, row)

		local title = create("TextLabel", {
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -135, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_WHITE,
			Text = string.format("%s %s: Empty Slot", meta.icon, meta.name),
		}, row)

		local sub = create("TextLabel", {
			Position = UDim2.fromOffset(10, 26),
			Size = UDim2.new(1, -135, 0, 28),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextWrapped = true,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_MUTED,
			Text = "Defeat Mini-Bosses or finish runs to earn gear.",
		}, row)

		local enchBtn = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(116, 44),
			BackgroundColor3 = BTN_PURPLE,
			BorderSizePixel = 0,
			AutoButtonColor = true,
			RichText = true,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = TEXT_WHITE,
			Text = "✨ Enchant +1\n45🔮 8✨",
		}, row)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, enchBtn)
		enchBtn.Activated:Connect(function()
			sessionAction:FireServer("EnchantSlot", slot)
		end)

		slotUiMap[slot] = { stroke = stroke, title = title, sub = sub, enchantBtn = enchBtn }
	end

	-- Right Side of Armory: Bag Inventory + Disenchant All
	local bagColumn = create("Frame", {
		Position = UDim2.fromOffset(462, 70),
		Size = UDim2.fromOffset(438, 450),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, armoryCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, bagColumn)

	local bagHeaderLabel = create("TextLabel", {
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(250, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GOLD,
		Text = "🎒 RELIQUARY BAG (0 / 18)",
	}, bagColumn)

	local disenchantAllBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(165, 28),
		BackgroundColor3 = BTN_RED,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = TEXT_WHITE,
		Text = "✨ Disenchant All Bag",
	}, bagColumn)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, disenchantAllBtn)
	disenchantAllBtn.Activated:Connect(function()
		sessionAction:FireServer("DisenchantAll")
	end)

	local bagScroll = create("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 44),
		Size = UDim2.new(1, -20, 1, -52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, bagColumn)
	create("UIListLayout", { Padding = UDim.new(0, 6) }, bagScroll)

	-- =========================================================================
	-- MODAL C: 4-ROW TIERED SANCTUARY TALENT TREE [N]
	-- =========================================================================
	local talentOverlay, talentCard = buildModalShell(
		gui,
		"TalentModal",
		"🏛️ SANCTUARY SOUL ALTAR — SPECIALIZATION TREE [N]",
		"Spend harvested Souls to unlock permanent passive ranks. Spend 5 points in Tier 1 -> Tier 2 -> Tier 3 -> Row 4 Capstones!"
	)

	local talentPointsHeader = create("TextLabel", {
		Position = UDim2.fromOffset(24, 66),
		Size = UDim2.fromOffset(620, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_CYAN,
		Text = "Total Talent Points Invested: 0   •   Available Souls: 0 🔮",
	}, talentCard)

	local respecBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 62),
		Size = UDim2.fromOffset(210, 30),
		BackgroundColor3 = BTN_SLATE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = TEXT_GOLD,
		Text = "🔄 Free Respec (Refund All Souls)",
	}, talentCard)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, respecBtn)
	respecBtn.Activated:Connect(function()
		sessionAction:FireServer("RespecTalents")
	end)

	local talentGridFrame = create("ScrollingFrame", {
		Position = UDim2.fromOffset(20, 98),
		Size = UDim2.new(1, -40, 1, -110),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, talentCard)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(280, 102),
		CellPadding = UDim2.fromOffset(12, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, talentGridFrame)

	local talentNodeUi: {
		[string]: {
			stroke: UIStroke,
			rankLbl: TextLabel,
			buyBtn: TextButton,
		},
	} = {}

	for idx, node in ipairs(RpgConfig.TALENT_NODES) do
		local cell = create("Frame", {
			LayoutOrder = idx,
			BackgroundColor3 = BG_DARK,
			BorderSizePixel = 0,
		}, talentGridFrame)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, cell)
		local stroke = create("UIStroke", { Color = BORDER_CYAN, Thickness = 1.2, Transparency = 0.3 }, cell)

		create("TextLabel", {
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -90, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Merriweather,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_GOLD,
			Text = string.format("%s %s (Row %d)", node.icon, node.name, node.row),
		}, cell)

		local rankLbl = create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 6),
			Size = UDim2.fromOffset(75, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = TEXT_CYAN,
			Text = string.format("0 / %d", node.maxRank),
		}, cell)

		create("TextLabel", {
			Position = UDim2.fromOffset(10, 28),
			Size = UDim2.new(1, -20, 0, 32),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextWrapped = true,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_WHITE,
			Text = node.descPerRank,
		}, cell)

		local buyBtn = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.new(1, -20, 0, 28),
			BackgroundColor3 = BTN_EMERALD,
			BorderSizePixel = 0,
			AutoButtonColor = true,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = TEXT_WHITE,
			Text = "Learn (40 🔮)",
		}, cell)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, buyBtn)
		buyBtn.Activated:Connect(function()
			sessionAction:FireServer("BuyTalent", node.id)
		end)

		talentNodeUi[node.id] = { stroke = stroke, rankLbl = rankLbl, buyBtn = buyBtn }
	end

	-- =========================================================================
	-- MODAL D: MYTHIC+ CRYPT KEYSTONES, EMISSARY QUESTS & GREAT VAULT [J]
	-- =========================================================================
	local keystoneOverlay, keystoneCard = buildModalShell(
		gui,
		"KeystoneModal",
		"🗝️ MYTHIC+ CRYPT KEYSTONES, EMISSARY BOUNTIES & GREAT VAULT [J]",
		"Slot a Mythic+ Keystone to amplify Dungeon difficulty, Souls, and Loot Item Level, or claim Daily & Weekly Vault chests!"
	)

	-- Left Box: Mythic+ Selector + Great Vault
	local mythicBox = create("Frame", {
		Position = UDim2.fromOffset(20, 72),
		Size = UDim2.fromOffset(430, 446),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, keystoneCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, mythicBox)

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.new(1, -28, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 140, 40),
		Text = "🗝️ ACTIVE DUNGEON KEYSTONE",
	}, mythicBox)

	local keystoneDescLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 42),
		Size = UDim2.new(1, -28, 0, 56),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextWrapped = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = "Normal Crypt",
	}, mythicBox)

	local keystoneBtnRow = create("Frame", {
		Position = UDim2.fromOffset(14, 104),
		Size = UDim2.new(1, -28, 0, 40),
		BackgroundTransparency = 1,
	}, mythicBox)

	local keyMinusBtn = create("TextButton", {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(125, 38),
		BackgroundColor3 = BTN_SLATE,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = TEXT_WHITE,
		Text = "◀ Lower Tier",
	}, keystoneBtnRow)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, keyMinusBtn)

	local keyPlusBtn = create("TextButton", {
		Position = UDim2.fromOffset(140, 0),
		Size = UDim2.fromOffset(145, 38),
		BackgroundColor3 = BTN_GOLD,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = TEXT_WHITE,
		Text = "Raise Mythic+ ▶",
	}, keystoneBtnRow)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, keyPlusBtn)

	keyMinusBtn.Activated:Connect(function()
		local cur = numAttr(player, "SelectedKeystone", 0)
		sessionAction:FireServer("SetKeystone", math.max(0, cur - 1))
	end)
	keyPlusBtn.Activated:Connect(function()
		local cur = numAttr(player, "SelectedKeystone", 0)
		local highest = numAttr(player, "HighestKeystone", 1)
		sessionAction:FireServer("SetKeystone", math.min(highest, cur + 1))
	end)

	-- Great Crypt Vault Section inside Left Box
	local vaultBox = create("Frame", {
		Position = UDim2.fromOffset(14, 165),
		Size = UDim2.new(1, -28, 0, 265),
		BackgroundColor3 = BG_CARD,
		BorderSizePixel = 0,
	}, mythicBox)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, vaultBox)
	create("UIStroke", { Color = BORDER_PURPLE, Thickness = 1.5 }, vaultBox)

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GOLD,
		Text = "🏦 THE GREAT CRYPT VAULT (WEEKLY)",
	}, vaultBox)

	local vaultInfoLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 38),
		Size = UDim2.new(1, -28, 0, 145),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		TextWrapped = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = "",
	}, vaultBox)

	local claimVaultBtn = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -28, 0, 44),
		BackgroundColor3 = BTN_PURPLE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = TEXT_WHITE,
		Text = "🎁 CLAIM WEEKLY GREAT VAULT CHEST",
	}, vaultBox)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, claimVaultBtn)
	claimVaultBtn.Activated:Connect(function()
		sessionAction:FireServer("ClaimVault")
	end)

	-- Right Box: 3 Daily Emissary Quests
	local questBox = create("Frame", {
		Position = UDim2.fromOffset(462, 72),
		Size = UDim2.fromOffset(438, 446),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, keystoneCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, questBox)

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.new(1, -28, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_CYAN,
		Text = "📜 DAILY ASHEN ORDER EMISSARY BOUNTIES",
	}, questBox)

	local questRowsContainer = create("Frame", {
		Position = UDim2.fromOffset(12, 46),
		Size = UDim2.new(1, -24, 1, -58),
		BackgroundTransparency = 1,
	}, questBox)
	create("UIListLayout", { Padding = UDim.new(0, 10) }, questRowsContainer)

	local questUiMap: { [string]: { progLbl: TextLabel, claimBtn: TextButton } } = {}
	for _, q in RpgConfig.DAILY_QUESTS do
		local qCard = create("Frame", {
			Size = UDim2.new(1, 0, 0, 118),
			BackgroundColor3 = BG_CARD,
			BorderSizePixel = 0,
		}, questRowsContainer)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, qCard)
		create("UIStroke", { Color = BORDER_CYAN, Thickness = 1, Transparency = 0.4 }, qCard)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Merriweather,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_GOLD,
			Text = q.title,
		}, qCard)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -24, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_MUTED,
			Text = string.format(
				"%s  •  Reward: +%d🔮 +%d✨ +%d⚜️ +%d🎲",
				q.desc,
				q.rewardSouls,
				q.rewardDust,
				q.rewardRep,
				q.rewardDice
			),
		}, qCard)

		local progLbl = create("TextLabel", {
			Position = UDim2.fromOffset(12, 54),
			Size = UDim2.fromOffset(220, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_CYAN,
			Text = string.format("Progress: 0 / %d", q.target),
		}, qCard)

		local cBtn = create("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -10),
			Size = UDim2.fromOffset(160, 34),
			BackgroundColor3 = BTN_EMERALD,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = TEXT_WHITE,
			Text = "Claim Bounty",
		}, qCard)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, cBtn)
		cBtn.Activated:Connect(function()
			sessionAction:FireServer("ClaimDaily", q.id)
		end)
		questUiMap[q.id] = { progLbl = progLbl, claimBtn = cBtn }
	end

	-- =========================================================================
	-- MODAL E: SANCTUARY TREASURY, PASSES, BLOOD MOON & PARTY INVITE [M]
	-- =========================================================================
	local shopOverlay, shopCard = buildModalShell(
		gui,
		"ShopModal",
		"💎 SANCTUARY TREASURY, HEIRLOOMS & SERVER BUFFS [M]",
		"Amplify convenience, build variety, and server-wide generosity. In Studio, all products can be tested immediately!"
	)

	local shopGrid = create("Frame", {
		Position = UDim2.fromOffset(20, 72),
		Size = UDim2.new(1, -40, 1, -90),
		BackgroundTransparency = 1,
	}, shopCard)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(282, 212),
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, shopGrid)

	local function makeShopCard(
		order: number,
		title: string,
		desc: string,
		btnText: string,
		btnColor: Color3,
		onClick: () -> ()
	): TextButton
		local cell = create("Frame", {
			LayoutOrder = order,
			BackgroundColor3 = BG_DARK,
			BorderSizePixel = 0,
		}, shopGrid)
		create("UICorner", { CornerRadius = UDim.new(0, 10) }, cell)
		create("UIStroke", { Color = BORDER_GOLD, Thickness = 1.4, Transparency = 0.25 }, cell)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 10),
			Size = UDim2.new(1, -24, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.Merriweather,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_GOLD,
			Text = title,
		}, cell)

		create("TextLabel", {
			Position = UDim2.fromOffset(12, 38),
			Size = UDim2.new(1, -24, 0, 112),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			RichText = true,
			TextWrapped = true,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_WHITE,
			Text = desc,
		}, cell)

		local btn = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.new(1, -24, 0, 40),
			BackgroundColor3 = btnColor,
			BorderSizePixel = 0,
			AutoButtonColor = true,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = TEXT_WHITE,
			Text = btnText,
		}, cell)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
		btn.Activated:Connect(onClick)
		return btn
	end

	local starterPackBtn = makeShopCard(
		1,
		"🎁 Heirloom Starter Chest",
		"• <b>🟨 Heirloom Phylactery Trinket</b> (Scales iLvl with your Hero Level!)\n• <b>+500 Souls 🔮</b> & <b>+50 Arcane Dust ✨</b>\n• <b>+5 Bonus Roll Coins 🎲</b> + Full Rested Bar",
		"Claim Starter Pack (49 R$)",
		BTN_GOLD,
		function()
			sessionAction:FireServer("BuyStarterPack")
		end
	)

	local passFourthBtn = makeShopCard(
		2,
		"🃏 Archmage's Insight (+1 Card)",
		"• Shows <b>4 Talent Cards instead of 3</b> on every in-run Level-Up!\n• Grants <b>+1 Free Bonus Roll Coin</b> at the start of every run.",
		"Unlock Pass (299 R$)",
		BTN_PURPLE,
		function()
			sessionAction:FireServer("BuyGamePass", "FourthCard")
		end
	)

	local passMagnetBtn = makeShopCard(
		3,
		"🧲 Astral Loot Vacuum Pass",
		"• Permanently increases your base Soul Crystal Pickup Radius by <b>+50%</b>.\n• Effortless kiting during dense Mythic+ swarms.",
		"Unlock Pass (149 R$)",
		BTN_EMERALD,
		function()
			sessionAction:FireServer("BuyGamePass", "Magnet")
		end
	)

	local passDoubleSoulsBtn = makeShopCard(
		4,
		"🟣 2x Soul Harvester Tabard",
		"• Permanently <b>DOUBLES (2.0x) all Souls</b> earned from Graveyard runs and Daily Emissary Bounties!\n• Includes +200 Instant Souls.",
		"Unlock Pass (399 R$)",
		BTN_PURPLE,
		function()
			sessionAction:FireServer("BuyGamePass", "DoubleSouls")
		end
	)

	local bloodMoonBtn = makeShopCard(
		5,
		"🩸 Rallying Cry: Blood Moon",
		"• Ignites the Server Blood Moon Banner for <b>15 Minutes</b>!\n• Grants <b>EVERY player in the server 2x Souls, +50% Hero XP & +12% Speed/Haste</b>!",
		"Ignite Server Buff (99 R$)",
		BTN_RED,
		function()
			sessionAction:FireServer("BuyBloodMoon")
		end
	)

	makeShopCard(
		6,
		"🤝 Party Co-Op Boost (+10%)",
		"• Each Friend in your server grants <b>+10% Bonus XP & Souls</b> (up to +30%)!\n• Stand in a downed ally's circle for 3s to <b>Battle-Rez them for FREE</b>!",
		"📨 Invite Friends (+10% Souls)",
		BTN_EMERALD,
		function()
			pcall(function()
				SocialService:PromptGameInvite(player)
			end)
		end
	)

	-- =========================================================================
	-- MODAL F: ADVENTURER'S FIELD GUIDE & EVOLUTION CODEX ([H])
	-- =========================================================================
	local guideOverlay, guideCard = buildModalShell(
		gui,
		"FieldGuideModal",
		"📖 ADVENTURER'S FIELD GUIDE & EVOLUTION CODEX",
		"Master the Crypts: Auto-Attacks, 3-Weapon Drafting, Legendary Evolutions, Shrines & Mythic+ Progression."
	)

	local guideGrid = create("Frame", {
		Position = UDim2.fromOffset(22, 68),
		Size = UDim2.new(1, -44, 1, -84),
		BackgroundTransparency = 1,
	}, guideCard)
	create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -8, 0.5, -8),
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, guideGrid)

	local GUIDE_SECTIONS = {
		{
			title = "⚔️ 1. COMBAT, CROWD-CONTROL & DASH CLEANSE",
			color = BORDER_CYAN,
			body = "• <b>Auto-Attack & Cleave:</b> Ranged weapons target nearest foes; <b>Crypt Cleaver</b> sweeps a <b>125° Frontal Cone</b> in the direction you face.\n"
				.. "• <b>Monster Crowd-Control:</b> Watch out for <b>🕸️ Snare</b> (-48% Speed), <b>❄️ Freeze</b> (Ice Root), <b>🌀 Confuse</b> (Scrambled Steering) & <b>💜 Charm</b> (Siren Pull)!\n"
				.. "• <b>Spectral Dash [Space / Shift / E]:</b> Instantly <b>breaks all Crowd-Control</b> and grants <b>2.5s Unstoppable Immunity</b> + shockwave knockback!",
		},
		{
			title = "🌟 2. MULTI-WEAPON DRAFT & EVOLUTIONS",
			color = BORDER_GOLD,
			body = "• <b>Wield Up to 3 Weapons:</b> Unlock your <b>2nd Weapon at Lv.4+</b> and your <b>3rd Weapon at Lv.8+</b> via Arsenal Level-Up Cards!\n"
				.. "• <b>Legendary Evolutions:</b> At <b>Lv.7+</b> with any weapon's <b>Primary Damage Talent at Rank 3+</b>, unlock its <b>🌟 EVOLUTION Capstone</b>:\n"
				.. "  🔮 Staff → <i>Astral Starfall</i>   •   🪓 Cleaver → <i>Crimson Guillotine</i>\n"
				.. "  🏮 Lantern → <i>Ashen Hellstorm</i>   •   🏹 Bow → <i>Thousand-Arrow Tempest</i>\n"
				.. "  🔫 Pistols → <i>Silver Executioner</i>   •   ⚡ Tome → <i>Mjolnir's Wrath</i>",
		},
		{
			title = "🔥 3. CRYPT SHRINES, RELIQUARIES & BOSSES",
			color = TEXT_GREEN,
			body = "• <b>Soul Braziers:</b> Stand inside a glowing cyan Brazier ring for <b>2.5s</b> to ignite it for <b>+25 Heal, +25 Ward, +4% Crit, +10% Haste & +15 Souls</b>!\n"
				.. "• <b>Crypt Reliquary Chests:</b> Slaying Mini-Bosses (3:00, 6:00, 9:00) and completing <b>Wave Bounties</b> drops Golden Reliquaries on the field—walk over them for instant XP bursts, Souls & Reroll Coins!\n"
				.. "• <b>Cursed Soul Urns:</b> Smash glowing purple urns with your attacks for bonus XP crystals!",
		},
		{
			title = "🏛️ 4. SANCTUARY RPG & NO DEAD RUNS",
			color = BORDER_PURPLE,
			body = "• <b>Every Run Rewards You:</b> Even a short run grants <b>Souls (🔮)</b>, <b>Hero XP</b>, <b>Artifact Mastery</b>, and a <b>Guaranteed 6-Slot RPG Gear Drop</b>!\n"
				.. "• <b>Hotkeys:</b> <b>[G]</b> Weapons • <b>[C]</b> Armory & Enchanting • <b>[N]</b> Sanctuary Talents • <b>[J]</b> Mythic+ Keystones & Weekly Vault • <b>[B]</b> Bestiary Grimoire • <b>[M]</b> Treasury • <b>[H]</b> Field Guide.",
		},
	}

	for idx, sec in ipairs(GUIDE_SECTIONS) do
		local gCell = create("Frame", {
			LayoutOrder = idx,
			BackgroundColor3 = BG_DARK,
			BorderSizePixel = 0,
		}, guideGrid)
		create("UICorner", { CornerRadius = UDim.new(0, 10) }, gCell)
		create("UIStroke", { Color = sec.color, Thickness = 1.6 }, gCell)

		create("TextLabel", {
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.Merriweather,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = sec.color,
			Text = sec.title,
		}, gCell)

		create("TextLabel", {
			Position = UDim2.fromOffset(14, 38),
			Size = UDim2.new(1, -28, 1, -48),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			RichText = true,
			TextWrapped = true,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = TEXT_WHITE,
			Text = sec.body,
		}, gCell)
	end

	-- =========================================================================
	-- MODAL G: CRYPT BESTIARY & EVOLUTION GRIMOIRE COMPENDIUM ([B])
	-- =========================================================================
	local grimoireOverlay, grimoireCard = buildModalShell(
		gui,
		"GrimoireModal",
		"📖 CRYPT BESTIARY & EVOLUTION GRIMOIRE [B]",
		"Slay monsters and forge Legendary Weapon Evolutions to unlock their Grimoire entries. Every discovery grants a permanent +0.5% All Damage & +1 Max HP bonus!"
	)

	local grimoireHeaderLabel = create("TextLabel", {
		Position = UDim2.fromOffset(24, 64),
		Size = UDim2.new(1, -48, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_CYAN,
		Text = "📖 Grimoire Discoveries: 0 / 24   •   Permanent Compendium Bonus: +0.0% All DMG & +0 Max HP",
	}, grimoireCard)

	local grimoireScroll = create("ScrollingFrame", {
		Position = UDim2.fromOffset(20, 92),
		Size = UDim2.new(1, -40, 1, -106),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, grimoireCard)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(210, 86),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grimoireScroll)

	type GrimoireCellUi = {
		stroke: UIStroke,
		title: TextLabel,
		cat: TextLabel,
		lore: TextLabel,
	}
	local grimoireUiMap: { [string]: GrimoireCellUi } = {}
	for idx, entry in ipairs(RpgConfig.GRIMOIRE_ENTRIES) do
		local cell = create("Frame", {
			LayoutOrder = idx,
			BackgroundColor3 = BG_DARK,
			BorderSizePixel = 0,
		}, grimoireScroll)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, cell)
		local stroke = create("UIStroke", { Color = BTN_SLATE, Thickness = 1.4 }, cell)

		local title = create("TextLabel", {
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.new(1, -16, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_MUTED,
			Text = "🔒 ??? (Undiscovered)",
		}, cell)

		local cat = create("TextLabel", {
			Position = UDim2.fromOffset(8, 24),
			Size = UDim2.new(1, -16, 0, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = TEXT_CYAN,
			Text = string.upper(entry.category) .. "  •  +0.5% DMG, +1 HP",
		}, cell)

		local lore = create("TextLabel", {
			Position = UDim2.fromOffset(8, 40),
			Size = UDim2.new(1, -16, 0, 40),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextWrapped = true,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = TEXT_MUTED,
			Text = if entry.category == "Evolution"
				then "Evolve this weapon in a run to unlock its codex."
				else "Defeat this creature in the Haunted Crypts to record it.",
		}, cell)

		grimoireUiMap[entry.id] = {
			stroke = stroke,
			title = title,
			cat = cat,
			lore = lore,
		}
	end

	-- Compact Sanctuary Quick-Guide Card on Left Side of Lobby
	local quickGuideCard = create("Frame", {
		Name = "QuickGuideCard",
		Position = UDim2.fromOffset(16, 122),
		Size = UDim2.fromOffset(330, 196),
		BackgroundColor3 = BG_DARK,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, lobbyFrame)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, quickGuideCard)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 1.8 }, quickGuideCard)

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_GOLD,
		Text = "🏛️ SANCTUARY CHAPEL BRIEFING",
	}, quickGuideCard)

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 114),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		TextWrapped = true,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = TEXT_WHITE,
		Text = "• <b>West Aisle:</b> Walk over <b>6 Weapon Pedestals</b> to equip & preview.\n"
			.. "• <b>East Combat Yard:</b> Attack <b>3 Target Dummies</b> with live DPS meter!\n"
			.. "• <b>Central Soul Font:</b> Claim <b>+20 Ward & +10% Speed</b> before deploying.\n"
			.. "• <b>South Narthex:</b> Step into the <b>Solo</b> or <b>Co-Op (+15% Souls)</b> Portal!",
	}, quickGuideCard)

	local openGuideBtn = create("TextButton", {
		Position = UDim2.fromOffset(12, 152),
		Size = UDim2.fromOffset(148, 34),
		BackgroundColor3 = BTN_PURPLE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = TEXT_WHITE,
		Text = "📘 FIELD GUIDE [H]",
	}, quickGuideCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, openGuideBtn)
	create("UIStroke", { Color = BORDER_CYAN, Thickness = 1.4 }, openGuideBtn)

	local openGrimoireBtn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 152),
		Size = UDim2.fromOffset(148, 34),
		BackgroundColor3 = BTN_GOLD,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = TEXT_WHITE,
		Text = "📖 GRIMOIRE [B]",
	}, quickGuideCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, openGrimoireBtn)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 1.4 }, openGrimoireBtn)

	-- Modal Open Wiring
	local function closeAllModals()
		arsenalOverlay.Visible = false
		armoryOverlay.Visible = false
		talentOverlay.Visible = false
		keystoneOverlay.Visible = false
		shopOverlay.Visible = false
		guideOverlay.Visible = false
		grimoireOverlay.Visible = false
	end

	openGuideBtn.Activated:Connect(function()
		local nextState = not guideOverlay.Visible
		closeAllModals()
		guideOverlay.Visible = nextState
	end)
	openGrimoireBtn.Activated:Connect(function()
		local nextState = not grimoireOverlay.Visible
		closeAllModals()
		grimoireOverlay.Visible = nextState
	end)
	arsenalButton.Activated:Connect(function()
		local nextState = not arsenalOverlay.Visible
		closeAllModals()
		arsenalOverlay.Visible = nextState
	end)
	armoryButton.Activated:Connect(function()
		local nextState = not armoryOverlay.Visible
		closeAllModals()
		armoryOverlay.Visible = nextState
	end)
	talentButton.Activated:Connect(function()
		local nextState = not talentOverlay.Visible
		closeAllModals()
		talentOverlay.Visible = nextState
	end)
	keystoneButton.Activated:Connect(function()
		local nextState = not keystoneOverlay.Visible
		closeAllModals()
		keystoneOverlay.Visible = nextState
	end)
	shopButton.Activated:Connect(function()
		local nextState = not shopOverlay.Visible
		closeAllModals()
		shopOverlay.Visible = nextState
	end)

	-- 3D Diegetic Sanctuary Chapel Alcove Stations -> Open Modal Trigger
	local lastModalTrigger = ""
	player:GetAttributeChangedSignal("OpenLobbyModal"):Connect(function()
		local raw = player:GetAttribute("OpenLobbyModal")
		if typeof(raw) ~= "string" or raw == "" or raw == lastModalTrigger then
			return
		end
		lastModalTrigger = raw
		local modalName = string.match(raw, "^(%a+)")
		if not modalName then
			return
		end
		closeAllModals()
		if modalName == "Talents" then
			talentOverlay.Visible = true
		elseif modalName == "Armory" then
			armoryOverlay.Visible = true
		elseif modalName == "Keystone" then
			keystoneOverlay.Visible = true
		elseif modalName == "Shop" then
			shopOverlay.Visible = true
		elseif modalName == "Arsenal" then
			arsenalOverlay.Visible = true
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local phase = player:GetAttribute("Phase")
		if phase ~= "Lobby" and phase ~= "InRun" then
			return
		end
		if input.KeyCode == Enum.KeyCode.G then
			local nextState = not arsenalOverlay.Visible
			closeAllModals()
			arsenalOverlay.Visible = nextState
		elseif input.KeyCode == Enum.KeyCode.C then
			local nextState = not armoryOverlay.Visible
			closeAllModals()
			armoryOverlay.Visible = nextState
		elseif input.KeyCode == Enum.KeyCode.N then
			local nextState = not talentOverlay.Visible
			closeAllModals()
			talentOverlay.Visible = nextState
		elseif input.KeyCode == Enum.KeyCode.J then
			local nextState = not keystoneOverlay.Visible
			closeAllModals()
			keystoneOverlay.Visible = nextState
		elseif input.KeyCode == Enum.KeyCode.M then
			local nextState = not shopOverlay.Visible
			closeAllModals()
			shopOverlay.Visible = nextState
		elseif input.KeyCode == Enum.KeyCode.H then
			local nextState = not guideOverlay.Visible
			closeAllModals()
			guideOverlay.Visible = nextState
		elseif input.KeyCode == Enum.KeyCode.B then
			local nextState = not grimoireOverlay.Visible
			closeAllModals()
			grimoireOverlay.Visible = nextState
		end
	end)

	local deployButton = create("TextButton", {
		Name = "DeployButton",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(390, 66),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		RichText = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 21,
		TextColor3 = TEXT_WHITE,
		TextStrokeColor3 = STROKE_DARK,
		TextStrokeTransparency = 0.05,
		Text = '⚔️ PLAY! ENTER THE CRYPT! 🔥\n<font size="13" color="#ffe885">Walk into Portal or Click to Battle!</font>',
	}, lobbyFrame)
	create("UICorner", { CornerRadius = UDim.new(0, 16) }, deployButton)
	addGradient(deployButton, Color3.fromRGB(16, 152, 86), Color3.fromRGB(10, 88, 64), 90)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 2.8 }, deployButton)

	deployButton.Activated:Connect(function()
		closeAllModals()
		sessionAction:FireServer("StartRun")
	end)

	-- =========================================================================
	-- 2. DOWNED / SOULSTONE BATTLE-REZ MODAL (Phase == "Downed", MON-6 0.8s Grace)
	-- =========================================================================
	local downedOverlay = create("Frame", {
		Name = "DownedModal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(32, 8, 14),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)

	local downedCard = create("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 380),
		BackgroundColor3 = BG_CARD,
		BorderSizePixel = 0,
	}, downedOverlay)
	create("UICorner", { CornerRadius = UDim.new(0, 14) }, downedCard)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 2.5 }, downedCard)

	create("TextLabel", {
		Position = UDim2.fromOffset(20, 14),
		Size = UDim2.new(1, -40, 0, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 25,
		TextColor3 = TEXT_GOLD,
		Text = "💀 SOULSTONE TRIGGERED...",
	}, downedCard)

	local revivesLeftLabel = create("TextLabel", {
		Position = UDim2.fromOffset(20, 46),
		Size = UDim2.new(1, -40, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = TEXT_CYAN,
		Text = "Soulstone Revives Remaining: 2 / 2",
	}, downedCard)

	local benefitBox = create("Frame", {
		Position = UDim2.fromOffset(22, 72),
		Size = UDim2.new(1, -44, 0, 82),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, downedCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, benefitBox)
	create("UIStroke", { Color = BORDER_CYAN, Thickness = 1, Transparency = 0.45 }, benefitBox)

	create("TextLabel", {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 1, -12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = '<b><font color="#6effe1">⚡ REINCARNATION / BATTLE REZ</font></b>\n'
			.. "• Restore <b>100% Max Health</b> & Keep All In-Run Talents\n"
			.. "• Detonate a <b>36-Stud Eldritch Nova</b> + 3s Divine Shield",
	}, benefitBox)

	local timerTrack = create("Frame", {
		Position = UDim2.fromOffset(22, 164),
		Size = UDim2.new(1, -44, 0, 20),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, downedCard)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, timerTrack)

	local timerFill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 165, 45),
		BorderSizePixel = 0,
	}, timerTrack)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, timerFill)

	local timerText = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = TEXT_WHITE,
		ZIndex = 2,
		Text = "10.0s",
	}, timerTrack)

	local reviveButton = create("TextButton", {
		Name = "ReviveButton",
		Position = UDim2.fromOffset(22, 194),
		Size = UDim2.new(1, -44, 0, 52),
		BackgroundColor3 = BTN_GOLD,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		RichText = true,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = TEXT_WHITE,
		Text = '⚡ USE SOULSTONE — KEEP BUILD\n<font size="12" color="#fff2c2">Full Heal + Eldritch Nova Clear</font>',
	}, downedCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, reviveButton)
	create("UIStroke", { Color = TEXT_GOLD, Thickness = 1.5 }, reviveButton)

	local softReviveButton = create("TextButton", {
		Name = "SoftReviveButton",
		Position = UDim2.fromOffset(22, 254),
		Size = UDim2.new(1, -44, 0, 44),
		BackgroundColor3 = BTN_PURPLE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = TEXT_WHITE,
		Text = string.format("🔮 Self-Rez with %d Souls", Constants.SOUL_REVIVE_SOFT_COST),
	}, downedCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, softReviveButton)

	local declineButton = create("TextButton", {
		Name = "DeclineButton",
		Position = UDim2.fromOffset(22, 306),
		Size = UDim2.new(1, -44, 0, 34),
		BackgroundColor3 = BTN_SLATE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = TEXT_MUTED,
		Text = "Release Spirit (Claim Run Rewards & Loot)",
	}, downedCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, declineButton)

	local coopRescueLabel = create("TextLabel", {
		Position = UDim2.fromOffset(22, 344),
		Size = UDim2.new(1, -44, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = TEXT_CYAN,
		Text = "🤝 Co-Op: Allies can stand near you for 3s to Battle-Rez you!",
	}, downedCard)

	local downedClickableAt = 0

	reviveButton.Activated:Connect(function()
		if os.clock() < downedClickableAt then
			return
		end
		sessionAction:FireServer("RequestRevive")
	end)
	softReviveButton.Activated:Connect(function()
		if os.clock() < downedClickableAt then
			return
		end
		sessionAction:FireServer("RequestSoftRevive")
	end)
	declineButton.Activated:Connect(function()
		if os.clock() < downedClickableAt then
			return
		end
		sessionAction:FireServer("DeclineRevive")
	end)

	if Constants.REVIVE_PRODUCT_ID > 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(Constants.REVIVE_PRODUCT_ID, Enum.InfoType.Product)
			end)
			if ok and typeof(info) == "table" and typeof(info.PriceInRobux) == "number" then
				reviveButton.Text = string.format(
					'⚡ USE SOULSTONE (%d R$)\n<font size="12" color="#fff2c2">Keep Build + Eldritch Nova</font>',
					info.PriceInRobux
				)
			end
		end)
	end

	-- =========================================================================
	-- 3. END-OF-RUN SUMMARY & WOW LOOT DROP MODAL (Phase == "Summary", LOOP-3)
	-- =========================================================================
	local summaryOverlay = create("Frame", {
		Name = "SummaryModal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 14, 22),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)

	local summaryCard = create("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(480, 420),
		BackgroundColor3 = BG_CARD,
		BorderSizePixel = 0,
	}, summaryOverlay)
	create("UICorner", { CornerRadius = UDim.new(0, 14) }, summaryCard)
	create("UIStroke", { Color = BORDER_CYAN, Thickness = 2 }, summaryCard)

	local summaryTitleLabel = create("TextLabel", {
		Position = UDim2.fromOffset(20, 14),
		Size = UDim2.new(1, -40, 0, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.Merriweather,
		TextSize = 25,
		TextColor3 = TEXT_CYAN,
		Text = "🕯️ DUNGEON RUN COMPLETE",
	}, summaryCard)

	local statsBox = create("Frame", {
		Position = UDim2.fromOffset(22, 52),
		Size = UDim2.new(1, -44, 0, 145),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, summaryCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, statsBox)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 1, Transparency = 0.5 }, statsBox)

	local summaryBodyLabel = create("TextLabel", {
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -32, 1, -16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		RichText = true,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = "",
	}, statsBox)

	-- Dropped WoW Gear Card inside Summary
	local summaryLootBox = create("Frame", {
		Position = UDim2.fromOffset(22, 208),
		Size = UDim2.new(1, -44, 0, 84),
		BackgroundColor3 = BG_DARK,
		BorderSizePixel = 0,
	}, summaryCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, summaryLootBox)
	local summaryLootStroke = create("UIStroke", { Color = BORDER_PURPLE, Thickness = 1.8 }, summaryLootBox)

	local summaryLootLabel = create("TextLabel", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 1, -16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		RichText = true,
		TextWrapped = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = TEXT_WHITE,
		Text = "🎁 Loot Acquired: Inspect in Armory [C]",
	}, summaryLootBox)

	local summaryWalletLabel = create("TextLabel", {
		Position = UDim2.fromOffset(22, 302),
		Size = UDim2.new(1, -44, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = TEXT_GOLD,
		Text = "Sanctuary Wallet: 0 Souls 🔮",
	}, summaryCard)

	local playAgainButton = create("TextButton", {
		Name = "PlayAgainButton",
		Position = UDim2.fromOffset(22, 340),
		Size = UDim2.fromOffset(210, 56),
		BackgroundColor3 = BTN_EMERALD,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = TEXT_WHITE,
		Text = "⚔️ PLAY AGAIN",
	}, summaryCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, playAgainButton)
	create("UIStroke", { Color = BORDER_GOLD, Thickness = 1.5 }, playAgainButton)

	local returnLobbyButton = create("TextButton", {
		Name = "ReturnLobbyButton",
		Position = UDim2.new(1, -232, 0, 340),
		Size = UDim2.fromOffset(210, 56),
		BackgroundColor3 = BTN_PURPLE,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = TEXT_WHITE,
		Text = "🏛️ SANCTUARY & ARMORY",
	}, summaryCard)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, returnLobbyButton)
	create("UIStroke", { Color = BORDER_CYAN, Thickness = 1.2, Transparency = 0.3 }, returnLobbyButton)

	playAgainButton.Activated:Connect(function()
		sessionAction:FireServer("StartRun")
	end)
	returnLobbyButton.Activated:Connect(function()
		sessionAction:FireServer("ReturnToLobby")
	end)

	-- =========================================================================
	-- RPG SYNC & UI POPULATOR
	-- =========================================================================
	local function renderRpgModals(data: RpgSyncPayload)
		-- 1. Top Header & Nav Badges
		local repName, repCur, repMax = RpgConfig.getReputationBracket(data.reputation)
		heroHeaderLabel.Text =
			string.format("🏛️ Lv.%d %s  •  Avg iLvl %d", data.heroLevel, data.title, data.avgIlvl)
		lobbyStatsLabel.Text = string.format(
			"🔮 Souls: <b>%d</b>  •  ✨ Dust: <b>%d</b>  •  🎲 Coins: <b>%d</b>  •  ⚜️ %s (%d/%d)",
			data.souls,
			data.arcaneDust,
			data.fateDice,
			repName,
			repCur,
			repMax
		)

		local xpRatio = math.clamp(data.heroXp / math.max(1, data.heroXpToNext), 0, 1)
		heroXpFill.Size = UDim2.fromScale(xpRatio, 1)
		heroXpFill.BackgroundColor3 = if data.restedXp > 0 then WOW_RESTED_BLUE else WOW_XP_PURPLE
		heroXpText.Text = if data.restedXp > 0
			then string.format(
				"Hero XP: %d / %d  (🟦 RESTED: +%d XP Pool • 200%% XP!)",
				data.heroXp,
				data.heroXpToNext,
				data.restedXp
			)
			else string.format("Hero XP: %d / %d", data.heroXp, data.heroXpToNext)

		armorySubLabel.Text = string.format(
			"Avg iLvl %d • %d Bag Items\nSet Pieces: %d/4",
			data.avgIlvl,
			#data.bagGear,
			data.activeSetCount
		)

		local totalTalentPts = 0
		for _, r in pairs(data.talents) do
			totalTalentPts += r
		end
		talentSubLabel.Text = string.format("%d Points Invested\n%d Souls Available", totalTalentPts, data.souls)

		local kInfo = RpgConfig.getKeystoneInfo(data.selectedKeystone)
		keystoneSubLabel.Text = string.format("%s\nVault Runs: %d/4", kInfo.name, data.weeklyRuns)
		deployButton.Text = string.format(
			'⚔️ ENTER %s\n<font size="13" color="#ffe885">Walk into Portal or Click to Deploy</font>',
			string.upper(kInfo.name)
		)

		if data.bloodMoonEndsAt > 0 then
			shopSubLabel.Text =
				string.format("🩸 Blood Moon Active (%ds)\nBy %s!", data.bloodMoonEndsAt, data.bloodMoonBuyer)
		else
			shopSubLabel.Text = "Heirlooms, Passes & Totem\n+10% Party Invite"
		end

		-- 2. Weapon Mastery Labels
		for wId, lbl in pairs(weaponMasteryLabels) do
			local mRank = data.weaponMastery[wId] or 1
			lbl.Text = string.format(
				"Artifact Mastery: Rank %d / 20 (+%d%% DMG%s)",
				mRank,
				(mRank - 1) * 3,
				if mRank >= 10 then " • +1 Aura" else ""
			)
		end

		-- 3. 6-Slot Armory & Bag
		if data.activeSetCount >= 4 then
			setStatusLabel.Text =
				string.format("🌟 ACTIVE 4-PIECE SET (%s): +12%% DMG + Full 4pc Bonus Active!", data.activeSetName)
		elseif data.activeSetCount >= 2 then
			setStatusLabel.Text = string.format(
				"✨ ACTIVE 2-PIECE SET (%s): +12%% All Damage! (%d/4 for 4pc)",
				data.activeSetName,
				data.activeSetCount
			)
		else
			setStatusLabel.Text = "Equip 2 or 4 matching Set pieces (Rare+) to activate Tier Set Bonuses!"
		end

		for _, slot in RpgConfig.GEAR_SLOTS do
			local ui = slotUiMap[slot]
			local meta = RpgConfig.SLOT_LABELS[slot]
			local item = data.equippedGear[slot]
			local ench = data.slotEnchants[slot] or 0
			local enchTag = if ench > 0 then string.format(" (+%d Enchant)", ench) else ""

			if item then
				local rInfo = RpgConfig.RARITY_INFO[item.rarity] or RpgConfig.RARITY_INFO[1]
				ui.stroke.Color = rInfo.color
				ui.title.TextColor3 = rInfo.color
				ui.title.Text =
					string.format("%s [%s] • iLvl %d%s", meta.icon, item.name, item.ilvl + ench * 2, enchTag)
				local setTag = if item.setId and RpgConfig.ITEM_SETS[item.setId]
					then " • Set: " .. RpgConfig.ITEM_SETS[item.setId].name
					else ""
				ui.sub.Text = formatGearStats(item) .. setTag
			else
				ui.stroke.Color = BTN_SLATE
				ui.title.TextColor3 = TEXT_MUTED
				ui.title.Text = string.format("%s %s: Empty%s", meta.icon, meta.name, enchTag)
				ui.sub.Text = "No relic equipped in this slot."
			end

			if ench >= 10 then
				ui.enchantBtn.Text = "MAX +10"
				ui.enchantBtn.BackgroundColor3 = BTN_SLATE
			else
				local cSouls, cDust = RpgConfig.getEnchantCost(ench)
				ui.enchantBtn.Text = string.format("✨ Enchant +%d\n%d🔮 %d✨", ench + 1, cSouls, cDust)
				ui.enchantBtn.BackgroundColor3 = if data.souls >= cSouls and data.arcaneDust >= cDust
					then BTN_PURPLE
					else BTN_SLATE
			end
		end

		for _, child in ipairs(bagScroll:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		bagHeaderLabel.Text = string.format("🎒 RELIQUARY BAG (%d / 18)", #data.bagGear)

		for _, item in ipairs(data.bagGear) do
			local rInfo = RpgConfig.RARITY_INFO[item.rarity] or RpgConfig.RARITY_INFO[1]
			local bRow = create("Frame", {
				Size = UDim2.new(1, -8, 0, 62),
				BackgroundColor3 = BG_SLOT,
				BorderSizePixel = 0,
			}, bagScroll)
			create("UICorner", { CornerRadius = UDim.new(0, 8) }, bRow)
			create("UIStroke", { Color = rInfo.color, Thickness = 1.3 }, bRow)

			create("TextLabel", {
				Position = UDim2.fromOffset(10, 6),
				Size = UDim2.new(1, -165, 0, 20),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = rInfo.color,
				Text = string.format("[%s] (%s • iLvl %d)", item.name, item.slot, item.ilvl),
			}, bRow)

			create("TextLabel", {
				Position = UDim2.fromOffset(10, 26),
				Size = UDim2.new(1, -165, 0, 30),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextWrapped = true,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = TEXT_WHITE,
				Text = formatGearStats(item),
			}, bRow)

			local eqBtn = create("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -80, 0.5, 0),
				Size = UDim2.fromOffset(72, 38),
				BackgroundColor3 = BTN_EMERALD,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = TEXT_WHITE,
				Text = "Equip",
			}, bRow)
			create("UICorner", { CornerRadius = UDim.new(0, 6) }, eqBtn)
			eqBtn.Activated:Connect(function()
				sessionAction:FireServer("EquipItem", item.uid)
			end)

			local deBtn = create("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(68, 38),
				BackgroundColor3 = BTN_SLATE,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = TEXT_CYAN,
				Text = string.format("+%d ✨", rInfo.dustValue + math.floor(item.ilvl * 0.2)),
			}, bRow)
			create("UICorner", { CornerRadius = UDim.new(0, 6) }, deBtn)
			deBtn.Activated:Connect(function()
				sessionAction:FireServer("DisenchantItem", item.uid)
			end)
		end

		-- 4. Sanctuary Talent Tree
		talentPointsHeader.Text = string.format(
			"Total Talent Points Invested: %d   •   Available Souls: %d 🔮",
			totalTalentPts,
			data.souls
		)
		for _, node in ipairs(RpgConfig.TALENT_NODES) do
			local ui = talentNodeUi[node.id]
			local curRank = data.talents[node.id] or 0
			ui.rankLbl.Text = string.format("%d / %d", curRank, node.maxRank)
			if curRank >= node.maxRank then
				ui.stroke.Color = BORDER_GOLD
				ui.buyBtn.Text = "✓ MAX RANK"
				ui.buyBtn.BackgroundColor3 = BTN_SLATE
			elseif totalTalentPts < node.reqPoints then
				ui.stroke.Color = BTN_SLATE
				ui.buyBtn.Text = string.format("🔒 Requires %d Pts in Tree", node.reqPoints)
				ui.buyBtn.BackgroundColor3 = BTN_SLATE
			else
				local cost = node.costs[curRank + 1] or 999
				ui.stroke.Color = BORDER_CYAN
				ui.buyBtn.Text = string.format("Upgrade Rank (%d 🔮)", cost)
				ui.buyBtn.BackgroundColor3 = if data.souls >= cost then BTN_EMERALD else BTN_SLATE
			end
		end

		-- 5. Keystones, Daily Quests & Weekly Great Vault
		keystoneDescLabel.Text =
			string.format("%s (Highest Unlocked: +%d)\n%s", kInfo.name, data.highestKeystone, kInfo.desc)
		local s1 = if data.weeklyRuns >= 1 then "✅ UNLOCKED (Epic+ Relic)" else "🔒 Complete 1 Run"
		local s2 = if data.weeklyRuns >= 4
			then "✅ UNLOCKED (Upgraded to Legendary!)"
			else string.format("🔒 Complete 4 Runs (%d/4)", data.weeklyRuns)
		local s3 = if data.weeklyRuns >= 8
			then "✅ UNLOCKED (Max iLvl Bonus!)"
			else string.format("🔒 Complete 8 Runs (%d/8)", data.weeklyRuns)

		vaultInfoLabel.Text = string.format(
			"<b>Weekly Dungeon Runs Completed: %d</b>\n\n"
				.. "• <b>Vault Slot 1:</b> %s\n"
				.. "• <b>Vault Slot 2:</b> %s\n"
				.. "• <b>Vault Slot 3:</b> %s\n\n"
				.. '<font color="#ffd878">Claim once per week for a high-iLvl Epic or Legendary relic + 150 Souls!</font>',
			data.weeklyRuns,
			s1,
			s2,
			s3
		)
		if data.vaultClaimed then
			claimVaultBtn.Text = "✓ WEEKLY VAULT CLAIMED"
			claimVaultBtn.BackgroundColor3 = BTN_SLATE
		elseif data.weeklyRuns >= 1 then
			claimVaultBtn.Text = "🎁 CLAIM WEEKLY GREAT VAULT CHEST!"
			claimVaultBtn.BackgroundColor3 = BTN_PURPLE
		else
			claimVaultBtn.Text = "Complete 1 Run to Unlock Vault"
			claimVaultBtn.BackgroundColor3 = BTN_SLATE
		end

		for _, q in RpgConfig.DAILY_QUESTS do
			local ui = questUiMap[q.id]
			local prog = data.dailyProgress[q.id] or 0
			local claimed = data.dailyClaimed[q.id] == true
			ui.progLbl.Text = string.format("Progress: %d / %d", math.min(prog, q.target), q.target)
			if claimed then
				ui.claimBtn.Text = "✓ Claimed"
				ui.claimBtn.BackgroundColor3 = BTN_SLATE
			elseif prog >= q.target then
				ui.claimBtn.Text = "🎁 Claim Bounty!"
				ui.claimBtn.BackgroundColor3 = BTN_GOLD
			else
				ui.claimBtn.Text = "In Progress"
				ui.claimBtn.BackgroundColor3 = BTN_SLATE
			end
		end

		-- 6. Treasury Pass Status
		if data.starterPackOwned then
			starterPackBtn.Text = "✓ HEIRLOOM CHEST OWNED"
			starterPackBtn.BackgroundColor3 = BTN_SLATE
		end
		if data.passFourthCard then
			passFourthBtn.Text = "✓ ARCHMAGE PASS ACTIVE"
			passFourthBtn.BackgroundColor3 = BTN_SLATE
		end
		if data.passMagnet then
			passMagnetBtn.Text = "✓ VACUUM PASS ACTIVE"
			passMagnetBtn.BackgroundColor3 = BTN_SLATE
		end
		if data.passDoubleSouls then
			passDoubleSoulsBtn.Text = "✓ 2X SOULS PASS ACTIVE"
			passDoubleSoulsBtn.BackgroundColor3 = BTN_SLATE
		end
		if data.bloodMoonEndsAt > 0 then
			bloodMoonBtn.Text = string.format("🩸 Active (%ds) — Extend +15m", data.bloodMoonEndsAt)
		end

		-- 7. Loot Drop Toast & Summary Card Update
		if data.lastLootDrop then
			local drop = data.lastLootDrop
			local rInfo = RpgConfig.RARITY_INFO[drop.rarity] or RpgConfig.RARITY_INFO[1]
			summaryLootStroke.Color = rInfo.color
			summaryLootLabel.Text = string.format(
				'🎁 <b><font color="#%s">[%s]</font></b>  (iLvl %d %s %s)\n%s',
				rInfo.hex,
				drop.name,
				drop.ilvl,
				rInfo.name,
				drop.slot,
				formatGearStats(drop)
			)
			if drop.uid ~= lastSeenLootUid then
				lastSeenLootUid = drop.uid
				showLootToast(drop)
			end
		end

		-- 8. Crypt Bestiary & Evolution Grimoire Compendium
		local gCount = data.grimoireCount or 0
		local totalEntries = #RpgConfig.GRIMOIRE_ENTRIES
		grimoireHeaderLabel.Text = string.format(
			"📖 Grimoire Discoveries: %d / %d   •   Permanent Compendium Bonus: +%.1f%% All DMG & +%d Max HP",
			gCount,
			totalEntries,
			gCount * 0.5,
			gCount
		)
		openGrimoireBtn.Text = string.format("📖 GRIMOIRE %d/%d [B]", gCount, totalEntries)

		local grimoireMap = data.grimoire or {}
		for _, entry in ipairs(RpgConfig.GRIMOIRE_ENTRIES) do
			local ui = grimoireUiMap[entry.id]
			if ui then
				local unlocked = grimoireMap[entry.id] == true
				if unlocked then
					ui.stroke.Color = if entry.category == "Evolution"
						then BORDER_GOLD
						elseif entry.category == "Boss" then BORDER_PURPLE
						else BORDER_CYAN
					ui.title.TextColor3 = TEXT_GOLD
					ui.title.Text = string.format("%s %s", entry.icon, entry.name)
					ui.cat.TextColor3 = TEXT_GREEN
					ui.cat.Text = string.format("✅ %s (+0.5%% DMG, +1 HP)", string.upper(entry.category))
					ui.lore.TextColor3 = TEXT_WHITE
					ui.lore.Text = entry.lore
				else
					ui.stroke.Color = BTN_SLATE
					ui.title.TextColor3 = TEXT_MUTED
					ui.title.Text = string.format("🔒 %s ???", entry.icon)
					ui.cat.TextColor3 = TEXT_CYAN
					ui.cat.Text = string.format("%s (Undiscovered)", string.upper(entry.category))
					ui.lore.TextColor3 = TEXT_MUTED
					ui.lore.Text = if entry.category == "Evolution"
						then "Evolve this weapon in a run to record it."
						else "Slay this creature in the Crypts to record it."
				end
			end
		end
	end

	-- =========================================================================
	-- STATE REFRESH & COUNTDOWN LOOP
	-- =========================================================================
	local downedLocalEnd = 0
	local lastPhase = ""

	local function refresh()
		local phaseAttr = player:GetAttribute("Phase")
		local phase = if typeof(phaseAttr) == "string" then phaseAttr else "Lobby"

		if phase ~= "Lobby" then
			closeAllModals()
		end

		lobbyFrame.Visible = (phase == "Lobby")
		downedOverlay.Visible = (phase == "Downed")
		summaryOverlay.Visible = (phase == "Summary")

		local souls = numAttr(player, "Souls", 0)
		local currentWeaponId = (player:GetAttribute("SelectedWeapon") :: string?) or "ArcanistStaff"
		local currentMeta = WeaponConfig.get(currentWeaponId :: any)
		if currentMeta then
			local mRank = if latestRpg and latestRpg.weaponMastery[currentWeaponId]
				then latestRpg.weaponMastery[currentWeaponId]
				else 1
			arsenalEquippedLabel.Text =
				string.format("%s %s\nMastery Rank %d / 20", currentMeta.icon, currentMeta.name, mRank)
		end
		for id, btn in weaponEquipButtons do
			if id == currentWeaponId then
				btn.Text = "✓ EQUIPPED"
				btn.BackgroundColor3 = BTN_EMERALD
				btn.AutoButtonColor = false
			else
				btn.Text = "⚡ EQUIP"
				btn.BackgroundColor3 = BTN_GOLD
				btn.AutoButtonColor = true
			end
		end

		if phase == "Downed" then
			if lastPhase ~= "Downed" then
				downedClickableAt = os.clock() + Constants.REVIVE_CLICK_GRACE_SECONDS
			end
			local used = numAttr(player, "RevivesUsed", 0)
			local maxRevives = numAttr(player, "MaxRevives", Constants.MAX_REVIVES_PER_RUN)
			local remaining = math.max(0, maxRevives - used)
			revivesLeftLabel.Text =
				string.format("Soulstone Revives Remaining This Run: %d / %d", remaining, maxRevives)
			softReviveButton.Text =
				string.format("🔮 Self-Rez with %d Souls (You have %d 🔮)", Constants.SOUL_REVIVE_SOFT_COST, souls)
			softReviveButton.BackgroundColor3 = if souls >= Constants.SOUL_REVIVE_SOFT_COST
				then BTN_PURPLE
				else BTN_SLATE

			local coopPct = numAttr(player, "CoopRevivePct", 0)
			if coopPct > 0 then
				coopRescueLabel.Text =
					string.format("🤝 ALLY BATTLE-REZ IN PROGRESS: %d%%!", math.floor(coopPct * 100))
			else
				coopRescueLabel.Text = "🤝 Co-Op: Allies can stand near you for 3s to Battle-Rez you!"
			end

			local serverRem = numAttr(player, "DownedRemaining", Constants.REVIVE_WINDOW_SECONDS)
			if lastPhase ~= "Downed" or math.abs((downedLocalEnd - os.clock()) - serverRem) > 1.2 then
				downedLocalEnd = os.clock() + serverRem
			end
		elseif phase == "Summary" then
			local runTime = numAttr(player, "LastRunTime", 0)
			local runKills = numAttr(player, "LastRunKills", 0)
			local runLevel = numAttr(player, "LastRunLevel", 1)
			local runSouls = numAttr(player, "LastRunSouls", 0)
			local runHeroXp = numAttr(player, "LastRunHeroXp", 0)
			local bossCleared = player:GetAttribute("BossDefeated") == true

			summaryTitleLabel.Text = if bossCleared
				then "🏆 STAGE BOSS VANQUISHED!"
				else "🕯️ DUNGEON RUN COMPLETE"
			summaryBodyLabel.Text = string.format(
				"⏱️  Time Survived:   <b>%s</b>\n"
					.. "💀  Enemies Slain:    <b>%d</b>\n"
					.. "✨  Run Level:       <b>LV %d</b>\n"
					.. '🔮  Souls Harvested: <b><font color="#6effe1">+%d Souls</font></b>\n'
					.. '🟦  Hero XP Gained:  <b><font color="#5cb8ff">+%d Hero XP</font></b>',
				formatTime(runTime),
				runKills,
				runLevel,
				runSouls,
				runHeroXp
			)
			summaryWalletLabel.Text = string.format(
				"Sanctuary Wallet: %d Souls 🔮  •  Hero Lv.%d (iLvl %d)",
				souls,
				numAttr(player, "HeroLevel", 1),
				numAttr(player, "AvgIlvl", 0)
			)
		end

		lastPhase = phase
	end

	rpgSyncRemote.OnClientEvent:Connect(function(payload: RpgSyncPayload)
		if typeof(payload) ~= "table" then
			return
		end
		latestRpg = payload
		renderRpgModals(payload)
		refresh()
	end)

	player.AttributeChanged:Connect(refresh)
	refresh()
	sessionAction:FireServer("RequestSync")

	RunService.Heartbeat:Connect(function()
		if not downedOverlay.Visible then
			return
		end
		local duration = math.max(1, numAttr(player, "DownedDuration", Constants.REVIVE_WINDOW_SECONDS))
		local left = math.max(0, downedLocalEnd - os.clock())
		timerFill.Size = UDim2.fromScale(math.clamp(left / duration, 0, 1), 1)
		timerText.Text = string.format("%.1fs", left)
	end)
end

return LobbyAndDeathUi
