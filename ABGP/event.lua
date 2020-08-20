local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetServerTime = GetServerTime;
local GetNumGroupMembers = GetNumGroupMembers;
local UnitIsGroupLeader = UnitIsGroupLeader;
local GetLootMethod = GetLootMethod;
local SetLootMethod = SetLootMethod;
local GetLootThreshold = GetLootThreshold;
local SetLootThreshold = SetLootThreshold;
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

_G.ABGP_RaidInfo3 = {};

-- https://wow.gamepedia.com/InstanceID
local instanceIds = {
    MoltenCore      = 409,
    -- Onyxia          = 249,
    BlackwingLair   = 469,
    -- ZulGurub        = 309,
    -- AQ20            = 509,
    AQ40            = 531,
};

-- https://wow.tools/dbc/?dbc=dungeonencounter
local bossIds = {
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

    -- Onyxia      = 1084,

    Razorgore   = 610,
    Vaelastrasz = 611,
    Broodlord   = 612,
    Firemaw     = 613,
    Ebonroc     = 614,
    Flamegor    = 615,
    Chromaggus  = 616,
    Nefarian    = 617,

    -- Venoxis     = 784,
    -- Jeklik      = 785,
    -- Marli       = 786,
    -- Mandokir    = 787,
    -- Madness     = 788,
    -- Thekal      = 789,
    -- Gahzranka   = 790,
    -- Arlokk      = 791,
    -- Jindo       = 792,
    -- Hakkar      = 793,

    Skeram      = 709,
    BugTrio     = 710,
    Sartura     = 711,
    Fankriss    = 712,
    Viscidus    = 713,
    Huhuran     = 714,
    TwinEmps    = 715,
    Ouro        = 716,
    Cthun       = 717,

    -- Kurinnaxx   = 718,
    -- Rajaxx      = 719,
    -- Moam        = 720,
    -- Buru        = 721,
    -- Ayamiss     = 722,
    -- Ossirian    = 723,
};

