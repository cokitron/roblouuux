--!strict
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

export type TrackDef = {
	title: string,
	localAsset: string,
	cloudAssetId: string,
}

-- The 5 Synthwave-Drift Graveyard Soundtrack songs from G:\Mi unidad\Beats\Syntwave-drift
-- `localAsset` plays immediately inside Roblox Studio from `content/music/`.
-- `cloudAssetId` can optionally be filled with `rbxassetid://<ID>` after uploading to Creator Hub.
local GRAVEYARD_PLAYLIST: { TrackDef } = {
	{
		title = "Synthwave Drift I (Untitled)",
		localAsset = "rbxasset://music/graveyard_1_untitled_1.mp3",
		cloudAssetId = "",
	},
	{
		title = "Synthwave Drift II (Untitled 1)",
		localAsset = "rbxasset://music/graveyard_2_untitled_2.mp3",
		cloudAssetId = "",
	},
	{
		title = "Tres — Crypt Night Drive",
		localAsset = "rbxasset://music/graveyard_3_tres.mp3",
		cloudAssetId = "",
	},
	{
		title = "Cuatro — Neon Graveyard",
		localAsset = "rbxasset://music/graveyard_4_cuatro.mp3",
		cloudAssetId = "",
	},
	{
		title = "Coastal Cruise — Blood Moon",
		localAsset = "rbxasset://music/graveyard_5_coastal_cruise.wav",
		cloudAssetId = "",
	},
}

local BASE_VOLUME = 0.44
local BOSS_VOLUME = 0.58
local FADE_INFO = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MusicController = {}

local function resolveSoundId(track: TrackDef): string
	if track.cloudAssetId ~= "" then
		return track.cloudAssetId
	end
	return track.localAsset
end

