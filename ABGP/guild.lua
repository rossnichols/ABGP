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

ABGP.Phases = {
    p1 = "p1",
    p3 = "p3",
};
ABGP.PhaseNames = {
    [ABGP.Phases.p1] = "Phase 1/2",
    [ABGP.Phases.p3] = "Phase 3/4",
};
ABGP.PhaseNamesShort = {
    [ABGP.Phases.p1] = "P 1/2",
    [ABGP.Phases.p3] = "P 3/4",
};
ABGP.PhasesSorted = {
    ABGP.Phases.p1,
    ABGP.Phases.p3
};
ABGP.PhasesAll = {
    [ABGP.Phases.p1] = ABGP.Phases.p1,
    [ABGP.Phases.p3] = ABGP.Phases.p3,
    p5 = "p5",
};
ABGP.PhaseNamesAll = {
    [ABGP.PhasesAll.p1] = "Phase 1/2",
    [ABGP.PhasesAll.p3] = "Phase 3/4",
    [ABGP.PhasesAll.p5] = "Phase 5",
};
ABGP.PhasesSortedAll = {
    ABGP.PhasesAll.p1,
    ABGP.PhasesAll.p3,
    ABGP.PhasesAll.p5,
};
ABGP.CurrentPhase = ABGP.Phases.p3;
ABGP.Priorities = {};
for phase in pairs(ABGP.PhasesAll) do
    ABGP.Priorities[phase] = {};
end

ABGP.RaidGroups = {
    RED = "RED",
    BLUE = "BLUE",
};
ABGP.RaidGroupNames = {
    [ABGP.RaidGroups.RED] = "Weekday",
    [ABGP.RaidGroups.BLUE] = "Weekend",
};
ABGP.RaidGroupsSorted = {
    ABGP.RaidGroups.RED,
    ABGP.RaidGroups.BLUE
};
local rankData = {
    ["Guild Master"] =   { ep = ABGP.RaidGroups.RED, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.RED,  [ABGP.Phases.p3] = ABGP.RaidGroups.RED } },
    ["Officer"] =        { ep = ABGP.RaidGroups.RED, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.RED,  [ABGP.Phases.p3] = ABGP.RaidGroups.RED } },
    ["Closer"] =         { ep = ABGP.RaidGroups.RED, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.RED,  [ABGP.Phases.p3] = ABGP.RaidGroups.RED } },
    ["Red Lobster"] =    { ep = ABGP.RaidGroups.RED, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.RED,  [ABGP.Phases.p3] = ABGP.RaidGroups.RED } },
    ["Purple Lobster"] = { ep = ABGP.RaidGroups.BLUE, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.RED,  [ABGP.Phases.p3] = ABGP.RaidGroups.BLUE } },
    ["Blue Lobster"] =   { ep = ABGP.RaidGroups.BLUE, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.BLUE, [ABGP.Phases.p3] = ABGP.RaidGroups.BLUE } },
    ["Officer Alt"] =    { ep = ABGP.RaidGroups.BLUE, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.BLUE, [ABGP.Phases.p3] = ABGP.RaidGroups.BLUE } },
    ["Lobster Alt"] =    { ep = ABGP.RaidGroups.BLUE, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.BLUE, [ABGP.Phases.p3] = ABGP.RaidGroups.BLUE } },
    ["Fiddler Crab"] =   { ep = ABGP.RaidGroups.BLUE, gp = { [ABGP.Phases.p1] = ABGP.RaidGroups.BLUE, [ABGP.Phases.p3] = ABGP.RaidGroups.BLUE } },
};

function ABGP:GetGPDecayInfo()
    return 0.25, 0;
end

function ABGP:GetGPRaidGroup(rank, phase)
    return rank and rankData[rank] and rankData[rank].gp[phase];
end

function ABGP:GetEPRaidGroup(rank)
    return rank and rankData[rank] and rankData[rank].ep;
end

function ABGP:GetPreferredRaidGroup()
    local group = self:Get("raidGroup");
    if group then return group; end

    local epgp = self:GetActivePlayer(UnitName("player"));
    local rank = epgp and epgp.rank;
    if not rank then return self.RaidGroupsSorted[1]; end

    local group = self:GetEPRaidGroup(rank);
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
    local noteGroup = publicNote:match("^ABGP Raid Group: (.+)$");
    if noteGroup then
        for raidGroup, raidGroupName in pairs(self.RaidGroupNames) do
            if noteGroup == raidGroupName then
                return raidGroup;
            end
        end
    end

    return self.RaidGroups.RED;
end

function ABGP:CheckProxy(publicNote)
    return publicNote:match("^ABGP Proxy: (.+)$");
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
        for phase, data in pairs(ABGP.Priorities) do
            table.wipe(data);
        end
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
