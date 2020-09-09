local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetServerTime = GetServerTime;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInGroup = IsInGroup;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local UnitAffectingCombat = UnitAffectingCombat;
local GetAutoCompleteResults = GetAutoCompleteResults;
local tContains = tContains;
local AUTOCOMPLETE_FLAG_IN_GROUP = AUTOCOMPLETE_FLAG_IN_GROUP;
local AUTOCOMPLETE_FLAG_NONE = AUTOCOMPLETE_FLAG_NONE;
local pairs = pairs;
local math = math;
local ipairs = ipairs;
local table = table;
local date = date;
local type = type;
local tonumber = tonumber;
local next = next;
local max = max;

_G.ABGP_RaidInfo3 = {};

-- https://wow.gamepedia.com/InstanceID
local instanceIds = {
    MoltenCore      = 409,
    Onyxia          = 249,
    BlackwingLair   = 469,
    ZulGurub        = 309,
    AQ20            = 509,
    AQ40            = 531,
};

-- https://wow.tools/dbc/?dbc=dungeonencounter
ABGP.BossIds = {
    Lucifron    = 663,
    Magmadar    = 664,
    Gehennas    = 665,
    Garr        = 666,
    Shazzrah    = 667,
    Geddon      = 668,
    Sulfuron    = 669,
    Golemagg    = 670,
    Majordomo   = 671,
    Ragnaros    = 672,

    Onyxia      = 1084,

    Razorgore   = 610,
    Vaelastrasz = 611,
    Broodlord   = 612,
    Firemaw     = 613,
    Ebonroc     = 614,
    Flamegor    = 615,
    Chromaggus  = 616,
    Nefarian    = 617,

    Venoxis     = 784,
    Jeklik      = 785,
    Marli       = 786,
    Mandokir    = 787,
    Madness     = 788,
    Thekal      = 789,
    Gahzranka   = 790,
    Arlokk      = 791,
    Jindo       = 792,
    Hakkar      = 793,

    Skeram      = 709,
    BugTrio     = 710,
    Sartura     = 711,
    Fankriss    = 712,
    Viscidus    = 713,
    Huhuran     = 714,
    TwinEmps    = 715,
    Ouro        = 716,
    Cthun       = 717,

    Kurinnaxx   = 718,
    Rajaxx      = 719,
    Moam        = 720,
    Buru        = 721,
    Ayamiss     = 722,
    Ossirian    = 723,
};
local bossIds = ABGP.BossIds;

local instanceInfo = {
    [instanceIds.MoltenCore]  = {
        name = "Molten Core",
        promptRaidStart = true,
        bosses = {
            bossIds.Lucifron, bossIds.Magmadar, bossIds.Gehennas, bossIds.Garr, bossIds.Shazzrah,
            bossIds.Geddon, bossIds.Sulfuron, bossIds.Golemagg, bossIds.Majordomo, bossIds.Ragnaros
        },
    },
    [instanceIds.BlackwingLair] = {
        name = "Blackwing Lair",
        promptRaidStart = true,
        bosses = {
            bossIds.Razorgore, bossIds.Vaelastrasz, bossIds.Broodlord, bossIds.Firemaw,
            bossIds.Ebonroc, bossIds.Flamegor, bossIds.Chromaggus, bossIds.Nefarian
        },
    },
    [instanceIds.AQ40] = {
        name = "Temple of Ahn'Qiraj",
        promptRaidStart = true,
        bosses = {
            bossIds.Skeram, bossIds.BugTrio, bossIds.Sartura, bossIds.Fankriss, bossIds.Viscidus,
            bossIds.Huhuran, bossIds.TwinEmps, bossIds.Ouro, bossIds.Cthun
        },
    },
    [instanceIds.Onyxia] = {
        name = "Onyxia",
        bosses = {
            bossIds.Onyxia
        },
    },
    [instanceIds.ZulGurub] = {
        name = "Zul'Gurub",
        bosses = {
            bossIds.Venoxis, bossIds.Jeklik, bossIds.Marli, bossIds.Mandokir, bossIds.Madness,
            bossIds.Thekal, bossIds.Gahzranka, bossIds.Arlokk, bossIds.Jindo, bossIds.Hakkar
        },
    },
    [instanceIds.AQ20] = {
        name = "Ruins of Ahn'Qiraj",
        bosses = {
            bossIds.Kurinnaxx, bossIds.Rajaxx, bossIds.Buru, bossIds.Ayamiss, bossIds.Ossirian, bossIds.Moam
        },
    },
};

