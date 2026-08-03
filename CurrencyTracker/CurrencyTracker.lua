CurrencyTracker = CreateFrame("Frame")

-------------------------------------------------
-- DEFAULTS
-------------------------------------------------

CurrencyTracker.CrestFrameWidth = 200
CurrencyTracker.CrestFrameHeight = 42
CurrencyTracker.AdventurerCrestID = 3383
CurrencyTracker.VeteranCrestID = 3341
CurrencyTracker.ChampionCrestID = 3343
CurrencyTracker.HeroCrestID = 3345
CurrencyTracker.MythCrestID = 3347
CurrencyTracker.NebulousVoidcoreID = 3418

CurrencyTracker.DEFAULT_CURRENCIES = { CurrencyTracker.AdventurerCrestID, CurrencyTracker.VeteranCrestID, CurrencyTracker.ChampionCrestID, CurrencyTracker.HeroCrestID, CurrencyTracker.MythCrestID,
    CurrencyTracker.NebulousVoidcoreID }

CurrencyTracker.CURRENCY_COLORS = {
    [CurrencyTracker.AdventurerCrestID] = { 1.00, 0.49, 0.040 },
    [CurrencyTracker.VeteranCrestID] = { 0.25, 0.78, 0.92 },
    [CurrencyTracker.ChampionCrestID] = { 0.60, 0.30, 1.00 },
    [CurrencyTracker.HeroCrestID] = { 0.13, 0.69, 0.29 },
    [CurrencyTracker.MythCrestID] = { 0.77, 0.12, 0.23 },
    [CurrencyTracker.NebulousVoidcoreID] = { 0.50, 0.50, 0.50 },
}

CurrencyTracker.DebugPlayers = {
    "Falcóne",
    "Lindstrom",
    "Sanbr",
    "Sânbr",
}


local function CopyTable(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function InitDB()
    if not CurrencyTrackerDB then
        CurrencyTrackerDB = {}
    end

    if not CurrencyTrackerAcctDB then
        CurrencyTrackerAcctDB = {}
    end

    -- toon lvl saved data
    CurrencyTrackerDB.fontSize = CurrencyTrackerDB.fontSize or 14
    CurrencyTrackerDB.opacity = tonumber(CurrencyTrackerDB.opacity) or 0.3
    CurrencyTrackerDB.showGold = CurrencyTrackerDB.showGold or false
    CurrencyTrackerDB.position = CurrencyTrackerDB.position or { "CENTER", "CENTER", 0, 0 }
    CurrencyTrackerDB.showCrestBar = CurrencyTrackerDB.showCrestBar or false
    CurrencyTrackerDB.upgradeGoldSpent = CurrencyTrackerDB.upgradeGoldSpent or 0
    CurrencyTrackerDB.upgradeGoldSpentXpac = CurrencyTrackerDB.upgradeGoldSpentXpac or 0

    -- Crest visibility (per character)
    if not CurrencyTrackerDB.crestVisibility then
        CurrencyTrackerDB.crestVisibility = {
            [CurrencyTracker.AdventurerCrestID] = true,
            [CurrencyTracker.VeteranCrestID] = true,
            [CurrencyTracker.ChampionCrestID] = true,
            [CurrencyTracker.HeroCrestID] = true,
            [CurrencyTracker.MythCrestID] = true,
        }
    end

    --Account lvl saved data
    CurrencyTrackerAcctDB.upgradeGoldSpentAcct = CurrencyTrackerAcctDB.upgradeGoldSpentAcct or 0

    -- Only create currencies table if it doesn't exist
    if not CurrencyTrackerDB.currencies then
        CurrencyTrackerDB.currencies = {}
    end

    -- First-time initialization
    if not CurrencyTrackerDB.initialized then
        CurrencyTrackerDB.currencies = CopyTable(CurrencyTracker.DEFAULT_CURRENCIES)
        CurrencyTrackerDB.showCrestBar = true
        CurrencyTrackerDB.initialized = true
    end

    -- Crest Colors (saved)
    if not CurrencyTrackerAcctDB.crestColors then
        CurrencyTrackerAcctDB.crestColors = CopyTable(CurrencyTracker.CURRENCY_COLORS)
    end
end

 function CurrencyTracker:GetCoinAtlasString(money, iconSize)
    iconSize = iconSize or 14

    local gold = floor(money / 10000)
    -- local silver = floor((money % 10000) / 100)
    -- local copper = money % 100

    local str = ""

    if gold > 0 then
        str = str .. gold .. "|A:Coin-Gold:" .. iconSize .. ":" .. iconSize .. "|a "
    end

    -- if silver > 0 or gold > 0 then
    --     str = str .. silver .. "|A:Coin-Silver:" .. iconSize .. ":" .. iconSize .. "|a "
    -- end

    -- str = str .. copper .. "|A:Coin-Copper:" .. iconSize .. ":" .. iconSize .. "|a"

    return str
end

function CurrencyTracker:GetCrestColor(currencyID)
    if CurrencyTrackerAcctDB and CurrencyTrackerAcctDB.crestColors and CurrencyTrackerAcctDB.crestColors[currencyID] then
        return CurrencyTrackerAcctDB.crestColors[currencyID]
    end
    return CurrencyTracker.CURRENCY_COLORS[currencyID] or { 1, 1, 1 }
end

function CurrencyTracker:CreateCrestBar(info, index)
    local color = CurrencyTracker:GetCrestColor(info.currencyID)

    local f = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    f:SetSize(CurrencyTracker.CrestFrameWidth, CurrencyTracker.CrestFrameHeight)

    if index == 1 then
        f:SetPoint("TOP", self.frame, "BOTTOM", 0, -6)
    else
        f:SetPoint("TOP", self.repBars[index - 1], "BOTTOM", 0, -6)
    end

    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Buttons/WHITE8x8",
        edgeSize = 1,
    })

    f:SetBackdropColor(color[1] * .08, color[2] * .08, color[3] * .08, 0.90)

    -- BORDER COLOR MATCHES BAR
    f:SetBackdropBorderColor(color[1], color[2], color[3], 1)

    -------------------------------------------------
    -- CREST ICON
    -------------------------------------------------

    local crest = f:CreateTexture(nil, "OVERLAY")
    crest:SetSize(16, 16)
    crest:SetPoint("TOPLEFT", 8, -4)
    crest:SetTexture(info.iconFileID)

    -------------------------------------------------
    -- TEXT
    -------------------------------------------------

    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.name:SetPoint("LEFT", crest, "RIGHT", 4, 0)
    f.name:SetText(info.name)
    f.name:SetTextColor(color[1], color[2], color[3])

    f.count = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.count:SetPoint("TOPRIGHT", -8, -7)
    f.count:SetText(info.quantity)
    f.count:SetTextColor(color[1], color[2], color[3])

    -------------------------------------------------
    -- BAR BACKGROUND
    -------------------------------------------------

    local barBG = f:CreateTexture(nil, "ARTWORK")
    barBG:SetPoint("BOTTOMLEFT", 8, 6)
    barBG:SetPoint("BOTTOMRIGHT", -8, 6)
    barBG:SetHeight(14)
    barBG:SetColorTexture(color[1], color[2], color[3], .2)

    -------------------------------------------------
    -- BAR FILL
    -------------------------------------------------
    local percent = info.totalEarned / info.maxQuantity
    percent = math.min(percent, 1)

    local bar = f:CreateTexture(nil, "OVERLAY")
    bar:SetPoint("LEFT", barBG, "LEFT")
    bar:SetHeight(14)
    bar:SetWidth((CurrencyTracker.CrestFrameWidth - 16) * percent)

    -- BAR COLOR MATCHES FRAME
    bar:SetColorTexture(color[1], color[2], color[3], 1)

    -------------------------------------------------
    -- PROGRESS TEXT
    -------------------------------------------------

    f.progress = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.progress:SetPoint("CENTER", barBG, "CENTER")
    f.progress:SetText(info.totalEarned .. " / " .. info.maxQuantity)

    -- TEXT COLOR MATCHES BAR
    f.progress:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    f.progress:SetTextColor(0.91, 0.92, 0.91)


    f.bar = bar
    f.barBG = barBG

    return f
