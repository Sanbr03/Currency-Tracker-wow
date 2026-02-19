local addonName, CurrencyTracker = ...
CurrencyTracker = CreateFrame("Frame")

-------------------------------------------------
-- DEFAULTS
-------------------------------------------------

local DEFAULT_CURRENCIES = { 3284, 3286, 3288, 3290 }

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

    CurrencyTrackerDB.currencies = CurrencyTrackerDB.currencies or CopyTable(DEFAULT_CURRENCIES)
    CurrencyTrackerDB.fontSize = CurrencyTrackerDB.fontSize or 14
    CurrencyTrackerDB.opacity = CurrencyTrackerDB.opacity or 0.3
    CurrencyTrackerDB.showGold = CurrencyTrackerDB.showGold or false
    CurrencyTrackerDB.position = CurrencyTrackerDB.position or { "CENTER", "CENTER", 0, 0 }
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

    for _, line in ipairs(self.lines) do
        line:Hide()
    end

    wipe(self.lines)

    local fontSize = CurrencyTrackerDB.fontSize
    local yOffset = -5
    local width = 0

    for _, id in ipairs(CurrencyTrackerDB.currencies) do
        local info = C_CurrencyInfo.GetCurrencyInfo(id)
        if info and info.name then
            local line = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            line:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            line:SetPoint("TOPLEFT", 10, yOffset)

            local text = "|T" .. info.iconFileID .. ":" .. fontSize .. ":" .. fontSize .. "|t "
                .. info.name .. " " .. info.quantity .. "/" .. info.maxQuantity

            line:SetText(text)

            yOffset = yOffset - (fontSize + 6)
            width = math.max(width, line:GetStringWidth())
            table.insert(self.lines, line)
        end
    end

    if CurrencyTrackerDB.showGold then
        local line = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        line:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
        line:SetPoint("TOPLEFT", 10, yOffset)
        line:SetText(C_CurrencyInfo.GetCoinTextureString(GetMoney()))
        yOffset = yOffset - (fontSize + 6)
        width = math.max(width, line:GetStringWidth())
        table.insert(self.lines, line)
    end

    f:SetSize(width + 20, math.abs(yOffset) + 10)
    f.bg:SetColorTexture(0, 0, 0, CurrencyTrackerDB.opacity)
end

-------------------------------------------------
-- SETTINGS WINDOW
-------------------------------------------------

function CurrencyTracker:CreateSettings()
    local f = CreateFrame("Frame", "CurrencyTrackerSettings", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(520, 500)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER")
    f.title:SetText("Currency Tracker Settings")

    -------------------------------------------------
    -- TAB BUTTONS
    -------------------------------------------------

    local tab1 = CreateFrame("Button", nil, f, "PanelTabButtonTemplate")
    tab1:SetID(1)
    tab1:SetText("General")
    tab1:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 5, 7)

    local tab2 = CreateFrame("Button", nil, f, "PanelTabButtonTemplate")
    tab2:SetID(2)
    tab2:SetText("All Currencies")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -15, 0)

    PanelTemplates_SetNumTabs(f, 2)
    PanelTemplates_SetTab(f, 1)

    -------------------------------------------------
    -- CONTENT FRAMES (FIXED ANCHORING)
    -------------------------------------------------

    local general = CreateFrame("Frame", nil, f)
    general:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -60)
    general:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)

    local allTab = CreateFrame("Frame", nil, f)
    allTab:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -60)
    allTab:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    allTab:Hide()

    local function SelectTab(id)
        PanelTemplates_SetTab(f, id)
        general:SetShown(id == 1)
        allTab:SetShown(id == 2)
    end

    tab1:SetScript("OnClick", function() SelectTab(1) end)
    tab2:SetScript("OnClick", function() SelectTab(2) end)

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

    local resetBtn = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 25)
    resetBtn:SetPoint("TOPLEFT", goldCheck, "BOTTOMLEFT", 0, -10)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        local f = CurrencyTracker.frame
        CurrencyTrackerDB.position = { "CENTER", "CENTER", 0, 0 }
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)

    local slider = CreateFrame("Slider", nil, general, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -40)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(200)
    slider:SetValue(CurrencyTrackerDB.opacity)
    slider:SetScript("OnValueChanged", function(self, value)
        CurrencyTrackerDB.opacity = value
        CurrencyTracker:UpdateDisplay()
    end)

    slider.label = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.label:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.label:SetText("Background Opacity")

    -------------------------------------------------
    -- ALL CURRENCIES TAB (SCROLL + SEARCH)
    -------------------------------------------------

    -- Search Box
    local searchBox = CreateFrame("EditBox", nil, allTab, "SearchBoxTemplate")
    searchBox:SetPoint("TOPLEFT", allTab, "TOPLEFT", 0, -5)
    searchBox:SetPoint("TOPRIGHT", allTab, "TOPRIGHT", -20, -5)
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)

    -- Scroll Frame
    local scroll = CreateFrame("ScrollFrame", nil, allTab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -5)
    scroll:SetPoint("BOTTOMRIGHT", -30, 5)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local checkboxes = {}

    local function RebuildCurrencyList()
        -- Clear old checkboxes
        for _, cb in ipairs(checkboxes) do
            cb:Hide()
        end
        wipe(checkboxes)

        local filter = searchBox:GetText()
        if filter then
            filter = string.lower(filter)
        end

        local y = -5

        for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(i)

            if info and not info.isHeader then
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

                    check:SetChecked(tContains(CurrencyTrackerDB.currencies, info.currencyID))

                    check:SetScript("OnClick", function(self)
                        if self:GetChecked() then
                            table.insert(CurrencyTrackerDB.currencies, info.currencyID)
                        else
                            for k, v in ipairs(CurrencyTrackerDB.currencies) do
                                if v == info.currencyID then
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

    searchBox:SetScript("OnTextChanged", function()
        RebuildCurrencyList()
    end)

    RebuildCurrencyList()


    self.settings = f
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
-- EVENTS
-------------------------------------------------

CurrencyTracker:RegisterEvent("PLAYER_LOGIN")
CurrencyTracker:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

CurrencyTracker:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        self:CreateDisplay()
        self:CreateMinimapButton()
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        self:UpdateDisplay()
    end
end)
