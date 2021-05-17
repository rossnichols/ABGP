local _G = _G;
local ABGP = _G.ABGP;

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GuildRoster = GuildRoster or _G.C_GuildInfo.GuildRoster;
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
    WEEKDAY = "WEEKDAY",
};
ABGP.RaidGroupNames = {
    [ABGP.RaidGroups.WEEKDAY] = "Weekday",
};
ABGP.RaidGroupNamesAll = {
    [ABGP.RaidGroups.WEEKDAY] = "Weekday",
};
ABGP.RaidGroupNamesReversed = {
    ["Weekday"] = ABGP.RaidGroups.WEEKDAY,
};
ABGP.RaidGroupsSorted = {
    ABGP.RaidGroups.WEEKDAY,
};
ABGP.RaidGroupsSortedAll = {
    ABGP.RaidGroups.WEEKDAY,
};
ABGP.RaidGroupsSortedReverse = {
    [ABGP.RaidGroups.WEEKDAY] = 1,
};
local rankData = {
    ["Top Doggo"] =         { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
    ["Top Doggo Alt"] =     { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
    ["Hot Dog"] =           { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
    ["Hot Dog Alt"] =       { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
    ["Bestest Friend"] =    { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
    ["Pugression"] =        { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
    ["Pugression Alt"] =    { raidGroup = ABGP.RaidGroups.WEEKDAY, priority = 1 },
};
local epThreshold = 0;

function ABGP:GetMinEP()
    return epThreshold;
end

function ABGP:GuildOnActivePlayersRefreshed()
    local epDecay = self:GetEPDecayInfo();
    epDecay = (100 - epDecay) / 100;
    epThreshold = 0;

    -- Find the max EP.
    for player, epgp in pairs(self:GetActivePlayers()) do
        if epgp.raidGroup then
            epThreshold = math.max(epThreshold, epgp.ep);
        end
    end

    -- Decay the found max EP twice to determine the min threshold.
    epThreshold = math.floor(epThreshold * epDecay * epDecay);
end

function ABGP:GetEPDecayInfo()
    return 25, 0;
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

function ABGP:IsInRaidGroup(active, raidGroup)
    return active.raidGroup == raidGroup;
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
    local prios = {
        "Resto Druid",
        "Chicken",
        "KAT4FITE",
        "Mage",
        "Holy Paladin",
        "Ret Paladin",
        "Prot Paladin",
        "Holy Priest",
        "Shadow Priest",
        "Slicey Rogue",
        "Warlock",
        "Prot Warrior",
        "DPS Warrior",
        "Hunter",
        "Resto Shaman",
        "Elemental Shaman",
        "Enhancement Shaman",
    };

    local priosMap = {};
    for _, prio in pairs(prios) do
        priosMap[prio] = prio;
    end

    return priosMap, prios;
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
