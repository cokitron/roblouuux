--!strict
local ServerStorage = game:GetService("ServerStorage")

local GraveyardBuildings = {}

-- PBR-aligned Palette (matches TextureCraft & SolidCraft materials)
local STONE_DARK = Color3.fromRGB(56, 60, 66)
local STONE_MID = Color3.fromRGB(74, 80, 86)
local STONE_LIGHT = Color3.fromRGB(98, 104, 112)
local STONE_MOSS = Color3.fromRGB(58, 72, 60)
local STONE_CREAM = Color3.fromRGB(118, 114, 106)
local COBBLE_DARK = Color3.fromRGB(52, 56, 60)
local IRON_DARK = Color3.fromRGB(34, 36, 40)
local IRON_RUST = Color3.fromRGB(48, 42, 38)
local BRONZE_ANTIQUE = Color3.fromRGB(148, 116, 68)
local WOOD_DARK = Color3.fromRGB(64, 48, 34)
local WOOD_WEATHERED = Color3.fromRGB(52, 42, 32)
local SOUL_CYAN = Color3.fromRGB(52, 215, 185)
local LANTERN_AMBER = Color3.fromRGB(255, 178, 72)
local TERRACOTTA = Color3.fromRGB(145, 78, 52)

type PartProps = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	shape: Enum.PartType?,
	transparency: number?,
	castShadow: boolean?,
}

type WedgeProps = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	transparency: number?,
	castShadow: boolean?,
}

local function makePart(props: PartProps): Part
	local part = Instance.new("Part")
	part.Name = props.name
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material
	part.Shape = props.shape or Enum.PartType.Block
	local isSolid = (props.transparency or 0) < 0.5
	part.Anchored = true
	part.CanCollide = isSolid
	part.CanTouch = false
	part.CanQuery = isSolid
	part.Transparency = props.transparency or 0
	part.CastShadow = if props.castShadow ~= nil then props.castShadow else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

local function makeWedge(props: WedgeProps): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = props.name
	wedge.Size = props.size
	wedge.CFrame = props.cframe
	wedge.Color = props.color
	wedge.Material = props.material
	local isSolid = (props.transparency or 0) < 0.5
	wedge.Anchored = true
	wedge.CanCollide = isSolid
	wedge.CanTouch = false
	wedge.CanQuery = isSolid
	wedge.Transparency = props.transparency or 0
	wedge.CastShadow = if props.castShadow ~= nil then props.castShadow else true
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Parent = props.parent
	return wedge
end

local function createPivotBase(model: Model, _size: Vector3): Part
	local root = makePart({
		name = "PivotRoot",
		size = Vector3.new(1, 0.05, 1),
		cframe = CFrame.new(0, 0, 0),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
		transparency = 1,
		castShadow = false,
	})
	model.PrimaryPart = root
	model.WorldPivot = CFrame.new(0, 0, 0)
	return root
end

