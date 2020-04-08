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
                    local limit = 3;
                    local gpHistory = _G.ABGP_Data[value.phase].gpHistory;

                    -- First pass: count
                    local count = 0;
                    for _, data in ipairs(gpHistory) do
                        if data.item == itemName then
                            count = count + 1;
                        end
                    end

                    if count > 0 then
                        local extra = "";
                        if count > limit then
                            extra = (" (%d of %d)"):format(limit, count);
                        end
                        self:AddLine(("Item History%s:"):format(extra), c[1], c[2], c[3]);
                        count = 0;

                        for _, data in ipairs(gpHistory) do
                            if data.item == itemName then
                                count = count + 1;
                                if count > limit then
                                    break;
                                end
                                self:AddDoubleLine(ABGP:ColorizeName(data.player), data.date, 1, 1, 1, 1, 1, 1);
                            end
                        end
                    end
                end
            end
        end);
    end
end
