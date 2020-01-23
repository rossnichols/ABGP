function ABGP:HookTooltips()
    for _, tt in pairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do
        tt:HookScript("OnTooltipSetItem", function(self)
            local value = ABGP:GetItemValue(self:GetItem());
            if value then
                self:AddDoubleLine("ABP GP Value: ", value.gp, 0.58, 0.89, 1, 1, 1, 1);
                self:AddDoubleLine("ABP Priorities: ", table.concat(value.priority, ", "), 0.58, 0.89, 1, 1, 1, 1);
            end
        end);
    end
end
