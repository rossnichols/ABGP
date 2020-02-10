local function ShouldAnnounceLoot()
    return IsAltKeyDown() and ABGP:IsPrivileged();
end

local function CanUseRaidWarning()
    if not IsInRaid() then return false; end

    local player = UnitName("player");
    for i = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(i);
        if name == player then
            return (rank > 0);
        end
    end

    return false;
end

local function SendAnnounceMessage(msg)
    if CanUseRaidWarning() then
        SendChatMessage(msg, "RAID_WARNING");
        return true;
    elseif ABGP.Debug then
        SendChatMessage(msg, "WHISPER", nil, UnitName("player"));
        return true;
    end
    return false;
end

local function AnnounceLoot(itemLink)
    if not (itemLink and ShouldAnnounceLoot()) then
        return false;
    end
    local value = ABGP:GetItemValue(string.match(itemLink, "%[(.*)%]"));
    if value then
        local notes = "";
        if value.notes then
            notes = ", Notes: " .. value.notes
        end
        if value.gp == 0 then
            return SendAnnounceMessage(string.format(
                "Now distributing %s - please roll if you want this item! No GP cost, Priority: %s%s.",
                itemLink,
                table.concat(value.priority, ", "),
                notes));
        else
            local ret = SendAnnounceMessage(string.format(
                "Now distributing %s - please whisper %s if you want this item! GP cost: %d, Priority: %s%s.",
                itemLink,
                UnitName("player"),
                value.gp,
                table.concat(value.priority, ", "),
                notes));
            if ret then
                ABGP:ShowDistrib(itemLink);
            end
            return ret;
        end
    else
        return SendAnnounceMessage(string.format(
            "Now distributing %s - please roll if you want this item! No GP cost.",
            itemLink));
    end
    return false;
end

local function ShouldAutoAnnounce()
    return IsMasterLooter() and ABGP:IsPrivileged();
end

local function ItemIsBoP(item)
    local bindType = select(14, GetItemInfo(item.link));
    return (bindType == 1);
end

local function ItemShouldTriggerAutoAnnounce(item)
    -- An item above the ML threshold that has a GP cost will trigger auto-announce.
    local hasGP = ABGP:GetItemValue(item.item);
    return item.quality >= GetLootThreshold() and hasGP and ItemIsBoP(item);
end

local function ItemShouldBeAutoAnnounced(item)
    if ItemShouldTriggerAutoAnnounce(item) then return true; end

    -- In addition to any item from above, BoP items above the loot threshold will also be announced.
    return item.quality >= GetLootThreshold() and ItemIsBoP(item);
end

function ABGP:AddAnnounceHooks()
    self:RegisterModifiedItemClickFn(AnnounceLoot);

    -- Create auto-announce frame
    local lastAnnounced;
    local frame = CreateFrame("FRAME");
    frame:RegisterEvent("LOOT_OPENED");
    frame:SetScript("OnEvent", function(self, event, ...)
        if not ShouldAutoAnnounce() then
            return;
        end

        local loot = GetLootInfo();
        local announce = false;

        -- Check for an item that will trigger auto-announce.
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item then
                item.link = GetLootSlotLink(i);
                if ItemShouldTriggerAutoAnnounce(item) then
                    announce = true;
                end
            end
        end
        if not announce then return; end

        -- Check to see if the last announced target was this one.
        local useTarget = UnitExists("target") and not UnitIsFriend('player', 'target') and UnitIsDead('target');
        local targetGUID = useTarget and UnitGUID("target") or "<no target>";
        if targetGUID == lastAnnounced then return; end
        lastAnnounced = targetGUID;

        -- Send messages for each item that meets announcement criteria.
        SendAnnounceMessage(useTarget
            and string.format("Items from %s:", UnitName("target"))
            or "Items from loot:");
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and ItemShouldBeAutoAnnounced(item) then
                SendAnnounceMessage(GetLootSlotLink(i));
            end
        end
    end);
end
