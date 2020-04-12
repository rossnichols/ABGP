local _G = _G;
local ABGP = ABGP;

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GuildRoster = GuildRoster;
local GetGuildInfo = GetGuildInfo;
local Ambiguate = Ambiguate;
local UnitName = UnitName;
local table = table;
local pairs = pairs;
local next = next;

ABGP.RaidGroups = {
    RED = "RED",
    BLUE = "BLUE",
};

local rankData = {
    [ABGP.RaidGroups.RED] = {
        ["Guild Master"] = true,
        ["Officer"] = true,
        ["Closer"] = true,
        ["Red Lobster"] = true,
        ["Purple Lobster"] = true,
    },
    [ABGP.RaidGroups.BLUE] = {
        ["Purple Lobster"] = true,
        ["Blue Lobster"] = true,
        ["Officer Alt"] = true,
        ["Lobster Alt"] = true,
        ["Fiddler Crab"] = true,
    },
};

function ABGP:IsRankInRaidGroup(rank, group)
    return rank and rankData[group][rank];
end

function ABGP:GetRaidGroup()
    local group = self:Get("raidGroup");
    if group then return group; end

    local _, rank = GetGuildInfo("player");
    if not rank then return next(rankData); end

    for group in pairs(rankData) do
        if self:IsRankInRaidGroup(rank, group) then
            self:Set("raidGroup", group);
            return group;
        end
    end

    return next(rankData);
end

function ABGP:IsTrial(rank)
    return rank == "Trial" or rank == "Trial Lobster";
end

function ABGP:CheckProxy(publicNote)
    return publicNote:match("^ABGP Proxy: (.+)$")
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
    return guildInfo[player];
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
        ["Rogue"] = "Rogue",
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
        "Metal Rogue",
        "Paladin (Holy)",
        "Paladin (Ret)",
        "Priest (Heal)",
        "Priest (Shadow)",
        "Rogue",
        "Slicey Rogue",
        "Stabby Rogue",
        "Tank",
        "Warlock",
        "Progression",
        "Garbage",
    };
end
