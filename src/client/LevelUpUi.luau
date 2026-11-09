--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants") :: ModuleScript)
local GameClock = require(Shared:WaitForChild("GameClock") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Types = require(Shared:WaitForChild("Types") :: ModuleScript)

type Card = {
	slot: Frame,
	scale: UIScale,
	glow: Frame,
	glowGradient: UIGradient,
	cardGradient: UIGradient,
	cardStroke: UIStroke,
	iconStroke: UIStroke,
	icon: TextLabel,
	name: TextLabel,
	meta: TextLabel,
	description: TextLabel,
	flavor: TextLabel,
	tweens: { Tween },
	readyAt: number,
}

local RARITIES = {
	{
		name = "Common",
		color = Color3.fromRGB(240, 248, 255),
		bgTop = Color3.fromRGB(24, 38, 64),
		bgBot = Color3.fromRGB(12, 18, 34),
	},
	{
		name = "Rare",
		color = Color3.fromRGB(105, 215, 255),
		bgTop = Color3.fromRGB(18, 56, 125),
		bgBot = Color3.fromRGB(10, 22, 54),
	},
	{
		name = "Epic",
		color = Color3.fromRGB(235, 140, 255),
		bgTop = Color3.fromRGB(82, 22, 132),
		bgBot = Color3.fromRGB(26, 10, 52),
	},
	{
		name = "Legendary",
		color = Color3.fromRGB(255, 210, 55),
		bgTop = Color3.fromRGB(135, 58, 12),
		bgBot = Color3.fromRGB(46, 16, 10),
	},
}
local EFFECT_COLOR = Color3.fromRGB(115, 255, 148)
local FLAVOR_COLOR = Color3.fromRGB(255, 228, 135)
local TITLE_COLOR = Color3.fromRGB(255, 232, 95)
local MUTED_COLOR = Color3.fromRGB(215, 225, 245)
local BORDER_COLOR = Color3.fromRGB(185, 195, 215)
local BEVEL_COLOR = Color3.fromRGB(110, 124, 165)
local PANEL_TOP = Color3.fromRGB(26, 34, 68)
local PANEL_BOTTOM = Color3.fromRGB(12, 16, 34)
local LEGENDARY_SHINE = Color3.fromRGB(255, 245, 160)
local STROKE_DARK = Color3.fromRGB(8, 5, 18)

local SERIF = "rbxasset://fonts/families/Merriweather.json"
local SERIF_BOLD = Font.new(SERIF, Enum.FontWeight.Bold)
local SERIF_ITALIC = Font.new(SERIF, Enum.FontWeight.Regular, Enum.FontStyle.Italic)

local REOPEN_AFTER = 1.5
local REVEAL_STAGGER = 0.08
local RARITY_SUSPENSE = 0.12
local CLICK_GRACE = 0.3
local REVEAL_SECONDS = 0.35
local HOVER_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE_TWEEN = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local SPIN_TWEEN = TweenInfo.new(2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

local KEY_FOR_SLOT = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
}

local LevelUpUi = {}

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

local function createText(parent: Instance, properties: { [string]: any }, maxSize: number): TextLabel
	properties.BackgroundTransparency = 1
	properties.TextScaled = true
	properties.TextWrapped = true
	local label = create("TextLabel", properties, parent)
	create("UITextSizeConstraint", { MaxTextSize = maxSize }, label)
	return label
end

local function buildCard(row: Frame, index: number, onChoose: (number) -> ()): Card
	local slot = create("Frame", {
		Name = "Slot" .. index,
		Size = UDim2.fromScale(0.23, 1),
		BackgroundTransparency = 1,
		LayoutOrder = index,
		Visible = false,
	}, row)
	local scale = create("UIScale", {}, slot)

	local glow = create("Frame", {
		Name = "Glow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 14, 1, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, slot)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, glow)
	local glowGradient = create("UIGradient", {}, glow)

	local button = create("TextButton", {
		Name = "Card",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, slot)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, button)
	local cardGradient = create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(PANEL_TOP, PANEL_BOTTOM),
	}, button)
	local cardStroke = create("UIStroke", {
		Color = BORDER_COLOR,
		Thickness = 2.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, button)

	local bevel = create("Frame", {
		Name = "Bevel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1,
	}, button)
	create("UICorner", { CornerRadius = UDim.new(0, 5) }, bevel)
	create("UIStroke", { Color = BEVEL_COLOR, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, bevel)

	local iconFrame = create("Frame", {
		Name = "IconFrame",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.07),
		Size = UDim2.fromScale(0.26, 0.26),
		BackgroundColor3 = Color3.fromRGB(12, 12, 20),
		BorderSizePixel = 0,
	}, button)
	create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, iconFrame)
	create("UICorner", { CornerRadius = UDim.new(0, 4) }, iconFrame)
	local iconStroke = create("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, iconFrame)
	local icon = createText(iconFrame, {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
	}, 60)

	local name = createText(button, {
		Name = "UpgradeName",
		Position = UDim2.fromScale(0.07, 0.36),
		Size = UDim2.fromScale(0.86, 0.11),
		FontFace = SERIF_BOLD,
		TextStrokeTransparency = 0.6,
	}, 22)
	local meta = createText(button, {
		Name = "Meta",
		Position = UDim2.fromScale(0.07, 0.47),
		Size = UDim2.fromScale(0.86, 0.065),
		Font = Enum.Font.GothamMedium,
		TextColor3 = MUTED_COLOR,
		RichText = true,
	}, 14)
	create("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.new(0.8, 0, 0, 1),
		BackgroundColor3 = BEVEL_COLOR,
		BorderSizePixel = 0,
	}, button)
	local description = createText(button, {
		Name = "Effect",
		Position = UDim2.fromScale(0.08, 0.59),
		Size = UDim2.fromScale(0.84, 0.17),
		Font = Enum.Font.GothamMedium,
		TextColor3 = EFFECT_COLOR,
	}, 18)
	local flavor = createText(button, {
		Name = "Flavor",
		Position = UDim2.fromScale(0.08, 0.77),
		Size = UDim2.fromScale(0.84, 0.12),
		FontFace = SERIF_ITALIC,
		TextColor3 = FLAVOR_COLOR,
	}, 14)
	createText(button, {
		Name = "Hotkey",
		Position = UDim2.fromScale(0.08, 0.9),
		Size = UDim2.fromScale(0.84, 0.06),
		Font = Enum.Font.Gotham,
		TextColor3 = MUTED_COLOR,
		Text = "Press " .. index,
	}, 12)

	local card: Card = {
		slot = slot,
		scale = scale,
		glow = glow,
		glowGradient = glowGradient,
		cardGradient = cardGradient,
		cardStroke = cardStroke,
		iconStroke = iconStroke,
		icon = icon,
		name = name,
		meta = meta,
		description = description,
		flavor = flavor,
		tweens = {},
		readyAt = math.huge,
	}

	button.Activated:Connect(function()
		onChoose(index)
	end)
	button.MouseEnter:Connect(function()
		if os.clock() >= card.readyAt then
			TweenService:Create(scale, HOVER_TWEEN, { Scale = 1.06 }):Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if os.clock() >= card.readyAt then
			TweenService:Create(scale, HOVER_TWEEN, { Scale = 1 }):Play()
		end
	end)
	return card
end

local function stopTweens(card: Card)
	for _, tween in card.tweens do
		tween:Cancel()
	end
	table.clear(card.tweens)
end

local function play(card: Card, tween: Tween)
	table.insert(card.tweens, tween)
	tween:Play()
end

local function showOffer(card: Card, offer: Types.UpgradeOffer, slotIndex: number, totalCount: number)
	stopTweens(card)
	local rarity = RARITIES[offer.rarity] or RARITIES[1]
	local tier = math.clamp(offer.rarity, 1, #RARITIES)
	card.slot.Size = UDim2.fromScale(if totalCount >= 4 then 0.225 else 0.30, 1)

	card.icon.Text = offer.icon
	card.iconStroke.Color = rarity.color
	card.cardStroke.Color = rarity.color
	card.cardGradient.Color = ColorSequence.new(rarity.bgTop, rarity.bgBot)
	card.name.Text = offer.name
	card.name.TextColor3 = rarity.color
	local rank = if offer.maxRank > 0
		then string.format("Rank %d / %d", offer.rank, offer.maxRank)
		else "Rank " .. offer.rank
	card.meta.Text = string.format('<font color="#%s">%s</font>  ·  %s', rarity.color:ToHex(), rarity.name, rank)
	card.description.Text = offer.description
	card.flavor.Text = '"' .. offer.flavor .. '"'

	card.glow.Visible = true
	card.glow.BackgroundTransparency = if tier >= 2 then 0.35 else 0.72
	card.glowGradient.Rotation = 0
	if tier == 4 then
		card.glowGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarity.color),
			ColorSequenceKeypoint.new(0.5, LEGENDARY_SHINE),
			ColorSequenceKeypoint.new(1, rarity.color),
		})
		play(card, TweenService:Create(card.glowGradient, SPIN_TWEEN, { Rotation = 360 }))
	else
		card.glowGradient.Color = ColorSequence.new(rarity.color)
	end
	if tier >= 3 then
		card.glow.BackgroundTransparency = 0.2
		play(card, TweenService:Create(card.glow, PULSE_TWEEN, { BackgroundTransparency = 0.65 }))
	end

	local delay = (slotIndex - 1) * REVEAL_STAGGER + (tier - 1) * RARITY_SUSPENSE
	card.scale.Scale = 0
	card.readyAt = os.clock() + delay + CLICK_GRACE
	local reveal = TweenInfo.new(REVEAL_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay)
	play(card, TweenService:Create(card.scale, reveal, { Scale = 1 }))
	card.slot.Visible = true
