--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local ServerTypes = require(script.Parent.ServerTypes)
local Upgrades = require(script.Parent.Upgrades)
local Constants = require(ReplicatedStorage.Shared.Constants)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local WeaponConfig = require(ReplicatedStorage.Shared.WeaponConfig)

type State = ServerTypes.State

-- Movement check tuning. Server-only so exploiters cannot read the thresholds (SEC-7).
local MOVE_SPEED_TOLERANCE = 1.25
local MOVE_BURST_STUDS = 16
local MOVE_SNAP_STUDS = 10
local MOVE_SPAWN_GRACE = 1
local RUBBER_BAND_COOLDOWN = 0.5
local OFFER_LATENCY_GRACE = 0.5

export type Target = {
	state: State,
	position: Vector3,
	velocity: Vector3,
	lookDir: Vector3,
}

local levelUpOffer = Remotes.get("LevelUpOffer")
local states: { [Player]: State } = {}
local targets: { Target } = {}
local frozen = false
local coopPortalTimer = 0
local nextChampionsSync = 0
local rng = Random.new()

local PlayerState = {}

local function syncLeaderstatsAndPrestigeTag(state: State)
	local player = state.player
	local profile = DataService.getProfile(player)
	local heroLv = if profile then profile.heroLevel else 1
	local bestMPlus = if profile then profile.highestKeystoneCleared else 0

	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
		ls = folder
	end
	if ls then
		local lvVal = ls:FindFirstChild("Hero Lv") :: IntValue?
		if not lvVal then
			local v = Instance.new("IntValue")
			v.Name = "Hero Lv"
			v.Parent = ls
			lvVal = v
		end
		if lvVal then
			lvVal.Value = heroLv
		end

		local mpVal = ls:FindFirstChild("Best M+") :: IntValue?
		if not mpVal then
			local v = Instance.new("IntValue")
			v.Name = "Best M+"
			v.Parent = ls
			mpVal = v
		end
		if mpVal then
			mpVal.Value = bestMPlus
		end

		local soulsVal = ls:FindFirstChild("Souls") :: IntValue?
		if not soulsVal then
			local v = Instance.new("IntValue")
			v.Name = "Souls"
			v.Parent = ls
			soulsVal = v
		end
		if soulsVal then
			soulsVal.Value = state.souls
		end
	end

	local character = state.character
	local head = character and character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local bb = head:FindFirstChild("HeroPrestigeTag") :: BillboardGui?
		if not bb then
			local newBb = Instance.new("BillboardGui")
			newBb.Name = "HeroPrestigeTag"
			newBb.Size = UDim2.fromOffset(210, 44)
			newBb.StudsOffset = Vector3.new(0, 2.7, 0)
			newBb.AlwaysOnTop = true
			newBb.MaxDistance = 65
			newBb.Parent = head

			local lbl = Instance.new("TextLabel")
			lbl.Name = "TagLabel"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBlack
			lbl.RichText = true
			lbl.TextSize = 12
			lbl.TextColor3 = Color3.fromRGB(255, 230, 130)
			lbl.TextStrokeColor3 = Color3.fromRGB(8, 10, 16)
			lbl.TextStrokeTransparency = 0.12
			lbl.Parent = newBb
			bb = newBb
		end
		local lbl = bb and bb:FindFirstChild("TagLabel") :: TextLabel?
		if lbl then
			local title = if bestMPlus >= 10
				then "👑 Archon of the Crypt"
				elseif heroLv >= 20 then "⚔️ Undying Vanguard"
				elseif heroLv >= 10 then "🛡️ Chapel Templar"
				else "✨ Sanctuary Initiate"
			local blessBadge = if player:GetAttribute("SanctuaryBlessingActive") == true
				then " <font color='#55ffaa'>[Blessed]</font>"
				else ""
			lbl.Text = string.format(
				"%s%s\n<font size='11' color='#a8ffeb'>Hero Lv.%d • M+%d • %d Kills</font>",
				title,
				blessBadge,
				heroLv,
				bestMPlus,
				state.bestKills
			)
		end
	end
end

local function countFriendsInServer(player: Player): number
	local friends = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWith(other.UserId)
			end)
			if ok and isFriend then
				friends += 1
			end
		end
	end
	return math.min(3, friends)
end

local function publish(state: State)
	local player = state.player
	local downedRemaining = 0
	if state.phase == "Downed" then
		downedRemaining = math.max(0, math.ceil(state.downedExpiresAt - os.clock()))
	end
	local friendCount = countFriendsInServer(player)
	player:SetAttribute("Phase", state.phase)
	player:SetAttribute("Health", math.ceil(state.health))
	player:SetAttribute("MaxHealth", state.maxHealth)
	player:SetAttribute("Xp", state.xp)
	player:SetAttribute("XpToNext", Constants.xpForLevel(state.level))
	player:SetAttribute("Level", state.level)
	player:SetAttribute("Kills", state.kills)
	player:SetAttribute("SelectedWeapon", state.selectedWeapon)
	player:SetAttribute("EquippedWeapons", table.concat(state.equippedWeapons, ","))
	local evolvedList: { string } = {}
	if (state.upgrades["evolve_staff"] or 0) >= 1 then
		table.insert(evolvedList, "ArcanistStaff")
	end
	if (state.upgrades["evolve_cleaver"] or 0) >= 1 then
		table.insert(evolvedList, "CryptCleaver")
	end
	if (state.upgrades["evolve_lantern"] or 0) >= 1 then
		table.insert(evolvedList, "SoulflameLantern")
	end
	if (state.upgrades["evolve_bow"] or 0) >= 1 then
		table.insert(evolvedList, "PhantomBow")
	end
	if (state.upgrades["evolve_pistols"] or 0) >= 1 then
		table.insert(evolvedList, "HexlockPistols")
	end
	if (state.upgrades["evolve_storm"] or 0) >= 1 then
		table.insert(evolvedList, "StormcallerTome")
	end
	player:SetAttribute("EvolvedWeapons", table.concat(evolvedList, ","))
	player:SetAttribute("CritChance", math.floor(state.critChance * 100 + 0.5))
	player:SetAttribute("CritDamage", math.floor(state.critMultiplier * 100 + 0.5))
	player:SetAttribute("OrbCount", if state.phase == "InRun" then state.orbCount else 0)
	player:SetAttribute("OrbRadius", Constants.ORB_RADIUS * state.orbRadiusMultiplier)
	player:SetAttribute("OrbSpeed", Constants.ORB_SPEED * state.orbSpeedMultiplier)
	player:SetAttribute("BoneCount", if state.phase == "InRun" then state.boneCount else 0)
	player:SetAttribute("BoneRadius", state.boneRadius)
	player:SetAttribute("BoneSpeed", state.boneSpeed)
	player:SetAttribute("ConsecratedRadius", if state.phase == "InRun" then state.consecratedRadius else 0)
	player:SetAttribute("ArcaneWard", math.ceil(state.arcaneWardCurrent))
	player:SetAttribute("ArcaneWardMax", state.arcaneWardMax)
	player:SetAttribute("Dead", not state.alive)
	player:SetAttribute("RunStart", state.runStart)
	player:SetAttribute("RevivesUsed", state.revivesUsed)
	player:SetAttribute("MaxRevives", Constants.MAX_REVIVES_PER_RUN)
	player:SetAttribute("DownedRemaining", downedRemaining)
	player:SetAttribute("DownedDuration", Constants.REVIVE_WINDOW_SECONDS)
	player:SetAttribute("Souls", state.souls)
	player:SetAttribute("LastRunSouls", state.lastRunSouls)
	player:SetAttribute("LastRunHeroXp", state.lastRunHeroXp)
	player:SetAttribute("LastRunTime", state.lastRunTime)
	player:SetAttribute("LastRunKills", state.lastRunKills)
	player:SetAttribute("LastRunLevel", state.lastRunLevel)
	player:SetAttribute("BestTime", state.bestTime)
	player:SetAttribute("BestKills", state.bestKills)
	player:SetAttribute("RerollDice", state.rerollDice)
	player:SetAttribute("ClaimAllUsed", state.claimAllUsed)
	player:SetAttribute("BossDefeated", state.bossDefeated)
	player:SetAttribute("FriendBoostPct", friendCount * 10)
	player:SetAttribute("CoopRevivePct", math.clamp(state.coopReviveProgress / Constants.COOP_REVIVE_SECONDS, 0, 1))
	player:SetAttribute("BountyTarget", state.bountyTarget)
	player:SetAttribute("BountyKills", state.bountyKills)
	player:SetAttribute("BountyExpiresClock", state.bountyExpiresClock)
	player:SetAttribute("CcKind", state.ccKind)
	player:SetAttribute("CcExpiresClock", state.ccExpiresClock)
	player:SetAttribute("CcSourceX", state.ccSourceX)
	player:SetAttribute("CcSourceZ", state.ccSourceZ)
	syncLeaderstatsAndPrestigeTag(state)