function MusicController.mount(playerGui: PlayerGui)
	local player = Players.LocalPlayer

	local musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "GraveyardMusicGroup"
	musicGroup.Volume = 1.0
	musicGroup.Parent = SoundService

	local activeSound = Instance.new("Sound")
	activeSound.Name = "GraveyardSynthwaveTrack"
	activeSound.SoundGroup = musicGroup
	activeSound.Looped = false
	activeSound.Volume = 0
	activeSound.RollOffMode = Enum.RollOffMode.InverseTapered
	activeSound.Parent = musicGroup

	-- Preload the 5 tracks asynchronously so track transitions have zero latency
	task.spawn(function()
		local preloadSounds: { Instance } = {}
		for _, track in ipairs(GRAVEYARD_PLAYLIST) do
			local s = Instance.new("Sound")
			s.SoundId = resolveSoundId(track)
			table.insert(preloadSounds, s)
		end
		pcall(function()
			ContentProvider:PreloadAsync(preloadSounds)
		end)
		for _, s in ipairs(preloadSounds) do
			s:Destroy()
		end
	end)

	local currentTrackIndex = 1
	local isMuted = false
	local isInGraveyard = false
	local activeTween: Tween? = nil

	-- Sleek Bottom-Left Synthwave Radio HUD Pill (visible while playing in the Graveyard)
	local gui = Instance.new("ScreenGui")
	gui.Name = "GraveyardMusicGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 2
	gui.Parent = playerGui

	local pill = Instance.new("Frame")
	pill.Name = "SynthwaveRadioPill"
	pill.AnchorPoint = Vector2.new(0, 1)
	pill.Position = UDim2.new(0, 14, 1, -16)
	pill.Size = UDim2.fromOffset(310, 38)
	pill.BackgroundColor3 = Color3.fromRGB(20, 14, 38)
	pill.BackgroundTransparency = 0.08
	pill.BorderSizePixel = 0
	pill.Visible = false
	pill.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = pill

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(235, 95, 255)
	stroke.Thickness = 1.8
	stroke.Parent = pill

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 18, 86)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 42, 88)),
	})
	grad.Rotation = 15
	grad.Parent = pill

	local trackLabel = Instance.new("TextLabel")
	trackLabel.Name = "TrackLabel"
	trackLabel.Position = UDim2.fromOffset(10, 0)
	trackLabel.Size = UDim2.new(1, -92, 1, 0)
	trackLabel.BackgroundTransparency = 1
	trackLabel.Font = Enum.Font.GothamBlack
	trackLabel.TextSize = 11
	trackLabel.TextXAlignment = Enum.TextXAlignment.Left
	trackLabel.TextTruncate = Enum.TextTruncate.AtEnd
	trackLabel.TextColor3 = Color3.fromRGB(125, 245, 255)
	trackLabel.TextStrokeColor3 = Color3.fromRGB(8, 5, 18)
	trackLabel.TextStrokeTransparency = 0.15
	trackLabel.Text = "🎵 1/5: Synthwave Drift I"
	trackLabel.Parent = pill

	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "NextTrackBtn"
	nextBtn.AnchorPoint = Vector2.new(1, 0.5)
	nextBtn.Position = UDim2.new(1, -44, 0.5, 0)
	nextBtn.Size = UDim2.fromOffset(34, 26)
	nextBtn.BackgroundColor3 = Color3.fromRGB(88, 32, 145)
	nextBtn.BorderSizePixel = 0
	nextBtn.AutoButtonColor = true
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 11
	nextBtn.TextColor3 = Color3.new(1, 1, 1)
	nextBtn.Text = "⏭️"
	nextBtn.Parent = pill

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, 6)
	nextCorner.Parent = nextBtn

	local muteBtn = Instance.new("TextButton")
	muteBtn.Name = "MuteBtn"
	muteBtn.AnchorPoint = Vector2.new(1, 0.5)
	muteBtn.Position = UDim2.new(1, -6, 0.5, 0)
	muteBtn.Size = UDim2.fromOffset(34, 26)
	muteBtn.BackgroundColor3 = Color3.fromRGB(28, 76, 118)
	muteBtn.BorderSizePixel = 0
	muteBtn.AutoButtonColor = true
	muteBtn.Font = Enum.Font.GothamBlack
	muteBtn.TextSize = 11
	muteBtn.TextColor3 = Color3.new(1, 1, 1)
	muteBtn.Text = "🔊"
	muteBtn.Parent = pill

	local muteCorner = Instance.new("UICorner")
	muteCorner.CornerRadius = UDim.new(0, 6)
	muteCorner.Parent = muteBtn

	local function getTargetVolume(): number
		if isMuted or not isInGraveyard then
			return 0
		end
		local bossName = Workspace:GetAttribute("ActiveBossName")
		if typeof(bossName) == "string" and bossName ~= "" then
			return BOSS_VOLUME
		end
		return BASE_VOLUME
	end

	local function updateUi()
		local track = GRAVEYARD_PLAYLIST[currentTrackIndex]
		pill.Visible = isInGraveyard
		trackLabel.Text = string.format("🎵 %d/%d: %s [V]", currentTrackIndex, #GRAVEYARD_PLAYLIST, track.title)
		muteBtn.Text = if isMuted then "🔇" else "🔊"
		muteBtn.BackgroundColor3 = if isMuted then Color3.fromRGB(125, 28, 48) else Color3.fromRGB(28, 76, 118)
	end

	local function tweenVolume(targetVol: number)
		if activeTween then
			activeTween:Cancel()
		end
		local tw = TweenService:Create(activeSound, FADE_INFO, { Volume = targetVol })
		activeTween = tw
		tw:Play()
	end

	local function playTrack(index: number)
		currentTrackIndex = ((index - 1) % #GRAVEYARD_PLAYLIST) + 1
		local track = GRAVEYARD_PLAYLIST[currentTrackIndex]
		activeSound:Stop()
		activeSound.SoundId = resolveSoundId(track)
		activeSound.TimePosition = 0
		activeSound.Volume = 0
		if isInGraveyard then
			activeSound:Play()
			tweenVolume(getTargetVolume())
		end
		updateUi()
	end

	local function advanceTrack()
		playTrack(currentTrackIndex + 1)
	end

	activeSound.Ended:Connect(function()
		if isInGraveyard then
			advanceTrack()
		end
	end)

	nextBtn.Activated:Connect(function()
		if isInGraveyard then
			advanceTrack()
		end
	end)

	muteBtn.Activated:Connect(function()
		isMuted = not isMuted
		tweenVolume(getTargetVolume())
		updateUi()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.V and isInGraveyard then
			advanceTrack()
		end
	end)

	local function onPhaseChanged()
		local phase = player:GetAttribute("Phase")
		local shouldPlay = (phase == "InRun" or phase == "Downed")
		if shouldPlay and not isInGraveyard then
			isInGraveyard = true
			if not activeSound.IsPlaying then
				playTrack(currentTrackIndex)
			else
				tweenVolume(getTargetVolume())
				updateUi()
			end
		elseif not shouldPlay and isInGraveyard then
			isInGraveyard = false
			tweenVolume(0)
			task.delay(0.9, function()
				if not isInGraveyard then
					activeSound:Stop()
					-- Advance playlist index so the next run greets the player with the next Synthwave track
					currentTrackIndex = (currentTrackIndex % #GRAVEYARD_PLAYLIST) + 1
				end
			end)
			updateUi()
		end
	end

	player:GetAttributeChangedSignal("Phase"):Connect(onPhaseChanged)
	Workspace:GetAttributeChangedSignal("ActiveBossName"):Connect(function()
		if isInGraveyard then
			tweenVolume(getTargetVolume())
		end
	end)

	onPhaseChanged()
end

return MusicController
