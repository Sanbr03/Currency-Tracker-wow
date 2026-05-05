local CurrencyTracker = ...
CurrencyTracker = CreateFrame("Frame")

-------------------------------------------------
-- DEFAULTS
-------------------------------------------------

local CrestFramWidth = 200
local CrestFramWHeight = 42
local AdventurerCrestID = 3383
local VeteranCrestID = 3341
local ChampionCrestID = 3343
local HeroCrestID = 3345
local MythCrestID = 3347
local NebulousVoidcoreID = 3418

local DEFAULT_CURRENCIES = { AdventurerCrestID, VeteranCrestID, ChampionCrestID, HeroCrestID, MythCrestID, NebulousVoidcoreID }

local CURRENCY_COLORS = {
    [AdventurerCrestID] = { 1.00, 0.49, 0.040 },
    [VeteranCrestID] = { 0.25, 0.78, 0.92 },
    [ChampionCrestID] = { 0.60, 0.30, 1.00 },
    [HeroCrestID] = { 0.13, 0.69, 0.29 },
    [MythCrestID] = { 0.77, 0.12, 0.23 },
    [NebulousVoidcoreID] = { 0.50, 0.50, 0.50 },
}

local DebugPlayers = {
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
            [AdventurerCrestID] = true,
            [VeteranCrestID] = true,
            [ChampionCrestID] = true,
            [HeroCrestID] = true,
            [MythCrestID] = true,
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
        CurrencyTrackerDB.currencies = CopyTable(DEFAULT_CURRENCIES)
        CurrencyTrackerDB.showCrestBar = true
        CurrencyTrackerDB.initialized = true
    end

    -- Crest Colors (saved)
    if not CurrencyTrackerAcctDB.crestColors then
        CurrencyTrackerAcctDB.crestColors = CopyTable(CURRENCY_COLORS)
    end
end

local function GetCoinAtlasString(money, iconSize)
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
    return CURRENCY_COLORS[currencyID] or { 1, 1, 1 }
end

function CurrencyTracker:CreateCrestBar(info, index)
    local color = CurrencyTracker:GetCrestColor(info.currencyID)

    local f = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    f:SetSize(CrestFramWidth, CrestFramWHeight)

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
    bar:SetWidth((CrestFramWidth - 16) * percent)

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
                if not CurrencyTrackerDB.showRepBar then
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
    if CurrencyTrackerDB.showRepBar then
        local index = 1
        for _, id in ipairs(DEFAULT_CURRENCIES) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if CurrencyTrackerDB.crestVisibility[id] ~= false and (info.totalEarned > 0 or info.quantity > 0) then
                if info and info.name then
                    local bar = self:CreateCrestBar(info, index)
                    table.insert(self.repBars, bar)
                    index = index + 1
                    repBarCount = repBarCount + 1
                    width = CrestFramWidth
                end
            end
        end
    end

    if CurrencyTrackerDB.showGold then
        local line = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        line:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
        line:SetPoint("TOPLEFT", 10, yOffset)
        line:SetText(GetCoinAtlasString(GetMoney()))
        yOffset = yOffset - (fontSize + 6)
        width = math.max(width, line:GetStringWidth())
        table.insert(self.lines, line)
    end


    -- Calculate total height: lines + spacing + rep bars
    local totalHeight = math.abs(yOffset) + (repBarCount * (CrestFramWHeight + 6)) + 10

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
        bar:SetPoint("TOPLEFT", 10, startY - ((i - 1) * (CrestFramWHeight + 6)))
        bar:Show()
    end
end

function CurrencyTracker:CreateReloadButton(parent)
    local reloadBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    reloadBtn:SetSize(140, 25)
    reloadBtn:SetPoint("BOTTOMLEFT", 10, 0)
    reloadBtn:SetText("Reload UI")

    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)
    return reloadBtn
end