end

local function getHumanoid(state: State): Humanoid?
	local character = state.character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(state: State): BasePart?
	local character = state.character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function applyHumanoidStats(state: State)
	local humanoid = getHumanoid(state)
	if humanoid then
		local now = os.clock()
		local dashMult = if now < state.dashEndsAt then Constants.DASH_SPEED_MULT else 1
		local ccMult = 1.0
		if state.ccKind ~= "" and now < state.ccExpiresAt then
			if state.ccKind == "Freeze" then
				ccMult = 0.08
			elseif state.ccKind == "Snare" then
				ccMult = Constants.CC_SNARE_SLOW_MULT
			elseif state.ccKind == "Charm" then
				ccMult = 0.55
			elseif state.ccKind == "Confuse" then
				ccMult = 0.78
			end
		end
		humanoid.WalkSpeed = Constants.PLAYER_WALK_SPEED * state.moveSpeedMultiplier * dashMult * ccMult
		humanoid.UseJumpPower = false
		humanoid.JumpHeight = 0
	end
end

local function teleportCharacter(state: State, targetFloorPos: Vector3, lookDir: Vector3, anchorRoot: boolean)
	local root = getRoot(state)
	local now = os.clock()
	local charPos = targetFloorPos + Vector3.new(0, 3, 0)
	local targetCf = CFrame.lookAt(charPos, charPos + lookDir)
	state.lastValidPosition = charPos
	state.moveBudget = MOVE_BURST_STUDS
	state.moveCheckedAt = now
	state.moveGraceUntil = now + MOVE_SPAWN_GRACE
	if root then
		root.Anchored = anchorRoot
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if not anchorRoot then
			pcall(root.SetNetworkOwner, root, nil)
		end
		root.CFrame = targetCf
	end
	if state.character then
		pcall(function()
			state.character:PivotTo(targetCf)
		end)
	end
	if root and not anchorRoot then
		task.delay(0.15, function()
			if states[state.player] == state and root.Parent and not root.Anchored then
				pcall(root.SetNetworkOwner, root, state.player)
			end
		end)
	end
end

local function getOfferCardCount(state: State): number
	local profile = DataService.getProfile(state.player)
	if profile and profile.passFourthCard then
		return Constants.MAX_OFFER_COUNT
	end
	return Constants.OFFER_COUNT
end

-- Every offer gets a new sequence number; ChooseUpgrade must echo it, so a click meant for an offer the
-- server already auto-picked can never land on the next one.
local function sendNextOffer(state: State)
	state.offerSeq += 1
	if state.pendingLevelUps <= 0 or state.phase ~= "InRun" then
		state.offer = nil
		local close: Types.LevelUpPayload = { seq = state.offerSeq, timeout = 0, offers = {} }
		levelUpOffer:FireClient(state.player, close)
		return
	end
	local slots = Upgrades.roll(state, getOfferCardCount(state))
	state.offer = slots
	local timeout = if state.afk then Constants.AFK_OFFER_TIMEOUT_SECONDS else Constants.OFFER_TIMEOUT_SECONDS
	state.offerExpiresAt = os.clock() + timeout + OFFER_LATENCY_GRACE
	local payload: Types.LevelUpPayload = {
		seq = state.offerSeq,
		timeout = timeout,
		offers = Upgrades.describe(state, slots),
	}
	levelUpOffer:FireClient(state.player, payload)
end

local function enterSummary(state: State)
	local survived = math.max(0, math.floor(GameClock.now() - state.runStart))
	local earnedSouls, earnedHeroXp = DataService.recordRunCompleted(
		state.player,
		state.kills,
		survived,
		state.level,
		state.selectedWeapon,
		state.bossDefeated
	)
	local profile = DataService.getProfile(state.player)

	state.phase = "Summary"
	state.alive = false
	state.health = 0
	state.pendingLevelUps = 0
	state.downedExpiresAt = 0
	state.purchasePromptOpen = false
	state.coopReviveProgress = 0
	state.souls = if profile then profile.souls else state.souls + earnedSouls
	state.lastRunSouls = earnedSouls
	state.lastRunHeroXp = earnedHeroXp
	state.lastRunTime = survived
	state.lastRunKills = state.kills
	state.lastRunLevel = state.level
	state.bestTime = if profile then profile.bestTime else math.max(state.bestTime, survived)
	state.bestKills = if profile then profile.bestKills else math.max(state.bestKills, state.kills)

	if state.offer ~= nil then
		sendNextOffer(state)
	end

	local root = getRoot(state)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.Anchored = true
	end

	publish(state)
end

local function enterDownedOrSummary(state: State)
	if state.phase ~= "InRun" then
		return
	end
	state.alive = false
	state.health = 0
	state.pendingLevelUps = 0
	state.coopReviveProgress = 0
	if state.offer ~= nil then
		sendNextOffer(state)
	end

	if state.revivesUsed < Constants.MAX_REVIVES_PER_RUN then
		state.phase = "Downed"
		state.downedExpiresAt = os.clock() + Constants.REVIVE_WINDOW_SECONDS
		state.purchasePromptOpen = false
		local root = getRoot(state)
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.Anchored = true
		end
		publish(state)
	else
		enterSummary(state)
	end
end

