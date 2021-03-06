local _G = _G;
local ABGP = _G.ABGP;

local debugOpts = {
    -- If set, extra debug messages will be printed.
    -- Verbose = true,

    -- If set, "BROADCAST" will get rerouted to "WHISPER" even in a group.
    -- PrivateComms = true,

    -- If set, opening an item will populate distrib with test entries.
    -- ShowTestDistrib = true,

    -- If set, alt+clicking items will show the loot frame instead of opening distrib.
    -- TestLootFrame = true,

    -- If set, some extra logging will be printed for comms.
    -- DebugComms = true,

    -- If set, item awards/updates will avoid editing the officer note.
    -- SkipOfficerNote = true,

    -- If set, changing item EPGP data will not "commit" them for propagation.
    -- IgnoreItemCommit = true,

    -- If set, the addon will never send its history to other players
    -- AvoidHistorySend = true,

    -- If set, shows WIP UI for history modifications
    HistoryUI = true,
};

function ABGP:GetDebugOpt(key)
    return self:Get("debug") and (not key or debugOpts[key]);
end

function ABGP:SetDebug(enable)
    self:Set("debug", enable);
end

ABGP.VersionOverride = "8.0.7";
ABGP.VersionCmpOverride = "8.0.7";