local instanceInfo = {
    [instanceIds.MoltenCore]  = {
        name = "Molten Core",
        bosses = {
            bossIds.Lucifron, bossIds.Magmadar, bossIds.Gehennas, bossIds.Garr, bossIds.Shazzrah,
            bossIds.Geddon, bossIds.Sulfuron, bossIds.Golemagg, bossIds.Majordomo, bossIds.Ragnaros
        },
    },
    [instanceIds.BlackwingLair] = {
        name = "Blackwing Lair",
        bosses = {
            bossIds.Razorgore, bossIds.Vaelastrasz, bossIds.Broodlord, bossIds.Firemaw,
            bossIds.Ebonroc, bossIds.Flamegor, bossIds.Chromaggus, bossIds.Nefarian
        },
    },
    [instanceIds.AQ40] = {
        name = "Temple of Ahn'Qiraj",
        bosses = {
            bossIds.Skeram, bossIds.BugTrio, bossIds.Sartura, bossIds.Fankriss, bossIds.Viscidus,
            bossIds.Huhuran, bossIds.TwinEmps, bossIds.Ouro, bossIds.Cthun
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

    [bossIds.Skeram]      = { instance = instanceIds.AQ40, name = "The Prophet Skeram" },
    [bossIds.BugTrio]     = { instance = instanceIds.AQ40, name = "Silithid Royalty" },
    [bossIds.Sartura]     = { instance = instanceIds.AQ40, name = "Battleguard Sartura" },
    [bossIds.Fankriss]    = { instance = instanceIds.AQ40, name = "Fankriss the Unyielding" },
    [bossIds.Viscidus]    = { instance = instanceIds.AQ40, name = "Viscidus" },
    [bossIds.Huhuran]     = { instance = instanceIds.AQ40, name = "Princess Huhuran" },
    [bossIds.TwinEmps]    = { instance = instanceIds.AQ40, name = "Twin Emperors" },
    [bossIds.Ouro]        = { instance = instanceIds.AQ40, name = "Ouro" },
    [bossIds.Cthun]       = { instance = instanceIds.AQ40, name = "C'thun" },
};

local function MakeRaid()
    return {
        instanceId = -1,
        name = "Custom",
        ticks = {},
        standby = {},
        bossKills = {},
        startTime = GetServerTime(),
        stopTime = GetServerTime(),
        disenchanter = nil,
        autoDistribute = false,
        mule = nil,
        trackAttendance = false,
        totalTicks = 0,
    };
end

local function TrackPlayer(raid, player, inRaid)
    raid.ticks[player] = raid.ticks[player] or 0;

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

local function AwardPlayerEP(raid, player)
    raid.ticks[player] = raid.ticks[player] + 1;
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
    raid.ticks[player] = nil;
    RemoveStandby(raid, player);
end

local currentInstance;
local activeWindow;
local pendingLootMethod;
local pendingLootThreshold;
local checkCombatWhilePending;

local function RefreshUI()
    if not activeWindow then return; end
    local windowRaid = activeWindow:GetUserData("raid");
    if not windowRaid then return; end

    local disenchanter = activeWindow:GetUserData("disenchanter");
    if disenchanter then
        disenchanter:SetValue(windowRaid.disenchanter);
    end

    local mule = activeWindow:GetUserData("mule");
    if mule then
        mule:SetValue(windowRaid.mule);
    end

    local lootMethod = activeWindow:GetUserData("lootMethod");
    if lootMethod then
        lootMethod:SetValue(GetLootMethod());
    end

    local lootTh = activeWindow:GetUserData("lootThreshold");
    if lootTh then
        lootTh:SetValue(GetLootThreshold());
    end

    local autoDistrib = activeWindow:GetUserData("autoDistrib");
    if autoDistrib then
        autoDistrib:SetValue(windowRaid.autoDistribute);
    end

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

local function AwardEP(raid, text)
    raid.totalTicks = raid.totalTicks + 1;
    ABGP:Notify("Applying EP tick to the current raid and standby (%s)!", text);

    EnsureAwardsEntries(raid);
    if IsInProgress(raid) then
        raid.stopTime = GetServerTime();
        local groupSize = GetNumGroupMembers();
        if groupSize == 0 then
            AwardPlayerEP(raid, UnitName("player"));
        else
            for i = 1, groupSize do
                local unit = "player";
                if IsInRaid() then
                    unit = "raid" .. i;
                elseif i ~= groupSize then
                    unit = "party" .. i;
                end

                local player = UnitName(unit);
                AwardPlayerEP(raid, player);
            end
        end

        for _, player in ipairs(raid.standby) do
            AwardPlayerEP(raid, player);
        end
    else
        for player in pairs(raid.ticks) do
            AwardPlayerEP(raid, player);
        end
    end

    RefreshUI();
end

function ABGP:IsRaidInProgress()
    return _G.ABGP_RaidInfo3.currentRaid ~= nil;
end

function ABGP:SetDisenchanter(player)
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    if player == "" then
        player = nil;
        self:Notify("Will not send disenchanted items to anyone.");
    else
        self:Notify("Sending disenchanted items to %s.", self:ColorizeName(player));
    end
    currentRaid.disenchanter = player;
    RefreshUI();
end

function ABGP:GetRaidDisenchanter()
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    return currentRaid.disenchanter;
end

function ABGP:SetMule(player)
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    if player == "" then
        player = nil;
        self:Notify("Clearing the designated raid mule.");
    else
        self:Notify("Sending muled items to %s.", self:ColorizeName(player));
    end
    currentRaid.mule = player;
    RefreshUI();
end

function ABGP:GetRaidMule()
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    return currentRaid.mule;
end

function ABGP:ShouldAutoDistribute()
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    return currentRaid.autoDistribute;
end

local function CheckBossEP(bossId, wasWipe)
    -- Check for info about the boss and an in-progress raid.
    local info = bossInfo[bossId];
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not (currentRaid and info) then return; end

    -- Check that the boss is for this raid.
    local raidInstance = currentRaid.instanceId;
    if info.instance ~= raidInstance then return; end

    if wasWipe then
        ABGP:LogDebug("This wipe is worth EP.");
        AwardEP(currentRaid, "boss attempt");
    elseif not currentRaid.bossKills[info.name] then
        ABGP:LogDebug("This boss is worth EP.");
        AwardEP(currentRaid, "boss kill");
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
    CheckBossEP(bossId);
end

function ABGP:EventOnBossLoot(data, distribution, sender)
    local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
    if not currentRaid then return; end

    local instance = instanceInfo[currentRaid.instanceId];
    if not instance then return; end

    -- See if the name corresponds to any bosses in the current instance.
    for _, id in ipairs(instance.bosses) do
        if bossInfo[id].name == data.name then
            CheckBossEP(id);
            break;
        end
    end
end

function ABGP:EventOnEncounterEnd(bossId, name, difficulty, groupSize, success)
    if success ~= 0 then return; end
    self:LogDebug("Wipe on %d[%d]!", bossId, name);
    CheckBossEP(bossId, true);
end

function ABGP:EventOnZoneChanged(name, instanceId)
    self:LogDebug("Zone changed to %s[%d]!", name, instanceId);
    currentInstance = instanceId;
    local info = instanceInfo[instanceId];
    if info then
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
        [custom] = "Custom",
    };
    local instanceSelector = AceGUI:Create("Dropdown");
    instanceSelector:SetFullWidth(true);
    instanceSelector:SetLabel("Instance");
    instanceSelector:SetList(instances, { instanceIds.MoltenCore, instanceIds.BlackwingLair, instanceIds.AQ40, custom });
    instanceSelector:SetCallback("OnValueChanged", function(widget, event, value)
        raidInstance = value;
        window:GetUserData("nameEdit"):SetValue(instances[raidInstance]);
        window:GetUserData("nameEdit"):SetDisabled(value ~= custom);
        window:GetUserData("attendanceTrack"):SetValue(value ~= custom);
        window:GetUserData("addStandby"):SetDisabled(value == custom);
    end);
    container:AddChild(instanceSelector);
    self:AddWidgetTooltip(instanceSelector, "If a preset instance is chosen, EP will automatically be recorded for boss kills.");

    local name = AceGUI:Create("ABGP_EditBox");
    name:SetFullWidth(true);
    name:SetMaxLetters(32);
    name:SetLabel("Name");
    container:AddChild(name);
    window:SetUserData("nameEdit", name);

    local attendanceTrack = AceGUI:Create("CheckBox");
    attendanceTrack:SetFullWidth(true);
    attendanceTrack:SetLabel("Track Attendance");
    attendanceTrack:SetCallback("OnValueChanged", function(widget, event, value)
        window:GetUserData("addStandby"):SetDisabled(not value);
    end);
    container:AddChild(attendanceTrack);
    window:SetUserData("attendanceTrack", attendanceTrack);
    self:AddWidgetTooltip(attendanceTrack, "If selected, attendance will be tracked for future export.");

    local addStandby = AceGUI:Create("Button");
    addStandby:SetFullWidth(true);
    addStandby:SetText("Add Standby");
    addStandby:SetCallback("OnClick", function(widget)
        _G.StaticPopup_Show("ABGP_ADD_STANDBY", nil, nil, windowRaid);
    end);
    window:SetUserData("addStandby", addStandby);
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
        windowRaid.trackAttendance = attendanceTrack:GetValue();
        _G.ABGP_RaidInfo3.currentRaid = windowRaid;
        EnsureAwardsEntries(windowRaid);
        self:Notify("Starting a new raid!");
        if windowRaid.trackAttendance then
            AwardEP(windowRaid, "on-time bonus");
        end
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
    popup:SetLayout("Fill");
    popup:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget);
        ABGP:ClosePopup(widget);
        window:SetUserData("popup", nil);
    end);
    local popupWidth = 300;
    popup:SetWidth(popupWidth);
    popup:SetHeight(300);
    ABGP:OpenPopup(popup);
    local _, _, screenWidth = _G.UIParent:GetRect();
    local windowLeft, _, windowWidth = window.frame:GetRect();
    popup.frame:ClearAllPoints();
    if screenWidth - windowWidth - windowLeft >= popupWidth then
        popup.frame:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    else
        popup.frame:SetPoint("TOPRIGHT", window.frame, "TOPLEFT");
    end

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("Table");
    scroll:SetUserData("table", { columns = { 120, 90, 40 } });
    popup:AddChild(scroll);

    local sorted = {};
    for player in pairs(windowRaid.ticks) do table.insert(sorted, player); end
    table.sort(sorted);

    for _, player in ipairs(sorted) do
        local elt = AceGUI:Create("ABGP_Header");
        elt:SetFullWidth(true);
        elt:SetText(self:ColorizeName(player));
        scroll:AddChild(elt);

        local ticks = AceGUI:Create("Dropdown");
        ticks:SetText("Ticks");
        ticks:SetFullWidth(true);
        ticks:SetCallback("OnValueChanged", function(widget, event, value)
            windowRaid.ticks[player] = value;
            widget:SetText(("Ticks: %d"):format(windowRaid.ticks[player]));
        end);
        scroll:AddChild(ticks);
        self:AddWidgetTooltip(ticks, "Select the number of ticks for which the player was present.");
        local values = {};
        for i = 0, windowRaid.totalTicks do values[i] = i; end
        ticks:SetList(values);
        ticks:SetValue(windowRaid.ticks[player]);
        ticks:SetText(("Ticks: %d"):format(windowRaid.ticks[player]));

        elt = AceGUI:Create("Button");
        elt:SetText("X");
        elt:SetCallback("OnClick", function()
            _G.StaticPopup_Show("ABGP_REMOVE_FROM_RAID", self:ColorizeName(player), nil, { player = player, raid = windowRaid });
        end);
        scroll:AddChild(elt);
        self:AddWidgetTooltip(elt, "Remove the player's data.");
    end

    window:SetUserData("popup", popup);
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

    if windowRaid.trackAttendance then
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
            AwardEP(windowRaid, "manual");
        end);
        container:AddChild(manualTIck);
        self:AddWidgetTooltip(manualTIck, "Manually trigger an attendance tick.");

        if not IsInProgress(windowRaid) or self:GetDebugOpt("DebugRaidUI") then
            local export = AceGUI:Create("Button");
            export:SetFullWidth(true);
            export:SetText("Export");
            export:SetCallback("OnClick", function(widget)
                self:ExportRaid(windowRaid);
            end);
            container:AddChild(export);
            self:AddWidgetTooltip(export, "Open the window to export this raid's EP in the spreadsheet.");
        end
    end

    if IsInProgress(windowRaid) then
        local raidTools = AceGUI:Create("InlineGroup");
        raidTools:SetTitle("Raid Tools");
        container:AddChild(raidTools);

        local autoDistrib = AceGUI:Create("CheckBox");
        autoDistrib:SetFullWidth(true);
        autoDistrib:SetLabel("Auto Distribution");
        autoDistrib:SetCallback("OnValueChanged", function(widget, event, value)
            windowRaid.autoDistribute = value;
        end);
        raidTools:AddChild(autoDistrib);
        window:SetUserData("autoDistrib", autoDistrib);
        self:AddWidgetTooltip(autoDistrib, "If enabled, items will be automatically opened for distribution when loot popups are created.");

        if UnitIsGroupLeader("player") then
            local lootMethod = GetLootMethod();
            local lootValues = {
                group = "Group Loot",
                master = "Master Loot",
                freeforall = "Free For All",
                needbeforegreed = "Need Before Greed",
                roundrobin = "Round Robin"
            };
            local lootSelector = AceGUI:Create("Dropdown");
            lootSelector:SetFullWidth(true);
            lootSelector:SetList(lootValues);
            lootSelector:SetValue(lootMethod);
            lootSelector:SetCallback("OnValueChanged", function(widget, event, value)
                pendingLootMethod = value;
                checkCombatWhilePending = not UnitAffectingCombat("player");
                self:ChangeLootMethod();
            end);
            raidTools:AddChild(lootSelector);
            window:SetUserData("lootMethod", lootSelector);
            self:AddWidgetTooltip(lootSelector, "Select the loot method.");

            local lootThreshold = GetLootThreshold();
            local lootThresholds = {
                ("%sCommon|r"):format(_G.ITEM_QUALITY_COLORS[1].hex),
                ("%sUncommon|r"):format(_G.ITEM_QUALITY_COLORS[2].hex),
                ("%sRare|r"):format(_G.ITEM_QUALITY_COLORS[3].hex),
                ("%sEpic|r"):format(_G.ITEM_QUALITY_COLORS[4].hex)
            };
            local lootSelector = AceGUI:Create("Dropdown");
            lootSelector:SetFullWidth(true);
            lootSelector:SetList(lootThresholds);
            lootSelector:SetValue(lootThreshold);
            lootSelector:SetCallback("OnValueChanged", function(widget, event, value)
                pendingLootThreshold = value;
                checkCombatWhilePending = not UnitAffectingCombat("player");
                self:ChangeLootMethod();
            end);
            raidTools:AddChild(lootSelector);
            window:SetUserData("lootThreshold", lootSelector);
            self:AddWidgetTooltip(lootSelector, "Select the loot method.");
        end

        if self:Get("masterLoot") and GetLootMethod() == "master" then
            local disenchanter = AceGUI:Create("ABGP_EditBox");
            disenchanter:SetFullWidth(true);
            disenchanter:SetLabel("Disenchanter");
            disenchanter:SetCallback("OnValueChanged", function(widget, event, value)
                self:SetDisenchanter(value);
            end);
            disenchanter:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE);
            raidTools:AddChild(disenchanter);
            window:SetUserData("disenchanter", disenchanter);
            self:AddWidgetTooltip(disenchanter, "Choose the player to whom disenchanted items, or ones you alt+ctrl+click, will get ML'd.");

            local mule = AceGUI:Create("ABGP_EditBox");
            mule:SetFullWidth(true);
            mule:SetLabel("Raid Mule");
            mule:SetCallback("OnValueChanged", function(widget, event, value)
                self:SetMule(value);
            end);
            mule:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE);
            raidTools:AddChild(mule);
            window:SetUserData("mule", mule);
            self:AddWidgetTooltip(mule, "Choose the player to whom items you alt+shift+click will get ML'd.");
        end
    end

    if windowRaid.trackAttendance then
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
    end

    if IsInProgress(windowRaid) then
        local stop = AceGUI:Create("Button");
        stop:SetFullWidth(true);
        stop:SetText("Stop");
        stop:SetCallback("OnClick", function(widget)
            _G.ABGP_RaidInfo3.pastRaids = _G.ABGP_RaidInfo3.pastRaids or {};

            local currentRaid = _G.ABGP_RaidInfo3.currentRaid;
            _G.ABGP_RaidInfo3.currentRaid = nil;
            self:Notify("Stopping the raid!");
            window:Hide();
            if currentRaid.trackAttendance then
                table.insert(_G.ABGP_RaidInfo3.pastRaids, 1, currentRaid);
                self:UpdateRaid(windowRaid);
            end
        end);
        container:AddChild(stop);
        self:AddWidgetTooltip(stop, "Stop the raid.");
    else
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

    local minTotalTicks = 0;
    local sortedPlayers = {};
    for player, ticks in pairs(windowRaid.ticks) do
        table.insert(sortedPlayers, player);
        minTotalTicks = math.max(minTotalTicks, ticks);
    end
    table.sort(sortedPlayers);

    local function buildExportText()
        local text = "";
        for _, player in ipairs(sortedPlayers) do
            local ticks = windowRaid.ticks[player];
            local epgp = self:GetActivePlayer(player);
            local breakdown = {};
            table.insert(breakdown, ("%d/%d ticks"):format(ticks, windowRaid.totalTicks));
            local ep = math.floor(ticks / windowRaid.totalTicks * 100 + 0.5);

            if epgp then
                if epgp.trial then
                    table.insert(breakdown, 1, "Trial");
                end
            else
                table.insert(breakdown, 1, "Non-raider");
            end

            text = text .. ("%s\t%s\t%s\t%s\t%s\t\t%s\n"):format(
                ep, "EP", windowRaid.name, player, raidDate, table.concat(breakdown, ", "));
        end

        return text;
    end

    local exportEdit;
    local ticks = AceGUI:Create("Dropdown");
    ticks:SetWidth(100);
    ticks:SetLabel("Total Ticks");
    ticks:SetCallback("OnValueChanged", function(widget, event, value)
        windowRaid.totalTicks = value;
        exportEdit:SetText(buildExportText());
        local values = {};
        for i = minTotalTicks, windowRaid.totalTicks + 5 do values[i] = i; end
        widget:SetList(values);
    end);
    self:AddWidgetTooltip(ticks, "Select the total number of ticks for the raid.");
    local values = {};
    for i = minTotalTicks, windowRaid.totalTicks + 5 do values[i] = i; end
    ticks:SetList(values);
    ticks:SetValue(windowRaid.totalTicks);

    exportEdit = self:OpenExportWindow(buildExportText(), ticks);
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

local function IsRaidInCombat()
    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end

        if UnitAffectingCombat(unit) then return true; end
    end

    return false;
end

function ABGP:ChangeLootMethod()
    local inCombat = UnitAffectingCombat("player");
    local passedCombatCheck = not checkCombatWhilePending or not inCombat;
    checkCombatWhilePending = not inCombat;

    local pendingMethod = pendingLootMethod or GetLootMethod();
    local pendingThreshold = pendingLootThreshold or GetLootThreshold();

    if (GetLootMethod() ~= pendingMethod or GetLootThreshold() ~= pendingThreshold) and IsInGroup() and passedCombatCheck then
        if not IsRaidInCombat() then
            SetLootMethod(pendingMethod, UnitName("player"), pendingThreshold);
        end
        self:ScheduleTimer("ChangeLootMethod", 1);
    else
        if GetLootMethod() ~= pendingMethod then
            self:Notify("Giving up trying to change the loot type (entered combat or not grouped).");
        end
        pendingLootMethod = nil;
        pendingLootThreshold = nil;
    end
end

function ABGP:EventOnLootChanged()
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
