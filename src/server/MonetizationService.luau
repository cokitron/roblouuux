--!strict
local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local PlayerState = require(script.Parent.PlayerState)
local ServerTypes = require(script.Parent.ServerTypes)
local Constants = require(ReplicatedStorage.Shared.Constants)

type ReceiptInfo = {
	PurchaseId: string,
	PlayerId: number,
	ProductId: number,
	CurrencySpent: number,
}

local processedReceipts: { [string]: boolean } = {}
local initialized = false

local MonetizationService = {}

local function executeReviveGrant(state: ServerTypes.State): boolean
	local pos = PlayerState.grantPaidRevive(state)
	if not pos then
		return false
	end
	EnemyService.shockwaveClear(
		pos,
		Constants.REVIVE_SHOCKWAVE_RADIUS,
		Constants.REVIVE_SHOCKWAVE_DAMAGE,
		Constants.REVIVE_SHOCKWAVE_KNOCKBACK,
		state
	)
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			state.player,
			Enum.AnalyticsEconomyFlowType.Sink,
			"SoulRevive",
			1,
			state.revivesUsed,
			Enum.AnalyticsEconomyTransactionType.IAP.Name,
			"MidRunSoulRevive"
		)
	end)
	return true
end

-- POL-1: ProcessReceipt is registered once, claims PurchaseId atomically before granting, never yields
-- before granting in-memory state, and returns NotProcessedYet if the player is absent or unable to receive.
local function processReceipt(receiptInfo: ReceiptInfo): Enum.ProductPurchaseDecision
	local purchaseId = receiptInfo.PurchaseId
	if processedReceipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local state = PlayerState.get(player)
	if not state then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local granted = false

	if productId == Constants.REVIVE_PRODUCT_ID and Constants.REVIVE_PRODUCT_ID > 0 then
		granted = executeReviveGrant(state)
	elseif productId == Constants.REROLL_PRODUCT_ID and Constants.REROLL_PRODUCT_ID > 0 then
		granted = PlayerState.rerollOffer(state, true)
	elseif productId == Constants.CLAIM_ALL_PRODUCT_ID and Constants.CLAIM_ALL_PRODUCT_ID > 0 then
		granted = PlayerState.claimAllOffer(state)
	elseif productId == Constants.BLOOD_MOON_PRODUCT_ID and Constants.BLOOD_MOON_PRODUCT_ID > 0 then
		DataService.activateBloodMoonBanner(player)
		granted = true
	elseif productId == Constants.STARTER_PACK_PRODUCT_ID and Constants.STARTER_PACK_PRODUCT_ID > 0 then
		granted = DataService.grantStarterPack(player)
	end

	if granted then
		processedReceipts[purchaseId] = true
		local profile = DataService.getProfile(player)
		if profile then
			profile.processedReceipts[purchaseId] = true
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.requestRevive(state: ServerTypes.State): boolean
	if state.phase ~= "Downed" or state.revivesUsed >= Constants.MAX_REVIVES_PER_RUN then
		return false
	end

	if Constants.REVIVE_PRODUCT_ID > 0 then
		PlayerState.notifyPurchasePromptOpened(state)
		pcall(function()
			MarketplaceService:PromptProductPurchase(state.player, Constants.REVIVE_PRODUCT_ID)
		end)
		return true
	end

	if RunService:IsStudio() then
		return executeReviveGrant(state)
	end

	return false
end

function MonetizationService.requestSoftRevive(state: ServerTypes.State): boolean
	local pos = PlayerState.trySoftSoulRevive(state)
	if not pos then
		return false
	end
	EnemyService.shockwaveClear(
		pos,
		Constants.REVIVE_SHOCKWAVE_RADIUS,
		Constants.REVIVE_SHOCKWAVE_DAMAGE,
		Constants.REVIVE_SHOCKWAVE_KNOCKBACK,
		state
	)
	return true
end

function MonetizationService.requestReroll(state: ServerTypes.State): boolean
	-- Try free Fate Die or Souls first
	if PlayerState.rerollOffer(state, false) then
		return true
	end
	if Constants.REROLL_PRODUCT_ID > 0 then
		pcall(function()
			MarketplaceService:PromptProductPurchase(state.player, Constants.REROLL_PRODUCT_ID)
		end)
		return true
	end
	if RunService:IsStudio() then
		return PlayerState.rerollOffer(state, true)
	end
	return false
end

function MonetizationService.requestClaimAll(state: ServerTypes.State): boolean
	if state.phase ~= "InRun" or not state.alive or state.offer == nil then
		return false
	end
	if state.claimAllUsed >= Constants.MAX_CLAIM_ALL_PER_RUN then
		return false
	end
	if Constants.CLAIM_ALL_PRODUCT_ID > 0 then
		pcall(function()
			MarketplaceService:PromptProductPurchase(state.player, Constants.CLAIM_ALL_PRODUCT_ID)
		end)
		return true
	end
	if RunService:IsStudio() then
		return PlayerState.claimAllOffer(state)
	end
	return false
end

function MonetizationService.requestBloodMoon(player: Player): boolean
	if Constants.BLOOD_MOON_PRODUCT_ID > 0 then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, Constants.BLOOD_MOON_PRODUCT_ID)
		end)
		return true
	end
	if RunService:IsStudio() then
		DataService.activateBloodMoonBanner(player)
		return true
	end
	return false
end

function MonetizationService.requestStarterPack(player: Player): boolean
	local profile = DataService.getProfile(player)
	if not profile or profile.starterPackOwned then
		return false
	end
	if Constants.STARTER_PACK_PRODUCT_ID > 0 then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, Constants.STARTER_PACK_PRODUCT_ID)
		end)
		return true
	end
	if RunService:IsStudio() then
		return DataService.grantStarterPack(player)
	end
	return false
end

function MonetizationService.requestGamePass(player: Player, passKey: string): boolean
	local passId = 0
	if passKey == "Magnet" then
		passId = Constants.PASS_MAGNET_ID
	elseif passKey == "FourthCard" then
		passId = Constants.PASS_FOURTH_CARD_ID
	elseif passKey == "DoubleSouls" then
		passId = Constants.PASS_DOUBLE_SOULS_ID
	else
		return false
	end

	if passId > 0 then
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, passId)
		end)
		return true
	end

	if RunService:IsStudio() then
		return DataService.grantGamePass(player, passKey)
	end
	return false
end

function MonetizationService.init()
	if initialized then
		return
	end
	initialized = true

	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptProductPurchaseFinished:Connect(
		function(userId: number, productId: number, isPurchased: boolean)
			if isPurchased then
				return
			end
			if productId ~= Constants.REVIVE_PRODUCT_ID then
				return
			end
			local player = Players:GetPlayerByUserId(userId)
			local state = if player then PlayerState.get(player) else nil
			if state then
				PlayerState.notifyPurchasePromptClosed(state)
			end
		end
	)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, gamePassId: number, wasPurchased: boolean)
			if not wasPurchased then
				return
			end
			if gamePassId == Constants.PASS_MAGNET_ID and Constants.PASS_MAGNET_ID > 0 then
				DataService.grantGamePass(player, "Magnet")
			elseif gamePassId == Constants.PASS_FOURTH_CARD_ID and Constants.PASS_FOURTH_CARD_ID > 0 then
				DataService.grantGamePass(player, "FourthCard")
			elseif gamePassId == Constants.PASS_DOUBLE_SOULS_ID and Constants.PASS_DOUBLE_SOULS_ID > 0 then
				DataService.grantGamePass(player, "DoubleSouls")
			end
		end
	)
end

return MonetizationService
