-------------------------------------------------------------------------------
--  EllesmereUIItemCount_Options.lua
--  The "Item Count" page: the row that used to sit in Bags > Extras, now the
--  "Item Count" row of the "Dworak" sidebar section, which EllesmereUIDworak
--  registers through EllesmereUI's Plugin API (EllesmereUI\PLUGINS_API.md),
--  so an EllesmereUI update never overwrites or breaks it.
--    Item Count on Tooltip (toggle, + inline cog: Show Count For, Item Count
--    Color, Bags Color, Bank Color)
--  Without EllesmereUIDworak the tooltip lines still work; /itemcount then
--  sets them from chat.
-------------------------------------------------------------------------------
local _, ns = ...
local Get, Set = ns.Get, ns.Set

local PAGE = "Item Count"

local function Prebuilding()
    if type(EllesmereUI.IsSearchPrebuild) == "function" then
        return EllesmereUI.IsSearchPrebuild()
    end
    return EllesmereUI._prebuilding
end

local function Refresh()
    if EllesmereUI.RefreshPage then EllesmereUI:RefreshPage() end
end

local function ColorRow(label, key)
    return { type = "colorpicker", label = label,
             get = function() return ns.GetColor(key) end,
             set = function(r, g, b) ns.SetColor(key, r, g, b) end }
end

local function BuildPage(pageName, parent, yOffset)
    local W = EllesmereUI.Widgets
    local y = yOffset
    local _, h
    parent._showRowDivider = true

    _, h = W:SectionHeader(parent, "ITEM COUNT", y);  y = y - h

    local countRow
    countRow, h = W:DualRow(parent, y,
        { type = "toggle", text = "Item Count on Tooltip",
          tooltip = "Add how many of the item you have to item tooltips: the total, then how many are in your "
              .. "bags and in your bank. Bank counts are complete once you have opened your bank on this character.",
          getValue = function() return Get("enabled") == true end,
          setValue = function(v)
              Set("enabled", v and true or false)
              Refresh()  -- the cog's disabled state
          end },
        { type = "label", text = "" }
    );  y = y - h

    if not Prebuilding() and EllesmereUI.BuildInlineCog then
        EllesmereUI.BuildInlineCog(countRow._leftRegion, {
            chain = false,
            disabled = function() return Get("enabled") ~= true end,
            disabledTooltip = "Item Count on Tooltip",
            title = "Item Count Options",
            rows = {
                { type = "dropdown", label = "Show Count For",
                  values = ns.MODES, order = ns.MODE_ORDER,
                  get = function() return Get("mode") end,
                  set = function(v) Set("mode", v) end },
                ColorRow("Item Count Color", "color"),
                ColorRow("Bags Color", "bagsColor"),
                ColorRow("Bank Color", "bankColor"),
            },
        })
    end

    return math.abs(y)
end

local DW = EllesmereUIDworak
if not (DW and DW.AddModule) then return end  -- tooltip still works; /itemcount for settings

DW.AddModule({
    key         = "ItemCount",
    title       = "Item Count",
    order       = 20,
    description = "How many of an item you have, on its tooltip: total, bags and bank.",
    pages       = { PAGE },
    buildPage   = BuildPage,
    onReset = function()
        ns.Reset()
        if EllesmereUI.InvalidatePageCache then EllesmereUI:InvalidatePageCache() end
    end,
})

function ns.OpenOptions()
    return DW.Open("ItemCount") and true or false
end

function ns.RefreshOptions()
    if EllesmereUI.InvalidatePageCache then pcall(EllesmereUI.InvalidatePageCache, EllesmereUI) end
end