end

function LevelUpUi.mount(playerGui: PlayerGui)
	local player = Players.LocalPlayer
	local levelUpOffer = Remotes.get("LevelUpOffer")
	local chooseUpgrade = Remotes.get("ChooseUpgrade")
	local sessionAction = Remotes.get("SessionAction")

	local gui = create("ScreenGui", {
		Name = "LevelUpUi",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local picker = create("Frame", {
		Name = "Picker",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(16, 10, 34),
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)

	createText(picker, {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.14),
		Size = UDim2.fromScale(0.8, 0.07),
		FontFace = SERIF_BOLD,
		TextColor3 = TITLE_COLOR,
		TextStrokeTransparency = 0.2,
		Text = "✨ LEVEL UP! PICK YOUR POWER! ✨",
	}, 42)
	local countdown = createText(picker, {
		Name = "Countdown",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.145),
		Size = UDim2.fromScale(0.8, 0.035),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(125, 245, 255),
	}, 16)

	local row = create("Frame", {
		Name = "Row",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.95, 0.60),
		BackgroundTransparency = 1,
	}, picker)
	create("UISizeConstraint", { MaxSize = Vector2.new(980, 340) }, row)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)

	-- Bottom WoW Impulse Action Bar (Bonus Roll Reroll + Miracle Claim All)
	local actionBar = create("Frame", {
		Name = "ImpulseBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.95),
		Size = UDim2.fromOffset(640, 48),
		BackgroundTransparency = 1,
	}, picker)

	local rerollBtn = create("TextButton", {
		Name = "RerollButton",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(305, 48),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		RichText = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextStrokeColor3 = STROKE_DARK,
		TextStrokeTransparency = 0.08,
		Text = "🎲 BONUS ROLL [R] (Guaranteed Rare+)",
	}, actionBar)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, rerollBtn)
	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(16, 78, 155), Color3.fromRGB(28, 34, 108)),
		Rotation = 90,
	}, rerollBtn)
	create("UIStroke", { Color = Color3.fromRGB(95, 235, 255), Thickness = 2 }, rerollBtn)

	local claimAllBtn = create("TextButton", {
		Name = "ClaimAllButton",
		Position = UDim2.fromOffset(325, 0),
		Size = UDim2.fromOffset(315, 48),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		RichText = true,
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 252, 240),
		TextStrokeColor3 = STROKE_DARK,
		TextStrokeTransparency = 0.08,
		Text = "👑 MIRACLE ROLL: CLAIM ALL CARDS!",
	}, actionBar)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, claimAllBtn)
	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(148, 68, 14), Color3.fromRGB(98, 22, 72)),
		Rotation = 90,
	}, claimAllBtn)
	create("UIStroke", { Color = Color3.fromRGB(255, 215, 75), Thickness = 2.2 }, claimAllBtn)

	local waiting = createText(gui, {
		Name = "Waiting",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromScale(0.8, 0.05),
		FontFace = SERIF_BOLD,
		TextColor3 = TITLE_COLOR,
		TextStrokeTransparency = 0.4,
		Text = "PAUSED · another player is choosing an upgrade",
		Visible = false,
	}, 24)

	local currentSeq = 0
	local offers: { Types.UpgradeOffer } = {}
	local deadline = 0
	local cards: { Card } = {}
	local lastPayload: Types.LevelUpPayload? = nil
	local awaitingSince: number? = nil

	local function updateImpulseLabels()
		local dice = player:GetAttribute("RerollDice")
		local diceNum = if typeof(dice) == "number" then dice else 0
		local souls = player:GetAttribute("Souls")
		local soulsNum = if typeof(souls) == "number" then souls else 0
		if diceNum > 0 then
			rerollBtn.Text = string.format(
				'🎲 BONUS ROLL [R] (%d Coin%s Left)\n<font size="11" color="#ffe580">Rerolls with Guaranteed Rare+ Odds</font>',
				diceNum,
				if diceNum == 1 then "" else "s"
			)
		elseif soulsNum >= Constants.REROLL_SOUL_COST then
			rerollBtn.Text = string.format(
				'🎲 BONUS ROLL [R] (%d Souls)\n<font size="11" color="#ffe580">Rerolls with Guaranteed Rare+ Odds</font>',
				Constants.REROLL_SOUL_COST
			)
		else
			rerollBtn.Text =
				'🎲 BONUS ROLL [R] (Bonus Roll)\n<font size="11" color="#ffe580">Rerolls with Guaranteed Rare+ Odds</font>'
		end

		local claimUsed = player:GetAttribute("ClaimAllUsed")
		local usedNum = if typeof(claimUsed) == "number" then claimUsed else 0
		local left = math.max(0, Constants.MAX_CLAIM_ALL_PER_RUN - usedNum)
		claimAllBtn.Visible = left > 0
		claimAllBtn.Text = string.format(
			'👑 MIRACLE: CLAIM ALL %d CARDS!\n<font size="11" color="#a8f5ff">Equip Every Card Above (%d/%d Left)</font>',
			#offers,
			left,
			Constants.MAX_CLAIM_ALL_PER_RUN
		)
	end

	local function close()
		offers = {}
		picker.Visible = false
		for _, card in cards do
			stopTweens(card)
			card.slot.Visible = false
			card.readyAt = math.huge
		end
	end

	local function choose(slot: number)
		local card = cards[slot]
		if not picker.Visible or not offers[slot] or not card or os.clock() < card.readyAt then
			return
		end
		close()
		awaitingSince = os.clock()
		chooseUpgrade:FireServer(currentSeq, slot)
	end

	rerollBtn.Activated:Connect(function()
		if not picker.Visible then
			return
		end
		sessionAction:FireServer("RerollOffer")
	end)

	claimAllBtn.Activated:Connect(function()
		if not picker.Visible then
			return
		end
		close()
		awaitingSince = os.clock()
		sessionAction:FireServer("ClaimAllOffer")
	end)

	local function open(payload: Types.LevelUpPayload)
		close()
		awaitingSince = nil
		if #payload.offers == 0 then
			lastPayload = nil
			return
		end
		lastPayload = payload
		currentSeq = payload.seq
		offers = payload.offers
		deadline = os.clock() + payload.timeout
		for slot, card in cards do
			local offer = offers[slot]
			if offer then
				showOffer(card, offer, slot, #offers)
			end
		end
		updateImpulseLabels()
		picker.Visible = true
	end

	for slot = 1, Constants.MAX_OFFER_COUNT do
		cards[slot] = buildCard(row, slot, choose)
	end

	levelUpOffer.OnClientEvent:Connect(function(payload: Types.LevelUpPayload)
		if typeof(payload) ~= "table" or typeof(payload.offers) ~= "table" then
			return
		end
		open(payload)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not picker.Visible then
			return
		end
		local slot = KEY_FOR_SLOT[input.KeyCode]
		if slot then
			choose(slot)
		elseif input.KeyCode == Enum.KeyCode.R then
			sessionAction:FireServer("RerollOffer")
		end
	end)

	player.AttributeChanged:Connect(function()
		if picker.Visible then
			updateImpulseLabels()
		end
	end)

	local shownSeconds = -1
	RunService.Heartbeat:Connect(function()
		local since = awaitingSince
		if since and os.clock() - since > REOPEN_AFTER and lastPayload then
			local remaining = deadline - os.clock()
			if remaining > 0 then
				local retry = table.clone(lastPayload)
				retry.timeout = remaining
				open(retry)
			else
				awaitingSince = nil
				lastPayload = nil
			end
		end
		waiting.Visible = GameClock.isPaused()
			and not picker.Visible
			and awaitingSince == nil
			and player:GetAttribute("Dead") ~= true
		if picker.Visible then
			local seconds = math.max(0, math.ceil(deadline - os.clock()))
			if seconds ~= shownSeconds then
				shownSeconds = seconds
				countdown.Text = string.format("Choose a Talent Card  ·  auto-pick in %ds", seconds)
			end
		end
	end)

	player:GetAttributeChangedSignal("Dead"):Connect(function()
		if player:GetAttribute("Dead") == true then
			close()
			awaitingSince = nil
			lastPayload = nil
		end
	end)
end

return LevelUpUi