local bossInfo = {
    [bossIds.Lucifron]  = { instance = instanceIds.MoltenCore, name = "Lucifron" },
    [bossIds.Magmadar]  = { instance = instanceIds.MoltenCore, name = "Magmadar" },
    [bossIds.Gehennas]  = { instance = instanceIds.MoltenCore, name = "Gehennas" },
    [bossIds.Garr]      = { instance = instanceIds.MoltenCore, name = "Garr" },
    [bossIds.Shazzrah]  = { instance = instanceIds.MoltenCore, name = "Shazzrah" },
    [bossIds.Geddon]    = { instance = instanceIds.MoltenCore, name = "Baron Geddon" },
    [bossIds.Sulfuron]  = { instance = instanceIds.MoltenCore, name = "Sulfuron Harbinger" },
    [bossIds.Golemagg]  = { instance = instanceIds.MoltenCore, name = "Golemagg the Incinerator" },
    [bossIds.Majordomo] = { instance = instanceIds.MoltenCore, name = "Majordomo Executus" },
    [bossIds.Ragnaros]  = { instance = instanceIds.MoltenCore, name = "Ragnaros" },

    [bossIds.Razorgore]   = { instance = instanceIds.BlackwingLair, name = "Razorgore the Untamed" },
    [bossIds.Vaelastrasz] = { instance = instanceIds.BlackwingLair, name = "Vaelastrasz the Corrupt" },
    [bossIds.Broodlord]   = { instance = instanceIds.BlackwingLair, name = "Broodlord Lashlayer" },
    [bossIds.Firemaw]     = { instance = instanceIds.BlackwingLair, name = "Firemaw" },
    [bossIds.Ebonroc]     = { instance = instanceIds.BlackwingLair, name = "Ebonroc" },
    [bossIds.Flamegor]    = { instance = instanceIds.BlackwingLair, name = "Flamegor" },
    [bossIds.Chromaggus]  = { instance = instanceIds.BlackwingLair, name = "Chromaggus" },
    [bossIds.Nefarian]    = { instance = instanceIds.BlackwingLair, name = "Nefarian" },

    [bossIds.Skeram]   = { instance = instanceIds.AQ40, name = "The Prophet Skeram" },
    [bossIds.BugTrio]  = { instance = instanceIds.AQ40, name = "Silithid Royalty" },
    [bossIds.Sartura]  = { instance = instanceIds.AQ40, name = "Battleguard Sartura" },
    [bossIds.Fankriss] = { instance = instanceIds.AQ40, name = "Fankriss the Unyielding" },
    [bossIds.Viscidus] = { instance = instanceIds.AQ40, name = "Viscidus" },
    [bossIds.Huhuran]  = { instance = instanceIds.AQ40, name = "Princess Huhuran" },
    [bossIds.TwinEmps] = { instance = instanceIds.AQ40, name = "Twin Emperors" },
    [bossIds.Ouro]     = { instance = instanceIds.AQ40, name = "Ouro" },
    [bossIds.Cthun]    = { instance = instanceIds.AQ40, name = "C'thun" },

    [bossIds.Onyxia] = { instance = instanceIds.Onyxia, name =  "Onyxia" },

    [bossIds.Venoxis]   = { instance = instanceIds.ZulGurub, name = "High Priest Venoxis" },
    [bossIds.Jeklik]    = { instance = instanceIds.ZulGurub, name = "High Priestess Jeklik" },
    [bossIds.Marli]     = { instance = instanceIds.ZulGurub, name = "High Priestess Mar'li" },
    [bossIds.Mandokir]  = { instance = instanceIds.ZulGurub, name = "Bloodlord Mandokir" },
    [bossIds.Madness]   = { instance = instanceIds.ZulGurub, name = "Edge of Madness" },
    [bossIds.Thekal]    = { instance = instanceIds.ZulGurub, name = "High Priest Thekal" },
    [bossIds.Gahzranka] = { instance = instanceIds.ZulGurub, name = "Gahz'ranka" },
    [bossIds.Arlokk]    = { instance = instanceIds.ZulGurub, name = "High Priestess Arlokk" },
    [bossIds.Jindo]     = { instance = instanceIds.ZulGurub, name = "Jin'do the Hexxer" },
    [bossIds.Hakkar]    = { instance = instanceIds.ZulGurub, name = "Hakkar" },

    [bossIds.Kurinnaxx] = { instance = instanceIds.AQ20, name = "Kurinnaxx" },
    [bossIds.Rajaxx]    = { instance = instanceIds.AQ20, name = "General Rajaxx" },
    [bossIds.Buru]      = { instance = instanceIds.AQ20, name = "Buru the Gorger" },
    [bossIds.Ayamiss]   = { instance = instanceIds.AQ20, name = "Ayamiss the Hunter" },
    [bossIds.Ossirian]  = { instance = instanceIds.AQ20, name = "Ossirian the Unscarred" },
    [bossIds.Moam]      = { instance = instanceIds.AQ20, name = "Moam" },
};

