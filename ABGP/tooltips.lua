local _G = _G;
local ABGP = _G.ABGP;

local IsAltKeyDown = IsAltKeyDown;
local UnitName = UnitName;
local table = table;
local pairs = pairs;
local ipairs = ipairs;
local date = date;
local next = next;

function ABGP:HookTooltips()
    for _, tt in pairs({ _G.GameTooltip, _G.ItemRefTooltip, _G.ShoppingTooltip1, _G.ShoppingTooltip2 }) do
        tt:HookScript("OnTooltipSetItem", function(self)
            local itemName = self:GetItem();
            local altShowsPrerelease = ABGP:Get("altShowsPrerelease");
            local store = (altShowsPrerelease and IsAltKeyDown()) and ABGP.ItemStore.PRERELEASE or ABGP.ItemStore.CURRENT;
            local value = ABGP:GetItemValue(itemName, store);
            if value then
                if not value.token then
                    self:AddDoubleLine(("%s Cost:"):format(ABGP:ColorizeText("ABGP")), ABGP:FormatCost(value.gp, value.category, "%s%s"), 1, 1, 1, 1, 1, 1);
                end

                if not value.related then
                    if next(value.priority) then
                        self:AddDoubleLine(("%s Priorities:"):format(ABGP:ColorizeText("ABGP")), table.concat(value.priority, ", "), 1, 1, 1, 1, 1, 1);
                    end
                    if value.notes then
                        self:AddDoubleLine(("%s Notes:"):format(ABGP:ColorizeText("ABGP")), value.notes, 1, 1, 1, 1, 1, 1);
                    end

                    local limit = ABGP:Get("itemHistoryLimit");
                    if limit > 0  and not altShowsPrerelease then
                        if IsAltKeyDown() then
                            local player = UnitName("player");
                            local gpHistory = ABGP:ProcessItemHistory(_G.ABGP_Data2.history.data);

                            local raidGroup = ABGP:GetPreferredRaidGroup();
                            local function shouldShowEntry(entry)
                                if entry[ABGP.ItemHistoryIndex.ITEMLINK] ~= value.itemLink then return false; end
                                local epgp = ABGP:GetActivePlayer(entry[ABGP.ItemHistoryIndex.PLAYER]);
                                if not epgp then return false; end
                                return epgp.raidGroup == raidGroup, entry[ABGP.ItemHistoryIndex.PLAYER] == player;
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
                                            local entryDate = date("%m/%d/%y", data[ABGP.ItemHistoryIndex.DATE]); -- https://strftime.org/
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
                end
                self:AddLine(" ");
            end
        end);
    end
end
