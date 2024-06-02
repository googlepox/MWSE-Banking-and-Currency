local common = require("GPBank.common.common")
local config = require("GPBank.config")
local bankMenu = require("GPBank.menus.bankMenu")
local accountMenu = require("GPBank.menus.accountMenu")
local loanMenu = require("GPBank.menus.loanMenu")
local payLoanMenu = require("GPBank.menus.payLoanMenu")
local takeLoanMenu = require("GPBank.menus.takeLoanMenu")

local OR = include("DOR.GPObjectReplacer")

local septimGold
local septimGold001Cursed
local septimGold005
local septimGold005Cursed
local septimGold010
local septimGold025
local septimGold100
local septimSilver
local septimSilver001Cursed
local septimSilver005
local septimSilver005Cursed
local septimSilver010
local septimSilver025
local septimSilver100
local septimCopper
local septimPaper0005
local septimPaper0010
local septimPaper0020
local septimPaper0050
local septimPaper0100
local septimPaper0500
local septimPaper1000
local currency = {}
local currentDay
local bankers

local function onBankButtonClick()
	bankMenu.createBankMenu()
end

local function createBankButton(parent,enabled)
	local bankButton
	if enabled then
		bankButton = parent:createTextSelect({id = common.GUI_ID_BankButton, text = "Imperial Bank"})
		bankButton:register("mouseClick", onBankButtonClick)
		bankButton.visible = true
	else
		bankButton = parent:createLabel({id = common.GUI_ID_BankButton, text = "Imperial Bank"})
		bankButton.color = tes3ui.getPalette("journal_finished_quest_color")
		bankButton.visible = true
	end
	return bankButton
end

local function updateBankButton()
	local menu = tes3ui.findMenu(common.GUI_ID_DialogMenu)
	if not menu then return end
	local actor = menu:getPropertyObject("PartHyperText_actor")
	local topics = menu:findChild(common.GUI_ID_DialogTopics):findChild(common.GUI_ID_ScrollPane)
	local dialogDivider = menu:findChild(common.GUI_ID_DialogDivider)
	local bankButton = menu:findChild(common.GUI_ID_BankButton)
	for _, banker in pairs(bankers) do
        if (actor.reference.baseObject.id == banker or actor.reference.baseObject.class.id:find("Banker") or actor.reference.baseObject.id:find("banker_") or actor.reference.baseObject.class.id:find("T_Glb_Banker")) then
            if (not bankButton) then
                bankButton = createBankButton(topics, true)
                topics:reorderChildren(dialogDivider, bankButton, 1)
                menu:updateLayout()
            end
        end
    end
end

local function onEnterFrame()
	updateBankButton()
	if currentDay ~= tes3.getGlobal("Day") then
		currentDay = tes3.getGlobal("Day")
		common.updateAccount()
        common.updateLoans()
        common.updateInvestments()
	end
	if common.GPBankData.loanCrime == true and tes3.mobilePlayer.bounty == 0 then
		common.GPBankData.loanCrime = false
	end
end

local function convertToCopper(e)
    if (e.element.name ~= "MenuDialog") then return end
    common.enterMenu()
    common.removeCoinStacks()
end

local function convertBack(e)
    common.GPBankData.activeLoans = common.activeLoans
    common.GPBankData.accountBalance = common.accountBalance
    common.GPBankData.accountCreated = common.accountCreated
    common.GPBankData.allCommodities =  common.allCommodities
    tes3.player.data.GPBank = common.GPBankData
    local actualCopper = common.getActualCopper(common.totalCopper)
    local newTotalCopper = 0
    local diff = common.totalCopperBefore - tes3.getPlayerGold()
    if (common.converted) then
        if (diff > 0 and common.actualCopperBefore ~= common.totalCopperBefore and actualCopper ~= common.totalCopper) then
            common.convertLoss(math.abs(diff))
        elseif (diff < 0 and common.actualCopperBefore ~= common.totalCopperBefore and actualCopper ~= common.totalCopper) then
            common.convertGain(diff)
        end
        common.fixCounts()
        common.updateCountsOnExit()
        common.totalCopperBefore = tes3.getPlayerGold()
        common.totalCopper = tes3.getPlayerGold()
        common.converted = false;
    end
end

local function onActivate(e)
    if (e.activator ~= tes3.mobilePlayer) then return end
    if (e.target.baseObject == septimGold001Cursed) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimGold, count = 1, playSound = false})
    elseif (e.target.baseObject == septimGold005Cursed) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimGold, count = 5, playSound = false})
    elseif (e.target.baseObject == septimGold005) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimGold, count = 5, playSound = false})
    elseif (e.target.baseObject == septimGold010) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimGold, count = 10, playSound = false})
    elseif (e.target.baseObject == septimGold025) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimGold, count = 25, playSound = false})
    elseif (e.target.baseObject == septimGold100) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimGold, count = 100, playSound = false})
    elseif (e.target.baseObject == septimSilver001Cursed) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimSilver, count = 1, playSound = false})
    elseif (e.target.baseObject == septimSilver005Cursed) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimSilver, count = 5, playSound = false})
    elseif (e.target.baseObject == septimSilver005) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimSilver, count = 5, playSound = false})
    elseif (e.target.baseObject == septimSilver010) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimSilver, count = 10, playSound = false})
    elseif (e.target.baseObject == septimSilver025) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimSilver, count = 25, playSound = false})
    elseif (e.target.baseObject == septimSilver100) then
        tes3.addItem({reference = tes3.mobilePlayer, item = septimSilver, count = 100, playSound = false})
    end