local tickCategories = {
    BOSSKILL = "BOSSKILL",
    BOSSWIPE = "BOSSWIPE",
    ONTIME = "ONTIME",
    MANUAL = "MANUAL",
};

local tickCategoryNames = {
    [tickCategories.BOSSKILL] = "boss kill",
    [tickCategories.BOSSWIPE] = "boss attempt",
    [tickCategories.ONTIME] = "on-time bonus",
    [tickCategories.MANUAL] = "manual",
};

local tickCategoryBreakdowns = {
    [tickCategories.BOSSKILL] = "%d/%d boss kills",
    [tickCategories.BOSSWIPE] = "%d/%d boss attempts",
    [tickCategories.ONTIME] = "on-time",
    [tickCategories.MANUAL] = "%d/%d manual",
};

local tickCategoriesSorted = {
    tickCategories.ONTIME,
    tickCategories.BOSSKILL,
    tickCategories.BOSSWIPE,
    tickCategories.MANUAL,
};

local function MakeRaid()
    return {
        instanceId = -1,
        name = "Custom",
        players = {},
        ticks = {},
        allowedTicks = {},
        standby = {},
        bossKills = {},
        startTime = GetServerTime(),
        stopTime = GetServerTime(),
    };
end

local function TrackPlayer(raid, player, inRaid)
    raid.players[player] = raid.players[player] or {};

    if inRaid then
        for i, standby in ipairs(raid.standby) do
            if standby == player then
                table.remove(raid.standby, i);
                break;
            end
        end
    end
end

local function IsInProgress(raid)
    return (raid and raid == _G.ABGP_RaidInfo3.currentRaid);
end

local function EnsureAwardsEntries(raid)
    TrackPlayer(raid, UnitName("player"), true);
    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end

        local player = UnitName(unit);
        TrackPlayer(raid, UnitName(unit), true);
    end

    for _, standby in ipairs(raid.standby) do
        TrackPlayer(raid, standby, false);
    end
end

local function AwardPlayerEP(raid, player, tick)
    raid.players[player][tick.time] = true;
end

local function AddStandby(raid, player)
    if tContains(raid.standby, player) or player == UnitName("player") then return; end

    ABGP:Notify("Adding %s to the standby list.", ABGP:ColorizeName(player));
    table.insert(raid.standby, player);
    EnsureAwardsEntries(raid);
end

local function RemoveStandby(raid, player)
    for i, standby in ipairs(raid.standby) do
        if standby == player then
            table.remove(raid.standby, i);
            break;
        end
    end
end

local function RemovePlayer(raid, player)
    raid.players[player] = nil;
    RemoveStandby(raid, player);
end

local function CountPlayerTicks(raid, player, category)
    local tickCount = 0;
    for tickTime, wasPresent in pairs(raid.players[player]) do
        if wasPresent and raid.allowedTicks[tickTime] and (not category or raid.ticks[tickTime].category == category) then
            tickCount = tickCount + 1;
        end
    end
    return tickCount;
end

local function CountValidTicks(raid, category)
    local totalTicks = 0;
    local totalValidTicks = 0;
    for _, tick in pairs(raid.ticks) do
        if not category or tick.category == category then
            totalTicks = totalTicks + 1;
            if raid.allowedTicks[tick.time] then
                totalValidTicks = totalValidTicks + 1;
            end
        end
    end

    return totalValidTicks, totalTicks;
end

local currentInstance;
local activeWindow;
local lastTickTime = 0;

