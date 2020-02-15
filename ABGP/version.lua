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

function ABGP:ParseVersion(version)
    local major, minor, patch, prerelease = version:match("^(%d+)%.(%d+)%.(%d+)%.?(%a*%d*)$");
    if not (major and minor and patch) then return; end
    if prerelease == "" then prerelease = nil; end

    return tonumber(major), tonumber(minor), tonumber(patch), prerelease;
end

local function VersionIsNewer(versionCmp, version, allowPrerelease)
    if versionCmp == version then return false; end

    local major, minor, patch, prerel = ABGP:ParseVersion(version);
    local majorCmp, minorCmp, patchCmp, prerelCmp = ABGP:ParseVersion(versionCmp);
    -- print(major, minor, patch, prerel, majorCmp, minorCmp, patchCmp, prerelCmp);
    if not (major and minor and patch and majorCmp and minorCmp and patchCmp) then return false; end

    if not allowPrerelease then
        -- if the compared version is prerelease, the current one must be as well.
        if prerelCmp and not prerel then return false; end
    end

    local prerelType, prerelVersion, prerelTypeCmp, prerelVersionCmp;
    if prerelCmp then
        prerelTypeCmp, prerelVersionCmp = prerelCmp:match("^(%a*)(%d*)$");
        prerelVersionCmp = tonumber(prerelVersionCmp);
    end
    if prerel then
        prerelType, prerelVersion = prerel:match("^(%a*)(%d*)$");
        prerelVersion = tonumber(prerelVersion);
    end

    if majorCmp ~= major then
        return majorCmp > major;
    elseif minorCmp ~= minor then
        return minorCmp > minor;
    elseif patchCmp ~= patch then
        return patchCmp > patch;
    elseif prerelTypeCmp ~= prerelType then
        return prerelTypeCmp > prerelType;
    elseif prerelVersionCmp ~= prerelVersion then
        return prerelVersionCmp > prerelVersion;
    else
        return false;
    end
end

local function CompareVersion(versionCmp, sender)
    -- See if we've already told the user about this version
    if versionCmp == announcedVersion then return; end

    -- See if we're already running this version
    local version = ABGP:GetCompareVersion();
    if versionCmp == version then return; end

    -- Make sure the version strings are valid
    if not (ABGP:ParseVersion(version) and ABGP:ParseVersion(versionCmp)) then return; end

    if VersionIsNewer(versionCmp, version) then
        StaticPopup_Show("ABGP_OUTDATED_VERSION", string.format(
            "%s: You're running an outdated addon version! Newer version %s discovered from %s, yours is %s.",
            ABGP:ColorizeText("ABGP"), ABGP:ColorizeText(versionCmp), ABGP:ColorizeName(sender), ABGP:ColorizeText(version)));
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
        versionCheckData.players[sender] = data.version;
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
    if not self:ParseVersion(self:GetVersion()) then
        self:Error("Unable to parse your version!");
        return;
    end
    if not IsInGroup() then
        self:Error("Not in a group!");
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
    versionCheckData.timer = self:ScheduleTimer("VersionCheckCallback", 3);
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
            local versionCmp = versionCheckData.players[player];
            if versionCmp then
                if VersionIsNewer(version, versionCmp, true) then
                    self:Notify("%s running an outdated version (%s)!", self:ColorizeName(player), ABGP:ColorizeText(versionCmp));
                    allUpToDate = false;
                end
            else
                self:Notify("%s is missing the addon!", self:ColorizeName(player));
                SendChatMessage("You don't have the ABGP addon installed! Please install it from Curse/Twitch for the ability to request loot.", "WHISPER", nil, player);
                allUpToDate = false;
            end
        end
    end

    if allUpToDate then
        self:Notify("Everyone is up to date!");
    end

    self:Notify("Version check complete!");
    versionCheckData = nil;
end

function ABGP:InitVersionCheck()
    if IsInGuild() then
        self:SendComm(self.CommTypes.VERSION_REQUEST, {}, "GUILD");
    end

    local f = CreateFrame("FRAME");
    f:RegisterEvent("GROUP_JOINED");
    f:SetScript("OnEvent", function()
        self:SendComm(self.CommTypes.VERSION_REQUEST, {}, "BROADCAST");
    end);
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
