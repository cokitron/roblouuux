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
		cloudAssetId = "rbxassetid://1837849285",
	},
	{
		title = "Synthwave Drift II (Untitled 1)",
		localAsset = "rbxasset://music/graveyard_2_untitled_2.mp3",
		cloudAssetId = "rbxassetid://1848354536",
	},
	{
		title = "Tres — Crypt Night Drive",
		localAsset = "rbxasset://music/graveyard_3_tres.mp3",
		cloudAssetId = "rbxassetid://1837849082",
	},
	{
		title = "Cuatro — Neon Graveyard",
		localAsset = "rbxasset://music/graveyard_4_cuatro.mp3",
		cloudAssetId = "rbxassetid://1843404009",
	},
	{
		title = "Coastal Cruise — Blood Moon",
		localAsset = "rbxasset://music/graveyard_5_coastal_cruise.wav",
		cloudAssetId = "rbxassetid://1845756489",
	},
}

local BASE_VOLUME = 0.44
local BOSS_VOLUME = 0.58
local CHAPEL_AMBIENCE_ID = "rbxassetid://9125602748" -- Heavenly Presence Eerie Choral Tones Dark Ru (SFX) - ProSoundEffects
local CHAPEL_VOLUME = 0.28
local FADE_INFO = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MusicController = {}

local function resolveSoundId(track: TrackDef): string
	if track.localAsset ~= "" then
		return track.localAsset
	end
	return track.cloudAssetId
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

	local chapelSound = Instance.new("Sound")
	chapelSound.Name = "SanctuaryChapelAmbience"
	chapelSound.SoundId = CHAPEL_AMBIENCE_ID
	chapelSound.SoundGroup = musicGroup
	chapelSound.Looped = true
	chapelSound.Volume = 0
	chapelSound.PlaybackSpeed = 0.96
	chapelSound.RollOffMode = Enum.RollOffMode.InverseTapered
	chapelSound.Parent = musicGroup

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
	local chapelTween: Tween? = nil

	-- Sleek Bottom-Left Synthwave Radio HUD Pill (visible while playing in the Graveyard)
	local gui = Instance.new("ScreenGui")
	gui.Name = "GraveyardMusicGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 2
	gui.Parent = playerGui

	local pill = Instance.new("Frame")
	pill.Name = "SynthwaveRadioPill"
	pill.AnchorPoint = Vector2.new(1, 1)
	pill.Position = UDim2.new(1, -12, 1, -8)
	pill.Size = UDim2.fromOffset(210, 26)
	pill.BackgroundColor3 = Color3.fromRGB(20, 14, 38)
	pill.BackgroundTransparency = 0.14
	pill.BorderSizePixel = 0
	pill.Visible = false
	pill.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = pill

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(235, 95, 255)
	stroke.Thickness = 1.4
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
	trackLabel.Position = UDim2.fromOffset(8, 0)
	trackLabel.Size = UDim2.new(1, -64, 1, 0)
	trackLabel.BackgroundTransparency = 1
	trackLabel.Font = Enum.Font.GothamBlack
	trackLabel.TextSize = 9
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
	nextBtn.Position = UDim2.new(1, -30, 0.5, 0)
	nextBtn.Size = UDim2.fromOffset(22, 18)
	nextBtn.BackgroundColor3 = Color3.fromRGB(88, 32, 145)
	nextBtn.BorderSizePixel = 0
	nextBtn.AutoButtonColor = true
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 9
	nextBtn.TextColor3 = Color3.new(1, 1, 1)
	nextBtn.Text = "⏭️"
	nextBtn.Parent = pill

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, 5)
	nextCorner.Parent = nextBtn

	local muteBtn = Instance.new("TextButton")
	muteBtn.Name = "MuteBtn"
	muteBtn.AnchorPoint = Vector2.new(1, 0.5)
	muteBtn.Position = UDim2.new(1, -5, 0.5, 0)
	muteBtn.Size = UDim2.fromOffset(22, 18)
	muteBtn.BackgroundColor3 = Color3.fromRGB(28, 76, 118)
	muteBtn.BorderSizePixel = 0
	muteBtn.AutoButtonColor = true
	muteBtn.Font = Enum.Font.GothamBlack
	muteBtn.TextSize = 9
	muteBtn.TextColor3 = Color3.new(1, 1, 1)
	muteBtn.Text = "🔊"
	muteBtn.Parent = pill

	local muteCorner = Instance.new("UICorner")
	muteCorner.CornerRadius = UDim.new(0, 5)
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

	local function tweenChapelVolume(targetVol: number)
		if chapelTween then
			chapelTween:Cancel()
		end
		local tw = TweenService:Create(chapelSound, FADE_INFO, { Volume = targetVol })
		chapelTween = tw
		tw:Play()
	end

	local function playTrack(index: number)
		currentTrackIndex = ((index - 1) % #GRAVEYARD_PLAYLIST) + 1
		local track = GRAVEYARD_PLAYLIST[currentTrackIndex]
		local requestedIdx = currentTrackIndex
		activeSound:Stop()
		activeSound.SoundId = resolveSoundId(track)
		activeSound.TimePosition = 0
		activeSound.Volume = 0
		if isInGraveyard then
			activeSound:Play()
			tweenVolume(getTargetVolume())
		end
		-- Cloud fallback: if local rbxasset://music/ file is unavailable (published server), switch to cloudAssetId
		if track.cloudAssetId ~= "" and activeSound.SoundId == track.localAsset then
			task.delay(1.2, function()
				if
					currentTrackIndex == requestedIdx
					and activeSound.SoundId == track.localAsset
					and not activeSound.IsLoaded
					and activeSound.TimeLength == 0
				then
					activeSound.SoundId = track.cloudAssetId
					if isInGraveyard then
						activeSound:Play()
						tweenVolume(getTargetVolume())
					end
				end
			end)
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
		tweenChapelVolume(if isMuted or isInGraveyard then 0 else CHAPEL_VOLUME)
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
			tweenChapelVolume(0)
			if not activeSound.IsPlaying then
				playTrack(currentTrackIndex)
			else
				tweenVolume(getTargetVolume())
				updateUi()
			end
		elseif not shouldPlay then
			if not chapelSound.IsPlaying then
				chapelSound:Play()
			end
			tweenChapelVolume(if isMuted then 0 else CHAPEL_VOLUME)
			if isInGraveyard then
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
