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
    elseif ABGP.Debug then
        SendChatMessage(msg, "WHISPER", nil, UnitName("player"));
    end
end

local function AnnounceLoot(itemLink)
    if not (itemLink and ShouldAnnounceLoot()) then return; end
    local value = ABGP:GetItemValue(GetItemInfo(itemLink));
    if value then
        if value.gp == 0 then
            SendAnnounceMessage(string.format(
                "Now distributing %s - please roll if you want this item! No GP cost, Priority: %s.",
                itemLink,
                table.concat(value.priority, ", ")));
        else
            SendAnnounceMessage(string.format(
                "Now distributing %s - please whisper %s if you want this item! GP cost: %d, Priority: %s.",
                itemLink,
                UnitName("player"),
                value.gp,
                table.concat(value.priority, ", ")));
        end
    else
        SendAnnounceMessage(string.format(
            "Now distributing %s - please roll if you want this item! No GP cost.",
            itemLink));
    end
end

local function ShouldAutoAnnounce()
    return IsMasterLooter() and ABGP:IsPrivileged();
end

local function ItemShouldTriggerAutoAnnounce(item)
    -- An item above the ML threshold that has a GP cost will trigger auto-announce.
    local hasGP = ABGP:GetItemValue(item.item) or ABGP.Debug;
    return item.quality >= GetLootThreshold() and hasGP;
end

local function ItemShouldBeAutoAnnounced(item)
    if ItemShouldTriggerAutoAnnounce(item) then return true; end

    -- In addition to any item from above, BoP items above the loot threshold will also be announced.
    local bindType = select(14, GetItemInfo(item.item));
    local isBoP = (bindType == 1) or ABGP.Debug;
    return item.quality >= GetLootThreshold() and isBoP;
end

function ABGP:AddAnnounceHooks()
    -- Hook loot buttons
    for _, frame in pairs({ LootButton1, LootButton2, LootButton3, LootButton4 }) do
        frame:HookScript("OnClick", function(self, event)
            AnnounceLoot(GetLootSlotLink(self.slot));
        end);
    end

    -- Hook bag buttons
    local bag = 1;
    while _G["ContainerFrame" .. bag .. "Item1"] do
        local slot = 1;
        while _G["ContainerFrame" .. bag .. "Item" .. slot] do
            local frame = _G["ContainerFrame" .. bag .. "Item" .. slot];
            frame:HookScript("OnClick", function(self, event)
                AnnounceLoot(GetContainerItemLink(self:GetParent():GetID(), self:GetID()));
            end);
            slot = slot + 1;
        end
        bag = bag + 1;
    end

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
        if UnitExists("target") then
            local targetGUID = UnitGUID("target");
            if targetGUID == lastAnnounced then return; end
            lastAnnounced = targetGUID;
        end

        -- Send messages for each item that meets announcement criteria.
        SendAnnounceMessage(UnitExists("target")
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
