--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants") :: ModuleScript)

local LEGACY_BIND_NAME = "SurvivorCamera"
local CAMERA_OFFSET = Vector3.new(0, Constants.CAMERA_VERTICAL_OFFSET, 0)

local CameraController = {}

local function alignCameraBehindCharacter(character: Model, lookDirectionOverride: Vector3?)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end

	humanoid.CameraOffset = CAMERA_OFFSET
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = Constants.CAMERA_FIELD_OF_VIEW

	local rawLook = lookDirectionOverride or root.CFrame.LookVector
	local flatLook = Vector3.new(rawLook.X, 0, rawLook.Z)
	local forward = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.new(0, 0, -1)

	local pitch = math.rad(Constants.CAMERA_DEFAULT_PITCH_DEGREES)
	local distance = Constants.CAMERA_DEFAULT_DISTANCE
	local focusPos = root.Position + CAMERA_OFFSET
	local camPos = focusPos - forward * (distance * math.cos(pitch)) + Vector3.new(0, distance * math.sin(pitch), 0)

	camera.CFrame = CFrame.lookAt(camPos, focusPos + forward * 6)
	camera.Focus = CFrame.new(focusPos)
end

function CameraController.start()
	local player = Players.LocalPlayer
	pcall(function()
		RunService:UnbindFromRenderStep(LEGACY_BIND_NAME)
	end)

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = Constants.CAMERA_MIN_ZOOM
	player.CameraMaxZoomDistance = Constants.CAMERA_MAX_ZOOM

	local function onCharacterReady(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 5)
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if not humanoid or not root then
			return
		end
		local phase = player:GetAttribute("Phase")
		local lookDir = if phase == "Lobby" then Vector3.new(0, 0, 1) else nil
		task.defer(function()
			alignCameraBehindCharacter(character, lookDir)
		end)
	end

	player.CharacterAdded:Connect(onCharacterReady)
	if player.Character then
		task.spawn(onCharacterReady, player.Character)
	end

	-- Re-orient the 3rd-person camera behind the character when teleporting between Lobby and Arena
	local lastPhase = player:GetAttribute("Phase")
	player:GetAttributeChangedSignal("Phase"):Connect(function()
		local newPhase = player:GetAttribute("Phase")
		if newPhase == lastPhase then
			return
		end
		lastPhase = newPhase
		local character = player.Character
		if not character then
			return
		end
		if newPhase == "Lobby" then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and root.Position.Z > -(Constants.ARENA_HALF_SIZE + 25) then
				local targetPos = Constants.LOBBY_SPAWN + Vector3.new(0, 3, 0)
				root.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 0, 1)))
			end
			task.delay(0.05, function()
				alignCameraBehindCharacter(character, Vector3.new(0, 0, 1))
			end)
		elseif newPhase == "InRun" then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and root.Position.Z < -(Constants.ARENA_HALF_SIZE + 15) then
				local targetPos = Constants.ARENA_SPAWN + Vector3.new(0, 3, 0)
				root.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 0, -1)))
			end
			task.delay(0.05, function()
				alignCameraBehindCharacter(character, Vector3.new(0, 0, -1))
			end)
		end
	end)
end

return CameraController
