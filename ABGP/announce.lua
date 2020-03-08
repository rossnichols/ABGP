local ABGP = ABGP;
local IsAltKeyDown = IsAltKeyDown;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local GetNumGroupMembers = GetNumGroupMembers;
local GetRaidRosterInfo = GetRaidRosterInfo;
local SendChatMessage = SendChatMessage;
local IsMasterLooter = IsMasterLooter;
local GetItemInfo = GetItemInfo;
local GetLootThreshold = GetLootThreshold;
local CreateFrame = CreateFrame;
local GetLootInfo = GetLootInfo;
local GetNumLootItems = GetNumLootItems;
local GetLootSlotLink = GetLootSlotLink;
local UnitExists = UnitExists;
local UnitIsFriend = UnitIsFriend;
local UnitIsDead = UnitIsDead;
local UnitGUID = UnitGUID;
local GetServerTime = GetServerTime;
local select = select;

local bossKills = {};
local lastBoss;

local function ShouldDistributeLoot()
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

local function DistributeLoot(itemLink)
    if not (itemLink and ShouldDistributeLoot()) then
        return false;
    end
    ABGP:ShowDistrib(itemLink);
    return true;
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

function ABGP:AddItemHooks()
    self:RegisterModifiedItemClickFn(DistributeLoot);

    -- Create auto-announce frame
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

        -- Determine the source of the loot. Use current target if it seems appropriate,
        -- otherwise use the last boss killed.
        local source = lastBoss;
        if UnitExists("target") and not UnitIsFriend('player', 'target') and UnitIsDead('target') then
            source = UnitName("target");
        end

        -- Limit auto-announce to boss kills, and only announce once per boss.
        if bossKills[source] and not bossKills[source].announced then
            bossKills[source].announced = true;

            -- Send messages for each item that meets announcement criteria.
            SendAnnounceMessage(("Loot from %s:"):format(source));
            for i = 1, GetNumLootItems() do
                local item = loot[i];
                if item and ItemShouldBeAutoAnnounced(item) then
                    SendAnnounceMessage(GetLootSlotLink(i));
                end
            end
        end
    end);
end

function ABGP:AnnounceOnBossKilled(id, name)
    bossKills[name] = { time = GetServerTime(), announced = false };
    lastBoss = name;
end