function PlayerState.reset(player: Player, character: Model): State
	local profile = DataService.loadPlayer(player)
	local previous = states[player]
	local state: State = {
		player = player,
		character = character,
		phase = "Lobby",
		alive = false,
		health = Constants.PLAYER_MAX_HEALTH,
		maxHealth = Constants.PLAYER_MAX_HEALTH,
		regenPerSecond = 0,
		xp = 0,
		level = 1,
		kills = 0,
		selectedWeapon = if previous and previous.selectedWeapon then previous.selectedWeapon else "ArcanistStaff",
		equippedWeapons = if previous and previous.equippedWeapons
			then previous.equippedWeapons
			else { "ArcanistStaff" },
		damageMultiplier = 1,
		cooldownMultiplier = 1,
		boltCount = 1,
		boltPierce = 0,
		orbCount = 1,
		moveSpeedMultiplier = 1,
		pickupRadius = Constants.PICKUP_RADIUS,
		boltSpeedMultiplier = 1,
		orbRadiusMultiplier = 1,
		orbSpeedMultiplier = 1,
		orbDamageMultiplier = 1,
		orbResonanceDamage = 0,
		arcaneWardMax = 0,
		arcaneWardCurrent = 0,
		cleaveDamageMultiplier = 1,
		cleaveCooldownMultiplier = 1,
		cleaveArcBonus = 0,
		cleaveReachBonus = 0,
		cleavePierce = Constants.CLEAVE_BASE_PIERCE,
		cleaveExecuteThreshold = 0,
		boneCount = 0,
		boneRadius = Constants.BONE_RADIUS,
		boneSpeed = Constants.BONE_SPEED,
		boneDamageMultiplier = 1,
		boneKnockbackMultiplier = 1,
		boneShatterDamage = 0,
		cinderDamageMultiplier = 1,
		cinderCooldownMultiplier = 1,
		cinderClusterCount = 1,
		cinderSplashMultiplier = 1,
		cinderDurationBonus = 0,
		cinderIncinerateRadius = 0,
		consecratedRadius = 0,
		consecratedDamageMultiplier = 1,
		consecratedSlowMultiplier = Constants.CONSECRATED_SLOW,
		hallowedPyreDamage = 0,
		retributiveFlareDamage = 0,
		armor = 0,
		critChance = Constants.BASE_CRIT_CHANCE,
		critMultiplier = Constants.BASE_CRIT_MULTIPLIER,
		critNovaDamage = 0,
		lookDirX = 0,
		lookDirZ = -1,
		bowCount = 0,
		bowPierce = Constants.BOW_BASE_PIERCE,
		bowDamageMultiplier = 1,
		bowCooldownMultiplier = 1,
		pistolCount = 0,
		pistolPierce = 0,
		pistolDamageMultiplier = 1,
		pistolCooldownMultiplier = 1,
		stormChains = 0,
		stormDamageMultiplier = 1,
		stormCooldownMultiplier = 1,
		xpMultiplier = 1,
		luck = 0,
		thorns = 0,
		lifestealChance = 0,
		lifestealAmount = 3,
		upgrades = {},
		offer = nil,
		offerSeq = if previous then previous.offerSeq else 0,
		offerExpiresAt = 0,
		nextOfferAllowedAt = 0,
		afk = false,
		immuneUntil = 0,
		pendingLevelUps = 0,
		runStart = GameClock.now(),
		revivesUsed = 0,
		downedExpiresAt = 0,
		purchasePromptOpen = false,
		souls = profile.souls,
		lastRunSouls = if previous then previous.lastRunSouls else 0,
		lastRunHeroXp = if previous then previous.lastRunHeroXp else 0,
		lastRunTime = if previous then previous.lastRunTime else 0,
		lastRunKills = if previous then previous.lastRunKills else 0,
		lastRunLevel = if previous then previous.lastRunLevel else 1,
		bestTime = profile.bestTime,
		bestKills = profile.bestKills,
		rerollDice = profile.fateDice,
		claimAllUsed = 0,
		bossDefeated = false,
		coopReviveProgress = 0,
		lastDamagedAt = -math.huge,
		lastValidPosition = nil,
		moveBudget = MOVE_BURST_STUDS,
		moveCheckedAt = os.clock(),
		moveGraceUntil = os.clock() + MOVE_SPAWN_GRACE,
		lastRubberBandAt = -math.huge,
		dashReadyAt = 0,
		dashEndsAt = 0,
		bountyTarget = 0,
		bountyKills = 0,
		bountyExpiresClock = 0,
		nextBountyClock = 0,
		ccKind = "",
		ccExpiresAt = 0,
		ccExpiresClock = 0,
		ccImmuneUntil = 0,
		ccSourceX = 0,
		ccSourceZ = 0,
		tenacityMult = 1,
	}
	states[player] = state
	applyHumanoidStats(state)

	task.defer(function()
		if states[player] == state and state.phase == "Lobby" then
			teleportCharacter(state, Constants.LOBBY_SPAWN, Vector3.new(0, 0, 1), false)
		end
	end)
	teleportCharacter(state, Constants.LOBBY_SPAWN, Vector3.new(0, 0, 1), false)
	publish(state)
	DataService.sync(player)

	local humanoid = getHumanoid(state)
	if humanoid then
		humanoid.BreakJointsOnDeath = false
		humanoid.HealthChanged:Connect(function(newHealth)
			if states[player] == state and newHealth <= 1 then
				humanoid.Health = Constants.PLAYER_MAX_HEALTH
				if state.phase == "InRun" and state.alive then
					enterDownedOrSummary(state)
				end
			end
		end)
		humanoid.Died:Once(function()
			if states[player] == state and state.phase == "InRun" then
				enterDownedOrSummary(state)
			end
		end)
	end
	return state
end

function PlayerState.claimSanctuaryBlessing(player: Player): boolean
	local state = states[player]
	if not state or state.phase ~= "Lobby" then
		return false
	end
	player:SetAttribute("SanctuaryBlessingActive", true)
	player:SetAttribute(
		"FieldEventBanner",
		string.format(
			"✨ SANCTUARY BLESSING CLAIMED! +20 Starting Ward & +10%% Move Speed on Next Expedition! (%d)",
			math.floor(os.clock() * 10)
		)
	)
	publish(state)
	return true
end

function PlayerState.startRun(state: State, isCoopDeploy: boolean?): boolean
	if state.phase ~= "Lobby" and state.phase ~= "Summary" then
		return false
	end
	local anyOtherInRun = false
	for _, other in states do
		if other ~= state and (other.phase == "InRun" or other.phase == "Downed") then
			anyOtherInRun = true
			break
		end
	end
	if not anyOtherInRun then
		local Director = require(script.Parent.Director)
		Director.resetRound()
	end
	local bonuses = DataService.computeBonuses(state.player)
	local profile = DataService.getProfile(state.player)
	local friendMult = 1 + countFriendsInServer(state.player) * 0.10
	local hasFontBlessing = state.player:GetAttribute("SanctuaryBlessingActive") == true
	state.player:SetAttribute("SanctuaryBlessingActive", false)
	local coopWardBonus = if isCoopDeploy then 15 else 0
	local fontWardBonus = if hasFontBlessing then 20 else 0
	local fontSpeedBonus = if hasFontBlessing then 0.10 else 0
	local coopXpMult = if isCoopDeploy then 1.15 else 1.0

	state.phase = "InRun"
	state.alive = true
	state.maxHealth = Constants.PLAYER_MAX_HEALTH + bonuses.bonusHp
	state.health = state.maxHealth
	state.regenPerSecond = bonuses.regenBonus
	state.xp = 0
	state.level = 1
	state.kills = 0
	state.damageMultiplier = bonuses.damageMult
	state.cooldownMultiplier = bonuses.cooldownMult
	state.moveSpeedMultiplier = bonuses.moveSpeedMult + fontSpeedBonus
	state.pickupRadius = Constants.PICKUP_RADIUS * bonuses.magnetMult
	state.armor = bonuses.armorBonus
	state.critChance = Constants.BASE_CRIT_CHANCE + bonuses.critBonus
	state.critMultiplier = Constants.BASE_CRIT_MULTIPLIER
	state.critNovaDamage = 0
	state.lookDirX = 0
	state.lookDirZ = -1
	state.xpMultiplier = bonuses.xpMult * friendMult * coopXpMult
	state.luck = bonuses.luckBonus
	state.thorns = 0
	state.lifestealChance = 0
	state.lifestealAmount = 3
	state.arcaneWardMax = bonuses.wardBonus + fontWardBonus + coopWardBonus
	state.arcaneWardCurrent = state.arcaneWardMax
	state.orbResonanceDamage = 0
	state.cleaveExecuteThreshold = 0
	state.boneShatterDamage = 0
	state.cinderIncinerateRadius = 0
	state.hallowedPyreDamage = 0
	state.retributiveFlareDamage = 0
	state.rerollDice = (if profile then profile.fateDice else 0) + bonuses.startingDice
	state.claimAllUsed = 0
	state.bossDefeated = false
	state.coopReviveProgress = 0

	-- Reset all weapon-specific counters before activating the chosen starter weapon
	state.boltCount = 0
	state.boltPierce = 0
	state.boltSpeedMultiplier = 1
	state.orbCount = 0
	state.orbRadiusMultiplier = 1
	state.orbSpeedMultiplier = 1
	state.orbDamageMultiplier = 1
	state.cleaveDamageMultiplier = 1
	state.cleaveCooldownMultiplier = 1
	state.cleaveArcBonus = 0
	state.cleaveReachBonus = 0
	state.cleavePierce = Constants.CLEAVE_BASE_PIERCE
	state.boneCount = 0
	state.boneRadius = Constants.BONE_RADIUS
	state.boneSpeed = Constants.BONE_SPEED
	state.boneDamageMultiplier = 1
	state.boneKnockbackMultiplier = 1
	state.cinderDamageMultiplier = 1
	state.cinderCooldownMultiplier = 1
	state.cinderClusterCount = 0
	state.cinderSplashMultiplier = 1
	state.cinderDurationBonus = 0
	state.consecratedRadius = 0
	state.consecratedDamageMultiplier = 1
	state.consecratedSlowMultiplier = 0
	state.bowCount = 0
	state.bowPierce = Constants.BOW_BASE_PIERCE
	state.bowDamageMultiplier = 1
	state.bowCooldownMultiplier = 1
	state.pistolCount = 0
	state.pistolPierce = 0
	state.pistolDamageMultiplier = 1
	state.pistolCooldownMultiplier = 1
	state.stormChains = 0
	state.stormDamageMultiplier = 1
	state.stormCooldownMultiplier = 1

	local wId = state.selectedWeapon or "ArcanistStaff"
	state.selectedWeapon = wId
	state.equippedWeapons = {}
	PlayerState.unlockWeaponInRun(state, wId, true)

	table.clear(state.upgrades)
	state.offer = nil
	state.pendingLevelUps = 0
	state.nextOfferAllowedAt = 0
	state.afk = false
	state.revivesUsed = 0
	state.downedExpiresAt = 0
	state.purchasePromptOpen = false
	state.runStart = GameClock.now()
	state.immuneUntil = os.clock() + Constants.SPAWN_IMMUNE_SECONDS
	state.lastDamagedAt = -math.huge
	state.dashReadyAt = 0
	state.dashEndsAt = 0
	state.bountyTarget = 20
	state.bountyKills = 0
	state.bountyExpiresClock = state.runStart + 45
	state.nextBountyClock = state.runStart + 45
	state.ccKind = ""
	state.ccExpiresAt = 0
	state.ccExpiresClock = 0
	state.ccImmuneUntil = os.clock() + Constants.SPAWN_IMMUNE_SECONDS
	state.ccSourceX = 0
	state.ccSourceZ = 0
	state.tenacityMult = 1
	state.player:SetAttribute("DashReadyClock", 0)
	state.player:SetAttribute("FieldEventBanner", "")

	applyHumanoidStats(state)
	sendNextOffer(state)
	teleportCharacter(state, Constants.ARENA_SPAWN, Vector3.new(0, 0, -1), frozen)
	publish(state)
	return true