-- =====================================================================
-- 1. Gothic Mausoleum (The Soul Crypt)
-- Footprint: 20 x 26 studs, Height: 20 studs
-- =====================================================================
function GraveyardBuildings.buildGothicMausoleum(): Model
	local model = Instance.new("Model")
	model.Name = "Gothic_Mausoleum"
	createPivotBase(model, Vector3.new(20, 20, 26))

	-- Plinth & Base Tiers
	makePart({
		name = "MossyBasePlinth",
		size = Vector3.new(20, 1.0, 26),
		cframe = CFrame.new(0, 0.5, 0),
		color = STONE_MOSS,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "UpperPlinthTier",
		size = Vector3.new(18.8, 0.6, 24.8),
		cframe = CFrame.new(0, 1.3, 0),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Main Ashlar Masonry Walls (18 x 24 footprint, height 10.5 from Y = 1.6 to 12.1)
	local wallH = 10.5
	local wallY = 1.6 + wallH * 0.5 -- 6.85
	-- Rear Wall (North / +Z)
	makePart({
		name = "RearWall",
		size = Vector3.new(18, wallH, 1.4),
		cframe = CFrame.new(0, wallY, 11.3),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Side Walls with Recessed Lancet Panels (West: -X, East: +X)
	for _, sx in ipairs({ -1, 1 }) do
		local xPos = sx * 8.3
		makePart({
			name = "SideWallMain",
			size = Vector3.new(1.4, wallH, 24),
			cframe = CFrame.new(xPos, wallY, 0),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
		})
		-- Recessed Lancet Niches along sides (Z = -4 and Z = +4)
		for _, nz in ipairs({ -4.5, 4.5 }) do
			makePart({
				name = "LancetNicheTrim",
				size = Vector3.new(0.3, 5.5, 2.2),
				cframe = CFrame.new(sx * 9.05, wallY, nz),
				color = STONE_DARK,
				material = Enum.Material.Slate,
				parent = model,
			})
			makePart({
				name = "LancetIronGrille",
				size = Vector3.new(0.1, 5.0, 1.8),
				cframe = CFrame.new(sx * 9.15, wallY, nz),
				color = IRON_DARK,
				material = Enum.Material.CorrodedMetal,
				parent = model,
			})
		end
	end

	-- Front Facade (South / -Z = -12) with Arched Portal Opening
	makePart({
		name = "FrontWallLeft",
		size = Vector3.new(5.6, wallH, 1.4),
		cframe = CFrame.new(-6.2, wallY, -11.3),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "FrontWallRight",
		size = Vector3.new(5.6, wallH, 1.4),
		cframe = CFrame.new(6.2, wallY, -11.3),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "PortalLintelOverhead",
		size = Vector3.new(6.8, 2.0, 1.6),
		cframe = CFrame.new(0, 11.1, -11.3),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Portal Flanking Pilasters / Columns
	for _, sx in ipairs({ -1, 1 }) do
		makePart({
			name = "PilasterShaft",
			size = Vector3.new(1.1, 9.8, 1.1),
			cframe = CFrame.new(sx * 3.7, 6.5, -12.1),
			color = STONE_LIGHT,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "PilasterCapital",
			size = Vector3.new(1.4, 0.6, 1.4),
			cframe = CFrame.new(sx * 3.7, 11.6, -12.1),
			color = STONE_CREAM,
			material = Enum.Material.Slate,
			parent = model,
		})
	end

	-- Crypt Double Doors (Heavy iron with studs and ring handles)
	for _, sx in ipairs({ -1, 1 }) do
		makePart({
			name = "CryptDoorLeaf",
			size = Vector3.new(2.9, 8.4, 0.4),
			cframe = CFrame.new(sx * 1.5, 5.8, -11.4),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		makePart({
			name = "IronDoorBandUpper",
			size = Vector3.new(2.95, 0.4, 0.48),
			cframe = CFrame.new(sx * 1.5, 8.2, -11.4),
			color = IRON_RUST,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		makePart({
			name = "IronDoorBandLower",
			size = Vector3.new(2.95, 0.4, 0.48),
			cframe = CFrame.new(sx * 1.5, 3.2, -11.4),
			color = IRON_RUST,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
	end
	-- Door Pull Rings
	makePart({
		name = "DoorRingLeft",
		size = Vector3.new(0.4, 0.4, 0.2),
		cframe = CFrame.new(-0.7, 5.8, -11.7),
		color = BRONZE_ANTIQUE,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})
	makePart({
		name = "DoorRingRight",
		size = Vector3.new(0.4, 0.4, 0.2),
		cframe = CFrame.new(0.7, 5.8, -11.7),
		color = BRONZE_ANTIQUE,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})
	-- Eerie Soulfire Seam Glow underneath doors
	local doorGlow = makePart({
		name = "DoorSoulSeam",
		size = Vector3.new(5.8, 0.2, 0.8),
		cframe = CFrame.new(0, 1.7, -11.4),
		color = SOUL_CYAN,
		material = Enum.Material.Neon,
		parent = model,
		transparency = 0.3,
		castShadow = false,
	})
	local cryptLight = Instance.new("PointLight")
	cryptLight.Name = "SoulSeamLight"
	cryptLight.Color = SOUL_CYAN
	cryptLight.Range = 12
	cryptLight.Brightness = 1.2
	cryptLight.Shadows = true
	cryptLight.Parent = doorGlow

	-- Entablature / Cornice Moldings (Jutting perimeter band at roofline)
	makePart({
		name = "CorniceBand",
		size = Vector3.new(19.4, 1.0, 25.4),
		cframe = CFrame.new(0, 12.6, 0),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "CorniceUpperLedge",
		size = Vector3.new(19.8, 0.4, 25.8),
		cframe = CFrame.new(0, 13.2, 0),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Triangular Gables (Front & Back Pediments)
	for _, sz in ipairs({ -1, 1 }) do
		local zPos = sz * 12.0
		-- Pediment tympanum center
		makePart({
			name = "PedimentTympanum",
			size = Vector3.new(13.0, 4.0, 1.2),
			cframe = CFrame.new(0, 15.2, zPos),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
		})
	end
	-- Front Tympanum Carved Cross Plaque
	makePart({
		name = "TympanumCrossV",
		size = Vector3.new(0.6, 2.4, 0.2),
		cframe = CFrame.new(0, 15.4, -12.65),
		color = STONE_CREAM,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "TympanumCrossH",
		size = Vector3.new(1.6, 0.5, 0.2),
		cframe = CFrame.new(0, 15.8, -12.65),
		color = STONE_CREAM,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Pitched Slate Roof (Slopes down to left and right)
	-- Ridge runs along Z from Z = -13 to +13 at Y = 18.2
	-- Left Roof Slope (-X)
	local roofW = 9.8
	local roofH = 5.2
	local roofLen = 26.2
	makeWedge({
		name = "RoofSlopeLeft",
		size = Vector3.new(roofLen, roofH, roofW),
		cframe = CFrame.new(-roofW * 0.5, 13.4 + roofH * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Right Roof Slope (+X)
	makeWedge({
		name = "RoofSlopeRight",
		size = Vector3.new(roofLen, roofH, roofW),
		cframe = CFrame.new(roofW * 0.5, 13.4 + roofH * 0.5, 0)
			* CFrame.Angles(0, -math.pi * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Roof Ridge Cap
	makePart({
		name = "RoofRidgeCap",
		size = Vector3.new(1.4, 0.8, 26.4),
		cframe = CFrame.new(0, 18.8, 0),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Apex Gothic Cross Finials (Front & Rear)
	for _, sz in ipairs({ -1, 1 }) do
		local zPos = sz * 12.8
		makePart({
			name = "RoofFinialBase",
			size = Vector3.new(0.8, 0.8, 0.8),
			cframe = CFrame.new(0, 19.4, zPos),
			color = STONE_LIGHT,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "RoofCrossShaft",
			size = Vector3.new(0.24, 2.0, 0.24),
			cframe = CFrame.new(0, 20.6, zPos),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		makePart({
			name = "RoofCrossArm",
			size = Vector3.new(1.2, 0.24, 0.24),
			cframe = CFrame.new(0, 21.0, zPos),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
	end

	return model
end

-- =====================================================================
-- 2. Catacomb Descent Portal (The Ossuary Arch)
-- Footprint: 16 x 18 studs, Height: 14 studs
-- =====================================================================
function GraveyardBuildings.buildCatacombDescentPortal(): Model
	local model = Instance.new("Model")
	model.Name = "Catacomb_Descent_Portal"
	createPivotBase(model, Vector3.new(16, 14, 18))

	-- Massive Stone Masonry Retaining Walls
	-- Central Portal Opening: 7.2 studs wide x 9.8 studs high, cutting from Z = -2 to Z = +2
	-- Left Retaining Wall Pier
	makePart({
		name = "LeftRetainingPier",
		size = Vector3.new(4.4, 11.5, 4.4),
		cframe = CFrame.new(-5.8, 5.75, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	-- Right Retaining Wall Pier
	makePart({
		name = "RightRetainingPier",
		size = Vector3.new(4.4, 11.5, 4.4),
		cframe = CFrame.new(5.8, 5.75, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	-- Flanking Wing Buttresses extending to the sides
	makePart({
		name = "LeftWingWall",
		size = Vector3.new(3.6, 9.5, 3.6),
		cframe = CFrame.new(-9.8, 4.75, 0.4),
		color = STONE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "RightWingWall",
		size = Vector3.new(3.6, 9.5, 3.6),
		cframe = CFrame.new(9.8, 4.75, 0.4),
		color = STONE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})

	-- Arched Portal Archivolt & Keystone
	makePart({
		name = "ArchLintelBeam",
		size = Vector3.new(8.0, 2.2, 4.8),
		cframe = CFrame.new(0, 10.8, 0),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Prominent Carved Keystone
	makePart({
		name = "ArchKeystone",
		size = Vector3.new(1.6, 2.6, 5.2),
		cframe = CFrame.new(0, 10.9, 0),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Ossuary Frieze / Relief Trim Band
	makePart({
		name = "OssuaryCorniceBand",
		size = Vector3.new(16.4, 1.0, 5.0),
		cframe = CFrame.new(0, 12.3, 0),
		color = STONE_CREAM,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "WallCrestCap",
		size = Vector3.new(16.8, 0.6, 5.4),
		cframe = CFrame.new(0, 13.0, 0),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Descending Catacomb Stairs (5 wide stepping tiers leading down into the subterranean abyss)
	local numSteps = 5
	local stepDepth = 2.4
	local stepRise = 0.55
	for i = 1, numSteps do
		local z = -2.5 + (i - 1) * stepDepth
		local y = 2.8 - (i - 1) * stepRise
		makePart({
			name = "DescentStep_" .. i,
			size = Vector3.new(7.0, stepRise, stepDepth + 0.1),
			cframe = CFrame.new(0, y - stepRise * 0.5, z),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
	end

	-- Subterranean Tunnel Vault Ceiling (behind the arch)
	makePart({
		name = "TunnelVaultCeiling",
		size = Vector3.new(7.4, 1.4, 8.0),
		cframe = CFrame.new(0, 9.4, 4.2),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Heavy Spiked Iron Portcullis (hanging partially lowered in archway)
	local portcullisH = 6.2
	local portcullisY = 6.8
	-- Horizontal Iron Bars
	for _, barY in ipairs({ portcullisY - 2.2, portcullisY, portcullisY + 2.2 }) do
		makePart({
			name = "PortcullisCrossbar",
			size = Vector3.new(6.8, 0.28, 0.28),
			cframe = CFrame.new(0, barY, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
	end
	-- Vertical Spiked Pickles
	for i = -3, 3 do
		local px = i * 0.95
		makePart({
			name = "PortcullisSpikeBar",
			size = Vector3.new(0.24, portcullisH, 0.24),
			cframe = CFrame.new(px, portcullisY, 0),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
		-- Bottom Spike Tip
		makePart({
			name = "PortcullisSpikeTip",
			size = Vector3.new(0.32, 0.45, 0.32),
			cframe = CFrame.new(px, portcullisY - portcullisH * 0.5 - 0.2, 0) * CFrame.Angles(0, math.pi * 0.25, 0),
			color = IRON_RUST,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
	end

	-- Twin Pedestals with Soulfire Braziers flanking the entrance
	for _, sx in ipairs({ -1, 1 }) do
		local px = sx * 5.8
		local pz = -3.2
		-- Stepped Pedestal Base
		makePart({
			name = "BrazierPedestalBase",
			size = Vector3.new(2.4, 0.6, 2.4),
			cframe = CFrame.new(px, 0.3, pz),
			color = STONE_MOSS,
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		makePart({
			name = "BrazierPedestalShaft",
			size = Vector3.new(1.8, 2.6, 1.8),
			cframe = CFrame.new(px, 1.9, pz),
			color = STONE_DARK,
			material = Enum.Material.Slate,
			parent = model,
		})
		makePart({
			name = "BrazierPedestalCap",
			size = Vector3.new(2.2, 0.4, 2.2),
			cframe = CFrame.new(px, 3.4, pz),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
		})
		-- Cast Iron Brazier Bowl
		makePart({
			name = "BrazierBowl",
			size = Vector3.new(1.8, 0.8, 1.8),
			cframe = CFrame.new(px, 4.0, pz),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			shape = Enum.PartType.Cylinder,
			parent = model,
		})
		-- Soulfire Glowing Coals (Neon Cyan with PointLight)
		local soulFlame = makePart({
			name = "SoulfireEmbers",
			size = Vector3.new(1.4, 0.6, 1.4),
			cframe = CFrame.new(px, 4.5, pz),
			color = SOUL_CYAN,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = model,
			castShadow = false,
		})
		local flameLight = Instance.new("PointLight")
		flameLight.Name = "SoulBrazierLight"
		flameLight.Color = SOUL_CYAN
		flameLight.Range = 16
		flameLight.Brightness = 2.0
		flameLight.Shadows = true
		flameLight.Parent = soulFlame
	end

	return model
end

-- =====================================================================
-- 3. Mortuary Chapel & Ruined Belfry
-- Footprint: 22 x 32 studs, Height: 32 studs
-- =====================================================================
function GraveyardBuildings.buildMortuaryChapel(): Model
	local model = Instance.new("Model")
	model.Name = "Mortuary_Chapel"
	createPivotBase(model, Vector3.new(22, 32, 32))

	-- Heavy Masonry Plinth Foundation
	makePart({
		name = "ChapelFoundationPlinth",
		size = Vector3.new(20, 1.2, 30),
		cframe = CFrame.new(0, 0.6, 2),
		color = STONE_MOSS,
		material = Enum.Material.Cobblestone,
		parent = model,
	})

	-- Nave Walls (Footprint: 17 x 24, Height: 12 studs from Y = 1.2 to 13.2)
	local naveH = 12.0
	local naveY = 1.2 + naveH * 0.5 -- 7.2
	local naveZ = 4.0 -- centered slightly back to leave room for western entrance tower
	-- East Chancel Wall (+Z)
	makePart({
		name = "ChancelWall",
		size = Vector3.new(17, naveH, 1.4),
		cframe = CFrame.new(0, naveY, naveZ + 11.3),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- North & South Flanking Nave Walls (-X and +X)
	for _, sx in ipairs({ -1, 1 }) do
		local xPos = sx * 7.8
		makePart({
			name = "NaveSideWall",
			size = Vector3.new(1.4, naveH, 22.6),
			cframe = CFrame.new(xPos, naveY, naveZ),
			color = STONE_MID,
			material = Enum.Material.Slate,
			parent = model,
		})
		-- 3 Stepped Exterior Buttresses per side (Z = naveZ - 6, naveZ, naveZ + 6)
		for _, bz in ipairs({ naveZ - 7, naveZ, naveZ + 7 }) do
			makePart({
				name = "ButtressLower",
				size = Vector3.new(1.8, 6.0, 1.8),
				cframe = CFrame.new(sx * 9.0, 4.2, bz),
				color = STONE_DARK,
				material = Enum.Material.Cobblestone,
				parent = model,
			})
			makePart({
				name = "ButtressUpper",
				size = Vector3.new(1.3, 5.5, 1.4),
				cframe = CFrame.new(sx * 8.8, 9.8, bz),
				color = STONE_MID,
				material = Enum.Material.Slate,
				parent = model,
			})
		end
		-- Gothic Lancet Windows on Nave sides
		for _, wz in ipairs({ naveZ - 3.5, naveZ + 3.5 }) do
			makePart({
				name = "ChapelLancetWindow",
				size = Vector3.new(0.2, 5.0, 1.8),
				cframe = CFrame.new(sx * 8.55, naveY + 0.5, wz),
				color = IRON_DARK,
				material = Enum.Material.CorrodedMetal,
				parent = model,
			})
		end
	end

	-- Nave Pitched Slate Roof (Slopes down to left and right)
	local roofH = 5.5
	local roofW = 9.2
	local roofLen = 23.2
	makeWedge({
		name = "ChapelRoofSlopeLeft",
		size = Vector3.new(roofLen, roofH, roofW),
		cframe = CFrame.new(-roofW * 0.5, 13.2 + roofH * 0.5, naveZ)
			* CFrame.Angles(0, math.pi * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makeWedge({
		name = "ChapelRoofSlopeRight",
		size = Vector3.new(roofLen, roofH, roofW),
		cframe = CFrame.new(roofW * 0.5, 13.2 + roofH * 0.5, naveZ)
			* CFrame.Angles(0, -math.pi * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Exposed Weathered Wooden Roof Rafters (Ruined gothic effect)
	for i = -2, 2 do
		makePart({
			name = "WeatheredRafterBeam",
			size = Vector3.new(16.0, 0.6, 0.6),
			cframe = CFrame.new(0, 14.8, naveZ + i * 4.2),
			color = WOOD_DARK,
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
	end

	-- Western Belfry Tower (8.5 x 8.5 studs, rising to Y = 22, Spire up to Y = 31)
	local towerZ = -8.5
	-- Tower Lower Base & Portal Frame
	makePart({
		name = "TowerBasePiers",
		size = Vector3.new(8.5, 13.2, 8.5),
		cframe = CFrame.new(0, 7.8, towerZ),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Gothic Arched Entrance Door (Oak with iron straps)
	makePart({
		name = "EntrancePortalDoor",
		size = Vector3.new(3.8, 8.0, 0.4),
		cframe = CFrame.new(0, 5.2, towerZ - 4.3),
		color = WOOD_WEATHERED,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	makePart({
		name = "EntrancePortalArchTrim",
		size = Vector3.new(4.8, 1.6, 0.8),
		cframe = CFrame.new(0, 9.6, towerZ - 4.3),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Belfry Chamber (Y = 14.4 to 21.0) with open arched sound louvers
	makePart({
		name = "BelfryPlatformFloor",
		size = Vector3.new(9.2, 0.8, 9.2),
		cframe = CFrame.new(0, 14.8, towerZ),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- 4 Corner Belfry Pillars
	for _, tx in ipairs({ -3.8, 3.8 }) do
		for _, tz in ipairs({ -3.8, 3.8 }) do
			makePart({
				name = "BelfryCornerPillar",
				size = Vector3.new(1.2, 6.2, 1.2),
				cframe = CFrame.new(tx, 18.2, towerZ + tz),
				color = STONE_LIGHT,
				material = Enum.Material.Slate,
				parent = model,
			})
		end
	end
	-- Belfry Cornice Cap
	makePart({
		name = "BelfryCorniceCap",
		size = Vector3.new(9.4, 1.0, 9.4),
		cframe = CFrame.new(0, 21.8, towerZ),
		color = STONE_MID,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Suspended Bronze Funeral Bell
	-- Bell Oak Crossbeam
	makePart({
		name = "BellYokeBeam",
		size = Vector3.new(6.8, 0.8, 0.8),
		cframe = CFrame.new(0, 19.8, towerZ),
		color = WOOD_DARK,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	-- Cast Bronze Bell
	makePart({
		name = "BronzeBellBody",
		size = Vector3.new(2.4, 2.6, 2.4),
		cframe = CFrame.new(0, 17.6, towerZ),
		color = BRONZE_ANTIQUE,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})
	makePart({
		name = "BronzeBellRim",
		size = Vector3.new(2.8, 0.5, 2.8),
		cframe = CFrame.new(0, 16.4, towerZ),
		color = BRONZE_ANTIQUE,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})

	-- Belfry Pyramidal Spire Roof (Y = 22.3 to 29.5)
	local spireH = 7.5
	local spireW = 4.4
	makeWedge({
		name = "SpireSlopeNorth",
		size = Vector3.new(8.8, spireH, spireW),
		cframe = CFrame.new(0, 22.3 + spireH * 0.5, towerZ + spireW * 0.5) * CFrame.Angles(0, 0, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makeWedge({
		name = "SpireSlopeSouth",
		size = Vector3.new(8.8, spireH, spireW),
		cframe = CFrame.new(0, 22.3 + spireH * 0.5, towerZ - spireW * 0.5) * CFrame.Angles(0, math.pi, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Spire Apex Crown & Iron Gothic Cross
	makePart({
		name = "SpireApexCap",
		size = Vector3.new(1.2, 0.8, 1.2),
		cframe = CFrame.new(0, 30.2, towerZ),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})
	makePart({
		name = "SpireIronCrossV",
		size = Vector3.new(0.28, 2.4, 0.28),
		cframe = CFrame.new(0, 31.6, towerZ),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	makePart({
		name = "SpireIronCrossH",
		size = Vector3.new(1.4, 0.28, 0.28),
		cframe = CFrame.new(0, 32.1, towerZ),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})

	return model
end

-- =====================================================================
-- 4. Caretaker's Gatehouse Lodge (The Cryptkeeper's Quarters)
-- Footprint: 20 x 18 studs, Height: 15 studs
-- =====================================================================
function GraveyardBuildings.buildCaretakerLodge(): Model
	local model = Instance.new("Model")
	model.Name = "Caretaker_Lodge"
	createPivotBase(model, Vector3.new(20, 15, 18))

	-- Cobblestone Ground Foundation Plinth
	makePart({
		name = "LodgeFoundationPlinth",
		size = Vector3.new(18, 1.0, 16),
		cframe = CFrame.new(-0.5, 0.5, 0),
		color = STONE_MOSS,
		material = Enum.Material.Cobblestone,
		parent = model,
	})

	-- Rough Fieldstone Walls (16 x 14 footprint, Height: 8.5 studs from Y = 1.0 to 9.5)
	local lodgeH = 8.5
	local lodgeY = 1.0 + lodgeH * 0.5 -- 5.25
	-- Rear Wall (+Z)
	makePart({
		name = "LodgeRearWall",
		size = Vector3.new(16, lodgeH, 1.4),
		cframe = CFrame.new(-0.5, lodgeY, 6.3),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	-- Left Wall (-X)
	makePart({
		name = "LodgeLeftWall",
		size = Vector3.new(1.4, lodgeH, 14),
		cframe = CFrame.new(-7.8, lodgeY, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	-- Right Wall (+X)
	makePart({
		name = "LodgeRightWall",
		size = Vector3.new(1.4, lodgeH, 14),
		cframe = CFrame.new(6.8, lodgeY, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	-- Front Facade (-Z) with Door & Service Window openings
	makePart({
		name = "LodgeFrontWallLeft",
		size = Vector3.new(4.2, lodgeH, 1.4),
		cframe = CFrame.new(-6.4, lodgeY, -6.3),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "LodgeFrontWallCenter",
		size = Vector3.new(4.0, lodgeH, 1.4),
		cframe = CFrame.new(0.5, lodgeY, -6.3),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "LodgeFrontWallRight",
		size = Vector3.new(3.8, lodgeH, 1.4),
		cframe = CFrame.new(5.6, lodgeY, -6.3),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "LodgeDoorLintel",
		size = Vector3.new(3.6, 1.8, 1.6),
		cframe = CFrame.new(-2.6, 8.6, -6.3),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Sturdy Timber Batten Service Door
	makePart({
		name = "LodgeWoodDoor",
		size = Vector3.new(3.2, 7.2, 0.4),
		cframe = CFrame.new(-2.6, 4.6, -6.4),
		color = WOOD_WEATHERED,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	-- Black Iron Door Hinges
	for _, hy in ipairs({ 3.0, 6.2 }) do
		makePart({
			name = "DoorIronStrapHinge",
			size = Vector3.new(2.4, 0.3, 0.48),
			cframe = CFrame.new(-2.8, hy, -6.45),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
	end

	-- Barred Service Window (Between Center & Right wall)
	makePart({
		name = "WindowStoneSill",
		size = Vector3.new(2.8, 0.4, 1.6),
		cframe = CFrame.new(3.2, 3.2, -6.3),
		color = STONE_LIGHT,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Iron Security Bars on Window
	for i = -1, 1 do
		makePart({
			name = "WindowIronBarV",
			size = Vector3.new(0.14, 2.6, 0.14),
			cframe = CFrame.new(3.2 + i * 0.7, 4.7, -6.3),
			color = IRON_DARK,
			material = Enum.Material.CorrodedMetal,
			parent = model,
		})
	end
	makePart({
		name = "WindowIronBarH",
		size = Vector3.new(2.4, 0.14, 0.14),
		cframe = CFrame.new(3.2, 4.7, -6.3),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})

	-- Timber Porch & Awning Over Service Door
	-- Heavy Gnarled Wooden Posts
	for _, px in ipairs({ -4.4, -0.8 }) do
		makePart({
			name = "PorchTimberPost",
			size = Vector3.new(0.7, 7.8, 0.7),
			cframe = CFrame.new(px, 4.9, -9.6),
			color = WOOD_DARK,
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
	end
	-- Overhead Timber Crossbeam
	makePart({
		name = "PorchHeaderBeam",
		size = Vector3.new(4.4, 0.6, 0.6),
		cframe = CFrame.new(-2.6, 8.5, -9.6),
		color = WOOD_DARK,
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	-- Sloping Timber Awning Shingles
	makePart({
		name = "PorchRoofAwning",
		size = Vector3.new(5.0, 0.4, 3.6),
		cframe = CFrame.new(-2.6, 9.0, -8.1) * CFrame.Angles(-math.rad(18), 0, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Hanging Wrought Iron Crypt Lantern
	makePart({
		name = "LanternWallBracket",
		size = Vector3.new(0.2, 0.8, 1.2),
		cframe = CFrame.new(-0.7, 6.8, -7.0),
		color = IRON_DARK,
		material = Enum.Material.CorrodedMetal,
		parent = model,
	})
	local lanternBulb = makePart({
		name = "LanternGlassBulb",
		size = Vector3.new(0.7, 0.9, 0.7),
		cframe = CFrame.new(-0.7, 6.0, -7.5),
		color = LANTERN_AMBER,
		material = Enum.Material.Neon,
		parent = model,
		castShadow = false,
	})
	local lanternLight = Instance.new("PointLight")
	lanternLight.Name = "LodgeLanternLight"
	lanternLight.Color = LANTERN_AMBER
	lanternLight.Range = 14
	lanternLight.Brightness = 1.8
	lanternLight.Shadows = true
	lanternLight.Parent = lanternBulb

	-- Heavy Fieldstone Chimney on East Flank (X = +8)
	makePart({
		name = "ChimneyLowerBreast",
		size = Vector3.new(3.8, 9.5, 4.4),
		cframe = CFrame.new(8.2, 5.75, 1.0),
		color = COBBLE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	makePart({
		name = "ChimneyUpperStack",
		size = Vector3.new(2.8, 5.5, 3.2),
		cframe = CFrame.new(8.2, 12.8, 1.0),
		color = STONE_DARK,
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	-- Terracotta Chimney Pot
	makePart({
		name = "TerracottaChimneyPot",
		size = Vector3.new(1.2, 1.6, 1.2),
		cframe = CFrame.new(8.2, 16.1, 1.0),
		color = TERRACOTTA,
		material = Enum.Material.Slate,
		shape = Enum.PartType.Cylinder,
		parent = model,
	})

	-- High Pitch Slate Gable Roof (Slopes down to West & East)
	local roofH = 5.2
	local roofW = 8.8
	local roofLen = 16.4
	makeWedge({
		name = "LodgeRoofSlopeLeft",
		size = Vector3.new(roofLen, roofH, roofW),
		cframe = CFrame.new(-0.5 - roofW * 0.5, 9.5 + roofH * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	makeWedge({
		name = "LodgeRoofSlopeRight",
		size = Vector3.new(roofLen, roofH, roofW),
		cframe = CFrame.new(-0.5 + roofW * 0.5, 9.5 + roofH * 0.5, 0)
			* CFrame.Angles(0, -math.pi * 0.5, 0)
			* CFrame.Angles(0, math.pi * 0.5, 0),
		color = COBBLE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})
	-- Roof Ridge Cap
	makePart({
		name = "LodgeRoofRidgeCap",
		size = Vector3.new(1.2, 0.6, 16.6),
		cframe = CFrame.new(-0.5, 14.8, 0),
		color = STONE_DARK,
		material = Enum.Material.Slate,
		parent = model,
	})

	return model
end

-- =====================================================================
-- Build All and Sync to ServerStorage.GraveyardBuildings
-- =====================================================================
function GraveyardBuildings.buildAll(): { [string]: Model }
	return {
		Gothic_Mausoleum = GraveyardBuildings.buildGothicMausoleum(),
		Catacomb_Descent_Portal = GraveyardBuildings.buildCatacombDescentPortal(),
		Mortuary_Chapel = GraveyardBuildings.buildMortuaryChapel(),
		Caretaker_Lodge = GraveyardBuildings.buildCaretakerLodge(),
	}
end

function GraveyardBuildings.syncToServerStorage(): Folder
	local targetFolder = ServerStorage:FindFirstChild("GraveyardBuildings")
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = "GraveyardBuildings"
		targetFolder.Parent = ServerStorage
	end

	local prefabs = GraveyardBuildings.buildAll()
	for name, model in pairs(prefabs) do
		local existing = targetFolder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		model.Parent = targetFolder
	end

	return targetFolder
end

return GraveyardBuildings
