local _G = _G;
local ABGP = _G.ABGP;

local IsAltKeyDown = IsAltKeyDown;
local UnitName = UnitName;
local table = table;
local pairs = pairs;
local ipairs = ipairs;
local date = date;

function ABGP:HookTooltips()
    for _, tt in pairs({ _G.GameTooltip, _G.ItemRefTooltip, _G.ShoppingTooltip1, _G.ShoppingTooltip2 }) do
        tt:HookScript("OnTooltipSetItem", function(self)
            local itemName = self:GetItem();
            local value = ABGP:GetItemValue(itemName);
            if value then
                self:AddDoubleLine(("%s Value:"):format(ABGP:ColorizeText("ABGP")), value.gp, 1, 1, 1, 1, 1, 1);
                self:AddDoubleLine(("%s Priorities:"):format(ABGP:ColorizeText("ABGP")), table.concat(value.priority, ", "), 1, 1, 1, 1, 1, 1);
                if value.notes then
                    self:AddDoubleLine(("%s Notes:"):format(ABGP:ColorizeText("ABGP")), value.notes, 1, 1, 1, 1, 1, 1);
                end

                local limit = ABGP:Get("itemHistoryLimit");
                if limit > 0 then
                    if IsAltKeyDown() then
                        local player = UnitName("player");
                        local gpHistory = ABGP:ProcessItemHistory(_G.ABGP_Data[value.phase].gpHistory);

                        local raidGroup = ABGP:GetPreferredRaidGroup();
                        local function shouldShowEntry(entry)
                            if entry[ABGP.ItemHistoryIndex.ITEMID] ~= value.itemId then return false; end
                            local epgp = ABGP:GetActivePlayer(entry[ABGP.ItemHistoryIndex.PLAYER]);
                            if not (epgp and epgp[value.phase]) then return false; end
                            return epgp[value.phase].gpRaidGroup == raidGroup, entry[ABGP.ItemHistoryIndex.PLAYER] == player;
                        end

                        -- First pass: count
                        local count = 0;
                        local hasSelfEntry = false;
                        for _, data in ipairs(gpHistory) do
                            local shouldShow, isSelf = shouldShowEntry(data);
                            if shouldShow then
                                count = count + 1;
                                if isSelf then hasSelfEntry = true; end
                            end
                        end

                        if count > 0 then
                            local extra = "";
                            if count > limit then
                                extra = (" (%d of %d)"):format(limit, count);
                            end
                            self:AddLine(("%s Item History%s:"):format(
                                ABGP:ColorizeText("ABGP"), extra), 1, 1, 1);
                            count = 0;

                            local showedSelf = false;
                            for _, data in ipairs(gpHistory) do
                                local shouldShow, isSelf = shouldShowEntry(data);
                                if shouldShow then
                                    local skip = hasSelfEntry and not isSelf and not showedSelf and count == limit - 1;
                                    if not skip then
                                        if isSelf then showedSelf = true; end
                                        count = count + 1;
                                        if count > limit then
                                            break;
                                        end
                                        local epgp = ABGP:GetActivePlayer(data[ABGP.ItemHistoryIndex.PLAYER]);
                                        local entryDate = date("%m/%d/%y", data[ABGP.ItemHistoryIndex.EFFECTIVE]); -- https://strftime.org/
                                        self:AddDoubleLine(" " .. ABGP:ColorizeName(epgp.player, epgp.class), entryDate, 1, 1, 1, 1, 1, 1);
                                    end
                                end
                            end
                        else
                            self:AddLine(("%s Item History: (none found)"):format(ABGP:ColorizeText("ABGP")), 1, 1, 1);
                        end
                    else
                        self:AddLine(("%s Item History: (hold %s)"):format(
                            ABGP:ColorizeText("ABGP"), ABGP:ColorizeText("alt")), 1, 1, 1);
                    end
                end
                self:AddLine(" ");
            end
        end);
    end
end
