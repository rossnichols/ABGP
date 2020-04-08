local _G = _G;
local ABGP = ABGP;

local IsAltKeyDown = IsAltKeyDown;
local table = table;
local pairs = pairs;
local ipairs = ipairs;

function ABGP:HookTooltips()
    for _, tt in pairs({ _G.GameTooltip, _G.ItemRefTooltip, _G.ShoppingTooltip1, _G.ShoppingTooltip2 }) do
        tt:HookScript("OnTooltipSetItem", function(self)
            local itemName = self:GetItem();
            local value = ABGP:GetItemValue(itemName);
            if value then
                local c = ABGP.ColorTable;
                self:AddDoubleLine("ABP GP Value: ", value.gp, c[1], c[2], c[3], 1, 1, 1);
                self:AddDoubleLine("ABP Priorities: ", table.concat(value.priority, ", "), c[1], c[2], c[3], 1, 1, 1);
                if value.notes then
                    self:AddDoubleLine("ABP Notes: ", value.notes, c[1], c[2], c[3], 1, 1, 1);
                end

                if IsAltKeyDown() then
                    local printedHeader = false;
                    local gpHistory = _G.ABGP_Data[value.phase].gpHistory;
                    for _, data in ipairs(gpHistory) do
                        if data.item == itemName then
                            if not printedHeader then
                                printedHeader = true;
                                self:AddLine("Item History:", c[1], c[2], c[3]);
                            end
                            self:AddDoubleLine(ABGP:ColorizeName(data.player), data.date, 1, 1, 1, 1, 1, 1);
                        end
                    end
                end
            end
        end);
    end
end
