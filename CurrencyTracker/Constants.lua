CurrencyTracker = CurrencyTracker or CreateFrame("Frame")

CurrencyTracker.CrestFrameWidth = 200
CurrencyTracker.CrestFrameHeight = 42

CurrencyTracker.AdventurerCrestID = 3442
CurrencyTracker.VeteranCrestID = 3443
CurrencyTracker.ChampionCrestID = 3444
CurrencyTracker.HeroCrestID = 3445
CurrencyTracker.MythCrestID = 3446
CurrencyTracker.NebulousVoidcoreID = 3418

CurrencyTracker.DEFAULT_CURRENCIES = {
    CurrencyTracker.AdventurerCrestID,
    CurrencyTracker.VeteranCrestID,
    CurrencyTracker.ChampionCrestID,
    CurrencyTracker.HeroCrestID,
    CurrencyTracker.MythCrestID,
    CurrencyTracker.NebulousVoidcoreID
}

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