end

-------------------------------------------------
-- MAIN DISPLAY FRAME
-------------------------------------------------

function CurrencyTracker:CreateDisplay()
    local f = CreateFrame("Frame", "CurrencyTrackerFrame", UIParent)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)

    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        CurrencyTrackerDB.position = { p, rp, x, y }
    end)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, CurrencyTrackerDB.opacity)

    self.frame = f
    self.lines = {}

    self:RestorePosition()
    self:UpdateDisplay()
end

function CurrencyTracker:RestorePosition()
    local pos = CurrencyTrackerDB.position
    if pos and #pos == 4 then
        self.frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        self.frame:SetPoint("CENTER")
    end
end

-------------------------------------------------
-- UPDATE DISPLAY
-------------------------------------------------

function CurrencyTracker:UpdateDisplay()
    local f = self.frame
    if not f then return end

    if not self.repBars then
        self.repBars = {}
    end

    for _, bar in ipairs(self.repBars) do
        bar:Hide()
    end

    wipe(self.repBars)

    for _, line in ipairs(self.lines) do
        line:Hide()
    end

    wipe(self.lines)

    local fontSize = CurrencyTrackerDB.fontSize
    local yOffset = -5
    local width = 0
    local repBarCount = 0

    for _, id in ipairs(CurrencyTrackerDB.currencies) do
        local info = C_CurrencyInfo.GetCurrencyInfo(id)
        if info and info.name then
            local line = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            line:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            line:SetPoint("TOPLEFT", 10, yOffset)
            local currencyLine

            if info.totalEarned == 0 then
                currencyLine = "|T" .. info.iconFileID .. ":" .. fontSize .. ":" .. fontSize .. "|t "
                    .. info.name .. " " .. info.quantity

                line:SetText(currencyLine)
                yOffset = yOffset - (fontSize + 6)
                width = math.max(width, line:GetStringWidth())
                table.insert(self.lines, line)
            else
                if not CurrencyTrackerDB.showCrestBar then
                    currencyLine = "|T" .. info.iconFileID .. ":" .. fontSize .. ":" .. fontSize .. "|t "
                        .. info.name .. " " .. info.quantity
                        .. " (" .. info.totalEarned .. "/" .. info.maxQuantity .. ")"

                    line:SetText(currencyLine)
                    yOffset = yOffset - (fontSize + 6)
                    width = math.max(width, line:GetStringWidth())
                    table.insert(self.lines, line)
                end
            end
        end
    end

    -- Create rep bars if enabled
    if CurrencyTrackerDB.showCrestBar then
        local index = 1
        for _, id in ipairs(CurrencyTracker.DEFAULT_CURRENCIES) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if info and info.name and CurrencyTrackerDB.crestVisibility[id] ~= false and (info.totalEarned > 0 or info.quantity > 0) then
                local bar = self:CreateCrestBar(info, index)
                table.insert(self.repBars, bar)
                index = index + 1
                repBarCount = repBarCount + 1
                width = CurrencyTracker.CrestFrameWidth
            end
        end
    end

    if CurrencyTrackerDB.showGold then
        local line = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        line:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
        line:SetPoint("TOPLEFT", 10, yOffset)
        line:SetText(CurrencyTracker:GetCoinAtlasString(GetMoney()))
        yOffset = yOffset - (fontSize + 6)
        width = math.max(width, line:GetStringWidth())
        table.insert(self.lines, line)
    end


    -- Calculate total height: lines + spacing + rep bars
    local totalHeight = math.abs(yOffset) + (repBarCount * (CurrencyTracker.CrestFrameHeight + 6)) + 10

    f:SetSize(width + 20, totalHeight)
    local opacity = tonumber(CurrencyTrackerDB.opacity) or 0.3
    f.bg:SetColorTexture(0, 0, 0, opacity)

    -- Reposition rep bars under the last text line
    local startY = -5
    for _, line in ipairs(self.lines) do
        startY = startY - (line:GetStringHeight() + 6)
    end

    for i, bar in ipairs(self.repBars) do
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", 10, startY - ((i - 1) * (CurrencyTracker.CrestFrameHeight + 6)))
        bar:Show()
    end
