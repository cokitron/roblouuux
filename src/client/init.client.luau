--!strict
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local CameraController = require(script.CameraController)
local Hud = require(script.Hud)
local LevelUpUi = require(script.LevelUpUi)
local LobbyAndDeathUi = require(script.LobbyAndDeathUi)
local WorldRenderer = require(script.WorldRenderer)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

CameraController.start()
WorldRenderer.start()
Hud.mount(playerGui)
LevelUpUi.mount(playerGui)
LobbyAndDeathUi.mount(playerGui)