end

function PlayerState.unlockWeaponInRun(state: State, wId: string, isStarter: boolean?)
	if not table.find(state.equippedWeapons, wId) then
		table.insert(state.equippedWeapons, wId)
	end
	local bonuses = DataService.computeBonuses(state.player)
	local profile = DataService.getProfile(state.player)
	local mastery = if profile and profile.weaponMastery[wId] then profile.weaponMastery[wId] else 1
	local masteryDmgMult = 1 + (mastery - 1) * 0.03

	if wId == "CryptCleaver" then
		state.cleaveDamageMultiplier = bonuses.damageMult * masteryDmgMult
		state.cleaveCooldownMultiplier = bonuses.cooldownMult
		state.cleavePierce = Constants.CLEAVE_BASE_PIERCE
		state.boneCount = math.max(state.boneCount, if mastery >= 10 then 3 else 2)
		state.boneDamageMultiplier = bonuses.damageMult * masteryDmgMult
		if isStarter then
			state.maxHealth += 35
			state.health = state.maxHealth
			state.armor += 2
		end
	elseif wId == "SoulflameLantern" then
		state.cinderDamageMultiplier = bonuses.damageMult * masteryDmgMult
		state.cinderCooldownMultiplier = bonuses.cooldownMult
		state.cinderClusterCount = math.max(state.cinderClusterCount, 1)
		state.consecratedRadius =
			math.max(state.consecratedRadius, Constants.CONSECRATED_RADIUS * (if mastery >= 10 then 1.15 else 1))
		state.consecratedDamageMultiplier = bonuses.damageMult * masteryDmgMult
		state.consecratedSlowMultiplier = math.max(state.consecratedSlowMultiplier, Constants.CONSECRATED_SLOW)
	elseif wId == "PhantomBow" then
		state.bowCount = math.max(state.bowCount, if mastery >= 10 then 3 else 2)
		state.bowPierce = math.max(state.bowPierce, Constants.BOW_BASE_PIERCE)
		state.bowDamageMultiplier = bonuses.damageMult * masteryDmgMult
		state.bowCooldownMultiplier = bonuses.cooldownMult
		if isStarter then
			state.critChance += 0.12
			state.moveSpeedMultiplier += 0.10
		else
			state.critChance += 0.05
		end
	elseif wId == "HexlockPistols" then
		state.pistolCount = math.max(state.pistolCount, if mastery >= 10 then 3 else 2)
		state.pistolPierce = math.max(state.pistolPierce, 1)
		state.pistolDamageMultiplier = bonuses.damageMult * masteryDmgMult
		state.pistolCooldownMultiplier = bonuses.cooldownMult
		if isStarter then
			state.critChance += 0.08
			state.cooldownMultiplier = math.max(Constants.MIN_COOLDOWN_MULTIPLIER, state.cooldownMultiplier * 0.90)
		else
			state.critChance += 0.04
		end
	elseif wId == "StormcallerTome" then
		state.stormChains = math.max(state.stormChains, Constants.STORM_CHAIN_COUNT + (if mastery >= 10 then 1 else 0))
		state.stormDamageMultiplier = bonuses.damageMult * masteryDmgMult
		state.stormCooldownMultiplier = bonuses.cooldownMult
		if isStarter then
			state.pickupRadius *= 1.25
			state.arcaneWardMax += 15
			state.arcaneWardCurrent = state.arcaneWardMax
		end
	else -- ArcanistStaff
		state.damageMultiplier = bonuses.damageMult * masteryDmgMult
		state.boltCount = math.max(state.boltCount, 1)
		state.orbCount = math.max(state.orbCount, if mastery >= 10 then 2 else 1)
		state.orbDamageMultiplier = bonuses.damageMult * masteryDmgMult
		if isStarter then
			state.arcaneWardMax += 15
			state.arcaneWardCurrent = state.arcaneWardMax
		end
	end

	applyHumanoidStats(state)
	publish(state)
end

function PlayerState.setWeapon(state: State, weaponId: string): boolean
	if state.phase ~= "Lobby" then
		return false
	end
	if not WeaponConfig.isValidId(weaponId) then
		return false
	end
	state.selectedWeapon = weaponId
	state.equippedWeapons = { weaponId }
	publish(state)
	return true
end

function PlayerState.returnToLobby(state: State): boolean
	if state.phase ~= "Summary" and state.phase ~= "Downed" and state.phase ~= "InRun" then
		return false
	end
	if state.phase == "Downed" or state.phase == "InRun" then
		enterSummary(state)
	end
	state.phase = "Lobby"
	state.alive = false
	state.health = Constants.PLAYER_MAX_HEALTH
	state.maxHealth = Constants.PLAYER_MAX_HEALTH
	state.moveSpeedMultiplier = 1
	state.downedExpiresAt = 0
	state.purchasePromptOpen = false
	state.coopReviveProgress = 0

	applyHumanoidStats(state)
	teleportCharacter(state, Constants.LOBBY_SPAWN, Vector3.new(0, 0, 1), false)
	publish(state)
	DataService.sync(state.player)
	return true
end

function PlayerState.declineRevive(state: State): boolean
	if state.phase ~= "Downed" then
		return false
	end
	enterSummary(state)
	return true
end

function PlayerState.notifyPurchasePromptOpened(state: State)
	if state.phase ~= "Downed" then
		return
	end
	state.purchasePromptOpen = true
	state.downedExpiresAt = math.max(state.downedExpiresAt, os.clock() + Constants.REVIVE_PROMPT_GRACE_SECONDS)
	publish(state)