local function RefreshUI()
    if not activeWindow then return; end
    local windowRaid = activeWindow:GetUserData("raid");
    if not windowRaid then return; end

    local scroll = activeWindow:GetUserData("standbyList");
    if scroll then
        scroll:ReleaseChildren();

        for _, standby in ipairs(windowRaid.standby) do
            local elt = AceGUI:Create("ABGP_Header");
            elt:SetFullWidth(true);
            elt:SetText(ABGP:ColorizeName(standby));
            elt:EnableHighlight(true);
            scroll:AddChild(elt);

            elt:SetUserData("player", standby);
            elt:SetCallback("OnClick", function(widget, event, button)
                if button == "RightButton" then
                    ABGP:ShowContextMenu({
                        {
                            text = "Remove from standby",
                            func = function(self, player)
                                RemoveStandby(windowRaid, player);
                                RefreshUI();
                            end,
                            arg1 = widget:GetUserData("player"),
                            notCheckable = true
                        },
                        { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" },
                    });
                end
            end);
        end
    end

    if activeWindow:GetUserData("popup") then
        activeWindow:GetUserData("popup"):Hide();
        ABGP:ManageRaid(activeWindow);
    end
end

local function GetTickServerTime()
    local nextTime = max(lastTickTime, GetServerTime());
    if nextTime == lastTickTime then nextTime = nextTime + 1; end
    lastTickTime = nextTime;
    return nextTime;
end

local function AwardEP(raid, category, extra)
    ABGP:Notify("Applying EP tick to the current raid and standby (%s)!", tickCategoryNames[category]);
    local tick = { time = GetTickServerTime(), category = category, extra = extra };
    raid.ticks[tick.time] = tick;
    raid.allowedTicks[tick.time] = true;

    EnsureAwardsEntries(raid);
    if IsInProgress(raid) then
        raid.stopTime = tick.time;
        local groupSize = GetNumGroupMembers();
        if groupSize == 0 then
            AwardPlayerEP(raid, UnitName("player"), tick);
        else
            for i = 1, groupSize do
                local unit = "player";
                if IsInRaid() then
                    unit = "raid" .. i;
                elseif i ~= groupSize then
                    unit = "party" .. i;
                end

                local player = UnitName(unit);
                AwardPlayerEP(raid, player, tick);
            end
        end

        for _, player in ipairs(raid.standby) do
            AwardPlayerEP(raid, player, tick);
        end
    else
        for player in pairs(raid.players) do
            AwardPlayerEP(raid, player, tick);
        end
    end

    RefreshUI();
end

function ABGP:InitEvents()
    if not _G.ABGP_RaidInfo3.pastRaids then return; end

    -- Convert ticks from array to map with time as key.
    for _, raid in ipairs(_G.ABGP_RaidInfo3.pastRaids) do
        if not raid.convertedTicks then
            local convert = false;
            for idx in pairs(raid.ticks) do
                if idx < 10000 then
                    convert = true;
                    break;
                end
            end
            if convert then
                raid.convertedTicks = true;
                local newTicks = {};
                for _, tick in pairs(raid.ticks) do
                    newTicks[tick.time] = tick;
                end
                raid.ticks = newTicks;
            end
        end
    end
end

function ABGP:GetRaidStatistics(raid)
    local ticks = CountValidTicks(raid);
    local kills = CountValidTicks(raid, tickCategories.BOSSKILL);
    local wipes = CountValidTicks(raid, tickCategories.BOSSWIPE);
    return ticks, kills, wipes;
end

function ABGP:IsRaidInProgress()
    return _G.ABGP_RaidInfo3.currentRaid ~= nil;
end

local function CheckBossEP(bossId, bossName, wasWipe)
    -- Check for info about the boss and an in-progress raid.
    local info = bossInfo[bossId];
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not (currentRaid and info) then return; end

    -- Check that the boss is for this raid.
    local raidInstance = currentRaid.instanceId;
    if info.instance ~= raidInstance then return; end

    if wasWipe then
        ABGP:LogDebug("This wipe is worth EP.");
        AwardEP(currentRaid, tickCategories.BOSSWIPE, bossName);
    elseif not currentRaid.bossKills[info.name] then
        ABGP:LogDebug("This boss is worth EP.");
        AwardEP(currentRaid, tickCategories.BOSSKILL, bossName);
        currentRaid.bossKills[info.name] = GetServerTime();

        -- See if we killed the final boss of the current raid.
        local bosses = instanceInfo[raidInstance].bosses;
        if bosses[#bosses] == bossId then
            ABGP:UpdateRaid();
        end
    end
end

function ABGP:EventOnBossKilled(bossId, name)
    self:LogDebug("%s[%d] defeated!", bossId, name);
    CheckBossEP(bossId, name);
end

function ABGP:EventOnBossLoot(data, distribution, sender)
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    local instance = instanceInfo[currentRaid.instanceId];
    if not instance then return; end

    -- See if the name corresponds to any bosses in the current instance.
    for _, id in ipairs(instance.bosses) do
        if bossInfo[id].name == data.name then
            CheckBossEP(id, data.name);
            break;
        end
    end
end

function ABGP:EventOnEncounterEnd(bossId, name, difficulty, groupSize, success)
    if success ~= 0 then return; end
    self:LogDebug("Wipe on %d[%d]!", bossId, name);
    CheckBossEP(bossId, name, true);
end

function ABGP:EventOnZoneChanged(name, instanceId)
    self:LogDebug("Zone changed to %s[%d]!", name, instanceId);
    currentInstance = instanceId;
    local info = instanceInfo[instanceId];
    if info and info.promptRaidStart then
        -- Gently suggest that a raid gets started.
        if self:IsPrivileged() and not self:IsRaidInProgress() and self:Get("promptRaidStart") then
            self:StartRaid();
        end
    end

    if self:IsRaidInProgress() then
        self:UpdateRaid();
    end
end

function ABGP:ShowRaidWindow()
    if self:IsRaidInProgress() then
        self:UpdateRaid();
    elseif not activeWindow then
        self:StartRaid();
    end
end

function ABGP:StartRaid()
    local raidInstance;
    local windowRaid = MakeRaid();
    if activeWindow then activeWindow:Hide(); end

    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("MEDIUM");
    window:SetLayout("Flow");
    window:SetTitle(("%s Raid"):format(self:ColorizeText("ABGP")));
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local container = AceGUI:Create("SimpleGroup");
    container:SetFullWidth(true);
    container:SetLayout("Flow");
    window:AddChild(container);

    local custom = -1;
    local instances = {
        [instanceIds.MoltenCore] = instanceInfo[instanceIds.MoltenCore].name,
        [instanceIds.BlackwingLair] = instanceInfo[instanceIds.BlackwingLair].name,
        [instanceIds.AQ40] = instanceInfo[instanceIds.AQ40].name,
        [instanceIds.Onyxia] = instanceInfo[instanceIds.Onyxia].name,
        [instanceIds.ZulGurub] = instanceInfo[instanceIds.ZulGurub].name,
        [instanceIds.AQ20] = instanceInfo[instanceIds.AQ20].name,
        [custom] = "Custom",
    };
    local instanceSelector = AceGUI:Create("Dropdown");
    instanceSelector:SetFullWidth(true);
    instanceSelector:SetLabel("Instance");
    instanceSelector:SetList(instances, {
        instanceIds.MoltenCore,
        instanceIds.BlackwingLair,
        instanceIds.AQ40,
        instanceIds.Onyxia,
        instanceIds.ZulGurub,
        instanceIds.AQ20,
        custom });
    instanceSelector:SetCallback("OnValueChanged", function(widget, event, value)
        raidInstance = value;
        window:GetUserData("nameEdit"):SetValue(instances[raidInstance]);
        window:GetUserData("nameEdit"):SetDisabled(value ~= custom);
    end);
    container:AddChild(instanceSelector);
    self:AddWidgetTooltip(instanceSelector, "If a preset instance is chosen, EP will automatically be recorded for boss kills.");

    local name = AceGUI:Create("ABGP_EditBox");
    name:SetFullWidth(true);
    name:SetMaxLetters(32);
    name:SetLabel("Name");
    container:AddChild(name);
    window:SetUserData("nameEdit", name);

    local addStandby = AceGUI:Create("Button");
    addStandby:SetFullWidth(true);
    addStandby:SetText("Add Standby");
    addStandby:SetCallback("OnClick", function(widget)
        _G.StaticPopup_Show("ABGP_ADD_STANDBY", nil, nil, windowRaid);
    end);
    container:AddChild(addStandby);
    self:AddWidgetTooltip(addStandby, "Add a player to the standby list.");

    local elt = AceGUI:Create("ABGP_Header");
    elt:SetFullWidth(true);
    elt:SetText("Current standby list:");
    container:AddChild(elt);

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetHeight(100);
    scrollContainer:SetLayout("Fill");
    container:AddChild(scrollContainer);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("standbyList", scroll);

    local start = AceGUI:Create("Button");
    start:SetFullWidth(true);
    start:SetText("Start");
    start:SetCallback("OnClick", function(widget)
        windowRaid.instanceId = raidInstance;
        windowRaid.name = name:GetValue();
        _G.ABGP_RaidInfo3.currentRaid = windowRaid;
        EnsureAwardsEntries(windowRaid);
        self:Notify("Starting a new raid!");
        AwardEP(windowRaid, tickCategories.ONTIME);
        window:Hide();
        self:UpdateRaid();
    end);
    container:AddChild(start);
    self:AddWidgetTooltip(start, "Start the raid.");

    local startingValue = instanceInfo[currentInstance] and currentInstance or custom;
    instanceSelector:SetValue(startingValue);
    instanceSelector:Fire("OnValueChanged", startingValue);

    container:DoLayout();
    self:BeginWindowManagement(window, "raid", {
        version = 1,
        defaultWidth = 200,
        defaultHeight = container.frame:GetHeight() + 57,
    });

    activeWindow = window;
    window.frame:Raise();
    window:SetUserData("raid", windowRaid);
end

function ABGP:ManageRaid(window)
    local windowRaid = window:GetUserData("raid");
    local popup = window:GetUserData("popup");
    if popup then
        popup:Hide();
        return;
    end

    local popup = AceGUI:Create("Window");
    popup.frame:SetFrameStrata("DIALOG");
    popup:SetTitle("Manage EP");
    popup:SetLayout("Flow");
    popup:SetCallback("OnClose", function(widget)
        ABGP:ClosePopup(widget);
        ABGP:EndWindowManagement(widget);
        AceGUI:Release(widget);
        window:SetUserData("popup", nil);
    end);
    local popupWidth = 435;
    local popupHeight = 300;
    popup:SetWidth(popupWidth);
    popup:SetHeight(popupHeight);
    ABGP:OpenPopup(popup);
    local _, _, screenWidth = _G.UIParent:GetRect();
    local windowLeft, _, windowWidth = window.frame:GetRect();
    popup.frame:ClearAllPoints();
    if screenWidth - windowWidth - windowLeft >= popupWidth then
        popup.frame:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    else
        popup.frame:SetPoint("TOPRIGHT", window.frame, "TOPLEFT");
    end

    local sorted = {};
    for player in pairs(windowRaid.players) do table.insert(sorted, player); end
    table.sort(sorted);

    local tickValues, ticksSorted = {}, {};
    for _, tick in pairs(windowRaid.ticks) do
        local extra = tick.extra and (" (%s)"):format(tick.extra) or "";
        local text = ("%s: %s%s"):format(date("%I:%M%p", tick.time), tickCategoryNames[tick.category], extra);
        tickValues[tick.time] = text;
        table.insert(ticksSorted, tick.time);
    end
    table.sort(ticksSorted);

    local valid, total = CountValidTicks(windowRaid);
    local allowedTicks = AceGUI:Create("ABGP_Filter");
    allowedTicks:SetValues(windowRaid.allowedTicks, false, tickValues, ticksSorted);
    allowedTicks:SetFullWidth(true);
    allowedTicks:SetDefaultText(("Attendance ticks (%d total, %d active)"):format(total, valid));
    allowedTicks:SetCallback("OnFilterClosed", function()
        RefreshUI();
    end);
    popup:AddChild(allowedTicks);
    self:AddWidgetTooltip(allowedTicks, "Select the ticks that should be used for attendance.");

    local container = AceGUI:Create("InlineGroup");
    container:SetLayout("Fill");
    container:SetFullWidth(true);
    container:SetFullHeight(true);
    container:SetTitle("Attendance");
    popup:AddChild(container);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("Table");
    scroll:SetUserData("table", { columns = { 120, 200, 50 } });
    container:AddChild(scroll);

    local allowedTickValues, allowedTicksSorted = {}, {};
    for _, tick in pairs(windowRaid.ticks) do
        if windowRaid.allowedTicks[tick.time] then
            local extra = tick.extra and (" (%s)"):format(tick.extra) or "";
            local text = ("%s: %s%s"):format(date("%I:%M%p", tick.time), tickCategoryNames[tick.category], extra);
            allowedTickValues[tick.time] = text;
            table.insert(allowedTicksSorted, tick.time);
        end
    end
    table.sort(allowedTicksSorted);

    for _, player in ipairs(sorted) do
        local elt = AceGUI:Create("ABGP_Header");
        elt:SetFullWidth(true);
        elt:SetText(self:ColorizeName(player));
        scroll:AddChild(elt);

        local tickFilter = AceGUI:Create("ABGP_Filter");
        tickFilter:SetValues(windowRaid.players[player], false, allowedTickValues, allowedTicksSorted);
        tickFilter:SetFullWidth(true);
        tickFilter:SetText(("Ticks (%d)"):format(CountPlayerTicks(windowRaid, player)));
        tickFilter:SetCallback("OnFilterClosed", function(widget)
            widget:SetText(("Ticks (%d)"):format(CountPlayerTicks(windowRaid, player)));
        end);
        scroll:AddChild(tickFilter);
        self:AddWidgetTooltip(tickFilter, "Select the ticks for which the player was present.");

        elt = AceGUI:Create("Button");
        elt:SetFullWidth(true);
        elt:SetText("X");
        elt:SetCallback("OnClick", function()
            _G.StaticPopup_Show("ABGP_REMOVE_FROM_RAID", self:ColorizeName(player), nil, { player = player, raid = windowRaid });
        end);
        scroll:AddChild(elt);
        self:AddWidgetTooltip(elt, "Remove the player's data.");
    end

    window:SetUserData("popup", popup);
    self:BeginWindowManagement(popup, "popup", {
        defaultWidth = popupWidth,
        defaultHeight = popupHeight,
    });
end

function ABGP:UpdateRaid(windowRaid)
    windowRaid = windowRaid or _G.ABGP_RaidInfo3.currentRaid;
    if not windowRaid then return; end
    if activeWindow then activeWindow:Hide(); end

    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("MEDIUM");
    window:SetLayout("Flow");
    window:SetTitle(windowRaid.name);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        local popup = widget:GetUserData("popup");
        if popup then popup:Hide(); end
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local container = AceGUI:Create("SimpleGroup");
    container:SetFullWidth(true);
    container:SetLayout("Flow");
    window:AddChild(container);

    local manageEP = AceGUI:Create("Button");
    manageEP:SetFullWidth(true);
    manageEP:SetText("Manage EP");
    manageEP:SetCallback("OnClick", function(widget)
        self:ManageRaid(window);
    end);
    container:AddChild(manageEP);
    self:AddWidgetTooltip(manageEP, "Open the window to individually manage everyone's awarded EP.");

    local manualTIck = AceGUI:Create("Button");
    manualTIck:SetFullWidth(true);
    manualTIck:SetText("Manual Tick");
    manualTIck:SetCallback("OnClick", function(widget)
        AwardEP(windowRaid, tickCategories.MANUAL);
    end);
    container:AddChild(manualTIck);
    self:AddWidgetTooltip(manualTIck, "Manually trigger an attendance tick.");

    local addStandby = AceGUI:Create("Button");
    addStandby:SetFullWidth(true);
    addStandby:SetText("Add Standby");
    addStandby:SetCallback("OnClick", function(widget)
        _G.StaticPopup_Show("ABGP_ADD_STANDBY", nil, nil, windowRaid);
    end);
    container:AddChild(addStandby);
    self:AddWidgetTooltip(addStandby, "Add a player to the standby list.");

    local elt = AceGUI:Create("ABGP_Header");
    elt:SetFullWidth(true);
    elt:SetText("Current standby list:");
    container:AddChild(elt);

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetHeight(100);
    scrollContainer:SetLayout("Fill");
    container:AddChild(scrollContainer);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("standbyList", scroll);

    if IsInProgress(windowRaid) then
        local stop = AceGUI:Create("Button");
        stop:SetFullWidth(true);
        stop:SetText("Stop");
        stop:SetCallback("OnClick", function(widget)
            _G.ABGP_RaidInfo3.pastRaids = _G.ABGP_RaidInfo3.pastRaids or {};
            local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
            _G.ABGP_RaidInfo3.currentRaid = nil;

            for player in pairs(currentRaid.players) do
                if CountPlayerTicks(currentRaid, player) == 0 then currentRaid.players[player] = nil; end
            end
            if next(currentRaid.players) then
                self:Notify("Stopping the raid!");
                table.insert(_G.ABGP_RaidInfo3.pastRaids, 1, currentRaid);
                window:Hide();
                self:UpdateRaid(windowRaid);
            else
                self:Notify("No players with ticks in this raid. It has been deleted.");
                window:Hide();
            end
        end);
        container:AddChild(stop);
        self:AddWidgetTooltip(stop, "Stop the raid.");
    else
        local export = AceGUI:Create("Button");
        export:SetFullWidth(true);
        export:SetText("Export");
        export:SetCallback("OnClick", function(widget)
            self:ExportRaid(windowRaid);
        end);
        container:AddChild(export);
        self:AddWidgetTooltip(export, "Open the window to export this raid's EP in the spreadsheet.");

        local delete = AceGUI:Create("Button");
        delete:SetFullWidth(true);
        delete:SetText("Delete");
        delete:SetCallback("OnClick", function(widget)
            ABGP:DeleteRaid(windowRaid);
        end);
        container:AddChild(delete);
        self:AddWidgetTooltip(delete, "Delete the raid.");
    end

    container:DoLayout();
    self:BeginWindowManagement(window, "raidUpdate", {
        version = 1,
        defaultWidth = 200,
        defaultHeight = container.frame:GetHeight() + 57,
    });

    window:SetUserData("raid", windowRaid);
    activeWindow = window;
    window.frame:Raise();
    RefreshUI();
end

function ABGP:DeleteRaid(raid)
    _G.StaticPopup_Show("ABGP_DELETE_RAID", nil, nil, raid);
end

function ABGP:ExportRaid(windowRaid)
    local raidDate = date("%m/%d/%y", windowRaid.startTime); -- https://strftime.org/
    local totalTicks = CountValidTicks(windowRaid);

    local substitutions = {};
    local function buildExportText()
        local sortedPlayers = {};
        for player in pairs(windowRaid.players) do
            table.insert(sortedPlayers, player);
        end
        table.sort(sortedPlayers, function(a, b)
            a = substitutions[a] or a;
            b = substitutions[b] or b;

            local aActive = self:GetActivePlayer(a);
            local bActive = self:GetActivePlayer(b);
            if not aActive and not bActive then return a < b; end
            if aActive and bActive then
                if aActive.raidGroup == bActive.raidGroup then
                    if aActive.rank == bActive.rank then return a < b; end
                    return aActive.rank < bActive.rank;
                end
                return self.RaidGroupsSortedReverse[aActive.raidGroup] < self.RaidGroupsSortedReverse[bActive.raidGroup];
            end
            return aActive ~= nil;
        end);

        local text = "";
        for _, player in ipairs(sortedPlayers) do
            local tickCount = CountPlayerTicks(windowRaid, player);
            if tickCount > 0 then
                local exportedPlayer = substitutions[player] or player;
                local ep = math.floor(tickCount / totalTicks * 100 + 0.5);
                local epgp = self:GetActivePlayer(exportedPlayer);
                local breakdown = {};
                local rank = "";
                local raidGroup = "";

                for _, category in ipairs(tickCategoriesSorted) do
                    local categoryCount = CountPlayerTicks(windowRaid, player, category);
                    if categoryCount > 0 then
                        local totalCategoryTicks = CountValidTicks(windowRaid, category);
                        table.insert(breakdown, tickCategoryBreakdowns[category]:format(categoryCount, totalCategoryTicks));
                    end
                end

                if epgp then
                    rank = epgp.rank;
                    raidGroup = self.RaidGroupNames[epgp.raidGroup];
                    if epgp.trial then
                        table.insert(breakdown, 1, "Trial");
                        ep = 0;
                    end
                else
                    table.insert(breakdown, 1, "Non-raider");
                    ep = 0;
                end

                if exportedPlayer ~= player then
                    table.insert(breakdown, ("attended on %s"):format(player));
                end

                text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                    ep, "EP", windowRaid.name, exportedPlayer, raidDate, raidGroup, rank, table.concat(breakdown, ", "));
            end
        end

        return text;
    end

    local exportEdit;
    local extra = AceGUI:Create("InlineGroup");
    extra:SetFullWidth(true);
    extra:SetTitle("Substitutions");
    extra:SetLayout("Flow");
    local edit = AceGUI:Create("MultiLineEditBox");
    edit:SetFullWidth(true);
    edit:SetLabel("Enter two names per row. If the first name attended the raid, they will be treated as the second name for EPGP.");
    edit:SetCallback("OnEnterPressed", function(widget, event, value)
        substitutions = {};
        local lines = { ("\n"):split(value) };
        for _, line in ipairs(lines) do
            local first, second = line:match("^(%S+)%s*(%S+)$");
            if first and second then
                substitutions[first] = second;
            end
        end
        exportEdit:SetText(buildExportText());
    end);
    extra:AddChild(edit);

    exportEdit = self:OpenExportWindow(buildExportText(), extra);
end

function ABGP:EventOnGroupJoined()
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    EnsureAwardsEntries(currentRaid);
end

function ABGP:EventOnGroupUpdate()
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    EnsureAwardsEntries(currentRaid);
    RefreshUI();
end

StaticPopupDialogs["ABGP_ADD_STANDBY"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Add a player to the standby list:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    autoCompleteSource = GetAutoCompleteResults,
    autoCompleteArgs = { bit.bor(AUTOCOMPLETE_FLAG_ONLINE, AUTOCOMPLETE_FLAG_INTERACTED_WITH, AUTOCOMPLETE_FLAG_IN_GUILD), bit.bor(AUTOCOMPLETE_FLAG_BNET, AUTOCOMPLETE_FLAG_IN_GROUP) },
    Commit = function(text, data)
        AddStandby(data, text);
        RefreshUI();
    end,
});
StaticPopupDialogs["ABGP_DELETE_RAID"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Delete this raid? This can't be undone!",
    button1 = "Yes",
    button2 = "No",
    showAlert = true,
    OnAccept = function(self, data)
        local raids = _G.ABGP_RaidInfo3.pastRaids;
        for i, raid in ipairs(raids) do
            if raid == data then
                table.remove(raids, i);
                ABGP:Notify("Deleted the raid!");
                if activeWindow then activeWindow:Hide(); end
                ABGP:RefreshUI();
                break;
            end
        end
    end,
});
StaticPopupDialogs["ABGP_REMOVE_FROM_RAID"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Remove %s's data from the raid?",
    button1 = "Yes",
    button2 = "No",
    showAlert = true,
    OnAccept = function(self, data)
        RemovePlayer(data.raid, data.player);
        RefreshUI();
    end,
});