function CurrencyTracker:CreateColorPicker(parent, currencyID, anchorTo, label)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(24, 24)
    btn:SetPoint("RIGHT", parent, "RIGHT", -250, 0)
    btn:SetPoint("TOP", anchorTo, "TOP", 0, 0)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn.tex = btn:CreateTexture(nil, "BACKGROUND")
    btn.tex:SetAllPoints()

    local function UpdateSwatch()
        local c = CurrencyTracker:GetCrestColor(currencyID)
        btn.tex:SetColorTexture(c[1], c[2], c[3])

        if label then
            label:SetTextColor(c[1], c[2], c[3])
        end
    end

    UpdateSwatch()

    btn:SetScript("OnClick", function(_, button)
        local current = CurrencyTracker:GetCrestColor(currencyID)

        if button == "LeftButton" and IsShiftKeyDown() then
            for _, id in ipairs(DEFAULT_CURRENCIES) do
                CurrencyTrackerAcctDB.crestColors[id] = { current[1], current[2], current[3] }
            end

            CurrencyTracker:UpdateDisplay()

            -- Refresh settings UI so all swatches + labels update
            if CurrencyTracker.settings then
                CurrencyTracker.settings:Hide()
                CurrencyTracker.settings = nil
                CurrencyTracker:CreateSettings()
                CurrencyTracker.settings:Show()
            end

            return
        end

        -- RIGHT CLICK → RESET SINGLE CREST
        if button == "RightButton" then
            local default = CURRENCY_COLORS[currencyID]
            CurrencyTrackerAcctDB.crestColors[currencyID] = { default[1], default[2], default[3] }

            btn.tex:SetColorTexture(default[1], default[2], default[3])
            if label then
                label:SetTextColor(default[1], default[2], default[3])
            end

            CurrencyTracker:UpdateDisplay()
            return
        end

        -- NORMAL LEFT CLICK → COLOR PICKER
        local function Callback(restore)
            local r, g, b

            if restore then
                r, g, b = restore.r, restore.g, restore.b
            else
                r, g, b = ColorPickerFrame:GetColorRGB()
            end

            CurrencyTrackerAcctDB.crestColors[currencyID] = { r, g, b }

            btn.tex:SetColorTexture(r, g, b)
            if label then
                label:SetTextColor(r, g, b)
            end

            CurrencyTracker:UpdateDisplay()
        end

        local info = {
            r = current[1],
            g = current[2],
            b = current[3],
            hasOpacity = false,
            swatchFunc = Callback,
            cancelFunc = Callback,
        }

        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        GameTooltip:AddLine(info and info.name or "Crest Color", 1, 0.82, 0)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left click to change", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right click to reset", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + Left click to copy to all", 0.6, 0.9, 1)

        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return btn
end

-------------------------------------------------
-- SETTINGS WINDOW
-------------------------------------------------

function CurrencyTracker:CreateSettings()
    local f = CreateFrame("Frame", "CurrencyTrackerSettings", UIParent, "BackdropTemplate")
    f:SetSize(520, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    -------------------------------------------------
    -- TITLE
    -------------------------------------------------

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -20)
    f.title:SetText("Currency Tracker")
    f.title:SetTextColor(1, 0.82, 0) -- WoW yellow

    -------------------------------------------------
    -- CLOSE BUTTON (modern X)
    -------------------------------------------------

    CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT")

    -------------------------------------------------
    -- CONTENT CONTAINER
    -------------------------------------------------

    local contentFrame = CreateFrame("Frame", nil, f)
    contentFrame:SetPoint("TOPLEFT", 15, -50)
    contentFrame:SetPoint("BOTTOMRIGHT", -15, 15)

    f.content = contentFrame
    f:Hide()

    -------------------------------------------------
    -- TAB BUTTONS
    -------------------------------------------------

    local tab1 = CreateFrame("Button", nil, f, "PanelTabButtonTemplate")
    tab1:SetID(1)
    tab1:SetText("General")
    tab1:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 15, 5)

    local tab2 = CreateFrame("Button", nil, f, "PanelTabButtonTemplate")
    tab2:SetID(2)
    tab2:SetText("All Currencies")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -15, 0)

    local tab3 = CreateFrame("Button", nil, f, "PanelTabButtonTemplate")
    tab3:SetID(3)
    tab3:SetText("Item Upgrade")
    tab3:SetPoint("LEFT", tab2, "RIGHT", -15, 0)

    local tab4 = CreateFrame("Button", nil, f, "PanelTabButtonTemplate")
    tab4:SetID(4)
    tab4:SetText("Crest Tracker")
    tab4:SetPoint("LEFT", tab3, "RIGHT", -15, 0)

    PanelTemplates_SetNumTabs(f, 4)
    PanelTemplates_SetTab(f, 1)

    -------------------------------------------------
    -- CONTENT FRAMES (FIXED ANCHORING)
    -------------------------------------------------

    local general = CreateFrame("Frame", nil, f.content)
    general:SetAllPoints()

    local allTab = CreateFrame("Frame", nil, f.content)
    allTab:SetAllPoints()
    allTab:Hide()

    local IUTab = CreateFrame("Frame", nil, f.content)
    IUTab:SetAllPoints()
    IUTab:Hide()

    local CrestTab = CreateFrame("Frame", nil, f.content)
    CrestTab:SetAllPoints()
    CrestTab:Hide()

    local function SelectTab(id)
        PanelTemplates_SetTab(f, id)
        general:SetShown(id == 1)
        allTab:SetShown(id == 2)
        IUTab:SetShown(id == 3)
        CrestTab:SetShown(id == 4)
    end

    tab1:SetScript("OnClick", function() SelectTab(1) end)
    tab2:SetScript("OnClick", function() SelectTab(2) end)
    tab3:SetScript("OnClick", function()
        SelectTab(3)
        CurrencyTracker:UpdateUpgradeGoldDisplay()
    end)
    tab4:SetScript("OnClick", function() SelectTab(4) end)

    -------------------------------------------------
    -- GENERAL TAB CONTENT
    -------------------------------------------------

    local goldCheck = CreateFrame("CheckButton", nil, general, "UICheckButtonTemplate")
    goldCheck:SetPoint("TOPLEFT", 10, -10)
    goldCheck.text:SetText("Show Gold")
    goldCheck:SetChecked(CurrencyTrackerDB.showGold)
    goldCheck:SetScript("OnClick", function(self)
        CurrencyTrackerDB.showGold = self:GetChecked()
        CurrencyTracker:UpdateDisplay()
    end)

    local repCheck = CreateFrame("CheckButton", nil, general, "UICheckButtonTemplate")
    repCheck:SetPoint("TOPLEFT", goldCheck, "BOTTOMLEFT", 0, -5)
    repCheck.text:SetText("Show Progress Bar for Crests")
    repCheck:SetChecked(CurrencyTrackerDB.showRepBar)
    repCheck:SetScript("OnClick", function(self)
        CurrencyTrackerDB.showRepBar = self:GetChecked()
        CurrencyTracker:UpdateDisplay()
    end)

    local resetBtn = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 25)
    resetBtn:SetPoint("TOPLEFT", repCheck, "BOTTOMLEFT", 0, -10)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        local f = CurrencyTracker.frame
        CurrencyTrackerDB.position = { "CENTER", "CENTER", 0, 0 }
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)

    -------------------------------------------------
    -- RELOAD UI BUTTON (ONLY FOR FALCÓNE)
    -------------------------------------------------

    local playerName = UnitName("player")

    if CurrencyTracker:ReloadButtonShow(playerName) then
        CurrencyTracker:CreateReloadButton(general)
    end

    local slider = CreateFrame("Slider", nil, general, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -20)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(200)
    slider:SetValue(CurrencyTrackerDB.opacity)
    slider:SetScript("OnValueChanged", function(self, value)
        CurrencyTrackerDB.opacity = tonumber(value) or 0.3
        CurrencyTracker:UpdateDisplay()
    end)

    slider.label = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.label:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.label:SetText("Background Opacity")

    -------------------------------------------------
    -- ALL CURRENCIES TAB (SCROLL + SEARCH)
    -------------------------------------------------
    local checkboxes = {}

    -- Search Box
    local searchBox = CreateFrame("EditBox", nil, allTab, "SearchBoxTemplate")
    searchBox:SetPoint("TOPLEFT", allTab, "TOPLEFT", 20, -40)
    searchBox:SetPoint("TOPRIGHT", allTab, "TOPRIGHT", -20, -40)
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)

    local uncheckBtn = CreateFrame("Button", nil, allTab, "UIPanelButtonTemplate")
    uncheckBtn:SetSize(140, 25)
    uncheckBtn:SetPoint("TOPRIGHT", allTab, "TOPRIGHT", -20, -5)
    uncheckBtn:SetText("Uncheck All")
    uncheckBtn:SetScript("OnClick", function()
        for _, cb in ipairs(checkboxes) do
            cb:SetChecked(false)
            cb:GetScript("OnClick")(cb)
        end
    end)

    -- Scroll Frame
    local scroll = CreateFrame("ScrollFrame", nil, allTab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -5)
    scroll:SetPoint("BOTTOMRIGHT", -43, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local function RebuildCurrencyList()
        -- Clear old checkboxes
        for _, cb in ipairs(checkboxes) do
            cb:Hide()
        end
        wipe(checkboxes)

        local filter = searchBox:GetText()
        if filter and filter ~= "" then
            filter = string.lower(filter)
        else
            filter = nil
        end

        local y = -5

        -- Build a master list from:
        -- 1) Default currencies
        -- 2) Currently tracked currencies
        local masterList = {}

        local function AddCurrency(id)
            if id and not tContains(masterList, id) then
                table.insert(masterList, id)
            end
        end

        -- 1️ Always include defaults
        for _, id in ipairs(DEFAULT_CURRENCIES) do
            AddCurrency(id)
        end

        -- 2️ Include tracked currencies
        for _, id in ipairs(CurrencyTrackerDB.currencies) do
            AddCurrency(id)
        end

        -- 3️ Include character discovered currencies
        for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(i)
            if info and not info.isHeader then
                AddCurrency(info.currencyID)
            end
        end

        -- Now build UI from master list
        for _, currencyID in ipairs(masterList) do
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)

            if info and info.name then
                local nameMatch = true

                if filter and filter ~= "" then
                    nameMatch = string.find(string.lower(info.name), filter, 1, true)
                end

                if nameMatch then
                    local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                    check:SetPoint("TOPLEFT", 10, y)

                    local iconSize = 16
                    local iconString = "|T" .. info.iconFileID .. ":" ..
                        iconSize .. ":" .. iconSize .. ":0:0:64:64:4:60:4:60|t "

                    check.text:SetText(iconString .. info.name)
                    check:SetChecked(tContains(CurrencyTrackerDB.currencies, currencyID))

                    check:SetScript("OnClick", function(self)
                        if self:GetChecked() then
                            table.insert(CurrencyTrackerDB.currencies, currencyID)
                        else
                            for k, v in ipairs(CurrencyTrackerDB.currencies) do
                                if v == currencyID then
                                    table.remove(CurrencyTrackerDB.currencies, k)
                                    break
                                end
                            end
                        end
                        CurrencyTracker:UpdateDisplay()
                    end)

                    table.insert(checkboxes, check)
                    y = y - 25
                end
            end
        end

        content:SetHeight(math.abs(y) + 20)
    end

    searchBox:HookScript("OnTextChanged", function()
        RebuildCurrencyList()
    end)
    RebuildCurrencyList()
    self.settings = f
    self:UpdateUpgradeGoldDisplay()

    -------------------------------------------------
    -- Item Upgrade gold tab
    -------------------------------------------------
    -------------------------------------------------
    -- UPGRADE GOLD SPENT DISPLAY
    -------------------------------------------------
    local fontSizeGold = 18
    local yOffset      = -10

    local titleText    = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", 0, 0)
    titleText:SetText("Gold Spent on Item Upgrades")

    local seasonText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    seasonText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", -100, yOffset - 5)
    seasonText:SetText("Current Season:")
    seasonText:SetTextColor(0.25, 0.78, 0.92)

    local upgradeSpentText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upgradeSpentText:SetPoint("TOPLEFT", seasonText, "BOTTOMLEFT", 0, yOffset)
    upgradeSpentText:SetText(GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpent))
    upgradeSpentText:SetFontHeight(fontSizeGold)
    upgradeSpentText:SetTextColor(0.25, 0.78, 0.92)
    self.upgradeSpentText = upgradeSpentText

    local xpacText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpacText:SetPoint("TOPLEFT", upgradeSpentText, "BOTTOMLEFT", 0, yOffset)
    xpacText:SetText("Current Xpac:")
    xpacText:SetTextColor(0.77, 0.12, 0.23)

    local upgradeSpentXpacText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upgradeSpentXpacText:SetPoint("TOPLEFT", xpacText, "BOTTOMLEFT", 0, yOffset)
    upgradeSpentXpacText:SetText(GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpentXpac))
    upgradeSpentXpacText:SetFontHeight(fontSizeGold)
    upgradeSpentXpacText:SetTextColor(0.77, 0.12, 0.23)
    self.upgradeSpentXpacText = upgradeSpentXpacText

    local accountFontColor = CURRENCY_COLORS[HeroCrestID]
    local accountText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    accountText:SetPoint("TOPLEFT", upgradeSpentXpacText, "BOTTOMLEFT", 0, yOffset)
    accountText:SetText("Account:")
    accountText:SetTextColor(accountFontColor[1], accountFontColor[2], accountFontColor[3])

    local upgradeSpentXpacAccountText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upgradeSpentXpacAccountText:SetPoint("TOPLEFT", accountText, "BOTTOMLEFT", 0, yOffset)
    upgradeSpentXpacAccountText:SetText(GetCoinAtlasString(CurrencyTrackerAcctDB.upgradeGoldSpentAcct))
    upgradeSpentXpacAccountText:SetFontHeight(fontSizeGold)
    upgradeSpentXpacAccountText:SetTextColor(accountFontColor[1], accountFontColor[2], accountFontColor[3])
    self.upgradeSpentXpacAccountText = upgradeSpentXpacAccountText
    local resetUpgrade = CreateFrame("Button", nil, IUTab, "UIPanelButtonTemplate")

    local testtext = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    testtext:SetPoint("TOPLEFT", upgradeSpentXpacAccountText, "BOTTOMLEFT", 0, yOffset)



    resetUpgrade:SetSize(160, 22)
    resetUpgrade:SetPoint("BOTTOMRIGHT", -10, 0)
    resetUpgrade:SetText("Reset Gold (Season)")

    resetUpgrade:SetScript("OnClick", function()
        CurrencyTrackerDB.upgradeGoldSpent = 0
        upgradeSpentText:SetText(
            "Gold Spent on Item Upgrades: " ..
            GetCoinAtlasString(0)
        )
    end)

    -------------------------------------------------
    -- RELOAD UI BUTTON
    -------------------------------------------------


    if CurrencyTracker:ReloadButtonShow(playerName) then
        CurrencyTracker:CreateReloadButton(IUTab)
    end


    -------------------------------------------------
    -- Crest Tracker Settings tab
    -------------------------------------------------
    local yStart = -65
    local rowSpacing = -30

    local nameX = 15
    local enableX = 180
    local colorX = 240

    -------------------------------------------------
    -- TITLE
    -------------------------------------------------
    local CTTitleText = CrestTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    CTTitleText:SetPoint("TOP", 0, -10)
    CTTitleText:SetText("Crest Tracker Settings")

    -------------------------------------------------
    -- COLUMN HEADERS
    -------------------------------------------------
    local enableHeader = CrestTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableHeader:SetPoint("TOPLEFT", CrestTab, "TOPLEFT", enableX, -40)
    enableHeader:SetText("Enable")

    local colorHeader = CrestTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorHeader:SetPoint("TOPLEFT", CrestTab, "TOPLEFT", colorX, -40)
    colorHeader:SetText("Color")

    -------------------------------------------------
    -- ROW HELPER FUNCTION
    -------------------------------------------------
    local function CreateCrestRow(index, text, currencyID)
        local y = yStart + (index * rowSpacing)

        -- NAME
        local label = CrestTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("TOPLEFT", CrestTab, "TOPLEFT", nameX, y)
        label:SetText(text)

        -- CHECKBOX (Enable column)
        local check = CreateFrame("CheckButton", nil, CrestTab, "UICheckButtonTemplate")
        check:SetPoint("CENTER", CrestTab, "TOPLEFT", enableX + 10, y - 8)
        check:SetChecked(CurrencyTrackerDB.crestVisibility[currencyID] ~= false)

        check:SetScript("OnClick", function(self)
            CurrencyTrackerDB.crestVisibility[currencyID] = self:GetChecked()
            CurrencyTracker:UpdateDisplay()
        end)

        -- COLOR PICKER (Color column)
        local picker = CurrencyTracker:CreateColorPicker(CrestTab, currencyID, label, label)
        picker:ClearAllPoints()
        picker:SetPoint("CENTER", CrestTab, "TOPLEFT", colorX + 12, y - 8)

        return label, check, picker
    end

    -------------------------------------------------
    -- ROWS
    -------------------------------------------------
    CreateCrestRow(0, "Adventurer Crest:", AdventurerCrestID)
    CreateCrestRow(1, "Veteran Crest:", VeteranCrestID)
    CreateCrestRow(2, "Champion Crest:", ChampionCrestID)
    CreateCrestRow(3, "Hero Crest:", HeroCrestID)
    CreateCrestRow(4, "Myth Crest:", MythCrestID)
    CreateCrestRow(5, "Nebulous Voidcore:", NebulousVoidcoreID)


    local resetAllBtn = CreateFrame("Button", nil, CrestTab, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(180, 24)
    resetAllBtn:SetPoint("BOTTOMRIGHT", -10, 0)
    resetAllBtn:SetText("Reset All Crest Colors")

    resetAllBtn:SetScript("OnClick", function()
        CurrencyTrackerAcctDB.crestColors = CopyTable(CURRENCY_COLORS)

        CurrencyTracker:UpdateDisplay()

        -- Force UI refresh of color swatches + labels
        if CrestTab and CrestTab:GetChildren() then
            for _, child in ipairs({ CrestTab:GetChildren() }) do
                if child.tex then
                    -- try to infer via closure not needed, just refresh all
                    -- simplest solution: rebuild settings
                    CurrencyTracker.settings:Hide()
                    CurrencyTracker.settings = nil
                    CurrencyTracker:CreateSettings()
                    CurrencyTracker.settings:Show()
                    break
                end
            end
        end
    end)

    if CurrencyTracker:ReloadButtonShow(playerName) then
        CurrencyTracker:CreateReloadButton(CrestTab)
    end
end

function CurrencyTracker:ReloadButtonShow(playerName)
    for _, name in ipairs(DebugPlayers) do
        if playerName == name then
            return true
        end
    end

    return false
end

function CurrencyTracker:ToggleSettings()
    if not self.settings then
        self:CreateSettings()
    end
    self.settings:SetShown(not self.settings:IsShown())
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
        GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpent)
    )

    self.upgradeSpentXpacText:SetText(
        GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpentXpac)
    )

    self.upgradeSpentXpacAccountText:SetText(
        GetCoinAtlasString(CurrencyTrackerAcctDB.upgradeGoldSpentAcct)
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