end

-- INIT

local function initCoins()
    septimGold = tes3.getObject("GPBankSeptimGold")
    septimGold005 = tes3.getObject("GPBankSeptimGold_005")
    septimGold010 = tes3.getObject("GPBankSeptimGold_010")
    septimGold025 = tes3.getObject("GPBankSeptimGold_025")
    septimGold100 = tes3.getObject("GPBankSeptimGold_100")
    septimGold001Cursed = tes3.getObject("GPBankGold_Dae_cursed_001")
    septimGold005Cursed = tes3.getObject("GPBankGold_Dae_cursed_005")
    septimSilver = tes3.getObject("GPBankSeptimSilver")
    septimSilver005 = tes3.getObject("GPBankSeptimGold_005")
    septimSilver010 = tes3.getObject("GPBankSeptimGold_010")
    septimSilver025 = tes3.getObject("GPBankSeptimGold_025")
    septimSilver100 = tes3.getObject("GPBankSeptimGold_100")
    septimSilver001Cursed = tes3.getObject("GPBankSilver_Dae_cursed_001")
    septimSilver005Cursed = tes3.getObject("GPBankSilver_Dae_cursed_005")
    septimCopper = tes3.getObject("Gold_001")
    septimGold.weight = config.septimGoldWeight / 100
    septimSilver.weight = config.septimSilverWeight / 100
    septimGold.value = config.septimGoldValue
    septimSilver.value = config.septimSilverValue
    septimCopper.name = "Septim (Copper)"
    septimPaper0005 = tes3.getObject("GPBankSeptimPaper0005")
    septimPaper0010 = tes3.getObject("GPBankSeptimPaper0010")
    septimPaper0020 = tes3.getObject("GPBankSeptimPaper0020")
    septimPaper0050 = tes3.getObject("GPBankSeptimPaper0050")
    septimPaper0100 = tes3.getObject("GPBankSeptimPaper0100")
    septimPaper0500 = tes3.getObject("GPBankSeptimPaper0500")
    septimPaper1000 = tes3.getObject("GPBankSeptimPaper1000")
    common.currency = {
        septimPaper0005,
        septimPaper0010,
        septimPaper0020,
        septimPaper0050,
        septimPaper0100,
        septimPaper0500,
        septimPaper1000,
        septimGold,
        septimSilver
    }
    common.currencies1 = {
        septimPaper0005,
        septimPaper0050,
        septimPaper1000,
    }
    common.currencies2 = {
        septimPaper0010,
        septimPaper0100,
        septimSilver,
    }
    common.currencies3 = {
        septimPaper0020,
        septimPaper0500,
        septimGold,
    }
end

local function initOnLoad()
    OR.loadORFile("GPBank._OR_GPBank")
    initCoins()
    common.commodities1 = {
        wickwheat = common.allCommodities.wickwheat,
        saltrice = common.allCommodities.saltrice,
        fish = common.allCommodities.fish,
        produce = common.allCommodities.produce,
    }
    common.commodities2 = {
        guars = common.allCommodities.guars,
        kwama = common.allCommodities.kwama,
        iron = common.allCommodities.iron,
        steel = common.allCommodities.steel
    }
    common.commodities3 = {
        silver = common.allCommodities.silver,
        gold = common.allCommodities.gold,
        ebony = common.allCommodities.ebony,
        gems = common.allCommodities.gems
    }
    common.commodities4 = {
        spirits = common.allCommodities.spirits,
        glass = common.allCommodities.glass,
        hides = common.allCommodities.hides,
        textiles = common.allCommodities.textiles,
    }
    currentDay = tes3.getGlobal("Day")
    bankers = {
        "chargen class",
        "canctunian ponius"
    }
    tes3.player.data.GPBank = tes3.player.data.GPBank or {}
    common.GPBankData = tes3.player.data.GPBank
    if common.GPBankData.activeLoans == nil then common.GPBankData.activeLoans = {} end
    common.activeLoans = common.GPBankData.activeLoans
    if common.GPBankData.accountBalance == nil then common.GPBankData.accountBalance = 0 end
    common.accountBalance = common.GPBankData.accountBalance
    if common.GPBankData.accountCreated == nil then common.GPBankData.accountCreated = false end
    common.accountCreated = common.GPBankData.accountCreated
    if common.GPBankData.daysTilCompound == nil then common.GPBankData.daysTilCompound = config.interestPeriodAccount end
    common.daysTilCompound = common.GPBankData.daysTilCompound
    if common.GPBankData.allCommodities == nil then common.GPBankData.allCommodities = common.allCommodities end
    common.allCommodities = common.GPBankData.allCommodities
    common.activeLoanMax = common.getMaxNumLoans()
    common.totalCopper = 0
    common.initCounts()
    common.updateCounts()
    common.updateCommodityLists()
    event.register(tes3.event.enterFrame, onEnterFrame)
    print("[MWSE Currency] MWSE Currency Initialized")
end

local function initialized()
    event.register(tes3.event.loaded, initOnLoad)
    event.register(tes3.event.uiActivated, convertToCopper)
    event.register(tes3.event.menuExit, convertBack)
    event.register(tes3.event.activate, onActivate)
end

event.register(tes3.event.initialized, initialized)

event.register("modConfigReady", function()
    require("gpbank.mcm")
    config = require("gpbank.config")
end)