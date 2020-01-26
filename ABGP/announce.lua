local function ShouldAnnounceLoot()
    return IsShiftKeyDown() and ABGP:IsPrivileged();
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

-- local function GetChatChannel()
--     if CanUseRaidWarning() then
--         return "RAID_WARNING";
--     elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
--         return "INSTANCE_CHAT";
--     elseif GetNumGroupMembers() > 0 and IsInRaid() then
--         return "RAID";
--     elseif IsInGroup() then
--         return "PARTY";
--     end
-- end

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
    if not (itemLink and ShouldAnnounceLoot()) then return; end
    local value = ABGP:GetItemValue(GetItemInfo(itemLink));
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
            return SendAnnounceMessage(string.format(
                "Now distributing %s - please whisper %s if you want this item! GP cost: %d, Priority: %s%s.",
                itemLink,
                UnitName("player"),
                value.gp,
                table.concat(value.priority, ", "),
                notes));
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
    local bindType = select(14, GetItemInfo(item.item));
    return (bindType == 1) or ABGP.Debug;
end

local function ItemShouldTriggerAutoAnnounce(item)
    -- An item above the ML threshold that has a GP cost will trigger auto-announce.
    local hasGP = ABGP:GetItemValue(item.item) or ABGP.Debug;
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
        if not ShouldAutoAnnounce() then return; end

        local loot = GetLootInfo();
        local announce = false;

        -- Check for an item that will trigger auto-announce.
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and ItemShouldTriggerAutoAnnounce(item) then
                announce = true;
                break;
            end
        end
        if not announce then return; end

        -- Check to see if the last announced target was this one.
        -- If nothing is targeted, we'll announce each time since we
        -- can't tell different non-target loot sources apart.
        local useTarget = UnitExists("target") and UnitIsEnemy("target");
        if useTarget then
            local targetGUID = UnitGUID("target");
            if targetGUID == lastAnnounced then return; end
            lastAnnounced = targetGUID;
        end

        -- Send messages for each item that meets announcement criteria.
        SendAnnounceMessage(useTarget
            and string.format("Items from %s:", UnitName("target"))
            or "Items from the void:");
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and ItemShouldBeAutoAnnounced(item) then
                SendAnnounceMessage(GetLootSlotLink(i));
            end
        end
    end);
end
