local _G = _G;
local ABGP = ABGP;

local IsInGroup = IsInGroup;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local IsInGuild = IsInGuild;
local UnitName = UnitName;
local UnitIsConnected = UnitIsConnected;
local SendChatMessage = SendChatMessage;
local CreateFrame = CreateFrame;
local GetAddOnMetadata = GetAddOnMetadata;
local UnitExists = UnitExists;
local tonumber = tonumber;
local table = table;
local pairs = pairs;
local ipairs = ipairs;

local versionCheckData;
local showedNagPopup = false;
local checkedGuild = false;

ABGP.LeaderContexts = {
    group = { leaders = {}, distrib = "BROADCAST", context = "group" },
    guild = { leaders = {},  distrib = "GUILD", context = "guild" },
};
local contextFns = {
    Reset = function(self)
        for k in pairs(self.leaders) do self.leaders[k] = nil; end
        local version = ABGP:GetCompareVersion();
        if self:IsRelease(version) then
            self:InsertLeader(UnitName("player"), version);
        end
    end,

    SendRequest = function(self)
        ABGP:SendComm(ABGP.CommTypes.VERSION_REQUEST, {
            version = ABGP:GetVersion(),
            context = self.context
        }, self.distrib);
    end,

    SendResponse = function(self)
        ABGP:SendComm(ABGP.CommTypes.VERSION_RESPONSE, {
            version = ABGP:GetVersion(),
            context = self.context
        }, self.distrib);
    end,

    OnRequest = function(self, data, distribution, sender)
        if sender == UnitName("player") or not self:IsRelease(data.version) then return; end

        if self:IsLeader() then
            self:SendResponse();
        else
            self.timer = ABGP:ScheduleTimer(self.CheckConsistency, 5, self);
        end

        if not self.leaders[sender] and self:IsSameOrNewer(data.version) then
            self:InsertLeader(sender, data.version);
        end
    end,

    OnResponse = function(self, data, distribution, sender)
        if sender == UnitName("player") or not self:IsRelease(data.version) then return; end

        if self.timer then
            ABGP:CancelTimer(self.timer);
            self.timer = nil;
        end

        if not self.leaders[sender] and self:IsSameOrNewer(data.version) then
            self:InsertLeader(sender, data.version);
        end
    end,

    CheckConsistency = function(self)
        ABGP:LogDebug("Context=%s consistency failure! %s", self.context, self:Leaders());
        self.timer = nil;
        self:Reset();
    end,

    IsLeader = function(self)
        return #self.leaders > 0 and self.leaders[#self.leaders].player == UnitName("player");
    end,

    IsRelease = function(self, version)
        local major, minor, patch, prerelType, prerelVersion = ABGP:ParseVersion(version);
        return major and not prerelType;
    end,

    InsertLeader = function(self, player, version)
        local insertIndex;

        if #self.leaders == 0 then
            insertIndex = 1;
        else
            for i = #self.leaders, 1, -1 do
                local leader = self.leaders[i];
                if self:IsSameOrNewer(version, leader.version) then
                    insertIndex = i + 1;
                    break;
                end
            end
        end

        if insertIndex then
            table.insert(self.leaders, insertIndex, { player = player, version = version });
            table.sort(self.leaders, function(a, b)
                if a.version ~= b.version then
                    return ABGP:VersionIsNewer(b.version, a.version);
                else
                    return a.player < b.player;
                end
            end);
            self.leaders[player] = true;
            -- ABGP:LogDebug("Leaders for context=%s: %s", self.context, self:Leaders());
        end
    end,

    CheckLeaders = function(self, checkFn)
        local removed = false;
        for i = #self.leaders, 1, -1 do
            local leader = self.leaders[i];
            if not checkFn(leader.player) then
                table.remove(self.leaders, i);
                self.leaders[leader.player] = nil;
                removed = true;
            end
        end

        if removed then
            -- ABGP:LogDebug("Leaders for context=%s: %s", self.context, self:Leaders());

            if self:IsLeader() then self:SendRequest(); end
        end
    end,

    IsSameOrNewer = function(self, version, versionCmp)
        versionCmp = versionCmp or ABGP:GetCompareVersion();
        local same = (version == versionCmp);
        local newer = ABGP:VersionIsNewer(version, versionCmp);
        return same or newer;
    end,

    Leaders = function(self)
        local str = "";
        for i, leader in ipairs(self.leaders) do
            str = ("%s%s%s:%s"):format(str, i == 1 and "" or ",", leader.player, leader.version);
        end
        return str;
    end,
};
for _, context in pairs(ABGP.LeaderContexts) do
    for name, fn in pairs(contextFns) do
        context[name] = fn;
    end