end

function PlayerState.notifyPurchasePromptClosed(state: State)
	if not state.purchasePromptOpen then
		return
	end
	state.purchasePromptOpen = false
	if state.phase == "Downed" then
		state.downedExpiresAt = math.min(state.downedExpiresAt, os.clock() + 5)
		publish(state)
	end
end

function PlayerState.grantPaidRevive(state: State): Vector3?
	if state.phase ~= "Downed" and state.phase ~= "Summary" then
		return nil
	end
	state.revivesUsed += 1
	state.purchasePromptOpen = false
	state.downedExpiresAt = 0
	state.coopReviveProgress = 0
	state.phase = "InRun"
	state.alive = true
	state.health = state.maxHealth
	state.immuneUntil = os.clock() + Constants.REVIVE_IMMUNE_SECONDS
	state.lastDamagedAt = -math.huge

	local root = getRoot(state)
	local pos = if root then root.Position else Vector3.new(0, 3, 0)
	local now = os.clock()
	state.lastValidPosition = pos
	state.moveBudget = MOVE_BURST_STUDS
	state.moveCheckedAt = now
	state.moveGraceUntil = now + MOVE_SPAWN_GRACE

	if root then
		root.Anchored = frozen
		if not frozen then
			pcall(root.SetNetworkOwner, root, state.player)
		end
	end

	publish(state)
	return pos
end

function PlayerState.trySoftSoulRevive(state: State): Vector3?
	if state.phase ~= "Downed" or state.revivesUsed >= Constants.MAX_REVIVES_PER_RUN then
		return nil
	end
	local profile = DataService.getProfile(state.player)
	if not profile or profile.souls < Constants.SOUL_REVIVE_SOFT_COST then
		return nil
	end
	profile.souls -= Constants.SOUL_REVIVE_SOFT_COST
	state.souls = profile.souls
	DataService.sync(state.player)
	return PlayerState.grantPaidRevive(state)
end

function PlayerState.rerollOffer(state: State, isPaidGrant: boolean): boolean
	if state.phase ~= "InRun" or not state.alive or state.offer == nil then
		return false
	end
	local profile = DataService.getProfile(state.player)
	if not isPaidGrant then
		if state.rerollDice > 0 then
			state.rerollDice -= 1
			if profile and profile.fateDice > 0 then
				profile.fateDice = math.max(0, profile.fateDice - 1)
			end
		elseif profile and profile.souls >= Constants.REROLL_SOUL_COST then
			profile.souls -= Constants.REROLL_SOUL_COST
			state.souls = profile.souls
		else
			return false
		end
	end

	-- Guaranteed higher luck on Bonus Roll
	local prevLuck = state.luck
	state.luck += 0.65
	sendNextOffer(state)
	state.luck = prevLuck
	if profile then
		DataService.sync(state.player)
	end
	publish(state)
	return true
end

function PlayerState.claimAllOffer(state: State): boolean
	local offer = state.offer
	if state.phase ~= "InRun" or not state.alive or not offer or #offer == 0 then
		return false
	end
	if state.claimAllUsed >= Constants.MAX_CLAIM_ALL_PER_RUN then
		return false
	end
	state.claimAllUsed += 1
	state.offer = nil
	state.pendingLevelUps = math.max(0, state.pendingLevelUps - 1)
	state.nextOfferAllowedAt = os.clock() + 6.0
	for _, choice in ipairs(offer) do
		Upgrades.apply(state, choice)
		DataService.recordDiscovery(state.player, choice.id)
	end
	applyHumanoidStats(state)
	state.offerSeq += 1
	local close: Types.LevelUpPayload = { seq = state.offerSeq, timeout = 0, offers = {} }
	levelUpOffer:FireClient(state.player, close)
	DataService.sync(state.player)
	publish(state)
	return true
end

function PlayerState.remove(player: Player)
	DataService.removePlayer(player)
	states[player] = nil
end

function PlayerState.get(player: Player): State?
	return states[player]
end

function PlayerState.getPosition(state: State): Vector3?
	local root = getRoot(state)
	return root and root.Position
end

local function rubberBand(state: State, position: Vector3, now: number)
	if now - state.lastRubberBandAt < RUBBER_BAND_COOLDOWN then
		return
	end
	local root = getRoot(state)
	if root then
		state.lastRubberBandAt = now
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = root.CFrame.Rotation + position
	end
end

local function checkMovement(state: State, position: Vector3, now: number): Vector3
	local dashMult = if now < state.dashEndsAt then Constants.DASH_SPEED_MULT else 1
	local maxSpeed = Constants.PLAYER_WALK_SPEED * state.moveSpeedMultiplier * dashMult * MOVE_SPEED_TOLERANCE
	local maxCap = if now < state.dashEndsAt then MOVE_BURST_STUDS + Constants.DASH_BURST_STUDS else MOVE_BURST_STUDS
	state.moveBudget = math.min(state.moveBudget + maxSpeed * (now - state.moveCheckedAt), maxCap)
	state.moveCheckedAt = now

	local last = state.lastValidPosition
	if last == nil then
		state.lastValidPosition = position
		return position
	end

	local dx = position.X - last.X
	local dz = position.Z - last.Z
	local distance = math.sqrt(dx * dx + dz * dz)
	if now < state.moveGraceUntil then
		-- Reject stale pre-teleport client packets (e.g., still reporting Chapel Z=-252 right after teleporting to Arena Z=0)
		if distance <= 28 then
			state.lastValidPosition = position
			return position
		else
			rubberBand(state, last, now)
			return last
		end
	end
	if distance <= state.moveBudget then
		state.moveBudget -= distance
		state.lastValidPosition = position
		return position
	end

	local step = state.moveBudget
	local accepted = Vector3.new(last.X + dx / distance * step, position.Y, last.Z + dz / distance * step)
	state.moveBudget = 0
	state.lastValidPosition = accepted
	if distance - step > MOVE_SNAP_STUDS then
		rubberBand(state, accepted, now)
	end
	return accepted
end

local function buildTargets(): { Target }
	local Arena = require(script.Parent.Arena)
	local limit = Constants.ARENA_HALF_SIZE
	local now = os.clock()
	local list: { Target } = {}
	for _, state in states do
		if state.phase == "InRun" and state.alive then
			local position = PlayerState.getPosition(state)
			if position and math.isfinite(position.X) and math.isfinite(position.Y) and math.isfinite(position.Z) then
				-- Safety guard: if character is still inside the Sanctuary Chapel region (Z < -242 or Y > 11),
				-- re-teleport them to Arena Spawn and do not spawn/fight with a phantom target until they arrive in the Graveyard!
				if position.Z < -(limit + 2) or position.Y > 11 then
					if now - state.lastRubberBandAt >= 0.25 then
						state.lastRubberBandAt = now
						teleportCharacter(state, Constants.ARENA_SPAWN, Vector3.new(0, 0, -1), frozen)
					end
					continue
				end
				local prev = state.lastValidPosition
				local dt = math.max(now - state.moveCheckedAt, 0.016)
				local checked = checkMovement(state, position, now)
				local cx = math.clamp(checked.X, -limit, limit)
				local cz = math.clamp(checked.Z, -limit, limit)
				local rx, rz = Arena.resolveObstacle(cx, cz, Constants.PLAYER_RADIUS, 0, false)
				local clamped = Vector3.new(math.clamp(rx, -limit, limit), checked.Y, math.clamp(rz, -limit, limit))
				local vx = if prev then math.clamp((clamped.X - prev.X) / dt, -30, 30) else 0
				local vz = if prev then math.clamp((clamped.Z - prev.Z) / dt, -30, 30) else 0

				local root = getRoot(state)
				if root then
					local lv = root.CFrame.LookVector
					local lLen = math.sqrt(lv.X * lv.X + lv.Z * lv.Z)
					if lLen > 0.05 then
						state.lookDirX = lv.X / lLen
						state.lookDirZ = lv.Z / lLen
					end
				end
				if vx * vx + vz * vz > 9 then
					local vLen = math.sqrt(vx * vx + vz * vz)
					local mx = vx / vLen
					local mz = vz / vLen
					local bx = state.lookDirX * 0.65 + mx * 0.35
					local bz = state.lookDirZ * 0.65 + mz * 0.35
					local bLen = math.sqrt(bx * bx + bz * bz)
					if bLen > 0.05 then
						state.lookDirX = bx / bLen
						state.lookDirZ = bz / bLen
					end
				end

				table.insert(list, {
					state = state,
					position = clamped,
					velocity = Vector3.new(vx, 0, vz),
					lookDir = Vector3.new(state.lookDirX, 0, state.lookDirZ),
				})
			end
		end
	end
	return list
