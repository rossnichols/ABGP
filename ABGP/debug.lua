local _G = _G;
local ABGP = ABGP;

local debugOpts = {
    -- Verbose = true,
    -- PrivateComms = true,
    -- ShowTestDistrib = true,
    -- TestLootFrame = true,
    -- DebugComms = true,
    -- DebugRaidUI = true,
    SkipOfficerNote = true,
    IgnoreItemUpdates = true,
};

function ABGP:GetDebug(key)
    return self:Get("debug") and (not key or debugOpts[key]);
end

ABGP.VersionOverride = "4.0.3";
ABGP.VersionCmpOverride = "4.0.3";