end

-------------------------------------------------
-- MINIMAP BUTTON
-------------------------------------------------

function CurrencyTracker:CreateMinimapButton()
    local button = CreateFrame("Button", "CurrencyTrackerMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetPoint("TOPLEFT")
    button:SetFrameLevel(8)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetSize(53, 53)
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border:SetPoint("TOPLEFT")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(17, 17)
    button.icon:SetTexture("Interface\\Icons\\Inv_valorstone_base")
    button.icon:SetPoint("CENTER")
    button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function() CurrencyTracker:ToggleSettings() end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Currency Tracker", 1, 0.82, 0)
        GameTooltip:AddLine("|cff00ff00Click|r to open settings", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-------------------------------------------------
-- UPGRADE VENDOR GOLD TRACKER
-------------------------------------------------

local lastMoney = 0

local function IsUpgradeFrameOpen()
    return ItemUpgradeFrame and ItemUpgradeFrame:IsShown()
end

local function UpdateUpgradeGold()
    local currentMoney = GetMoney()

    if currentMoney < lastMoney then
        local spent = lastMoney - currentMoney

        if IsUpgradeFrameOpen() then
            CurrencyTrackerDB.upgradeGoldSpent = CurrencyTrackerDB.upgradeGoldSpent + spent
            CurrencyTrackerDB.upgradeGoldSpentXpac = CurrencyTrackerDB.upgradeGoldSpentXpac + spent
            CurrencyTrackerAcctDB.upgradeGoldSpentAcct = CurrencyTrackerAcctDB.upgradeGoldSpentAcct + spent

            if CurrencyTracker.UpdateUpgradeGoldDisplay then
                CurrencyTracker:UpdateUpgradeGoldDisplay()
            end
        end
    end

    lastMoney = currentMoney
end


function CurrencyTracker:UpdateUpgradeGoldDisplay()
    if not self.upgradeSpentText then return end

    self.upgradeSpentText:SetText(
        CurrencyTracker:GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpent)
    )

    self.upgradeSpentXpacText:SetText(
        CurrencyTracker:GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpentXpac)
    )

    self.upgradeSpentXpacAccountText:SetText(
        CurrencyTracker:GetCoinAtlasString(CurrencyTrackerAcctDB.upgradeGoldSpentAcct)
    )
end

-------------------------------------------------
-- EVENTS
-------------------------------------------------

CurrencyTracker:RegisterEvent("PLAYER_LOGIN")
CurrencyTracker:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
CurrencyTracker:RegisterEvent("PLAYER_MONEY")

CurrencyTracker:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        lastMoney = GetMoney()
        self:CreateDisplay()
        self:CreateMinimapButton()
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        self:UpdateDisplay()
    elseif event == "PLAYER_MONEY" then
        UpdateUpgradeGold()
    end
end)
