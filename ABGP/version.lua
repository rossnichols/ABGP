local announcedVersion;
local versionCheckData;

function ABGP:GetVersion()
    if ABGP.VersionDebug then
        return ABGP.VersionDebug;
    else
        return GetAddOnMetadata("ABGP", "Version");
    end
end

function ABGP:GetCompareVersion()
    if ABGP.VersionCmpDebug then
        return ABGP.VersionCmpDebug;
    else
        return self:GetVersion();
    end
end

local function ParseVersion(version)
    local major, minor, patch = version:match("^(%d-)%.(%d-)%.(%d-)$");
    if not (major and minor and patch) then return; end

    return tonumber(major), tonumber(minor), tonumber(patch);
end

local function VersionIsNewer(versionCmp, version)
    if versionCmp == version then return false; end

    local major, minor, patch = ParseVersion(version);
    local majorCmp, minorCmp, patchCmp = ParseVersion(versionCmp);
    if not (major and minor and patch and majorCmp and minorCmp and patchCmp) then return false; end

    return (majorCmp > major) or
           (majorCmp == major and minorCmp > minor) or
           (majorCmp == major and minorCmp == minor and patchCmp > patch);
end

local function CompareVersion(versionCmp, sender)
    -- See if we've already told the user about this version
    if versionCmp == announcedVersion then return; end

    -- See if we're already running this version
    local version = ABGP:GetCompareVersion();
    if versionCmp == version then return; end

    -- Make sure the version strings are valid
    if not (ParseVersion(version) and ParseVersion(versionCmp)) then return; end

    if VersionIsNewer(versionCmp, version) then
        ABGP:Error("You're running an outdated addon version! Newer version %s%s|r discovered from %s, yours is %s%s|r.",
            ABGP.Color, versionCmp, ABGP:ColorizeName(sender), ABGP.Color, version);
        announcedVersion = versionCmp;
    end
end

function ABGP:OnVersionRequest(data, distribution, sender)
    -- Reset the announced version if the sender requested so that the message will print again.
    if data.reset then
        announcedVersion = nil;
    end

    self:SendComm(self.CommTypes.VERSION_RESPONSE, {}, distribution);
    CompareVersion(data.version, sender);
end

function ABGP:OnVersionResponse(data, distribution, sender)
    CompareVersion(data.version, sender);

    if distribution ~= "GUILD" and versionCheckData and not versionCheckData.players[sender] then
        versionCheckData.players[sender] = version;
        versionCheckData.received = versionCheckData.received + 1;

        -- See if we can end the timer early if everyone has responded.
        if versionCheckData.received == versionCheckData.total then
            self:CancelTimer(versionCheckData.timer);
            self:VersionCheckCallback();
        end
    end
end

function ABGP:PerformVersionCheck()
    if versionCheckData then
        self:Error("Already performing version check!");
        return;
    end
    if not IsInGroup() then
        self:Error("Not in a group!");
        return;
    end
    if not ParseVersion(self:GetVersion()) then
        self:Error("Unable to parse your version!");
        return;
    end

    -- Reset announcedVersion in case the version check reveals a newer version.
    announcedVersion = nil;

    versionCheckData = {
        total = GetNumGroupMembers(),
        received = 0,
        players = {},
    };

    self:Notify("Performing version check...");
    self:SendComm(self.CommTypes.VERSION_REQUEST, {
        reset = true,
    }, "BROADCAST");
    versionCheckData.timer = self:ScheduleTimer("VersionCheckCallback", 5);
end

function ABGP:VersionCheckCallback()
    if not versionCheckData then return; end
    local version = self:GetCompareVersion();

    local allUpToDate = true;
    for i = 1, GetNumGroupMembers() do
        local player = GetRaidRosterInfo(i);
        local versionCmp = versionCheckData.players[player];
        if versionCmp then
            if VersionIsNewer(version, versionCmp) then
                self:Notify("%s running an outdated version (%s%s|r)!", self:ColorizeName(player), ABGP.Color, versionCmp);
                allUpToDate = false;
            end
        else
            self:Notify("%s is missing the addon!", self:ColorizeName(player));
            SendChatMessage("You don't have the ABGP addon installed! Please install it for the ability to request loot.", "WHISPER", nil, player);
            allUpToDate = false;
        end
    end

    if allUpToDate then
        self:Notify("Everyone is up to date!");
    end

    self:Notify("Version check complete!");
    versionCheckData = nil;
end

function ABGP:InitVersionCheck()
    -- Delay the initial version check so the player's more likely to see it.
    self:ScheduleTimer(function()
        if IsInGuild() then
            self:SendComm(self.CommTypes.VERSION_REQUEST, {}, "GUILD");
        end
    end, 30);

    local f = CreateFrame("FRAME");
    f:RegisterEvent("GROUP_JOINED");
    f:SetScript("OnEvent", function()
        self:SendComm(self.CommTypes.VERSION_REQUEST, {}, "BROADCAST");
    end);
end
