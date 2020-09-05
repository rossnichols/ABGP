local _G = _G;
local ABGP = _G.ABGP;

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GuildRoster = GuildRoster;
local Ambiguate = Ambiguate;
local UnitName = UnitName;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local UnitIsGroupLeader = UnitIsGroupLeader;
local UnitIsUnit = UnitIsUnit;
local table = table;
local pairs = pairs;
local math = math;

ABGP.Priorities = {};

ABGP.RaidGroups = {
    RED = "RED",
    BLUE = "BLUE",
    SPLITHIGH = "SPLITHIGH",
    SPLITLOW = "SPLITLOW"
};
ABGP.RaidGroupNames = {
    [ABGP.RaidGroups.RED] = "Weekday",
    [ABGP.RaidGroups.BLUE] = "Weekend",
};
ABGP.RaidGroupNamesAll = {
    [ABGP.RaidGroups.RED] = "Weekday",
    [ABGP.RaidGroups.BLUE] = "Weekend",
    [ABGP.RaidGroups.SPLITHIGH] = "Splits (Loot Prio)",
    [ABGP.RaidGroups.SPLITLOW] = "Splits (No Loot Prio)",
};
ABGP.RaidGroupNamesReversed = {
    ["Weekday"] = ABGP.RaidGroups.RED,
    ["Weekend"] = ABGP.RaidGroups.BLUE,
};
ABGP.RaidGroupsSorted = {
    ABGP.RaidGroups.RED,
    ABGP.RaidGroups.BLUE,
};
ABGP.RaidGroupsSortedAll = {
    ABGP.RaidGroups.RED,
    ABGP.RaidGroups.BLUE,
    ABGP.RaidGroups.SPLITHIGH,
    ABGP.RaidGroups.SPLITLOW,
};
ABGP.RaidGroupsSortedReverse = {
    [ABGP.RaidGroups.RED] = 1,
    [ABGP.RaidGroups.BLUE] = 2,
};
local rankData = {
    ["Guild Master"] =   { raidGroup = ABGP.RaidGroups.RED, altRaidGroup = ABGP.RaidGroups.SPLITHIGH, priority = 1 },
    ["Officer"] =        { raidGroup = ABGP.RaidGroups.RED, altRaidGroup = ABGP.RaidGroups.SPLITHIGH, priority = 1 },
    ["Closer"] =         { raidGroup = ABGP.RaidGroups.RED, altRaidGroup = ABGP.RaidGroups.SPLITHIGH, priority = 1 },
    ["Red Lobster"] =    { raidGroup = ABGP.RaidGroups.RED, altRaidGroup = ABGP.RaidGroups.SPLITHIGH, priority = 1 },
    ["Purple Lobster"] = { raidGroup = ABGP.RaidGroups.BLUE, altRaidGroup = ABGP.RaidGroups.SPLITHIGH, priority = 1 },
    ["Blue Lobster"] =   { raidGroup = ABGP.RaidGroups.BLUE, altRaidGroup = ABGP.RaidGroups.SPLITLOW, priority = 2 },
    ["Officer Alt"] =    { raidGroup = ABGP.RaidGroups.BLUE, altRaidGroup = ABGP.RaidGroups.SPLITLOW, priority = 2 },
    ["Lobster Alt"] =    { raidGroup = ABGP.RaidGroups.BLUE, altRaidGroup = ABGP.RaidGroups.SPLITLOW, priority = 2 },
};
local epMins = {
    [ABGP.RaidGroups.RED] = 0,
    [ABGP.RaidGroups.BLUE] = 0,
};

function ABGP:GetMinEP(raidGroup)
    return self:IsPrivileged() and epMins[raidGroup] or 0;
end

function ABGP:GetGPDecayInfo()
    return 15, 0;
end

function ABGP:GetEPGPMultipliers()
    return 0.85, 1.0;
end

function ABGP:GetRaidGroup(rank)
    return rank and rankData[rank] and rankData[rank].raidGroup;
end


function ABGP:IsInRaidGroup(rank, raidGroup)
    if not rank or not rankData[rank] then return false; end
    return rankData[rank].raidGroup == raidGroup or rankData[rank].altRaidGroup == raidGroup;
end

function ABGP:GetRankPriority(rank)
    return rank and rankData[rank] and rankData[rank].priority or math.huge;
end

