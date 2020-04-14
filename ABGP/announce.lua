local ABGP = ABGP;
local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local GetLootInfo = GetLootInfo;
local GetNumLootItems = GetNumLootItems;
local GetLootSlotLink = GetLootSlotLink;
local UnitExists = UnitExists;
local UnitIsFriend = UnitIsFriend;
local UnitIsDead = UnitIsDead;
local GetServerTime = GetServerTime;
local GetLootMethod = GetLootMethod;
local select = select;
local table = table;
local ipairs = ipairs;

local bossKills = {};
local lastBoss;

local function ItemShouldBeAutoAnnounced(item)
    -- Announce rare+ BoP items
    return item.quality >= 3 and select(14, GetItemInfo(item.link)) == 1;
end

function ABGP:AnnounceOnLootOpened()
    if GetLootMethod() ~= "master" then return; end
    local loot = GetLootInfo();
    local announce = false;

    -- Check for an item that will trigger auto-announce.
    for i = 1, GetNumLootItems() do
        local item = loot[i];
        if item then
            item.link = GetLootSlotLink(i);
            if ItemShouldBeAutoAnnounced(item) then
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
    if source and bossKills[source] and not bossKills[source].announced then
        -- Send messages for each item that meets announcement criteria.
        local announceItems = {};
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and ItemShouldBeAutoAnnounced(item) then
                table.insert(announceItems, GetLootSlotLink(i));
            end
        end

        local data = { source = source, items = announceItems };
        self:SendComm(self.CommTypes.BOSS_LOOT, data, "BROADCAST");
        self:AnnounceOnBossLoot(data);
    end
end

function ABGP:AnnounceOnBossLoot(data)
    if bossKills[data.source] and not bossKills[data.source].announced then
        bossKills[data.source].announced = true;

        self:Notify("Loot from %s:", self:ColorizeText(data.source));
        for _, itemLink in ipairs(data.items) do
            self:Notify(itemLink);
        end
    end
end

function ABGP:AnnounceOnBossKilled(id, name)
    bossKills[name] = { time = GetServerTime(), announced = false };
    lastBoss = name;
end

function ABGP:AnnounceOnZoneChanged()
    lastBoss = nil;
end
