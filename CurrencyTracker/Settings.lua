CurrencyTracker = _G.CurrencyTracker

function CurrencyTracker:CreateSettings()
    local settings = CreateFrame("Frame", "CurrencyTrackerSettings", UIParent, "ButtonFrameTemplate")
    settings:SetSize(520, 500)
    settings:SetPoint("CENTER")
    settings:SetFrameStrata("DIALOG")
    settings:SetToplevel(true)
    settings:SetMovable(true)
    settings:EnableMouse(true)
    settings:RegisterForDrag("LeftButton")
    settings:SetScript("OnDragStart", settings.StartMoving)
    settings:SetScript("OnDragStop", settings.StopMovingOrSizing)

    -------------------------------------------------
    -- TITLE
    -------------------------------------------------
    settings:SetTitle("Currency Tracker Settings")

    -------------------------------------------------
    -- Portrait Texture
    -------------------------------------------------
    settings:SetPortraitTextureRaw(5868902)

    -------------------------------------------------
    -- CONTENT CONTAINER
    -------------------------------------------------
    settings.content = settings.Inset
    settings:Hide()

    -------------------------------------------------
    -- TAB BUTTONS
    -------------------------------------------------
    local tab1 = CreateFrame("Button", nil, settings, "PanelTabButtonTemplate")
    tab1:SetID(1)
    tab1:SetText("General")
    tab1:SetPoint("TOPLEFT", settings, "BOTTOMLEFT", 15, 5)

    local tab2 = CreateFrame("Button", nil, settings, "PanelTabButtonTemplate")
    tab2:SetID(2)
    tab2:SetText("All Currencies")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -15, 0)

    local tab3 = CreateFrame("Button", nil, settings, "PanelTabButtonTemplate")
    tab3:SetID(3)
    tab3:SetText("Item Upgrade")
    tab3:SetPoint("LEFT", tab2, "RIGHT", -15, 0)

    local tab4 = CreateFrame("Button", nil, settings, "PanelTabButtonTemplate")
    tab4:SetID(4)
    tab4:SetText("Crest Tracker")
    tab4:SetPoint("LEFT", tab3, "RIGHT", -15, 0)

    PanelTemplates_SetNumTabs(settings, 4)
    PanelTemplates_SetTab(settings, 1)

    -------------------------------------------------
    -- CONTENT FRAMES (FIXED ANCHORING)
    -------------------------------------------------
    local general = CreateFrame("Frame", nil, settings.content)
    general:SetAllPoints()

    local allTab = CreateFrame("Frame", nil, settings.content)
    allTab:SetAllPoints()
    allTab:Hide()

    local IUTab = CreateFrame("Frame", nil, settings.content)
    IUTab:SetAllPoints()
    IUTab:Hide()

    local CrestTab = CreateFrame("Frame", nil, settings.content)
    CrestTab:SetAllPoints()
    CrestTab:Hide()

    local function SelectTab(id)
        PanelTemplates_SetTab(settings, id)
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

    local CrestBarCheck = CreateFrame("CheckButton", nil, general, "UICheckButtonTemplate")
    CrestBarCheck:SetPoint("TOPLEFT", goldCheck, "BOTTOMLEFT", 0, -5)
    CrestBarCheck.text:SetText("Show Progress Bar for Crests")
    CrestBarCheck:SetChecked(CurrencyTrackerDB.showCrestBar)
    CrestBarCheck:SetScript("OnClick", function(self)
        CurrencyTrackerDB.showCrestBar = self:GetChecked()
        CurrencyTracker:UpdateDisplay()
    end)

    local resetBtn = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 25)
    resetBtn:SetPoint("TOPLEFT", CrestBarCheck, "BOTTOMLEFT", 0, -10)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        local f = CurrencyTracker.frame
        CurrencyTrackerDB.position = { "CENTER", "CENTER", 0, 0 }
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)

    -------------------------------------------------
    -- RELOAD UI BUTTON
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
    uncheckBtn:SetPoint("TOPRIGHT", allTab, "TOPRIGHT", -20, -10)
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
        for _, id in ipairs(CurrencyTracker.DEFAULT_CURRENCIES) do
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
                            if not tContains(CurrencyTrackerDB.currencies, currencyID) then
                                table.insert(CurrencyTrackerDB.currencies, currencyID)
                            end
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
    self.settings = settings
    self:UpdateUpgradeGoldDisplay()

    -------------------------------------------------
    -- Item Upgrade gold tab
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
    upgradeSpentText:SetText(CurrencyTracker:GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpent))
    upgradeSpentText:SetFontHeight(fontSizeGold)
    upgradeSpentText:SetTextColor(0.25, 0.78, 0.92)
    self.upgradeSpentText = upgradeSpentText

    local xpacText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpacText:SetPoint("TOPLEFT", upgradeSpentText, "BOTTOMLEFT", 0, yOffset)
    xpacText:SetText("Current Xpac:")
    xpacText:SetTextColor(0.77, 0.12, 0.23)

    local upgradeSpentXpacText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upgradeSpentXpacText:SetPoint("TOPLEFT", xpacText, "BOTTOMLEFT", 0, yOffset)
    upgradeSpentXpacText:SetText(CurrencyTracker:GetCoinAtlasString(CurrencyTrackerDB.upgradeGoldSpentXpac))
    upgradeSpentXpacText:SetFontHeight(fontSizeGold)
    upgradeSpentXpacText:SetTextColor(0.77, 0.12, 0.23)
    self.upgradeSpentXpacText = upgradeSpentXpacText

    local accountFontColor = CurrencyTracker.CURRENCY_COLORS[CurrencyTracker.HeroCrestID]
    local accountText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    accountText:SetPoint("TOPLEFT", upgradeSpentXpacText, "BOTTOMLEFT", 0, yOffset)
    accountText:SetText("Account:")
    accountText:SetTextColor(accountFontColor[1], accountFontColor[2], accountFontColor[3])

    local upgradeSpentXpacAccountText = IUTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upgradeSpentXpacAccountText:SetPoint("TOPLEFT", accountText, "BOTTOMLEFT", 0, yOffset)
    upgradeSpentXpacAccountText:SetText(CurrencyTracker:GetCoinAtlasString(CurrencyTrackerAcctDB.upgradeGoldSpentAcct))
    upgradeSpentXpacAccountText:SetFontHeight(fontSizeGold)
    upgradeSpentXpacAccountText:SetTextColor(accountFontColor[1], accountFontColor[2], accountFontColor[3])
    self.upgradeSpentXpacAccountText = upgradeSpentXpacAccountText
    local resetUpgrade = CreateFrame("Button", nil, IUTab, "UIPanelButtonTemplate")

    resetUpgrade:SetSize(160, 25)
    resetUpgrade:SetPoint("BOTTOMRIGHT", -10, 10)
    resetUpgrade:SetText("Reset Gold (Season)")

    resetUpgrade:SetScript("OnClick", function()
        CurrencyTrackerDB.upgradeGoldSpent = 0
        upgradeSpentText:SetText(
            "Gold Spent on Item Upgrades: " ..
            CurrencyTracker:GetCoinAtlasString(0)
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
    CreateCrestRow(0, "Adventurer Crest:", CurrencyTracker.AdventurerCrestID)
    CreateCrestRow(1, "Veteran Crest:", CurrencyTracker.VeteranCrestID)
    CreateCrestRow(2, "Champion Crest:", CurrencyTracker.ChampionCrestID)
    CreateCrestRow(3, "Hero Crest:", CurrencyTracker.HeroCrestID)
    CreateCrestRow(4, "Myth Crest:", CurrencyTracker.MythCrestID)
    CreateCrestRow(5, "Nebulous Voidcore:", CurrencyTracker.NebulousVoidcoreID)

    local resetAllBtn = CreateFrame("Button", nil, CrestTab, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(180, 25)
    resetAllBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    resetAllBtn:SetText("Reset All Crest Colors")

    resetAllBtn:SetScript("OnClick", function()
        CurrencyTrackerAcctDB.crestColors = CurrencyTracker:CopyTable(CurrencyTracker.CURRENCY_COLORS)

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

function CurrencyTracker:CreateReloadButton(parent)
    local reloadBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    reloadBtn:SetSize(140, 25)
    reloadBtn:SetPoint("BOTTOMLEFT", 10, 10)
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
            for _, id in ipairs(CurrencyTracker.DEFAULT_CURRENCIES) do
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
            local default = CurrencyTracker.CURRENCY_COLORS[currencyID]
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
function CurrencyTracker:ReloadButtonShow(playerName)
    for _, name in ipairs(CurrencyTracker.DebugPlayers) do
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
