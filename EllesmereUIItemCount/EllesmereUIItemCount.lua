-------------------------------------------------------------------------------
--  EllesmereUIItemCount.lua   (standalone add-on, no EllesmereUI file edited)
--  Item Count on Tooltip: adds how many of the hovered item you own to item
--  tooltips (GameTooltip and ItemRefTooltip). "Show Count For":
--    "both" (default) = Item Count (total) + Bags + Bank
--    "bags"           = Bags only
--    "bank"           = Bank only
--  Lines are always shown, zeros included (e.g. "Bank 0").
--  Counts: C_Item.GetItemCount(id, false) = bags; (id, true, false, true) =
--  total; bank = total - bags. Bank counts come from the game's own bank
--  cache, so they are complete once the bank has been opened on this character.
--
--  Settings live in this add-on's own SavedVariables (EllesmereUIItemCountDB),
--  so an EllesmereUI update cannot remove them. Formerly part of
--  EllesmereUIBags.lua (Bags > Extras); on first login the old Bags profile
--  values (show-for mode and colours) are copied over once if present.
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DEFAULTS = {
    enabled   = true,
    mode      = "both",                         -- both | bags | bank
    color     = { r = 1,   g = 0.82, b = 0   }, -- Item Count (total) row
    bagsColor = { r = 0.8, g = 0.8,  b = 0.8 }, -- Bags row
    bankColor = { r = 0.8, g = 0.8,  b = 0.8 }, -- Bank row
}
ns.DEFAULTS = DEFAULTS
ns.MODES = { both = "Bags + Bank", bags = "Bags", bank = "Bank" }
ns.MODE_ORDER = { "both", "bags", "bank" }

local function CopyColor(c)
    return { r = c.r, g = c.g, b = c.b }
end

local function DB()
    local db = EllesmereUIItemCountDB
    if type(db) ~= "table" then
        db = {}
        EllesmereUIItemCountDB = db
    end
    return db
end
ns.DB = DB

function ns.Get(key)
    local v = DB()[key]
    if v == nil then
        v = DEFAULTS[key]
        if type(v) == "table" then v = CopyColor(v) end
    end
    return v
end

function ns.Set(key, value)
    DB()[key] = value
end

function ns.GetColor(key)
    local c = DB()[key]
    if type(c) == "table" and c.r then return c.r, c.g, c.b end
    local d = DEFAULTS[key]
    return d.r, d.g, d.b
end

function ns.SetColor(key, r, g, b)
    DB()[key] = { r = r, g = g, b = b }
end

function ns.Reset()
    wipe(DB())
    DB().migrated = true
end

local function Print(msg)
    local p = (EllesmereUI and EllesmereUI.Print) or print
    p("|cff0cd29dItem Count:|r " .. msg)
end
ns.Print = Print

-------------------------------------------------------------------------------
--  Tooltip lines
-------------------------------------------------------------------------------
local GetCount = (C_Item and C_Item.GetItemCount) or GetItemCount

local function Loc(s)
    local L = EllesmereUI and EllesmereUI.L
    if type(L) == "function" then
        local ok, t = pcall(L, s)
        if ok and type(t) == "string" then return t end
    end
    return s
end

local TAG, TAG_BAGS, TAG_BANK

-- Skip a tooltip that already carries our lines (post-calls can repeat).
local function HasCountLine(tooltip, name)
    local n = tooltip:NumLines() or 0
    for i = n, math.max(1, n - 8), -1 do
        local fs = _G[name .. "TextLeft" .. i]
        local txt = fs and fs:GetText()
        if txt and not (issecretvalue and issecretvalue(txt)) then
            if txt == TAG or txt == "  " .. TAG_BAGS or txt == "  " .. TAG_BANK
               or txt == TAG_BAGS or txt == TAG_BANK then
                return true
            end
        end
    end
    return false
end

