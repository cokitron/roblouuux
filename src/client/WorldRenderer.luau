--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants") :: ModuleScript)
local EnemyVisuals = require(Shared:WaitForChild("EnemyVisuals") :: ModuleScript)
local GameClock = require(Shared:WaitForChild("GameClock") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Types = require(Shared:WaitForChild("Types") :: ModuleScript)
local SoundController = require(script.Parent.SoundController)

type Sample = {
	t: number,
	x: number,
	z: number,
}

-- One drawn enemy: a cloned template (or fallback primitive) whose parts are all moved together each frame
-- by multiplying the root CFrame with each part's fixed offset from the template pivot.
type Entity = {
	root: Instance,
	parts: { BasePart },
	offsets: { CFrame },
	roles: { number },
	baseColors: { Color3 },
	lights: { PointLight },
	visual: EnemyVisuals.Visual,
	samples: { Sample },
	facingX: number,
	facingZ: number,
	flashUntil: number,
}

type HeldWeaponRig = {
	weaponId: string,
	primary: Model,
	offhand: Model?,
	lights: { PointLight },
	attackStartedAt: number,
	shotIndex: number,
}

type Bolt = {
	model: Model,
	record: Types.BoltRecord,
}

type DamagePopup = {
	anchor: Part,
	billboard: BillboardGui,
	label: TextLabel,
	stroke: UIStroke,
	scale: UIScale,
	x: number,
	y: number,
	z: number,
	vx: number,
	vy: number,
	vz: number,
	age: number,
	lifetime: number,
	crit: number,
	targetScale: number,
	active: boolean,
}

local rng = Random.new()

local BIND_NAME = "SurvivorWorld"
local SAMPLE_LIMIT = 4
local SNAPSHOT_HEADER_BYTES = Constants.SNAPSHOT_HEADER_BYTES
local SNAPSHOT_ENTRY_BYTES = Constants.SNAPSHOT_ENTRY_BYTES
local TOMBSTONE_SECONDS = 2
local FACING_SHARPNESS = 12
local FLASH_SECONDS = 0.12
local FLASH_TINT = Color3.fromRGB(255, 60, 60)
local FLASH_AMOUNT = 0.65
local BOLT_COLOR = Color3.fromRGB(90, 220, 255)
local BOLT_BLADE_COLOR = Color3.fromRGB(38, 165, 250)
local BOLT_BRONZE = Color3.fromRGB(164, 126, 62)
local ORB_COLOR = Color3.fromRGB(255, 178, 58)
local ORB_RING_BRONZE = Color3.fromRGB(142, 104, 48)
local ORB_SPIKE_GOLD = Color3.fromRGB(255, 224, 110)
local DEATH_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local WorldRenderer = {}

local function newPart(
	shape: Enum.PartType,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function addTrail(part: Part)
	local left = Instance.new("Attachment")
	left.Position = Vector3.new(-0.6, 0, 0)
	left.Parent = part
	local right = Instance.new("Attachment")
	right.Position = Vector3.new(0.6, 0, 0)
	right.Parent = part

	local trail = Instance.new("Trail")
	trail.Attachment0 = left
	trail.Attachment1 = right
	trail.Lifetime = 0.18
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(BOLT_COLOR)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = part
end

-- Arcane Spearhead Magic Bolt (matches magic_bolt.sc + TextureCraft cyan crystal & bronze collar)
local function buildMagicBolt(parent: Instance, initialCFrame: CFrame, overcharge: boolean?): Model
	local model = Instance.new("Model")
	model.Name = if overcharge then "ArcaneLanceBolt" else "MagicBolt"
	local s = if overcharge then 1.45 else 1.0
	local coreColor = if overcharge then Color3.fromRGB(215, 130, 255) else BOLT_COLOR
	local bladeColor = if overcharge then Color3.fromRGB(95, 245, 255) else BOLT_BLADE_COLOR
	local collarColor = if overcharge then Color3.fromRGB(255, 215, 95) else BOLT_BRONZE

	local core =
		newPart(Enum.PartType.Block, Vector3.new(0.45 * s, 0.45 * s, 2.55 * s), coreColor, Enum.Material.Neon, model)
	core.Name = "SpearCore"
	model.PrimaryPart = core

	local bladeH =
		newPart(Enum.PartType.Block, Vector3.new(1.25 * s, 0.22 * s, 1.75 * s), bladeColor, Enum.Material.Neon, model)
	bladeH.Name = "CrystalBladeH"
	bladeH.CFrame = CFrame.new(0, 0, -0.25 * s)

	local bladeV =
		newPart(Enum.PartType.Block, Vector3.new(0.22 * s, 1.25 * s, 1.75 * s), bladeColor, Enum.Material.Neon, model)
	bladeV.Name = "CrystalBladeV"
	bladeV.CFrame = CFrame.new(0, 0, -0.25 * s)

	local collar =
		newPart(Enum.PartType.Block, Vector3.new(0.82 * s, 0.82 * s, 0.36 * s), collarColor, Enum.Material.Metal, model)
	collar.Name = "ArcaneCollar"
	collar.CFrame = CFrame.new(0, 0, 0.42 * s) * CFrame.Angles(0, 0, math.pi * 0.25)

	local tail =
		newPart(Enum.PartType.Block, Vector3.new(0.68 * s, 0.68 * s, 0.48 * s), bladeColor, Enum.Material.Neon, model)
	tail.Name = "TailFin"
	tail.CFrame = CFrame.new(0, 0, 0.98 * s) * CFrame.Angles(0, 0, math.pi * 0.25)

	if overcharge then
		local halo = newPart(
			Enum.PartType.Cylinder,
			Vector3.new(0.18, 2.2, 2.2),
			Color3.fromRGB(255, 215, 110),
			Enum.Material.Neon,
			model
		)
		halo.Name = "OverchargeHalo"
		halo.CFrame = CFrame.new(0, 0, 0.1) * CFrame.Angles(0, math.pi * 0.5, 0)
	end

	model:PivotTo(initialCFrame)
	addTrail(core)
	model.Parent = parent
	return model
end

-- Nightshade Spectral Longbow Arrow (feathered emerald-cyan shaft + broadhead tip)
local function buildSpectralArrow(parent: Instance, initialCFrame: CFrame, overcharge: boolean?): Model
	local model = Instance.new("Model")
	model.Name = if overcharge then "GaleArrow" else "SpectralArrow"
	local s = if overcharge then 1.35 else 1.0
	local shaftColor = if overcharge then Color3.fromRGB(255, 230, 95) else Color3.fromRGB(85, 255, 190)
	local featherColor = if overcharge then Color3.fromRGB(120, 255, 235) else Color3.fromRGB(45, 210, 155)

	local shaft =
		newPart(Enum.PartType.Block, Vector3.new(0.22 * s, 0.22 * s, 3.1 * s), shaftColor, Enum.Material.Neon, model)
	shaft.Name = "ArrowShaft"
	model.PrimaryPart = shaft

	local head =
		newPart(Enum.PartType.Block, Vector3.new(0.75 * s, 0.16 * s, 0.95 * s), featherColor, Enum.Material.Neon, model)
	head.Name = "Broadhead"
	head.CFrame = CFrame.new(0, 0, -1.25 * s) * CFrame.Angles(0, math.pi * 0.25, 0)

	local fletchH =
		newPart(Enum.PartType.Block, Vector3.new(0.95 * s, 0.12 * s, 0.75 * s), featherColor, Enum.Material.Neon, model)
	fletchH.Name = "FletchingH"
	fletchH.CFrame = CFrame.new(0, 0, 1.15 * s)

	local fletchV =
		newPart(Enum.PartType.Block, Vector3.new(0.12 * s, 0.95 * s, 0.75 * s), featherColor, Enum.Material.Neon, model)
	fletchV.Name = "FletchingV"
	fletchV.CFrame = CFrame.new(0, 0, 1.15 * s)

	model:PivotTo(initialCFrame)
	addTrail(shaft)
	model.Parent = parent
	return model
end

-- Witch Hunter Hexlock Silver Bullet
local function buildSilverBullet(parent: Instance, initialCFrame: CFrame, overcharge: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "SilverBullet"
	local s = if overcharge then 1.35 else 1.0
	local slugColor = if overcharge then Color3.fromRGB(255, 195, 75) else Color3.fromRGB(240, 248, 255)
	local jacketColor = if overcharge then Color3.fromRGB(255, 75, 130) else Color3.fromRGB(255, 140, 65)

	local slug =
		newPart(Enum.PartType.Block, Vector3.new(0.34 * s, 0.34 * s, 1.45 * s), slugColor, Enum.Material.Neon, model)
	slug.Name = "SilverSlug"
	model.PrimaryPart = slug

	local casing =
		newPart(Enum.PartType.Block, Vector3.new(0.48 * s, 0.48 * s, 0.55 * s), jacketColor, Enum.Material.Neon, model)
	casing.Name = "TracerRing"
	casing.CFrame = CFrame.new(0, 0, 0.35 * s)

	model:PivotTo(initialCFrame)
	addTrail(slug)
	model.Parent = parent
	return model
end

-- Runic Astrolabe Guardian Orb (matches guardian_orb.sc + TextureCraft solar core & gimbal rings)
local function buildGuardianOrb(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "GuardianOrb"

	local core =
		newPart(Enum.PartType.Ball, Vector3.one * (Constants.ORB_SIZE * 0.88), ORB_COLOR, Enum.Material.Neon, model)
	core.Name = "SolarCore"
	model.PrimaryPart = core

	local eqRing =
		newPart(Enum.PartType.Cylinder, Vector3.new(0.28, 2.85, 2.85), ORB_RING_BRONZE, Enum.Material.Metal, model)
	eqRing.Name = "EquatorialRing"
	eqRing.CFrame = CFrame.Angles(0, 0, math.pi * 0.5)

	local merRing =
		newPart(Enum.PartType.Cylinder, Vector3.new(0.24, 2.7, 2.7), ORB_RING_BRONZE, Enum.Material.Metal, model)
	merRing.Name = "MeridianRing"
	merRing.CFrame = CFrame.Angles(math.pi * 0.32, 0, 0)

	local spikeX = newPart(Enum.PartType.Block, Vector3.new(3.35, 0.3, 0.3), ORB_SPIKE_GOLD, Enum.Material.Neon, model)
	spikeX.Name = "CardinalSpikesX"

	local spikeZ = newPart(Enum.PartType.Block, Vector3.new(0.3, 0.3, 3.35), ORB_SPIKE_GOLD, Enum.Material.Neon, model)
	spikeZ.Name = "CardinalSpikesZ"

	local light = Instance.new("PointLight")
	light.Color = ORB_COLOR
	light.Brightness = 1.4
	light.Range = 14
	light.Shadows = false
	light.Parent = core

	model.Parent = parent
	return model
end

-- Ossuary Bone Shard for Bone Whirlwind
local function buildBoneShard(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "BoneShard"

	local rib = newPart(
		Enum.PartType.Block,
		Vector3.new(0.55, 2.2, 0.4),
		Color3.fromRGB(230, 224, 210),
		Enum.Material.Slate,
		model
	)
	rib.Name = "Rib"
	model.PrimaryPart = rib

	local tip = newPart(
		Enum.PartType.Wedge,
		Vector3.new(0.55, 1.2, 0.4),
		Color3.fromRGB(210, 200, 185),
		Enum.Material.Slate,
		model
	)
	tip.Name = "Tip"
	tip.CFrame = rib.CFrame * CFrame.new(0, 1.6, 0)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(180, 100, 255)
	light.Brightness = 1.2
	light.Range = 10
	light.Shadows = false
	light.Parent = rib

	model.Parent = parent
	return model
end

function WorldRenderer.start()
	local snapshotEvent = Remotes.getUnreliable("EnemySnapshot")
	local worldEvents = Remotes.get("WorldEvents")
	local boltsFired = Remotes.get("BoltsFired")

	local folder = Instance.new("Folder")
	folder.Name = "ClientWorld"
	folder.Parent = workspace

	local entities: { [number]: Entity } = {}
	local tombstones: { [number]: number } = {}
	local cancelledBolts: { [number]: number } = {}
	local clearedBefore = -math.huge
	local bolts: { [number]: Bolt } = {}
	local pendingBolts: { Types.BoltRecord } = {}
	local pendingEvents: { Types.WorldEventsPayload } = {}
	local orbSets: { [Player]: { Model } } = {}
	local boneSets: { [Player]: { Model } } = {}
	local consecratedRings: { [Player]: Part } = {}
	local weaponRigs: { [Player]: HeldWeaponRig } = {}
	local movedParts: { BasePart } = {}
	local movedCFrames: { CFrame } = {}
	local popupPool: { DamagePopup } = {}
	local popupCursor = 0

	local function triggerWeaponAttack(ox: number, oz: number)
		local bestPlayer: Player? = nil
		local bestDistSq = 144
		for _, player in Players:GetPlayers() do
			local ch = player.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local dx = root.Position.X - ox
				local dz = root.Position.Z - oz
				local d2 = dx * dx + dz * dz
				if d2 < bestDistSq then
					bestDistSq = d2
					bestPlayer = player
				end
			end
		end
		if bestPlayer then
			local rig = weaponRigs[bestPlayer]
			if rig then
				rig.attackStartedAt = os.clock()
				rig.shotIndex += 1
			end
		end
	end

	local function groundY(): number
		local value = workspace:GetAttribute("GroundY")
		return if typeof(value) == "number" then value else 0
	end

	local function getTemplate(name: string?): Instance?
		local models = ReplicatedStorage:FindFirstChild("EnemyModels")
		return if name and models then models:FindFirstChild(name) else nil
	end

	local function classifyPartRole(partName: string): number
		if string.find(partName, "WingLeft") or string.find(partName, "WingL") then
			return 1
		elseif string.find(partName, "WingRight") or string.find(partName, "WingR") then
			return 2
		elseif
			string.find(partName, "LegL")
			or string.find(partName, "ForelegL")
			or string.find(partName, "HindlegR")
			or string.find(partName, "GreaveL")
		then
			return 3
		elseif
			string.find(partName, "LegR")
			or string.find(partName, "ForelegR")
			or string.find(partName, "HindlegL")
			or string.find(partName, "GreaveR")
		then
			return 4
		elseif string.find(partName, "ArmL") or string.find(partName, "ClawLeft") then
			return 5
		elseif
			string.find(partName, "ArmR")
			or string.find(partName, "ClawRight")
			or string.find(partName, "Weapon")
			or string.find(partName, "Scythe")
			or string.find(partName, "Greatsword")
			or string.find(partName, "Club")
			or string.find(partName, "Staff")
		then
			return 6
		elseif
			string.find(partName, "Tail")
			or string.find(partName, "Tendril")
			or string.find(partName, "Jaw")
			or string.find(partName, "Mandible")
		then
			return 7
		elseif string.find(partName, "Ring") or string.find(partName, "Bubble") or string.find(partName, "Ember") then
			return 8
		elseif
			string.find(partName, "Skull")
			or string.find(partName, "Head")
			or string.find(partName, "Cranium")
			or string.find(partName, "Horn")
			or string.find(partName, "Crown")
		then
			return 9
		end
		return 0
	end

	local function createEntity(visual: EnemyVisuals.Visual): Entity
		local parts: { BasePart } = {}
		local offsets: { CFrame } = {}
		local roles: { number } = {}
		local baseColors: { Color3 } = {}
		local lights: { PointLight } = {}
		local root: Instance

		local template = getTemplate(visual.model)
		if template then
			root = template:Clone()
			for _, descendant in root:GetDescendants() do
				if descendant:IsA("BasePart") then
					table.insert(parts, descendant)
					table.insert(offsets, descendant.CFrame)
					table.insert(roles, classifyPartRole(descendant.Name))
					table.insert(baseColors, descendant.Color)
				elseif descendant:IsA("PointLight") then
					table.insert(lights, descendant)
				end
			end
			root.Parent = folder
		else
			local part = newPart(visual.shape, visual.size, visual.color, Enum.Material.SmoothPlastic, folder)
			root = part
			parts[1] = part
			offsets[1] = CFrame.new(0, visual.size.Y / 2, 0)
			roles[1] = 0
			baseColors[1] = visual.color
		end

		return {
			root = root,
			parts = parts,
			offsets = offsets,
			roles = roles,
			baseColors = baseColors,
			lights = lights,
			visual = visual,
			samples = {},
			facingX = 0,
			facingZ = -1,
			flashUntil = 0,
		}
	end

	local function pushSample(id: number, kind: number, time: number, x: number, z: number)
		if tombstones[id] or time <= clearedBefore then
			return
		end
		local entity = entities[id]
		if not entity then
			local visual = EnemyVisuals.list[kind]
			if not visual then
				return
			end
			entity = createEntity(visual)
			entities[id] = entity
		end
		local samples = entity.samples
		local last = samples[#samples]
		if last then
			if time <= last.t then
				return
			end
			local dx = x - last.x
			local dz = z - last.z
			if dx * dx + dz * dz > Constants.TELEPORT_DISTANCE ^ 2 then
				table.clear(samples)
			end
		end
		table.insert(samples, { t = time, x = x, z = z })
		if #samples > SAMPLE_LIMIT then
			table.remove(samples, 1)
		end
	end

	local function onSnapshot(data: unknown)
		if typeof(data) ~= "buffer" or buffer.len(data) < SNAPSHOT_HEADER_BYTES then
			return
		end
		local time = buffer.readf64(data, 0)
		local count = buffer.readu16(data, 8)
		if buffer.len(data) < SNAPSHOT_HEADER_BYTES + count * SNAPSHOT_ENTRY_BYTES then
			return
		end
		local offset = SNAPSHOT_HEADER_BYTES
		for _ = 1, count do
			pushSample(
				buffer.readu16(data, offset),
				buffer.readu8(data, offset + 2),
				time,
				buffer.readf32(data, offset + 3),
				buffer.readf32(data, offset + 7)
			)
			offset += SNAPSHOT_ENTRY_BYTES
		end
	end

	-- Hit feedback is a short red tint on every part, restored by updateEnemies (no tween per part).
	local function flash(entity: Entity)
		for index, part in entity.parts do
			part.Color = entity.baseColors[index]:Lerp(FLASH_TINT, FLASH_AMOUNT)
		end
		entity.flashUntil = os.clock() + FLASH_SECONDS
	end

	local function popAndRemove(entity: Entity)
		for _, part in entity.parts do
			local scatterGoal: { [string]: any } = {
				Transparency = 1,
				CFrame = part.CFrame
					* CFrame.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(0.6, 2.1), rng:NextNumber(-1.6, 1.6))
					* CFrame.Angles(rng:NextNumber(-2.6, 2.6), rng:NextNumber(-2.6, 2.6), 0),
			}
			TweenService:Create(part, DEATH_TWEEN, scatterGoal):Play()
		end
		Debris:AddItem(entity.root, DEATH_TWEEN.Time + 0.05)
	end

	-- Pooled 3D Floating Combat Text Fountain (Normal / Critical ⚡ / Super-Crit 💥)
	local function acquireDamagePopup(): DamagePopup
		local maxPool = Constants.MAX_FLOATING_NUMBERS
		if #popupPool < maxPool then
			local anchor = newPart(
				Enum.PartType.Ball,
				Vector3.new(0.2, 0.2, 0.2),
				Color3.new(1, 1, 1),
				Enum.Material.SmoothPlastic,
				folder
			)
			anchor.Name = "DmgAnchor"
			anchor.Transparency = 1

			local bb = Instance.new("BillboardGui")
			bb.Name = "DmgBillboard"
			bb.Size = UDim2.fromOffset(140, 48)
			bb.AlwaysOnTop = true
			bb.LightInfluence = 0
			bb.MaxDistance = 150
			bb.Parent = anchor

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBlack
			lbl.TextSize = 24
			lbl.TextColor3 = Color3.fromRGB(255, 250, 235)
			lbl.Parent = bb

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(16, 10, 28)
			stroke.Thickness = 2.5
			stroke.Parent = lbl

			local scale = Instance.new("UIScale")
			scale.Scale = 1
			scale.Parent = lbl

			local entry: DamagePopup = {
				anchor = anchor,
				billboard = bb,
				label = lbl,
				stroke = stroke,
				scale = scale,
				x = 0,
				y = -500,
				z = 0,
				vx = 0,
				vy = 0,
				vz = 0,
				age = 0,
				lifetime = 0.65,
				crit = 0,
				targetScale = 1,
				active = false,
			}
			table.insert(popupPool, entry)
			return entry
		end

		popupCursor = (popupCursor % maxPool) + 1
		return popupPool[popupCursor]
	end

	local function spawnDamageNumber(wx: number, wz: number, dmg: number, crit: number)
		local gy = groundY()
		local popup = acquireDamagePopup()
		popup.x = wx + rng:NextNumber(-0.85, 0.85)
		popup.y = gy + 3.4 + rng:NextNumber(0, 0.65)
		popup.z = wz + rng:NextNumber(-0.85, 0.85)
		popup.vx = rng:NextNumber(-5.2, 5.2)
		popup.vz = rng:NextNumber(-5.2, 5.2)
		popup.vy = if crit >= 2 then 16.0 elseif crit == 1 then 13.5 else 10.5
		popup.age = 0
		popup.lifetime = if crit >= 2 then 0.85 elseif crit == 1 then 0.76 else 0.62
		popup.crit = crit
		popup.active = true
		popup.billboard.Enabled = true
		popup.label.TextTransparency = 0
		popup.stroke.Transparency = 0
		popup.anchor.Position = Vector3.new(popup.x, popup.y, popup.z)

		if crit >= 2 then
			popup.label.Text = string.format("💥%d CRIT!!", dmg)
			popup.label.TextColor3 = Color3.fromRGB(255, 85, 235)
			popup.stroke.Color = Color3.fromRGB(255, 225, 65)
			popup.stroke.Thickness = 3
			popup.targetScale = 1.65
			popup.scale.Scale = 0.35

			local burst = newPart(
				Enum.PartType.Cylinder,
				Vector3.new(0.25, 1.5, 1.5),
				Color3.fromRGB(255, 95, 235),
				Enum.Material.Neon,
				folder
			)
			burst.CFrame = CFrame.new(wx, gy + 2.4, wz) * CFrame.Angles(0, 0, math.pi * 0.5)
			TweenService:Create(burst, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.1, 6.5, 6.5),
				Transparency = 1,
			}):Play()
			Debris:AddItem(burst, 0.3)
		elseif crit == 1 then
			popup.label.Text = string.format("⚡%d!", dmg)
			popup.label.TextColor3 = Color3.fromRGB(255, 205, 45)
			popup.stroke.Color = Color3.fromRGB(95, 18, 28)
			popup.stroke.Thickness = 2.8
			popup.targetScale = 1.38
			popup.scale.Scale = 0.35

			local spark =
				newPart(Enum.PartType.Ball, Vector3.one * 1.4, Color3.fromRGB(255, 225, 75), Enum.Material.Neon, folder)
			spark.Position = Vector3.new(wx, gy + 2.4, wz)
			TweenService:Create(spark, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.one * 3.6,
				Transparency = 1,
			}):Play()
			Debris:AddItem(spark, 0.25)
		else
			popup.label.Text = tostring(dmg)
			popup.label.TextColor3 = if dmg >= 25 then Color3.fromRGB(255, 238, 155) else Color3.fromRGB(250, 250, 245)
			popup.stroke.Color = Color3.fromRGB(16, 10, 28)
			popup.stroke.Thickness = 2.2
			popup.targetScale = 1.0
			popup.scale.Scale = 0.48
		end
	end

	local function updateDamageNumbers(dt: number)
		for _, popup in popupPool do
			if popup.active then
				popup.age += dt
				if popup.age >= popup.lifetime then
					popup.active = false
					popup.billboard.Enabled = false
					popup.anchor.Position = Vector3.new(0, -500, 0)
				else
					popup.vy -= 28 * dt
					popup.x += popup.vx * dt
					popup.y += popup.vy * dt
					popup.z += popup.vz * dt
					popup.anchor.Position = Vector3.new(popup.x, popup.y, popup.z)

					local t = popup.age / popup.lifetime
					if t < 0.18 then
						-- Overshoot pop-in bounce
						local popAlpha = t / 0.18
						local overshoot = if popup.crit >= 1 then 1.28 else 1.12
						popup.scale.Scale = popup.targetScale * overshoot * popAlpha
					elseif t < 0.34 then
						local settleAlpha = (t - 0.18) / 0.16
						local overshoot = if popup.crit >= 1 then 1.28 else 1.12
						popup.scale.Scale = popup.targetScale * (overshoot + (1 - overshoot) * settleAlpha)
					else
						popup.scale.Scale = popup.targetScale
					end

					if t > 0.65 then
						local fade = (t - 0.65) / 0.35
						popup.label.TextTransparency = fade
						popup.stroke.Transparency = fade
					end
				end
			end
		end
	end

	local function clearWorld(clearTime: number)
		for id, entity in entities do
			entity.root:Destroy()
			entities[id] = nil
		end
		for id, bolt in bolts do
			bolt.model:Destroy()
			bolts[id] = nil
		end
		for _, popup in popupPool do
			popup.active = false
			popup.billboard.Enabled = false
			popup.anchor.Position = Vector3.new(0, -500, 0)
		end
		-- Only bolts fired before the clear are dropped; ones already queued from the next run stay.
		for i = #pendingBolts, 1, -1 do
			if pendingBolts[i].t0 <= clearTime then
				table.remove(pendingBolts, i)
			end
		end
	end

	local function applyEvent(event: Types.WorldEventsPayload, serverNow: number)
		if event.clear then
			clearWorld(event.t)
		end
		if #event.hits > 0 then
			local maxCrit = 0
			for _, hit in event.hits do
				if hit.crit > maxCrit then
					maxCrit = hit.crit
				end
				local entity = entities[hit.id]
				local hx, hz = hit.x, hit.z
				if entity then
					flash(entity)
					local lastSample = entity.samples[#entity.samples]
					if lastSample then
						hx, hz = lastSample.x, lastSample.z
					end
				end
				spawnDamageNumber(hx, hz, hit.dmg, hit.crit)
			end
			if maxCrit >= 2 then
				SoundController.play("HitSuperCrit")
			elseif maxCrit == 1 then
				SoundController.play("HitCrit")
			else
				SoundController.play("HitNormal")
			end
		end
		if #event.kills > 0 then
			SoundController.play("EnemyKill")
		end
		for _, id in event.kills do
			tombstones[id] = serverNow + TOMBSTONE_SECONDS
			local entity = entities[id]
			if entity then
				entities[id] = nil
				popAndRemove(entity)
			end
		end
		for _, id in event.bolts do
			local bolt = bolts[id]
			if bolt then
				bolts[id] = nil
				bolt.model:Destroy()
			else
				-- Removal beat the spawn record (two separate remotes): remember it so the bolt never appears.
				cancelledBolts[id] = serverNow + TOMBSTONE_SECONDS
			end
		end
		if event.shockwaves then
			if #event.shockwaves > 0 then
				SoundController.play("Shockwave")
			end
			local gy = groundY()
			local waveTween = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			for _, sw in event.shockwaves do
				local ring = newPart(
					Enum.PartType.Cylinder,
					Vector3.new(0.4, 3, 3),
					Color3.fromRGB(90, 255, 225),
					Enum.Material.Neon,
					folder
				)
				ring.CFrame = CFrame.new(sw.x, gy + 0.6, sw.z) * CFrame.Angles(0, 0, math.pi * 0.5)
				ring.Transparency = 0.15
				local d = sw.radius * 2
				TweenService:Create(ring, waveTween, {
					Size = Vector3.new(0.15, d, d),
					Transparency = 1,
				}):Play()
				Debris:AddItem(ring, 0.5)
			end
		end
		if event.cleaves then
			local gy = groundY()
			local cleaveTween = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			for _, cl in event.cleaves do
				triggerWeaponAttack(cl.ox, cl.oz)
				SoundController.play(if cl.overcharge then "CleaveOvercharge" else "Cleave")
				if cl.overcharge then
					-- 360-Degree Executioner's Maelstrom whirl ring
					local maelstrom = newPart(
						Enum.PartType.Cylinder,
						Vector3.new(0.45, 4, 4),
						Color3.fromRGB(255, 85, 200),
						Enum.Material.Neon,
						folder
					)
					maelstrom.CFrame = CFrame.new(cl.ox, gy + 1.8, cl.oz) * CFrame.Angles(0, 0, math.pi * 0.5)
					maelstrom.Transparency = 0.15
					local d = cl.radius * 2
					TweenService
						:Create(maelstrom, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Vector3.new(0.18, d, d),
							Transparency = 1,
						})
						:Play()
					Debris:AddItem(maelstrom, 0.36)
				end
				-- True 3-Wedge Directional Frontal Cone Fan in front of the player
				local baseCf = CFrame.lookAt(
					Vector3.new(cl.ox, gy + 1.8, cl.oz),
					Vector3.new(cl.ox + cl.dirX, gy + 1.8, cl.oz + cl.dirZ)
				)
				local fanSpread = math.rad(math.min(cl.arc, 160) * 0.32)
				local coneColor = if cl.overcharge then Color3.fromRGB(255, 110, 215) else Color3.fromRGB(205, 130, 255)
				for w = -1, 1 do
					local rayCf = baseCf * CFrame.Angles(0, w * fanSpread, 0)
					local wedge = newPart(
						Enum.PartType.Block,
						Vector3.new(cl.radius * 0.65, 0.28, cl.radius * 0.55),
						coneColor,
						Enum.Material.Neon,
						folder
					)
					wedge.CFrame = rayCf * CFrame.new(0, 0, -cl.radius * 0.35)
					wedge.Transparency = 0.25
					if w == 0 then
						local flashLight = Instance.new("PointLight")
						flashLight.Color = coneColor
						flashLight.Brightness = if cl.overcharge then 3.2 else 2.0
						flashLight.Range = cl.radius * 1.15
						flashLight.Shadows = false
						flashLight.Parent = wedge
						TweenService:Create(flashLight, cleaveTween, { Brightness = 0 }):Play()
					end
					TweenService:Create(wedge, cleaveTween, {
						CFrame = rayCf * CFrame.new(0, 0, -cl.radius * 0.72),
						Size = Vector3.new(cl.radius * 0.95, 0.14, cl.radius * 0.32),
						Transparency = 1,
					}):Play()
					Debris:AddItem(wedge, 0.28)
				end
			end
		end
		if event.cinders then
			if #event.cinders > 0 then
				SoundController.play("Cinder")
			end
			local gy = groundY()
			for _, cin in event.cinders do
				triggerWeaponAttack(cin.ox, cin.oz)
				local lob = newPart(
					Enum.PartType.Ball,
					Vector3.one * (if cin.overcharge then 2.2 else 1.6),
					if cin.overcharge then Color3.fromRGB(255, 195, 75) else Color3.fromRGB(255, 125, 45),
					Enum.Material.Neon,
					folder
				)
				lob.Position = Vector3.new(cin.ox, gy + 3.2, cin.oz)
				local lobTween = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				TweenService:Create(lob, lobTween, {
					Position = Vector3.new(cin.tx, gy + 0.4, cin.tz),
					Size = Vector3.one * 0.5,
				}):Play()
				task.delay(0.28, function()
					lob:Destroy()
					if cin.overcharge then
						-- Purgatory Geyser vertical soul-fire pillar
						local pillar = newPart(
							Enum.PartType.Cylinder,
							Vector3.new(16, cin.splashRadius * 0.85, cin.splashRadius * 0.85),
							Color3.fromRGB(255, 175, 65),
							Enum.Material.Neon,
							folder
						)
						pillar.CFrame = CFrame.new(cin.tx, gy + 8, cin.tz) * CFrame.Angles(0, 0, math.pi * 0.5)
						pillar.Transparency = 0.2
						TweenService
							:Create(pillar, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								Size = Vector3.new(22, 0.4, 0.4),
								Transparency = 1,
							})
							:Play()
						Debris:AddItem(pillar, 0.6)
					end
					local pool = newPart(
						Enum.PartType.Cylinder,
						Vector3.new(0.2, cin.splashRadius * 2, cin.splashRadius * 2),
						if cin.overcharge then Color3.fromRGB(255, 155, 55) else Color3.fromRGB(255, 105, 40),
						Enum.Material.Neon,
						folder
					)
					pool.CFrame = CFrame.new(cin.tx, gy + 0.12, cin.tz) * CFrame.Angles(0, 0, math.pi * 0.5)
					pool.Transparency = 0.4
					TweenService:Create(pool, TweenInfo.new(cin.duration, Enum.EasingStyle.Linear), {
						Transparency = 1,
					}):Play()
					Debris:AddItem(pool, cin.duration + 0.1)
				end)
			end
		end
		if event.emergences then
			local gy = groundY()
			for _, em in event.emergences do
				local ring = newPart(
					Enum.PartType.Cylinder,
					Vector3.new(0.3, 1.8, 1.8),
					Color3.fromRGB(120, 255, 160),
					Enum.Material.Neon,
					folder
				)
				ring.CFrame = CFrame.new(em.x, gy + 0.2, em.z) * CFrame.Angles(0, 0, math.pi * 0.5)
				ring.Transparency = 0.2
				TweenService:Create(ring, TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.12, 7.5, 7.5),
					Transparency = 1,
				}):Play()
				Debris:AddItem(ring, 0.52)

				local mound = newPart(
					Enum.PartType.Cylinder,
					Vector3.new(0.5, 2.6, 2.6),
					Color3.fromRGB(58, 52, 66),
					Enum.Material.Slate,
					folder
				)
				mound.CFrame = CFrame.new(em.x, gy + 0.25, em.z) * CFrame.Angles(0, 0, math.pi * 0.5)
				TweenService:Create(mound, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = CFrame.new(em.x, gy + 1.8, em.z) * CFrame.Angles(0, 0, math.pi * 0.5),
					Size = Vector3.new(3.2, 0.8, 0.8),
					Transparency = 1,
				}):Play()
				Debris:AddItem(mound, 0.5)
			end
		end
		if event.lightnings then
			if #event.lightnings > 0 then
				SoundController.play("Lightning")
			end
			local gy = groundY()
			for _, ln in event.lightnings do
				triggerWeaponAttack(ln.x1, ln.z1)
				local p1 = Vector3.new(ln.x1, gy + 2.6, ln.z1)
				local p2 = Vector3.new(ln.x2, gy + 2.6, ln.z2)
				local mid = (p1 + p2) * 0.5
					+ Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(0.4, 1.4), rng:NextNumber(-1.6, 1.6))
				local arcColor = if ln.overcharge then Color3.fromRGB(255, 235, 110) else Color3.fromRGB(95, 235, 255)

				local function spawnSegment(a: Vector3, b: Vector3, withLight: boolean)
					local len = (b - a).Magnitude
					local seg = newPart(
						Enum.PartType.Block,
						Vector3.new(0.35, 0.35, math.max(0.5, len)),
						arcColor,
						Enum.Material.Neon,
						folder
					)
					seg.CFrame = CFrame.lookAt((a + b) * 0.5, b)
					if withLight then
						local arcLight = Instance.new("PointLight")
						arcLight.Color = arcColor
						arcLight.Brightness = if ln.overcharge then 3.5 else 2.2
						arcLight.Range = if ln.overcharge then 18 else 12
						arcLight.Shadows = false
						arcLight.Parent = seg
						TweenService
							:Create(arcLight, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								Brightness = 0,
							})
							:Play()
					end
					TweenService:Create(seg, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = Vector3.new(0.08, 0.08, math.max(0.5, len)),
						Transparency = 1,
					}):Play()
					Debris:AddItem(seg, 0.25)
				end

				spawnSegment(p1, mid, false)
				spawnSegment(mid, p2, true)

				if ln.overcharge then
					local skyBolt = newPart(
						Enum.PartType.Cylinder,
						Vector3.new(22, 2.2, 2.2),
						Color3.fromRGB(165, 245, 255),
						Enum.Material.Neon,
						folder
					)
					skyBolt.CFrame = CFrame.new(ln.x2, gy + 11, ln.z2) * CFrame.Angles(0, 0, math.pi * 0.5)
					TweenService
						:Create(skyBolt, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Vector3.new(26, 0.2, 0.2),
							Transparency = 1,
						})
						:Play()
					Debris:AddItem(skyBolt, 0.42)
				end
			end
		end
	end

	local function spawnBolt(record: Types.BoltRecord)
		if cancelledBolts[record.id] then
			return
		end
		triggerWeaponAttack(record.ox, record.oz)
		local y = groundY() + Constants.PROJECTILE_HEIGHT
		local startPos = Vector3.new(record.ox, y, record.oz)
		local initialCf = CFrame.lookAt(startPos, startPos + Vector3.new(record.dx, 0, record.dz))
		local model: Model
		if record.kind == "Arrow" then
			SoundController.play("Arrow")
			model = buildSpectralArrow(folder, initialCf, record.overcharge)
		elseif record.kind == "Bullet" then
			SoundController.play("Bullet")
			model = buildSilverBullet(folder, initialCf, record.overcharge)
		else
			SoundController.play("Bolt")
			model = buildMagicBolt(folder, initialCf, record.overcharge)
		end
		bolts[record.id] = { model = model, record = record }
	end

	local function updateEnemies(renderTime: number, dt: number)
		local ground = groundY()
		local now = os.clock()
		local facingAlpha = 1 - math.exp(-dt * FACING_SHARPNESS)
		local moved = 0

		local playerPositions: { Vector3 } = {}
		for _, p in Players:GetPlayers() do
			local char = p.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp and hrp:IsA("BasePart") then
					table.insert(playerPositions, hrp.Position)
				end
			end
		end

		for id, entity in entities do
			local samples = entity.samples
			local count = #samples
			local last = samples[count]
			if renderTime - last.t > Constants.ENTITY_TIMEOUT then
				entity.root:Destroy()
				entities[id] = nil
				continue
			end

			local x, z = last.x, last.z
			local moveX, moveZ = 0, 0
			local sampleSpan = 0
			if count > 1 and renderTime < last.t then
				if renderTime <= samples[1].t then
					x, z = samples[1].x, samples[1].z
				else
					for i = count - 1, 1, -1 do
						local a = samples[i]
						if renderTime >= a.t then
							local b = samples[i + 1]
							sampleSpan = b.t - a.t
							local alpha = (renderTime - a.t) / math.max(sampleSpan, 1e-4)
							x = a.x + (b.x - a.x) * alpha
							z = a.z + (b.z - a.z) * alpha
							moveX, moveZ = b.x - a.x, b.z - a.z
							break
						end
					end
				end
			elseif count > 1 and renderTime > last.t then
				-- Newest sample is behind render time (late packet): coast on the last velocity, briefly.
				local previous = samples[count - 1]
				local span = last.t - previous.t
				if span > 1e-4 then
					sampleSpan = span
					local ahead = math.min(renderTime - last.t, Constants.MAX_EXTRAPOLATION)
					moveX, moveZ = last.x - previous.x, last.z - previous.z
					x = last.x + moveX / span * ahead
					z = last.z + moveZ / span * ahead
				end
			end

			-- Turn toward the direction of travel smoothly so separation jitter does not make enemies twitch.
			local moveLength = math.sqrt(moveX * moveX + moveZ * moveZ)
			local sampleSpeed = if sampleSpan > 1e-4 then moveLength / sampleSpan else 0
			if moveLength > 1e-3 then
				entity.facingX += (moveX / moveLength - entity.facingX) * facingAlpha
				entity.facingZ += (moveZ / moveLength - entity.facingZ) * facingAlpha
			end

			local visual = entity.visual
			local phase = renderTime * (visual.floatFreq or 8.5) + id * 1.37
			local s = math.sin(phase)
			local c = math.cos(phase)
			local bobY = 0
			local rollZ = 0
			local pitchX = -math.min(moveLength * 0.25, 0.14)
			if visual.floatAmp then
				bobY = s * visual.floatAmp
				rollZ = math.cos(phase * 0.7) * 0.08
				pitchX += c * 0.06
			else
				bobY = math.abs(s) * 0.24
				rollZ = s * 0.065
			end

			local wingFlapL = CFrame.Angles(0, c * 0.12, s * 0.48)
			local wingFlapR = CFrame.Angles(0, -c * 0.12, -s * 0.48)
			local legSwingL = CFrame.Angles(s * 0.48, 0, 0)
			local legSwingR = CFrame.Angles(-s * 0.48, 0, 0)
			local armSwingL = CFrame.Angles(-s * 0.32, 0, 0)
			local armSwingR = CFrame.Angles(s * 0.42, 0, c * 0.15)
			local tailWag = CFrame.Angles(s * 0.12, c * 0.32, 0)
			local orbitSpin = CFrame.Angles(0, phase * 0.55, 0) * CFrame.new(0, s * 0.16, 0)
			local headLook = CFrame.Angles(c * 0.09, s * 0.11, 0)

			-- Crypt Legionnaire (Skeleton): Synchronized Phalanx Thrust & Close-Range Breacher Launch
			if visual.name == "Skeleton" then
				local minPlayerDistSq = math.huge
				for _, pPos in playerPositions do
					local dx = pPos.X - x
					local dz = pPos.Z - z
					local dSq = dx * dx + dz * dz
					if dSq < minPlayerDistSq then
						minPlayerDistSq = dSq
					end
				end

				if sampleSpeed > 17.5 then
					-- Airborne Close-Range Breacher Launch (at most 2 per cohort): leaps forward & rams shield/blade!
					local launchWave = math.sin((renderTime * 14) % math.pi)
					bobY = 0.95 + 0.45 * launchWave
					pitchX = -0.46
					legSwingL = CFrame.Angles(-0.55, 0, 0)
					legSwingR = CFrame.Angles(0.35, 0, 0)
					armSwingL = CFrame.new(0, 0.15, -0.65) * CFrame.Angles(0.55, 0.35, 0)
					armSwingR = CFrame.new(0, 0.2, -1.85) * CFrame.Angles(0.35, 0, 0)
				elseif minPlayerDistSq <= 15 * 15 then
					-- Shared cohort cadence (no per-entity phase offset!) so the entire line thrusts in unison
					local legionCycle = renderTime % 1.85
					if legionCycle < 0.30 then
						-- Synchronized Shield-Wall Brace & Wind-Up
						local windAlpha = legionCycle / 0.30
						pitchX = 0.08 * windAlpha
						armSwingL = CFrame.new(0.18 * windAlpha, 0, -0.25 * windAlpha)
							* CFrame.Angles(0.2 * windAlpha, 0.35 * windAlpha, 0)
						armSwingR = CFrame.new(0, 0.1 * windAlpha, 0.75 * windAlpha)
							* CFrame.Angles(-0.35 * windAlpha, 0, 0)
					elseif legionCycle < 0.58 then
						-- Synchronized Phalanx Blade Thrust!
						local thrustAlpha = math.sin(((legionCycle - 0.30) / 0.28) * math.pi)
						pitchX = -0.28 * thrustAlpha
						armSwingL = CFrame.new(0.18, 0, -0.25) * CFrame.Angles(0.2, 0.35, 0)
						armSwingR = CFrame.new(0, 0.12 * thrustAlpha, -1.95 * thrustAlpha)
							* CFrame.Angles(0.25 * thrustAlpha, 0, 0)
					end
				end
			end

			-- Light Animation: Organic multi-sine candle/soul flicker on monster PointLights
			if #entity.lights > 0 then
				local flicker = 1.35 + 0.32 * math.sin(renderTime * 7.5 + id) + 0.18 * math.cos(renderTime * 16.3 + id)
				for _, light in entity.lights do
					light.Brightness = flicker
				end
			end

			local position = Vector3.new(x, ground + bobY, z)
			local rootCFrame = CFrame.lookAt(position, position + Vector3.new(entity.facingX, 0, entity.facingZ))
				* CFrame.Angles(pitchX, 0, rollZ)
			local roles = entity.roles
			for index, part in entity.parts do
				moved += 1
				movedParts[moved] = part
				local baseOffset = entity.offsets[index]
				local role = roles[index]
				if role == 1 then
					movedCFrames[moved] = rootCFrame * baseOffset * wingFlapL
				elseif role == 2 then
					movedCFrames[moved] = rootCFrame * baseOffset * wingFlapR
				elseif role == 3 then
					movedCFrames[moved] = rootCFrame * baseOffset * legSwingL
				elseif role == 4 then
					movedCFrames[moved] = rootCFrame * baseOffset * legSwingR
				elseif role == 5 then
					movedCFrames[moved] = rootCFrame * baseOffset * armSwingL
				elseif role == 6 then
					movedCFrames[moved] = rootCFrame * baseOffset * armSwingR
				elseif role == 7 then
					movedCFrames[moved] = rootCFrame * baseOffset * tailWag
				elseif role == 8 then
					movedCFrames[moved] = rootCFrame * baseOffset * orbitSpin
				elseif role == 9 then
					movedCFrames[moved] = rootCFrame * baseOffset * headLook
				else
					movedCFrames[moved] = rootCFrame * baseOffset
				end
			end

			if entity.flashUntil > 0 and now >= entity.flashUntil then
				entity.flashUntil = 0
				for index, part in entity.parts do
					part.Color = entity.baseColors[index]
				end
			end
		end

		for i = #movedParts, moved + 1, -1 do
			movedParts[i] = nil
			movedCFrames[i] = nil
		end
		workspace:BulkMoveTo(movedParts, movedCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local function updateBolts(renderTime: number)
		local y = groundY() + Constants.PROJECTILE_HEIGHT
		for id, bolt in bolts do
			local record = bolt.record
			local age = renderTime - record.t0
			if age >= Constants.BOLT_LIFETIME then
				bolt.model:Destroy()
				bolts[id] = nil
			else
				local travelled = record.v * math.max(age, 0)
				local position = Vector3.new(record.ox + record.dx * travelled, y, record.oz + record.dz * travelled)
				local spin = age * 14
				bolt.model:PivotTo(
					CFrame.lookAt(position, position + Vector3.new(record.dx, 0, record.dz)) * CFrame.Angles(0, 0, spin)
				)
			end
		end
	end

	local function numberAttribute(player: Player, name: string, fallback: number): number
		local value = player:GetAttribute(name)
		return if typeof(value) == "number" and math.isfinite(value) then value else fallback
	end

	local function updateOrbs(serverNow: number)
		local y = groundY() + Constants.PROJECTILE_HEIGHT
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local orbAttribute = player:GetAttribute("OrbCount")
			local wanted = 0
			if typeof(orbAttribute) == "number" and player:GetAttribute("Dead") ~= true then
				wanted = orbAttribute
			end

			local orbs = orbSets[player]
			if not orbs then
				orbs = {}
				orbSets[player] = orbs
			end
			while #orbs < wanted do
				table.insert(orbs, buildGuardianOrb(folder))
			end
			while #orbs > wanted do
				local orb = table.remove(orbs)
				if orb then
					orb:Destroy()
				end
			end

			-- A character that streams out keeps its orbs (hidden below ground) instead of destroying and recreating them.
			local anchor = if root and root:IsA("BasePart") then root else nil
			local radius = numberAttribute(player, "OrbRadius", Constants.ORB_RADIUS)
			local baseAngle = (serverNow * numberAttribute(player, "OrbSpeed", Constants.ORB_SPEED)) % (math.pi * 2)
			for index, orb in orbs do
				if anchor then
					local center = anchor.Position
					local angle = baseAngle + (index - 1) * math.pi * 2 / wanted
					local orbPos =
						Vector3.new(center.X + math.cos(angle) * radius, y, center.Z + math.sin(angle) * radius)
					orb:PivotTo(
						CFrame.new(orbPos) * CFrame.Angles(serverNow * 2.2, serverNow * 3.4 + index, serverNow * 1.6)
					)
				else
					orb:PivotTo(CFrame.new(0, -500, 0))
				end
			end
		end
	end

	local function updateBones(serverNow: number)
		local y = groundY() + Constants.PROJECTILE_HEIGHT
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local boneAttr = player:GetAttribute("BoneCount")
			local wanted = 0
			if typeof(boneAttr) == "number" and player:GetAttribute("Dead") ~= true then
				wanted = boneAttr
			end

			local bones = boneSets[player]
			if not bones then
				bones = {}
				boneSets[player] = bones
			end
			while #bones < wanted do
				table.insert(bones, buildBoneShard(folder))
			end
			while #bones > wanted do
				local b = table.remove(bones)
				if b then
					b:Destroy()
				end
			end

			local anchor = if root and root:IsA("BasePart") then root else nil
			local radius = numberAttribute(player, "BoneRadius", Constants.BONE_RADIUS)
			local speed = numberAttribute(player, "BoneSpeed", Constants.BONE_SPEED)
			local baseAngle = (serverNow * speed) % (math.pi * 2)
			for index, bone in bones do
				if anchor then
					local center = anchor.Position
					local angle = baseAngle + (index - 1) * math.pi * 2 / wanted
					local bPos =
						Vector3.new(center.X + math.cos(angle) * radius, y, center.Z + math.sin(angle) * radius)
					bone:PivotTo(CFrame.new(bPos) * CFrame.Angles(serverNow * 3.5, -angle, serverNow * 2.1))
				else
					bone:PivotTo(CFrame.new(0, -500, 0))
				end
			end
		end
	end

	local function updateConsecrated(serverNow: number)
		local gy = groundY()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local crAttr = player:GetAttribute("ConsecratedRadius")
			local wantedRadius = 0
			if typeof(crAttr) == "number" and player:GetAttribute("Dead") ~= true then
				wantedRadius = crAttr
			end

			local ring = consecratedRings[player]
			if wantedRadius > 0 then
				if not ring then
					ring = newPart(
						Enum.PartType.Cylinder,
						Vector3.new(0.18, wantedRadius * 2, wantedRadius * 2),
						Color3.fromRGB(255, 215, 85),
						Enum.Material.Neon,
						folder
					)
					ring.Transparency = 0.68
					consecratedRings[player] = ring
				else
					ring.Size = Vector3.new(0.18, wantedRadius * 2, wantedRadius * 2)
				end
				if root and root:IsA("BasePart") then
					ring.CFrame = CFrame.new(root.Position.X, gy + 0.16, root.Position.Z)
						* CFrame.Angles(0, serverNow * 0.4, 0)
						* CFrame.Angles(0, 0, math.pi * 0.5)
				else
					ring.CFrame = CFrame.new(0, -500, 0)
				end
			else
				if ring then
					ring:Destroy()
					consecratedRings[player] = nil
				end
			end
		end
	end

	local function destroyWeaponRig(rig: HeldWeaponRig)
		rig.primary:Destroy()
		if rig.offhand then
			rig.offhand:Destroy()
		end
	end

	local function buildHeldWeaponRig(weaponId: string): HeldWeaponRig?
		local wModels = ReplicatedStorage:FindFirstChild("WeaponModels")
		local template = if wModels then wModels:FindFirstChild(weaponId) else nil
		if not template or not template:IsA("Model") then
			return nil
		end
		local primary = template:Clone()
		primary.Parent = folder
		local offhand: Model? = nil
		if weaponId == "HexlockPistols" then
			offhand = template:Clone()
			if offhand then
				offhand.Parent = folder
			end
		end
		local lights: { PointLight } = {}
		for _, desc in primary:GetDescendants() do
			if desc:IsA("PointLight") then
				table.insert(lights, desc)
			end
		end
		if offhand then
			for _, desc in offhand:GetDescendants() do
				if desc:IsA("PointLight") then
					table.insert(lights, desc)
				end
			end
		end
		return {
			weaponId = weaponId,
			primary = primary,
			offhand = offhand,
			lights = lights,
			attackStartedAt = 0,
			shotIndex = 0,
		}
	end

	local aimChevronPart: Part? = nil
	local ccRingPart: Part? = nil
	local ccPrismPart: Part? = nil
	local function getOrCreateAimChevron(): Part
		if aimChevronPart then
			return aimChevronPart
		end
		local part = Instance.new("Part")
		part.Name = "AimChevron"
		part.Size = Vector3.new(2.4, 0.08, 2.4)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(95, 240, 255)
		part.Transparency = 0.55
		part.CFrame = CFrame.new(0, -500, 0)
		part.Parent = folder
		aimChevronPart = part
		return part
	end

	local function getOrCreateCcVisuals(): (Part, Part)
		if ccRingPart and ccPrismPart then
			return ccRingPart, ccPrismPart
		end
		local ring = Instance.new("Part")
		ring.Name = "CcStatusRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.14, 5.2, 5.2)
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanTouch = false
		ring.CanQuery = false
		ring.CastShadow = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(95, 240, 255)
		ring.Transparency = 0.35
		ring.CFrame = CFrame.new(0, -500, 0)
		ring.Parent = folder

		local prism = Instance.new("Part")
		prism.Name = "CcStatusPrism"
		prism.Size = Vector3.new(3.8, 5.4, 3.8)
		prism.Anchored = true
		prism.CanCollide = false
		prism.CanTouch = false
		prism.CanQuery = false
		prism.CastShadow = false
		prism.Material = Enum.Material.Glass
		prism.Color = Color3.fromRGB(110, 235, 255)
		prism.Transparency = 0.45
		prism.CFrame = CFrame.new(0, -500, 0)
		prism.Parent = folder

		ccRingPart = ring
		ccPrismPart = prism
		return ring, prism
	end

	local function poseCharacterDualPistols(
		character: Model?,
		active: boolean,
		rightKick: number,
		leftKick: number,
		idleSway: number
	)
		if not character then
			return
		end
		local rUpper = character:FindFirstChild("RightUpperArm")
		local lUpper = character:FindFirstChild("LeftUpperArm")
		local rLower = character:FindFirstChild("RightLowerArm")
		local lLower = character:FindFirstChild("LeftLowerArm")
		local rShoulder = if rUpper then rUpper:FindFirstChild("RightShoulder") else nil
		local lShoulder = if lUpper then lUpper:FindFirstChild("LeftShoulder") else nil
		local rElbow = if rLower then rLower:FindFirstChild("RightElbow") else nil
		local lElbow = if lLower then lLower:FindFirstChild("LeftElbow") else nil

		if active then
			if rShoulder and rShoulder:IsA("Motor6D") then
				rShoulder.Transform = CFrame.Angles(math.rad(82) + rightKick * 0.45 + idleSway * 0.4, math.rad(-5), 0)
			end
			if lShoulder and lShoulder:IsA("Motor6D") then
				lShoulder.Transform = CFrame.Angles(math.rad(82) + leftKick * 0.45 - idleSway * 0.4, math.rad(5), 0)
			end
			if rElbow and rElbow:IsA("Motor6D") then
				rElbow.Transform = CFrame.Angles(math.rad(12) + rightKick * 0.25, 0, 0)
			end
			if lElbow and lElbow:IsA("Motor6D") then
				lElbow.Transform = CFrame.Angles(math.rad(12) + leftKick * 0.25, 0, 0)
			end
		end
	end

	local function updatePlayerWeapons(serverNow: number)
		local now = os.clock()
		local localPlayer = Players.LocalPlayer
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local wAttr = player:GetAttribute("SelectedWeapon")
			local equippedAttr = player:GetAttribute("EquippedWeapons")
			local equippedStr = if typeof(equippedAttr) == "string" then equippedAttr else ""
			local wantedId = if typeof(wAttr) == "string" and player:GetAttribute("Dead") ~= true then wAttr else ""
			if player:GetAttribute("Dead") ~= true and string.find(equippedStr, "HexlockPistols", 1, true) ~= nil then
				wantedId = "HexlockPistols"
			end

			if player == localPlayer then
				local chevron = getOrCreateAimChevron()
				local ccRing, ccPrism = getOrCreateCcVisuals()
				if
					player:GetAttribute("Phase") == "InRun"
					and player:GetAttribute("Dead") ~= true
					and root
					and root:IsA("BasePart")
				then
					local lv = root.CFrame.LookVector
					local flatLook = Vector3.new(lv.X, 0, lv.Z)
					if flatLook.Magnitude > 0.05 then
						flatLook = flatLook.Unit
						local checkWeapons = if equippedStr ~= "" then equippedStr else wantedId
						local isCleaver = string.find(checkWeapons, "CryptCleaver", 1, true) ~= nil
						local dist = if isCleaver then 7.5 else 5.2
						local pos =
							Vector3.new(root.Position.X + flatLook.X * dist, 0.14, root.Position.Z + flatLook.Z * dist)
						chevron.Size = if isCleaver then Vector3.new(4.2, 0.09, 1.4) else Vector3.new(1.8, 0.08, 0.8)
						chevron.Color = if isCleaver
							then Color3.fromRGB(215, 115, 255)
							else Color3.fromRGB(95, 240, 255)
						chevron.Transparency = if isCleaver then 0.35 else 0.62
						chevron.CFrame = CFrame.lookAt(pos, pos + flatLook)
					end

					local ccKindRaw = player:GetAttribute("CcKind")
					local ccKind = if typeof(ccKindRaw) == "string" then ccKindRaw else ""
					local ccExpRaw = player:GetAttribute("CcExpiresClock")
					local ccExp = if typeof(ccExpRaw) == "number" then ccExpRaw else 0
					if ccKind ~= "" and serverNow < ccExp then
						local spin = serverNow * 4.5
						ccRing.CFrame = CFrame.new(root.Position.X, 0.22, root.Position.Z)
							* CFrame.Angles(0, spin, math.pi / 2)
						if ccKind == "Freeze" then
							ccRing.Color = Color3.fromRGB(95, 240, 255)
							ccPrism.Color = Color3.fromRGB(115, 235, 255)
							ccPrism.Size = Vector3.new(3.8, 5.4, 3.8)
							ccPrism.Transparency = 0.42
							ccPrism.CFrame = CFrame.new(root.Position.X, root.Position.Y, root.Position.Z)
								* CFrame.Angles(0, spin * 0.3, 0)
						elseif ccKind == "Confuse" then
							ccRing.Color = Color3.fromRGB(215, 110, 255)
							ccPrism.Color = Color3.fromRGB(255, 225, 85)
							ccPrism.Size = Vector3.new(2.2, 0.45, 2.2)
							ccPrism.Transparency = 0.25
							ccPrism.CFrame = CFrame.new(root.Position.X, root.Position.Y + 3.2, root.Position.Z)
								* CFrame.Angles(0.35, spin * 2.2, 0.35)
						elseif ccKind == "Charm" then
							ccRing.Color = Color3.fromRGB(255, 95, 195)
							local sxRaw = player:GetAttribute("CcSourceX")
							local szRaw = player:GetAttribute("CcSourceZ")
							local sx = if typeof(sxRaw) == "number" then sxRaw else root.Position.X
							local sz = if typeof(szRaw) == "number" then szRaw else root.Position.Z
							local midX = (root.Position.X + sx) * 0.5
							local midZ = (root.Position.Z + sz) * 0.5
							local tDist =
								math.clamp(math.sqrt((sx - root.Position.X) ^ 2 + (sz - root.Position.Z) ^ 2), 1, 24)
							ccPrism.Color = Color3.fromRGB(255, 105, 205)
							ccPrism.Size = Vector3.new(0.35, 0.35, tDist)
							ccPrism.Transparency = 0.30
							ccPrism.CFrame = CFrame.lookAt(Vector3.new(midX, 2.2, midZ), Vector3.new(sx, 2.2, sz))
						else -- Snare
							ccRing.Color = Color3.fromRGB(95, 255, 135)
							ccPrism.CFrame = CFrame.new(0, -500, 0)
						end
					else
						ccRing.CFrame = CFrame.new(0, -500, 0)
						ccPrism.CFrame = CFrame.new(0, -500, 0)
					end
				else
					chevron.CFrame = CFrame.new(0, -500, 0)
					ccRing.CFrame = CFrame.new(0, -500, 0)
					ccPrism.CFrame = CFrame.new(0, -500, 0)
				end
			end

			local rig = weaponRigs[player]
			if wantedId == "" then
				if rig then
					destroyWeaponRig(rig)
					weaponRigs[player] = nil
				end
				continue
			end

			if not rig or rig.weaponId ~= wantedId then
				if rig then
					destroyWeaponRig(rig)
				end
				rig = buildHeldWeaponRig(wantedId)
				if rig then
					weaponRigs[player] = rig
				end
			end

			if not rig then
				continue
			end

			if not root or not root:IsA("BasePart") then
				rig.primary:PivotTo(CFrame.new(0, -500, 0))
				if rig.offhand then
					rig.offhand:PivotTo(CFrame.new(0, -500, 0))
				end
				continue
			end

			local vel = root.AssemblyLinearVelocity
			local horizSpeed = math.sqrt(vel.X * vel.X + vel.Z * vel.Z)
			local moveFactor = math.clamp(horizSpeed / 16, 0, 1.2)
			local walkBob = math.sin(serverNow * 9.5) * 0.18 * moveFactor
			local idleSway = math.sin(serverNow * 2.8) * 0.08
			local attackElapsed = now - rig.attackStartedAt
			local attackAlpha = if attackElapsed >= 0 and attackElapsed < 0.24 then 1 - (attackElapsed / 0.24) else 0
			local attackPulse = math.sin(attackAlpha * math.pi)

			-- Flickering + attack flare on held weapon PointLights
			local baseGlow = 1.25 + 0.25 * math.sin(serverNow * 8.2) + attackPulse * 1.65
			for _, light in rig.lights do
				light.Brightness = baseGlow
			end

			local rootCf = root.CFrame
			if wantedId == "PhantomBow" then
				-- Held in left hand, tilted slightly into a ranger stance; tilts & recoils on shot
				local drawKick = attackPulse * 0.28
				local bowCf = rootCf
					* CFrame.new(-1.35, 0.35 + walkBob, -1.05 + drawKick)
					* CFrame.Angles(idleSway + attackPulse * 0.18, 0.15, 0.22)
				rig.primary:PivotTo(bowCf)
			elseif wantedId == "CryptCleaver" then
				-- Sweeps a 130-degree horizontal slash across the front during a cleave
				local swingYaw = if attackAlpha > 0 then (0.5 - attackAlpha) * 2.35 else -0.35 + idleSway
				local swingPitch = if attackAlpha > 0 then -1.25 else -0.35 + walkBob * 0.6
				local cleaverCf = rootCf
					* CFrame.new(1.45, 0.25 + walkBob, -0.85 - attackPulse * 0.65)
					* CFrame.Angles(swingPitch, swingYaw, -0.35)
				rig.primary:PivotTo(cleaverCf)
			elseif wantedId == "HexlockPistols" then
				-- Dual-wielding flintlock revolvers held in outstretched hands with alternating upward muzzle recoil
				local rightKick = if rig.shotIndex % 2 == 0 then attackPulse else attackPulse * 0.35
				local leftKick = if rig.shotIndex % 2 == 1 then attackPulse else attackPulse * 0.35
				poseCharacterDualPistols(character, true, rightKick, leftKick, idleSway)
				local rightCf = rootCf
					* CFrame.new(1.18, 0.36 + walkBob * 0.35, -1.62 + rightKick * 0.32)
					* CFrame.Angles(rightKick * 0.55 + idleSway * 0.4, math.rad(-4), 0)
				rig.primary:PivotTo(rightCf)
				if rig.offhand then
					local leftCf = rootCf
						* CFrame.new(-1.18, 0.36 - walkBob * 0.35, -1.62 + leftKick * 0.32)
						* CFrame.Angles(leftKick * 0.55 - idleSway * 0.4, math.rad(4), 0)
					rig.offhand:PivotTo(leftCf)
				end
			elseif wantedId == "ArcanistStaff" then
				-- Held upright in right hand; thrusts forward when casting bolts
				local staffCf = rootCf
					* CFrame.new(1.45, 0.15 + walkBob, -0.75 - attackPulse * 0.65)
					* CFrame.Angles(-0.22 - attackPulse * 0.45 + idleSway, 0, -0.08)
				rig.primary:PivotTo(staffCf)
			elseif wantedId == "SoulflameLantern" then
				-- Swings like a pendulum censer from the warden's outstretched hand
				local pendulumZ = math.sin(serverNow * 4.2) * (0.18 + moveFactor * 0.22)
				local pendulumX = math.cos(serverNow * 3.6) * 0.15 - attackPulse * 0.42
				local lanternCf = rootCf
					* CFrame.new(1.5, 0.45 + walkBob, -0.95)
					* CFrame.Angles(pendulumX, 0, pendulumZ)
				rig.primary:PivotTo(lanternCf)
			elseif wantedId == "StormcallerTome" then
				-- Levitates and orbits gently in front-left of the battle-mage
				local hoverY = 0.65 + math.sin(serverNow * 3.8) * 0.32 + attackPulse * 0.45
				local tomeCf = rootCf
					* CFrame.new(-1.55, hoverY, -1.15)
					* CFrame.Angles(0.25 + attackPulse * 0.35, math.sin(serverNow * 2.1) * 0.28, idleSway)
				rig.primary:PivotTo(tomeCf)
			end
		end
	end

	local function onRenderStep(dt: number)
		-- Game time, not raw server time: it stops during level-up pauses, freezing everything drawn from it.
		local serverNow = GameClock.now()
		local renderTime = serverNow - Constants.RENDER_DELAY

		while pendingBolts[1] and pendingBolts[1].t0 <= renderTime do
			spawnBolt(table.remove(pendingBolts, 1) :: Types.BoltRecord)
		end
		while pendingEvents[1] and pendingEvents[1].t <= renderTime do
			applyEvent(table.remove(pendingEvents, 1) :: Types.WorldEventsPayload, serverNow)
		end
		for id, expiresAt in tombstones do
			if serverNow > expiresAt then
				tombstones[id] = nil
			end
		end
		for id, expiresAt in cancelledBolts do
			if serverNow > expiresAt then
				cancelledBolts[id] = nil
			end
		end

		updateEnemies(renderTime, dt)
		updateBolts(renderTime)
		updateOrbs(serverNow)
		updateBones(serverNow)
		updateConsecrated(serverNow)
		updatePlayerWeapons(serverNow)
		updateDamageNumbers(dt)
	end

	snapshotEvent.OnClientEvent:Connect(onSnapshot)
	worldEvents.OnClientEvent:Connect(function(payload: Types.WorldEventsPayload)
		if payload.clear then
			-- Unreliable packets can arrive late: refuse any snapshot older than the reset immediately.
			clearedBefore = math.max(clearedBefore, payload.t)
		end
		table.insert(pendingEvents, payload)
	end)
	boltsFired.OnClientEvent:Connect(function(records: { Types.BoltRecord })
		for _, record in records do
			table.insert(pendingBolts, record)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local orbs = orbSets[player]
		if orbs then
			for _, orb in orbs do
				orb:Destroy()
			end
			orbSets[player] = nil
		end
		local bones = boneSets[player]
		if bones then
			for _, bone in bones do
				bone:Destroy()
			end
			boneSets[player] = nil
		end
		local ring = consecratedRings[player]
		if ring then
			ring:Destroy()
			consecratedRings[player] = nil
		end
		local rig = weaponRigs[player]
		if rig then
			destroyWeaponRig(rig)
			weaponRigs[player] = nil
		end
	end)

	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 2, onRenderStep)
end

return WorldRenderer