end

function PlayerState.getTargets(): { Target }
	return targets
end

function PlayerState.hasActiveRunners(): boolean
	for _, state in states do
		if state.phase == "InRun" or state.phase == "Downed" then
			return true
		end
	end
	return false
end

function PlayerState.damage(state: State, amount: number): boolean
	if state.phase ~= "InRun" or not state.alive then
		return false
	end
	local now = os.clock()
	if now < state.immuneUntil or now - state.lastDamagedAt < Constants.DAMAGE_COOLDOWN then
		return false
	end
	state.lastDamagedAt = now

	local netDamage = math.max(1, amount - state.armor)
	if state.arcaneWardCurrent > 0 then
		local absorbed = math.min(state.arcaneWardCurrent, netDamage)
		state.arcaneWardCurrent -= absorbed
		netDamage -= absorbed
	end

	if state.retributiveFlareDamage > 0 then
		local root = getRoot(state)
		local pos = if root then root.Position else Vector3.new(0, 3, 0)
		local EnemyService = require(script.Parent.EnemyService)
		EnemyService.shockwaveClear(pos, 16, state.retributiveFlareDamage * state.damageMultiplier, 20, state)
	end

	state.health -= netDamage
	if state.health <= 0 then
		enterDownedOrSummary(state)
	else
		publish(state)
	end
	return true
end

function PlayerState.heal(state: State, amount: number)
	if state.phase ~= "InRun" or not state.alive or state.health >= state.maxHealth then
		return
	end
	state.health = math.min(state.maxHealth, state.health + amount)
	publish(state)
end

function PlayerState.grantShrineBlessing(state: State)
	if state.phase ~= "InRun" or not state.alive then
		return
	end
	local profile = DataService.getProfile(state.player)
	if profile then
		profile.souls += 15
		state.souls = profile.souls
		DataService.sync(state.player)
	end
	state.health = math.min(state.maxHealth, state.health + 25)
	state.arcaneWardMax += 25
	state.arcaneWardCurrent = math.min(state.arcaneWardMax, state.arcaneWardCurrent + 25)
	state.critChance += 0.04
	state.cooldownMultiplier = math.max(Constants.MIN_COOLDOWN_MULTIPLIER, state.cooldownMultiplier * 0.90)
	state.player:SetAttribute(
		"FieldEventBanner",
		string.format(
			"🔥 SOUL BRAZIER IGNITED! +15 Souls • +25 HP & Ward • +4%% Crit & +10%% Haste! (%d)",
			math.floor(os.clock() * 10)
		)
	)
	publish(state)
end

function PlayerState.grantReliquaryChest(state: State, isBossChest: boolean)
	if state.phase ~= "InRun" or not state.alive then
		return
	end
	local soulsBonus = if isBossChest then 40 else 20
	local profile = DataService.getProfile(state.player)
	if profile then
		profile.souls += soulsBonus
		state.souls = profile.souls
		DataService.sync(state.player)
	end
	state.health = math.min(state.maxHealth, state.health + 35)
	state.arcaneWardMax += 20
	state.arcaneWardCurrent = math.min(state.arcaneWardMax, state.arcaneWardCurrent + 20)
	if isBossChest or state.rerollDice < 3 then
		state.rerollDice += 1
	end
	local bannerText = if isBossChest
		then string.format(
			"👑 BOSS RELIQUARY CLAIMED! +%d Souls • +1 Bonus Roll Coin • +20 Ward! (%d)",
			soulsBonus,
			math.floor(os.clock() * 10)
		)
		else string.format(
			"🎁 CRYPT RELIQUARY OPENED! +%d Souls • +35 HP Heal • +20 Ward! (%d)",
			soulsBonus,
			math.floor(os.clock() * 10)
		)
	state.player:SetAttribute("FieldEventBanner", bannerText)
	publish(state)
end

function PlayerState.applyCrowdControl(
	state: State,
	ccKind: string,
	baseDuration: number,
	sourceX: number,
	sourceZ: number
): boolean
	if state.phase ~= "InRun" or not state.alive or frozen then
		return false
	end
	local now = os.clock()
	if now < state.immuneUntil or now < state.dashEndsAt or now < state.ccImmuneUntil then
		return false
	end
	local duration = math.max(0.35, baseDuration * state.tenacityMult)
	state.ccKind = ccKind
	state.ccExpiresAt = now + duration
	state.ccExpiresClock = GameClock.now() + duration
	state.ccSourceX = sourceX
	state.ccSourceZ = sourceZ
	local postImmune = if ccKind == "Snare" then 2.2 else Constants.CC_HARD_IMMUNE_SECONDS
	state.ccImmuneUntil = now + duration + postImmune
	state.moveBudget = math.min(MOVE_BURST_STUDS + 10, state.moveBudget + 8)

	-- Refund 0.9s of Spectral Dash cooldown on Hard CC so skilled players can reactively Dash-Cleanse!
	if ccKind ~= "Snare" and state.dashReadyAt > now + 0.5 then
		state.dashReadyAt = math.max(now + 0.35, state.dashReadyAt - 0.9)
		local rem = math.max(0, state.dashReadyAt - now)
		state.player:SetAttribute("DashReadyClock", GameClock.now() + rem)
	end

	if ccKind == "Freeze" then
		local root = getRoot(state)
		if root then
			root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		end
	end

	applyHumanoidStats(state)
	publish(state)
	return true
end