function ABGP:GetPreferredRaidGroup()
    local group = self:Get("raidGroup");
    if group then return group; end

    local epgp = self:GetActivePlayer(UnitName("player"));
    local rank = epgp and epgp.rank;
    if not rank then return self.RaidGroupsSorted[1]; end

    local group = self:GetRaidGroup(rank);
    if group then
        self:Set("raidGroup", group);
        return group;
    end

    return self.RaidGroupsSorted[1];
end

function ABGP:IsTrial(rank)
    return rank == "Trial" or rank == "Trial Lobster" or rank == "Lobster Trial";
end

function ABGP:GetTrialRaidGroup(publicNote)
    local noteGroup = publicNote:match("^ABGP Raid Group: (.+)$") or publicNote:match("^ABGP.+RG:([^%s]+)");
    if noteGroup then
        for raidGroup, raidGroupName in pairs(self.RaidGroupNames) do
            if noteGroup == raidGroupName then
                return raidGroup;
            end
        end
    end

    return false;
end

function ABGP:CheckProxy(publicNote)
    return publicNote:match("^ABGP Proxy: (.+)$") or publicNote:match("^ABGP.+P:([^%s]+)");
end

local guildInfo = {};

function ABGP:RebuildGuildInfo()
    table.wipe(guildInfo);
    for i = 1, GetNumGuildMembers() do
        local data = { GetGuildRosterInfo(i) };
        if data[1] then
            data.player = Ambiguate(data[1], "short");
            data.index = i;
            guildInfo[data.player] = data;
        else
            -- Seen this API fail before. If that happens,
            -- request another guild roster update.
            GuildRoster();
        end
    end
end

function ABGP:GetGuildInfo(player)
    if player then return guildInfo[player]; end
    return guildInfo;
end

function ABGP:GetItemPriorities()
    return {
        ["Druid (Heal)"] = "Druid (Heal)",
        ["KAT4FITE"] = "KAT4FITE",
        ["Hunter"] = "Hunter",
        ["Mage"] = "Mage",
        ["Paladin (Holy)"] = "Paladin (Holy)",
        ["Paladin (Ret)"] = "Paladin (Ret)",
        ["Priest (Heal)"] = "Priest (Heal)",
        ["Priest (Shadow)"] = "Priest (Shadow)",
        ["Slicey Rogue"] = "Slicey Rogue",
        ["Stabby Rogue"] = "Stabby Rogue",
        ["Warlock"] = "Warlock",
        ["Tank"] = "Tank",
        ["Metal Rogue"] = "Metal Rogue",
        ["Progression"] = "Progression",
        ["Garbage"] = "Garbage",
    }, {
        "Druid (Heal)",
        "KAT4FITE",
        "Hunter",
        "Mage",
        "Paladin (Holy)",
        "Paladin (Ret)",
        "Priest (Heal)",
        "Priest (Shadow)",
        "Slicey Rogue",
        "Stabby Rogue",
        "Warlock",
        "Tank",
        "Metal Rogue",
        "Progression",
        "Garbage",
    };
end

local lastSyncTarget;

local function GetSyncTarget()
    if not IsInRaid() then return; end

    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "raid" .. i;

        if UnitIsGroupLeader(unit) and not UnitIsUnit(unit, "player") then
            return UnitName(unit);
        end
    end
end

local function CheckSync(force)
    if not ABGP:Get("outsider") then return; end

    local target = GetSyncTarget();
    ABGP:LogDebug("Sync target: %s", target or "<none>");
    if not target then
        lastSyncTarget = nil;
        table.wipe(ABGP.Priorities);
        ABGP:RefreshActivePlayers();
        return;
    end

    if force or (lastSyncTarget ~= target) then
        lastSyncTarget = target;
        ABGP:LogDebug("Syncing with %s...", ABGP:ColorizeName(target));
        ABGP:SendComm(ABGP.CommTypes.REQUEST_PRIORITY_SYNC, {}, "WHISPER", target);
    end
end

function ABGP:OutsiderOnOfficerNotesUpdated()
    CheckSync(true);
end

function ABGP:OutsiderOnPartyLeaderChanged()
    CheckSync(false);
end

function ABGP:OutsiderOnGroupLeft()
    CheckSync(false);
end

function ABGP:OutsiderOnGroupUpdate()
    CheckSync(false);
end

function ABGP:OutsiderOnGroupJoined()
    CheckSync(true);
end
