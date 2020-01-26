function ABGP:HookTooltips()
    for _, tt in pairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do
        tt:HookScript("OnTooltipSetItem", function(self)
            local value = ABGP:GetItemValue(self:GetItem());
            if value then
                local c = ABGP.ColorTable;
                self:AddDoubleLine("ABP GP Value: ", value.gp, c[1], c[2], c[3], 1, 1, 1);
                self:AddDoubleLine("ABP Priorities: ", table.concat(value.priority, ", "), c[1], c[2], c[3], 1, 1, 1);
                if value.notes then
                    self:AddDoubleLine("ABP Notes: ", value.notes, c[1], c[2], c[3], 1, 1, 1);
                end
            end
        end);
    end
end