local function ItemCountHook(tooltip, data)
    if ns.Get("enabled") ~= true then return end
    if not data or not data.id then return end
    if issecretvalue and issecretvalue(data.id) then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    local ok, name = pcall(tooltip.GetName, tooltip)
    if not ok or not name then return end

    if not TAG then
        TAG, TAG_BAGS, TAG_BANK = Loc("Item Count"), Loc("Bags"), Loc("Bank")
    end

    local id = data.id
    local okB, bags = pcall(GetCount, id, false, false, false)
    local okT, total = pcall(GetCount, id, true, false, true)
    bags = (okB and tonumber(bags)) or 0
    total = (okT and tonumber(total)) or bags
    local bank = total - bags
    if bank < 0 then bank = 0 end

    if HasCountLine(tooltip, name) then return end

    -- Row colours: label and number share the row's colour.
    local mode = ns.Get("mode")
    local tr, tg, tb = ns.GetColor("color")
    local br, bg, bb = ns.GetColor("bagsColor")
    local kr, kg, kb = ns.GetColor("bankColor")
    if mode == "bags" then
        tooltip:AddDoubleLine(TAG_BAGS, tostring(bags), br, bg, bb, br, bg, bb)
    elseif mode == "bank" then
        tooltip:AddDoubleLine(TAG_BANK, tostring(bank), kr, kg, kb, kr, kg, kb)
    else
        tooltip:AddDoubleLine(TAG, tostring(total), tr, tg, tb, tr, tg, tb)
        tooltip:AddDoubleLine("  " .. TAG_BAGS, tostring(bags), br, bg, bb, br, bg, bb)
        tooltip:AddDoubleLine("  " .. TAG_BANK, tostring(bank), kr, kg, kb, kr, kg, kb)
    end
    tooltip:Show()
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
   and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        pcall(ItemCountHook, tooltip, data)
    end)
else
    Print("this client has no TooltipDataProcessor, so no counts can be added.")
end

-------------------------------------------------------------------------------
--  One-time import of the old Bags > Extras settings (EllesmereUI <= 9.4 edit)
-------------------------------------------------------------------------------
local function ImportOldBagsSettings()
    local db = DB()
    if db.migrated then return end
    db.migrated = true
    local bdb = EllesmereUI and EllesmereUI._bagsDB
    local p = type(bdb) == "table" and type(bdb.profile) == "table" and bdb.profile
    if not p then return end
    local m = p.bagTooltipItemCountMode
    if m == "both" or m == "bags" or m == "bank" then db.mode = m end
    local function C(old, new)
        local c = p[old]
        if type(c) == "table" and tonumber(c.r) and tonumber(c.g) and tonumber(c.b) then
            db[new] = { r = c.r, g = c.g, b = c.b }
        end
    end
    C("bagTooltipItemCountColor", "color")
    C("bagTooltipItemCountBagsColor", "bagsColor")
    C("bagTooltipItemCountBankColor", "bankColor")
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    pcall(ImportOldBagsSettings)
end)

-------------------------------------------------------------------------------
--  /itemcount            open Dworak > Item Count (or print the status)
--  /itemcount on | off   switch the tooltip lines
--  /itemcount both | bags | bank
-------------------------------------------------------------------------------
local function Status()
    Print((ns.Get("enabled") and "on" or "off") .. ", showing: " .. (ns.MODES[ns.Get("mode")] or "?")
        .. ".  /itemcount on | off | both | bags | bank")
end

SLASH_EUIITEMCOUNT1 = "/itemcount"
SlashCmdList.EUIITEMCOUNT = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg == "on" or msg == "off" then
        ns.Set("enabled", msg == "on")
    elseif ns.MODES[msg] then
        ns.Set("mode", msg)
    elseif msg == "" and ns.OpenOptions and ns.OpenOptions() then
        return
    else
        Status()
        return
    end
    Status()
    if ns.RefreshOptions then ns.RefreshOptions() end  -- the open page shows the new value
end