end

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

function ABGP:ParseVersion(version)
    local major, minor, patch, prerelType, prerelVersion = version:match("^(%d+)%.(%d+)%.(%d+)%-?(%a*)(%d*)$");
    if not (major and minor and patch) then return; end
    if prerelType == "" then prerelType = nil; end
    if prerelVersion == "" then prerelVersion = nil; end

    return tonumber(major), tonumber(minor), tonumber(patch), prerelType, tonumber(prerelVersion);
end

function ABGP:VersionIsNewer(versionCmp, version, allowPrerelease)
    if versionCmp == version then return false; end

    local major, minor, patch, prerelType, prerelVersion = ABGP:ParseVersion(version);
    local majorCmp, minorCmp, patchCmp, prerelTypeCmp, prerelVersionCmp = ABGP:ParseVersion(versionCmp);
    -- print(major, minor, patch, prerel, majorCmp, minorCmp, patchCmp, prerelCmp);
    if not (major and minor and patch and majorCmp and minorCmp and patchCmp) then return false; end

    if not allowPrerelease then
        -- if the compared version is prerelease, the current one must be as well.
        if prerelTypeCmp and not prerelType then return false; end
    end

    if majorCmp ~= major then
        return majorCmp > major;
    elseif minorCmp ~= minor then
        return minorCmp > minor;
    elseif patchCmp ~= patch then
        return patchCmp > patch;
    elseif (prerelTypeCmp ~= nil) ~= (prerelType ~= nil) then
        return prerelTypeCmp == nil;
    elseif prerelTypeCmp ~= prerelType then
        return prerelTypeCmp > prerelType;
    elseif prerelVersionCmp ~= prerelVersion then
        return prerelVersionCmp > prerelVersion;
    else
        return false;
    end
end

local function CompareVersion(versionCmp, sender)
    -- See if we've already told the user to upgrade
    if showedNagPopup then return; end

    -- See if we're already running this version
    local version = ABGP:GetCompareVersion();
    if versionCmp == version then return; end

    -- Make sure the version strings are valid
    if not (ABGP:ParseVersion(version) and ABGP:ParseVersion(versionCmp)) then return; end

    if ABGP:VersionIsNewer(versionCmp, version) then
        _G.StaticPopup_Show("ABGP_OUTDATED_VERSION",
            ("%s: You're running an outdated addon version! Newer version %s discovered from %s, yours is %s. Please upgrade so you can request loot!"):format(
            ABGP:ColorizeText("ABGP"), ABGP:ColorizeText(versionCmp), ABGP:ColorizeName(sender), ABGP:ColorizeText(version)));
        showedNagPopup = true;
    end
end

function ABGP:NotifyVersionMismatch()
    _G.StaticPopup_Show("ABGP_OUTDATED_VERSION",
        ("%s: You've installed a new version! All functionality is disabled until you restart your game client."):format(
        ABGP:ColorizeText("ABGP")));
end

function ABGP:OnVersionRequest(data, distribution, sender)
    if data.reset then
        -- Reset the announced version if the sender requested so that the message will print again.
        showedNagPopup = false;
        self:SendComm(self.CommTypes.VERSION_RESPONSE, {
            commPriority = "INSTANT",
            version = self:GetVersion()
        }, distribution);
    elseif data.context then
        self.LeaderContexts[data.context]:OnRequest(data, distribution, sender);
    elseif self:VersionIsNewer(self:GetCompareVersion(), data.version) then
        self:SendComm(self.CommTypes.VERSION_RESPONSE, {
            version = self:GetVersion()
        }, distribution);
    end

    CompareVersion(data.version, sender);
