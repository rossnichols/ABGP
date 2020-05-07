local _G = _G;
local ABGP = ABGP;

local IsInGroup = IsInGroup;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local UnitIsConnected = UnitIsConnected;
local SendChatMessage = SendChatMessage;
local GetAddOnMetadata = GetAddOnMetadata;
local tonumber = tonumber;

local versionCheckData;
local showedNagPopup = false;
local checkedGuild = false;

function ABGP:GetVersion()
    local version = GetAddOnMetadata("ABGP", "Version");
    if version == "${ADDON_VERSION}" then
        return ABGP.VersionOverride;
    end
    return version;
end

function ABGP:GetCompareVersion()
    local version = GetAddOnMetadata("ABGP", "Version");
    if version == "${ADDON_VERSION}" then
        return ABGP.VersionCmpOverride;
    end
    return version;
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
    elseif self:VersionIsNewer(self:GetCompareVersion(), data.version) then
        self:SendComm(self.CommTypes.VERSION_RESPONSE, {
            version = self:GetVersion()
        }, distribution);
    end

    CompareVersion(data.version, sender);
end

function ABGP:OnVersionResponse(data, distribution, sender)
    if versionCheckData and not versionCheckData.players[sender] then
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

    local major, _, _, prerelType = ABGP:ParseVersion(self:GetVersion());
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
    self:SendComm(self.CommTypes.VERSION_REQUEST, {
        version = self:GetVersion()
    }, "BROADCAST");
end

function ABGP:VersionOnGuildRosterUpdate()
    if not checkedGuild then
        checkedGuild = true;
        self:ScheduleTimer(function(self)
            self:SendComm(self.CommTypes.VERSION_REQUEST, {
                version = self:GetVersion()
            }, "GUILD");
        end, 30, self);
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