function PlayerState.getMaxOffensivePowerRatio(elapsed: number): number
	local expectedPower = 1.0 + (elapsed / 110) + (elapsed / 220) ^ 1.45
	local maxRatio = 1.0
	for _, state in states do
		if state.phase == "InRun" and state.alive then
			local weapons = math.max(1, #state.equippedWeapons)
			local weaponFactor = 1.0 + (weapons - 1) * 0.65
			local evolutions = 0
			for _, evoId in
				{
					"evolve_staff",
					"evolve_cleaver",
					"evolve_lantern",
					"evolve_bow",
					"evolve_pistols",
					"evolve_storm",
				}
			do
				if (state.upgrades[evoId] or 0) >= 1 then
					evolutions += 1
				end
			end
			local maxDmgMult = math.max(
				state.damageMultiplier,
				state.cleaveDamageMultiplier,
				state.cinderDamageMultiplier,
				state.bowDamageMultiplier,
				state.pistolDamageMultiplier,
				state.stormDamageMultiplier
			)
			local hasteFactor = 1.0 / math.max(0.28, state.cooldownMultiplier)
			local critFactor = 1.0 + state.critChance * (state.critMultiplier - 1.0) * 0.45
			local rawPower = weaponFactor * maxDmgMult * hasteFactor * critFactor * (1.0 + evolutions * 0.35)
			local ratio = rawPower / math.max(1.0, expectedPower)
			if ratio > maxRatio then
				maxRatio = ratio
			end
		end
	end
	return maxRatio
end

function PlayerState.dash(state: State): boolean
	local inRun = state.phase == "InRun" and state.alive and not frozen
	local inLobby = state.phase == "Lobby"
	if not inRun and not inLobby then
		return false
	end
	local now = os.clock()
	if now < state.dashReadyAt then
		return false
	end
	local brokeCc = inRun and state.ccKind ~= "" and now < state.ccExpiresAt
	state.ccKind = ""
	state.ccExpiresAt = 0
	state.ccExpiresClock = 0
	state.ccImmuneUntil = math.max(state.ccImmuneUntil, now + Constants.CC_DASH_CLEANSE_IMMUNE_SECONDS)

	local cd = if inLobby then 1.8 else Constants.DASH_COOLDOWN
	state.dashReadyAt = now + cd
	state.dashEndsAt = now + Constants.DASH_DURATION
	state.immuneUntil = math.max(state.immuneUntil, now + Constants.DASH_IMMUNE_SECONDS)
	state.moveBudget =
		math.min(MOVE_BURST_STUDS + Constants.DASH_BURST_STUDS, state.moveBudget + Constants.DASH_BURST_STUDS)
	applyHumanoidStats(state)

	local root = getRoot(state)
	if root then
		local lv = root.CFrame.LookVector
		local dir = Vector3.new(lv.X, 0, lv.Z)
		if dir.Magnitude < 0.05 then
			dir = Vector3.new(state.lookDirX, 0, state.lookDirZ)
		else
			dir = dir.Unit
		end
		local burstSpeed = Constants.PLAYER_WALK_SPEED * state.moveSpeedMultiplier * Constants.DASH_SPEED_MULT
		root.AssemblyLinearVelocity = Vector3.new(dir.X * burstSpeed, root.AssemblyLinearVelocity.Y, dir.Z * burstSpeed)
		if inRun then
			local EnemyService = require(script.Parent.EnemyService)
			EnemyService.shockwaveClear(root.Position, 10, 14 * state.damageMultiplier, 12, state)
		end
	end

	if brokeCc then
		state.player:SetAttribute(
			"FieldEventBanner",
			string.format(
				"✨ SPECTRAL DASH SHATTERED CROWD-CONTROL! (Unstoppable 2.5s) (%d)",
				math.floor(os.clock() * 10)
			)
		)
	end
	state.player:SetAttribute("DashReadyClock", GameClock.now() + cd)
	publish(state)
	return true
end

function PlayerState.addKill(state: State)
	state.kills += 1
	local gameNow = GameClock.now()
	if state.bountyTarget > 0 and gameNow < state.bountyExpiresClock then
		state.bountyKills += 1
		if state.bountyKills >= state.bountyTarget then
			local targetCompleted = state.bountyTarget
			state.bountyTarget = 0
			state.bountyKills = 0
			state.nextBountyClock = gameNow + 35
			local profile = DataService.getProfile(state.player)
			if profile then
				profile.souls += 25
				state.souls = profile.souls
				DataService.sync(state.player)
			end
			state.rerollDice += 1
			local pos = PlayerState.getPosition(state)
			if pos then
				local Arena = require(script.Parent.Arena)
				Arena.spawnReliquaryChest(pos.X + 14, pos.Z, false)
			end
			state.player:SetAttribute(
				"FieldEventBanner",
				string.format(
					"🏆 WAVE BOUNTY COMPLETE (%d/%d)! +25 Souls • +1 Coin • Reliquary Dropped! (%d)",
					targetCompleted,
					targetCompleted,
					math.floor(os.clock() * 10)
				)
			)
		end
	end
	publish(state)
end

function PlayerState.addXp(state: State, amount: number)
	if state.phase ~= "InRun" or not state.alive then
		return
	end
	local needed = Constants.xpForLevel(state.level)
	local gained = math.min(needed, amount * state.xpMultiplier)
	state.xp += gained
	while state.xp >= needed do
		state.xp -= needed
		state.level += 1
		state.pendingLevelUps += 1
		needed = Constants.xpForLevel(state.level)
	end
	if state.pendingLevelUps > 0 and state.offer == nil and os.clock() >= state.nextOfferAllowedAt then
		sendNextOffer(state)
	end
	publish(state)
end

local function resolveOffer(state: State, slot: number): boolean
	local offer = state.offer
	local choice = offer and offer[slot]
	if state.phase ~= "InRun" or not state.alive or not choice then
		return false
	end
	state.offer = nil
	state.pendingLevelUps = math.max(0, state.pendingLevelUps - 1)
	state.nextOfferAllowedAt = os.clock() + 8.0
	Upgrades.apply(state, choice)
	DataService.recordDiscovery(state.player, choice.id)
	applyHumanoidStats(state)
	state.offerSeq += 1
	local close: Types.LevelUpPayload = { seq = state.offerSeq, timeout = 0, offers = {} }
	levelUpOffer:FireClient(state.player, close)
	publish(state)
	return true
end

function PlayerState.chooseUpgrade(state: State, seq: number, slot: number): boolean
	if seq ~= state.offerSeq then
		return false
	end
	state.afk = false
	return resolveOffer(state, slot)
end

function PlayerState.expireOffers()
	local now = os.clock()
	for _, state in states do
		local offer = state.offer
		if offer and now >= state.offerExpiresAt then
			state.afk = true
			resolveOffer(state, rng:NextInteger(1, #offer))
		end
		if state.phase == "Downed" then
			if now >= state.downedExpiresAt then
				enterSummary(state)
			else
				local rem = math.max(0, math.ceil(state.downedExpiresAt - now))
				if state.player:GetAttribute("DownedRemaining") ~= rem then
					state.player:SetAttribute("DownedRemaining", rem)
				end
			end
		end
	end
end

function PlayerState.anyOfferOpen(): boolean
	local anyDowned = false
	local livingCount = 0
	for _, state in states do
		if state.phase == "InRun" and state.alive then
			livingCount += 1
		elseif state.phase == "Downed" then
			anyDowned = true
		end
	end
	for _, state in states do
		if state.phase == "InRun" and state.alive and state.offer ~= nil then
			if livingCount <= 1 or not state.afk then
				return true
			end
		end
	end
	if anyDowned and livingCount == 0 then
		return true
	end
	return false
end

function PlayerState.setFrozen(value: boolean)
	frozen = value
	local now = os.clock()
	local graceUntil = now + Constants.RESUME_GRACE_SECONDS
	for _, state in states do
		if state.phase == "InRun" then
			local root = getRoot(state)
			if root then
				root.Anchored = value
				if not value then
					pcall(root.SetNetworkOwner, root, state.player)
					state.lastValidPosition = root.Position
				end
			end
			if not value then
				state.immuneUntil = graceUntil
				state.moveCheckedAt = now
			end
		end
	end
end

function PlayerState.step(dt: number)
	local Arena = require(script.Parent.Arena)
	local portalX = Constants.LOBBY_PORTAL_POS.X
	local portalZ = Constants.LOBBY_PORTAL_POS.Z
	local portalRadiusSq = Constants.LOBBY_PORTAL_RADIUS * Constants.LOBBY_PORTAL_RADIUS
	local coopPortalX = Constants.LOBBY_COOP_PORTAL_POS.X
	local coopPortalZ = Constants.LOBBY_COOP_PORTAL_POS.Z
	local coopPortalRadiusSq = Constants.LOBBY_COOP_PORTAL_RADIUS * Constants.LOBBY_COOP_PORTAL_RADIUS
	local coopRadiusSq = Constants.COOP_REVIVE_RADIUS * Constants.COOP_REVIVE_RADIUS

	local queuedCoop: { State } = {}

	for _, state in states do
		if state.phase == "Lobby" then
			if state.dashEndsAt > 0 and os.clock() >= state.dashEndsAt then
				state.dashEndsAt = 0
				applyHumanoidStats(state)
			end
			local pos = PlayerState.getPosition(state)
			if pos and math.isfinite(pos.X) and math.isfinite(pos.Z) then
				local dx = pos.X - portalX
				local dz = pos.Z - portalZ
				if dx * dx + dz * dz <= portalRadiusSq then
					PlayerState.startRun(state, false)
				else
					local cdx = pos.X - coopPortalX
					local cdz = pos.Z - coopPortalZ
					if cdx * cdx + cdz * cdz <= coopPortalRadiusSq then
						table.insert(queuedCoop, state)
					end
				end
			end
		elseif state.phase == "Downed" then
			-- Co-op Battle-Rez Ring (LOOP-6): living teammates within 8 studs revive downed ally in 3s
			local downedPos = PlayerState.getPosition(state)
			local rescuer: State? = nil
			if downedPos then
				for _, other in states do
					if other ~= state and other.phase == "InRun" and other.alive then
						local opos = PlayerState.getPosition(other)
						if opos then
							local dx = opos.X - downedPos.X
							local dz = opos.Z - downedPos.Z
							if dx * dx + dz * dz <= coopRadiusSq then
								rescuer = other
								break
							end
						end
					end
				end
			end
			if rescuer then
				state.coopReviveProgress += dt
				state.downedExpiresAt = math.max(state.downedExpiresAt, os.clock() + 2)
				if state.coopReviveProgress >= Constants.COOP_REVIVE_SECONDS then
					local revivedPos = PlayerState.grantPaidRevive(state)
					state.health = math.ceil(state.maxHealth * 0.65)
					local rescuerProfile = DataService.getProfile(rescuer.player)
					if rescuerProfile then
						rescuerProfile.souls += 20
						rescuer.souls = rescuerProfile.souls
						DataService.sync(rescuer.player)
					end
					if revivedPos then
						local EnemyService = require(script.Parent.EnemyService)
						EnemyService.shockwaveClear(revivedPos, 24, 150, 22, state)
					end
				end
				publish(state)
			elseif state.coopReviveProgress > 0 then
				state.coopReviveProgress = math.max(0, state.coopReviveProgress - dt * 0.5)
				publish(state)
			end
		elseif state.phase == "InRun" and state.alive then
			local needPublish = false
			local gameNow = GameClock.now()
			if state.pendingLevelUps > 0 and state.offer == nil and os.clock() >= state.nextOfferAllowedAt then
				sendNextOffer(state)
				needPublish = true
			end
			if state.bountyTarget > 0 and gameNow >= state.bountyExpiresClock then
				state.bountyTarget = 0
				state.bountyKills = 0
				state.nextBountyClock = gameNow + 25
				needPublish = true
			elseif state.bountyTarget == 0 and gameNow >= state.nextBountyClock then
				local elapsed = math.max(0, gameNow - state.runStart)
				state.bountyTarget = 14 + math.min(26, math.floor(elapsed / 25) * 4)
				state.bountyKills = 0
				state.bountyExpiresClock = gameNow + 35
				needPublish = true
			end
			if state.dashEndsAt > 0 and os.clock() >= state.dashEndsAt then
				state.dashEndsAt = 0
				applyHumanoidStats(state)
			end
			local nowClock = os.clock()
			if state.ccKind ~= "" then
				if nowClock >= state.ccExpiresAt then
					state.ccKind = ""
					state.ccExpiresAt = 0
					state.ccExpiresClock = 0
					applyHumanoidStats(state)
					needPublish = true
				else
					local root = getRoot(state)
					if root then
						if state.ccKind == "Freeze" then
							root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
						elseif state.ccKind == "Charm" then
							local dx = state.ccSourceX - root.Position.X
							local dz = state.ccSourceZ - root.Position.Z
							local dist = math.sqrt(dx * dx + dz * dz)
							if dist > 2.2 then
								local pullSpeed = Constants.PLAYER_WALK_SPEED * state.moveSpeedMultiplier * 0.62
								root.AssemblyLinearVelocity = Vector3.new(
									(dx / dist) * pullSpeed,
									root.AssemblyLinearVelocity.Y,
									(dz / dist) * pullSpeed
								)
								state.moveBudget = math.min(MOVE_BURST_STUDS + 8, state.moveBudget + pullSpeed * dt)
							end
						elseif state.ccKind == "Confuse" then
							local wobbleAngle = gameNow * 9.5 + state.player.UserId
							local wSpeed = Constants.PLAYER_WALK_SPEED * state.moveSpeedMultiplier * 0.45
							root.AssemblyLinearVelocity = Vector3.new(
								math.cos(wobbleAngle) * wSpeed,
								root.AssemblyLinearVelocity.Y,
								math.sin(wobbleAngle) * wSpeed
							)
							state.moveBudget = math.min(MOVE_BURST_STUDS + 8, state.moveBudget + wSpeed * dt)
						end
					end
				end
			end
			if state.regenPerSecond > 0 and state.health < state.maxHealth then
				local displayedBefore = math.ceil(state.health)
				state.health = math.min(state.maxHealth, state.health + state.regenPerSecond * dt)
				if math.ceil(state.health) ~= displayedBefore then
					needPublish = true
				end
			end
			if
				state.arcaneWardMax > 0
				and state.arcaneWardCurrent < state.arcaneWardMax
				and (os.clock() - state.lastDamagedAt >= 6)
			then
				local wardBefore = math.ceil(state.arcaneWardCurrent)
				state.arcaneWardCurrent = math.min(state.arcaneWardMax, state.arcaneWardCurrent + 8 * dt)
				if math.ceil(state.arcaneWardCurrent) ~= wardBefore then
					needPublish = true
				end
			end
			if needPublish then
				publish(state)
			end
		end
	end

	if #queuedCoop > 0 then
		coopPortalTimer += dt
		local rem = Constants.LOBBY_COOP_COUNTDOWN_SECONDS - coopPortalTimer
		Arena.updateCoopPortalBillboard(#queuedCoop, rem)
		if coopPortalTimer >= Constants.LOBBY_COOP_COUNTDOWN_SECONDS then
			coopPortalTimer = 0
			for _, s in queuedCoop do
				PlayerState.startRun(s, true)
			end
			Arena.updateCoopPortalBillboard(0, nil)
		end
	elseif coopPortalTimer > 0 then
		coopPortalTimer = 0
		Arena.updateCoopPortalBillboard(0, nil)
	end

	local nowClock = os.clock()
	if nowClock >= nextChampionsSync then
		nextChampionsSync = nowClock + 2.5
		local heroEntries: { { name: string, lv: number, mp: number } } = {}
		local killEntries: { { name: string, kills: number, souls: number } } = {}
		for _, st in states do
			local prof = DataService.getProfile(st.player)
			local lv = if prof then prof.heroLevel else 1
			local mp = if prof then prof.highestKeystoneCleared else 0
			table.insert(heroEntries, { name = st.player.DisplayName, lv = lv, mp = mp })
			table.insert(killEntries, { name = st.player.DisplayName, kills = st.bestKills, souls = st.souls })
		end
		table.sort(heroEntries, function(a, b)
			if a.mp ~= b.mp then
				return a.mp > b.mp
			end
			return a.lv > b.lv
		end)
		table.sort(killEntries, function(a, b)
			if a.kills ~= b.kills then
				return a.kills > b.kills
			end
			return a.souls > b.souls
		end)
		local westLines = { "<b>🏆 HALL OF CHAMPIONS</b>", "<font color='#9effd8'>Top Hero Level & Mythic+</font>" }
		local eastLines =
			{ "<b>💀 SLAYERS OF THE CRYPT</b>", "<font color='#ffd080'>Top Undying Kills & Souls</font>" }
		for i = 1, math.min(3, #heroEntries) do
			local e = heroEntries[i]
			table.insert(westLines, string.format("#%d %s — Lv.%d (M+%d)", i, e.name, e.lv, e.mp))
		end
		for i = 1, math.min(3, #killEntries) do
			local e = killEntries[i]
			table.insert(eastLines, string.format("#%d %s — %d Kills (%d Souls)", i, e.name, e.kills, e.souls))
		end
		Arena.updateHallOfChampions(table.concat(westLines, "\n"), table.concat(eastLines, "\n"))
	end

	targets = buildTargets()
end

return PlayerState