end

function ABGP:OnVersionResponse(data, distribution, sender)
    if data.context then
        self.LeaderContexts[data.context]:OnResponse(data, distribution, sender);
    elseif versionCheckData and not versionCheckData.players[sender] then
        versionCheckData.players[sender] = data.version;
        versionCheckData.received = versionCheckData.received + 1;

        -- See if we can end the timer early if everyone has responded.
        if versionCheckData.received == versionCheckData.total then
            self:CancelTimer(versionCheckData.timer);
            self:VersionCheckCallback();
        end
    end

    CompareVersion(data.version, sender);
end

local function GetNumOnlineGroupMembers()
    local count = 0;
    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end
        if UnitIsConnected(unit) then
            count = count + 1;
        end
    end

    return count;
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

    local major, minor, patch, prerelType, prerelVersion = ABGP:ParseVersion(self:GetVersion());
    if not major then
        self:Error("Unable to parse your version!");
        return;
    end
    if prerelType then
        self:Notify("You're using a prerelease version! This check will likely find a lot of 'outdated' versions.");
    end

    -- Reset showedNagPopup in case the version check reveals a newer version.
    showedNagPopup = false;

    versionCheckData = {
        total = GetNumOnlineGroupMembers(),
        received = 0,
        players = {},
    };

    self:Notify("Performing version check...");
    self:SendComm(self.CommTypes.VERSION_REQUEST, {
        reset = true,
        version = self:GetVersion()
    }, "BROADCAST");
    versionCheckData.timer = self:ScheduleTimer("VersionCheckCallback", 5);
end

function ABGP:VersionCheckCallback()
    if not versionCheckData then return; end
    local version = self:GetCompareVersion();

    local allUpToDate = true;
    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end
        local player = UnitName(unit);
        if player then
            if UnitIsConnected(unit) then
                local versionCmp = versionCheckData.players[player];
                if versionCmp then
                    if self:VersionIsNewer(version, versionCmp, true) then
                        self:Notify("%s running an outdated version (%s)!", self:ColorizeName(player), ABGP:ColorizeText(versionCmp));
                        SendChatMessage(
                            ("You don't have the latest ABGP version installed! Please update it from Curse/Twitch so you can request loot. The latest version is %s."):format(version),
                            "WHISPER", nil, player);
                        allUpToDate = false;
                    end
                else
                    self:Notify("%s is missing the addon!", self:ColorizeName(player));
                    SendChatMessage(
                        "You don't have the ABGP addon installed! Please install it from Curse/Twitch so you can request loot.",
                        "WHISPER", nil, player);
                    allUpToDate = false;
                end
            else
                self:Notify("%s was offline for the version check.", self:ColorizeName(player));
                allUpToDate = false;
            end
        end
    end

    if allUpToDate then
        self:Notify("Everyone is up to date!");
    end

    versionCheckData = nil;
end

function ABGP:VersionOnGroupJoined()
    self.LeaderContexts.group:Reset();
    self.LeaderContexts.group:SendRequest();
end

function ABGP:VersionOnGroupLeft()
    self.LeaderContexts.group:Reset();
end

function ABGP:VersionOnGroupUpdate()
    self.LeaderContexts.group:CheckLeaders(function(player)
        return UnitExists(player);
    end);
end

function ABGP:VersionOnGuildRosterUpdate()
    if checkedGuild then
        self.LeaderContexts.guild:CheckLeaders(function(player)
            if player == UnitName("player") then return true; end
            local guildInfo = ABGP:GetGuildInfo(player);
            return guildInfo and guildInfo[9];
        end);
    else
        checkedGuild = true;
        self.LeaderContexts.guild:Reset();
        self.LeaderContexts.guild:SendRequest();
    end
end

StaticPopupDialogs["ABGP_OUTDATED_VERSION"] = {
    text = "%s",
    button1 = "Ok",
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    exclusive = true,
    showAlert = true,
};
