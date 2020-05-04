local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetServerTime = GetServerTime;
local GetAutoCompleteResults = GetAutoCompleteResults;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local pairs = pairs;
local math = math;
local ipairs = ipairs;
local table = table;
local strlen = strlen;
local date = date;
local type = type;
local tonumber = tonumber;

_G.ABGP_RaidInfo = {};

-- https://wow.gamepedia.com/InstanceID
local instanceIds = {
    MoltenCore    = 409,
    Onyxia        = 249,
    BlackwingLair = 469,
    ZulGurub      = 309,
};

-- https://wow.gamepedia.com/DungeonEncounterID
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
};

local instanceInfo = {
    [instanceIds.MoltenCore]  = {
        phase = ABGP.Phases.p1,
        name = "Molten Core",
        shortName = "MC",
        bosses = {
            bossIds.Lucifron, bossIds.Magmadar, bossIds.Gehennas, bossIds.Garr, bossIds.Shazzrah,
            bossIds.Geddon, bossIds.Sulfuron, bossIds.Golemagg, bossIds.Majordomo, bossIds.Ragnaros
        },
        awards = {
            [ABGP.RaidGroups.RED] = { ABGP.Phases.p1, ABGP.Phases.p3 },
            [ABGP.RaidGroups.BLUE] = { ABGP.Phases.p1 },
        },
    },
    -- [instanceIds.Onyxia] = {
    --     phase = ABGP.Phases.p1,
    --     name = "Onyxia's Lair",
    --     bosses = {
    --         bossIds.Onyxia
    --     }
    -- },
    [instanceIds.BlackwingLair] = {
        phase = ABGP.Phases.p3,
        name = "Blackwing Lair",
        shortName = "BWL",
        bosses = {
            bossIds.Razorgore, bossIds.Vaelastrasz, bossIds.Broodlord, bossIds.Firemaw,
            bossIds.Ebonroc, bossIds.Flamegor, bossIds.Chromaggus, bossIds.Nefarian
        },
        awards = {
            [ABGP.RaidGroups.RED] = { ABGP.Phases.p3 },
            [ABGP.RaidGroups.BLUE] = { ABGP.Phases.p3 },
        },
    },
    [instanceIds.ZulGurub] = {
        phase = ABGP.Phases.p3,
        name = "Zul'Gurub",
        shortName = "ZG",
        bosses = {
            bossIds.Venoxis, bossIds.Jeklik, bossIds.Marli, bossIds.Mandokir, bossIds.Madness,
            bossIds.Thekal, bossIds.Gahzranka, bossIds.Arlokk, bossIds.Jindo, bossIds.Hakkar
        },
        awards = {
            [ABGP.RaidGroups.RED] = { ABGP.Phases.p3 },
            [ABGP.RaidGroups.BLUE] = { ABGP.Phases.p3 },
        },
    },
};

local bossInfo = {
    [bossIds.Lucifron]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Lucifron" },
    [bossIds.Magmadar]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Magmadar" },
    [bossIds.Gehennas]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Gehennas" },
    [bossIds.Garr]      = { instance = instanceIds.MoltenCore, ep = 5, name = "Garr" },
    [bossIds.Shazzrah]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Shazzrah" },
    [bossIds.Geddon]    = { instance = instanceIds.MoltenCore, ep = 5, name = "Baron Geddon" },
    [bossIds.Sulfuron]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Sulfuron Harbinger" },
    [bossIds.Golemagg]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Golemagg the Incinerator" },
    [bossIds.Majordomo] = { instance = instanceIds.MoltenCore, ep = 5, name = "Majordomo Executus" },
    [bossIds.Ragnaros]  = { instance = instanceIds.MoltenCore, ep = 5, name = "Ragnaros" },

    [bossIds.Onyxia] = { instance = instanceIds.Onyxia, ep = 5, name =  "Onyxia" },

    [bossIds.Razorgore]   = { instance = instanceIds.BlackwingLair, ep = 10, name = "Razorgore the Untamed" },
    [bossIds.Vaelastrasz] = { instance = instanceIds.BlackwingLair, ep = 10, name = "Vaelastrasz the Corrupt" },
    [bossIds.Broodlord]   = { instance = instanceIds.BlackwingLair, ep = 10, name = "Broodlord Lashlayer" },
    [bossIds.Firemaw]     = { instance = instanceIds.BlackwingLair, ep = 10, name = "Firemaw" },
    [bossIds.Ebonroc]     = { instance = instanceIds.BlackwingLair, ep = 10, name = "Ebonroc" },
    [bossIds.Flamegor]    = { instance = instanceIds.BlackwingLair, ep = 10, name = "Flamegor" },
    [bossIds.Chromaggus]  = { instance = instanceIds.BlackwingLair, ep = 10, name = "Chromaggus" },
    [bossIds.Nefarian]    = { instance = instanceIds.BlackwingLair, ep = 10, name = "Nefarian" },

    [bossIds.Venoxis]     = { instance = instanceIds.ZulGurub, ep = 5, name = "High Priest Venoxis" },
    [bossIds.Jeklik]      = { instance = instanceIds.ZulGurub, ep = 5, name = "High Priestess Jeklik" },
    [bossIds.Marli]       = { instance = instanceIds.ZulGurub, ep = 5, name = "High Priestess Mar'li" },
    [bossIds.Mandokir]    = { instance = instanceIds.ZulGurub, ep = 5, name = "Bloodlord Mandokir" },
    [bossIds.Madness]     = { instance = instanceIds.ZulGurub, ep = 5, name = "Edge of Madness" },
    [bossIds.Thekal]      = { instance = instanceIds.ZulGurub, ep = 5, name = "High Priest Thekal" },
    [bossIds.Gahzranka]   = { instance = instanceIds.ZulGurub, ep = 5, name = "Gahz'ranka" },
    [bossIds.Arlokk]      = { instance = instanceIds.ZulGurub, ep = 5, name = "High Priestess Arlokk" },
    [bossIds.Jindo]       = { instance = instanceIds.ZulGurub, ep = 5, name = "Jin'do the Hexxer" },
    [bossIds.Hakkar]      = { instance = instanceIds.ZulGurub, ep = 5, name = "Hakkar" },
};

local currentInstance;
local activeWindow;

local function IsInProgress(raid)
    return (raid and raid == _G.ABGP_RaidInfo.currentRaid);
end

local function RefreshUI()
    if not activeWindow then return; end
    local windowRaid = activeWindow:GetUserData("raid");
    if not IsInProgress(windowRaid) then return; end
    local scroll = activeWindow:GetUserData("standbyList");
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
                            ABGP:RemoveStandby(player);
                        end,
                        arg1 = widget:GetUserData("player"),
                        notCheckable = true
                    },
                    { text = "Cancel", notCheckable = true },
                });
            end
        end);
    end
end

local function EnsureAwardsEntries()
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end

        local player = UnitName(unit);
        currentRaid.awards[player] = currentRaid.awards[player] or 0;
    end
end

function ABGP:AwardEP(ep)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    self:Alert("Awarding %d EP to the current raid!", ep);
    currentRaid.stopTime = GetServerTime();

    EnsureAwardsEntries();
    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end

        local player = UnitName(unit);
        currentRaid.awards[player] = currentRaid.awards[player] + ep;
    end

    for _, player in ipairs(currentRaid.standby) do
        currentRaid.awards[player] = currentRaid.awards[player] + ep;
    end
end

function ABGP:AddStandby(player)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    self:Notify("Adding %s to the standby list!", self:ColorizeName(player));
    table.insert(currentRaid.standby, player);
    currentRaid.awards[player] = currentRaid.awards[player] or 0;
    RefreshUI();
end

function ABGP:RemoveStandby(player)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    self:Notify("Removing %s from the standby list!", self:ColorizeName(player));
    for i, standby in ipairs(currentRaid.standby) do
        if standby == player then
            table.remove(currentRaid.standby, i);
            break;
        end
    end
    RefreshUI();
end

function ABGP:EventOnBossKilled(bossId, name)
    self:LogDebug("%s defeated!", name);
    local info = bossInfo[bossId];
    if info then
        self:LogDebug("This boss is worth %d EP.", info.ep);
        self:AwardEP(info.ep);
    end
end

function ABGP:EventOnZoneChanged(name, instanceId)
    self:LogDebug("Zone changed to %s[%d]!", name, instanceId);
    currentInstance = instanceId;
    local info = instanceInfo[instanceId];
    if info then
        self:LogDebug("This instance is associated with phase %s.", info.phase);
        self.CurrentPhase = info.phase;
    end
end

function ABGP:ShowRaidWindow()
    self:CancelRaidStateCheck();

    if _G.ABGP_RaidInfo.currentRaid then
        self:UpdateRaid();
    elseif not activeWindow then
        self:StartRaid();
    end
end

function ABGP:StartRaid()
    local raidInstance, raidPhase;

    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window:SetTitle(("%s Raid"):format(self:ColorizeText("ABGP")));
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raid", {
        version = math.random(),
        defaultWidth = 150,
        minWidth = 150,
        maxWidth = 150,
        defaultHeight = 300,
        minHeight = 300,
        maxHeight = 300
    });
    self:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
    end);

    local custom = -1;
    local instances = {
        [instanceIds.MoltenCore] = instanceInfo[instanceIds.MoltenCore].name,
        -- [instanceIds.Onyxia] = instanceInfo[instanceIds.Onyxia].name,
        [instanceIds.BlackwingLair] = instanceInfo[instanceIds.BlackwingLair].name,
        [instanceIds.ZulGurub] = instanceInfo[instanceIds.ZulGurub].name,
        [custom] = "Custom",
    };
    local instanceSelector = AceGUI:Create("Dropdown");
    instanceSelector:SetFullWidth(true);
    instanceSelector:SetLabel("Instance");
    instanceSelector:SetList(instances, { instanceIds.MoltenCore, --[[ instanceIds.Onyxia, ]] instanceIds.BlackwingLair, instanceIds.ZulGurub, custom });
    instanceSelector:SetCallback("OnValueChanged", function(widget, event, value)
        raidInstance = value;

        local shortName = "Raid";
        local raidGroupEP = window:GetUserData("raidGroupEP");
        local selectors = window:GetUserData("raidGroupSelectors");

        if instanceInfo[value] then
            shortName = instanceInfo[value].shortName;
            for raidGroup, awards in pairs(instanceInfo[value].awards) do
                table.wipe(raidGroupEP[raidGroup]);
                for _, phase in ipairs(awards) do
                    raidGroupEP[raidGroup][phase] = true;
                end
                selectors[raidGroup]:UpdateCheckboxes();
            end
            window:GetUserData("phaseSelector"):SetValue(instanceInfo[value].phase);
        else
            for raidGroup in pairs(self.RaidGroups) do
                table.wipe(raidGroupEP[raidGroup]);
                selectors[raidGroup]:UpdateCheckboxes();
            end
        end
        window:GetUserData("nameEdit"):SetText(("%s %s"):format(date("%m/%d/%y", GetServerTime()), shortName)); -- https://strftime.org/
    end);
    window:AddChild(instanceSelector);

    local name = AceGUI:Create("EditBox");
    name:SetFullWidth(true);
    name:SetMaxLetters(32);
    name:SetLabel("Name");
    name:SetCallback("OnEnterPressed", function(widget)
        AceGUI:ClearFocus();
    end);
    window:AddChild(name);
    window:SetUserData("nameEdit", name);

    local phaseSelector = AceGUI:Create("Dropdown");
    phaseSelector:SetFullWidth(true);
    phaseSelector:SetLabel("Phase");
    phaseSelector:SetList(self.PhaseNames, self.PhasesSorted);
    phaseSelector:SetCallback("OnValueChanged", function(widget, event, value)
        raidPhase = value;
    end);
    window:AddChild(phaseSelector);
    window:SetUserData("phaseSelector", phaseSelector);

    local raidGroupSelectors = {};
    window:SetUserData("raidGroupSelectors", raidGroupSelectors);
    local raidGroupEP = {};
    window:SetUserData("raidGroupEP", raidGroupEP);
    for _, raidGroup in ipairs(self.RaidGroupsSorted) do
        raidGroupEP[raidGroup] = {};

        local epSelector = AceGUI:Create("ABGP_Filter");
        epSelector:SetFullWidth(true);
        epSelector:SetValues(raidGroupEP[raidGroup], false, self.PhaseNamesShort, self.PhasesSorted);
        epSelector:SetCallback("OnFilterUpdated", function()

        end);
        epSelector:SetLabel(("%s EP"):format(self.RaidGroupNames[raidGroup]));
        window:AddChild(epSelector);
        raidGroupSelectors[raidGroup] = epSelector;
    end

    local start = AceGUI:Create("Button");
    start:SetFullWidth(true);
    start:SetText("Start");
    start:SetCallback("OnClick", function(widget)
        _G.ABGP_RaidInfo.currentRaid = {
            instanceId = raidInstance,
            name = name:GetText(),
            raidGroupEP = raidGroupEP,
            awards = {},
            standby = {},
            startTime = GetServerTime(),
            stopTime = GetServerTime(),
        };
        self:Notify("Starting raid!");
        window:Hide();
    end);
    window:AddChild(start);

    local startingValue = instanceInfo[currentInstance] and currentInstance or custom;
    instanceSelector:SetValue(startingValue);
    instanceSelector:Fire("OnValueChanged", startingValue);
end

function ABGP:UpdateRaid(windowRaid)
    windowRaid = windowRaid or _G.ABGP_RaidInfo.currentRaid;
    if not windowRaid then return; end

    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window:SetTitle(windowRaid.name);
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raidUpdate", {
        version = math.random(),
        defaultWidth = 150,
        minWidth = 150,
        maxWidth = 150,
        defaultHeight = 300,
        minHeight = 300,
        maxHeight = 300
    });
    self:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    if IsInProgress(windowRaid) then
        local stop = AceGUI:Create("Button");
        stop:SetFullWidth(true);
        stop:SetText("Stop");
        stop:SetCallback("OnClick", function(widget)
            _G.ABGP_RaidInfo.pastRaids = _G.ABGP_RaidInfo.pastRaids or {};
            table.insert(_G.ABGP_RaidInfo.pastRaids, 1, _G.ABGP_RaidInfo.currentRaid);
            _G.ABGP_RaidInfo.currentRaid = nil;

            self:Notify("Stopping the raid!");
            window:Hide();
            self:UpdateRaid(windowRaid);
        end);
        window:AddChild(stop);

        local epSlider = AceGUI:Create("Slider");
        epSlider:SetFullWidth(true);
        epSlider:SetSliderValues(1, 20, 1);
        epSlider:SetValue(5);
        window:AddChild(epSlider);

        local awardEP = AceGUI:Create("Button");
        awardEP:SetFullWidth(true);
        awardEP:SetText("Award EP");
        awardEP:SetCallback("OnClick", function(widget)
            self:AwardEP(epSlider:GetValue());
        end);
        window:AddChild(awardEP);
    end

    if not IsInProgress(windowRaid) or self.Debug then
        local export = AceGUI:Create("Button");
        export:SetFullWidth(true);
        export:SetText("Export");
        export:SetCallback("OnClick", function(widget)
            self:ExportRaid(windowRaid);
        end);
        window:AddChild(export);
    end

    if not IsInProgress(windowRaid) and self.Debug then
        local restart = AceGUI:Create("Button");
        restart:SetFullWidth(true);
        restart:SetText("Restart");
        restart:SetCallback("OnClick", function(widget)
            local past = _G.ABGP_RaidInfo.pastRaids;
            for i, raid in ipairs(past) do
                if raid == windowRaid then
                    self:Notify("Restarting the raid!");
                    self:RestartRaid(i);
                    break;
                end
            end
        end);
        window:AddChild(restart);
    end

    local manageEP = AceGUI:Create("Button");
    manageEP:SetFullWidth(true);
    manageEP:SetText("Manage EP");
    manageEP:SetCallback("OnClick", function(widget)
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
        popup:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); window:SetUserData("popup", nil); end);
        popup:SetWidth(240);
        popup:SetHeight(300);
        popup.frame:ClearAllPoints();
        popup.frame:SetPoint("TOPLEFT", window.frame, "TOPRIGHT", 0, 0);
        ABGP:OpenWindow(popup);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetLayout("Table");
        scroll:SetUserData("table", { columns = { 110, 75 } });
        popup:AddChild(scroll);

        local sorted = {};
        for player in pairs(windowRaid.awards) do table.insert(sorted, player); end
        table.sort(sorted);

        for _, player in ipairs(sorted) do
            local elt = AceGUI:Create("ABGP_Header");
            elt:SetFullWidth(true);
            elt:SetText(self:ColorizeName(player));
            scroll:AddChild(elt);

            elt = AceGUI:Create("EditBox");
            elt:SetFullWidth(true);
            elt:SetText(windowRaid.awards[player]);
            scroll:AddChild(elt);
            elt:SetCallback("OnEnterPressed", function(widget, event, value)
                value = tonumber(value);
                if type(value) == "number" and value > 0 and math.floor(value) == value then
                    windowRaid.awards[player] = value;
                    self:Notify("EP for %s set to %d.", self:ColorizeName(player), value);
                else
                    value = windowRaid.awards[player];
                    self:Error("Invalid value! EP for %s remains at %d.", self:ColorizeName(player), value);
                end
                widget:SetText(value);
                AceGUI:ClearFocus();
            end);
        end

        window:SetUserData("popup", popup);
    end);
    window:AddChild(manageEP);

    if IsInProgress(windowRaid) then
        local addStandby = AceGUI:Create("Button");
        addStandby:SetFullWidth(true);
        addStandby:SetText("Add Standby");
        addStandby:SetCallback("OnClick", function(widget)
            _G.StaticPopup_Show("ABGP_ADD_STANDBY");
        end);
        window:AddChild(addStandby);

        local elt = AceGUI:Create("ABGP_Header");
        elt:SetFullWidth(true);
        elt:SetText("Current standby list:");
        window:AddChild(elt);

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Fill");
        window:AddChild(scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        window:SetUserData("standbyList", scroll);
    end

    window:SetUserData("raid", windowRaid);
    activeWindow = window;
    RefreshUI();
end

function ABGP:RestartRaid(i)
    local past = _G.ABGP_RaidInfo.pastRaids;
    local raid = past[i];
    table.remove(past, i);
    _G.ABGP_RaidInfo.currentRaid = raid;
    if activeWindow then activeWindow:Hide(); end
    self:UpdateRaid();
end

function ABGP:ExportRaid(windowRaid)
    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("DIALOG");
    window:SetTitle("Export");
    window:SetHeight(450);
    window:SetLayout("List");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); end);
    ABGP:OpenWindow(window);

    local raidDate = date("%m/%d/%y", windowRaid.startTime); -- https://strftime.org/

    local skippedPlayers = {};
    for player, ep in pairs(windowRaid.awards) do
        local epgp = self:GetActivePlayer(player);
        if not epgp then
            table.insert(skippedPlayers, self:ColorizeName(player));
        end
    end
    if #skippedPlayers > 0 then
        local text = "The following players were skipped due to unknown raid group:\n";
        text = text .. table.concat(skippedPlayers, ", ");
        local skipped = AceGUI:Create("ABGP_Header");
        skipped:SetFullWidth(true);
        skipped:SetHeight(32);
        skipped:SetWordWrap(true);
        skipped:SetText(text);
        window:AddChild(skipped);
    end

    local tableContainer = AceGUI:Create("SimpleGroup");
    tableContainer:SetFullWidth(true);
    tableContainer:SetFullHeight(true);
    tableContainer:SetLayout("Table");
    local nPhases = #self.PhasesSorted;
    local columns = {};
    for i = 1, nPhases do table.insert(columns, 1 / nPhases); end
    tableContainer:SetUserData("table", { columns = columns });
    window:AddChild(tableContainer);

    for _, phase in ipairs(self.PhasesSorted) do
        local text = "";
        local i = 1;
        for player, ep in pairs(windowRaid.awards) do
            local epgp = self:GetActivePlayer(player);
            if epgp then
                local raidGroup = epgp.epRaidGroup;
                if windowRaid.raidGroupEP[raidGroup] and windowRaid.raidGroupEP[raidGroup][phase] then
                    text = text .. ("%s%d\t%s\t%s\t%s\t\t%s"):format(
                        (i == 1 and "" or "\n"), ep, windowRaid.name, player, raidDate, "Tracked by ABGP");
                    i = i + 1;
                end
            end
        end

        local edit = AceGUI:Create("MultiLineEditBox");
        edit:SetFullWidth(true);
        edit:SetFullHeight(true);
        edit:SetLabel(self.PhaseNames[phase]);
        edit:SetNumLines(25);
        edit:SetText(text);
        edit:DisableButton(true);
        tableContainer:AddChild(edit);
        edit:HighlightText();
        edit:SetCallback("OnEditFocusGained", function()
            edit:HighlightText();
        end);
    end

    window.frame:Raise();
end

function ABGP:CancelRaidStateCheck()
    if self.checkRaidTimer then
        self:CancelTimer(self.checkRaidTimer);
        self.checkRaidTimer = nil;
    end
end

function ABGP:CheckRaidState()
    self.checkRaidTimer = nil;
    if _G.ABGP_RaidInfo.currentRaid then
        self:Alert("A raid is currently in progress!");
    end
end

function ABGP:EventOnGroupJoined()
    EnsureAwardsEntries();
end

function ABGP:EventOnGroupUpdate()
    EnsureAwardsEntries();
end

StaticPopupDialogs["ABGP_ADD_STANDBY"] = {
    text = "Add a player to the standby list:",
    button1 = "Done",
    button2 = "Cancel",
	hasEditBox = 1,
	autoCompleteSource = GetAutoCompleteResults,
	autoCompleteArgs = { bit.bor(AUTOCOMPLETE_FLAG_ONLINE, AUTOCOMPLETE_FLAG_INTERACTED_WITH), bit.bor(AUTOCOMPLETE_FLAG_BNET, AUTOCOMPLETE_FLAG_IN_GROUP) },
	maxLetters = 31,
    OnAccept = function(self, data)
        ABGP:AddStandby(self.editBox:GetText());
    end,
    OnShow = function(self, data)
        self.editBox:SetAutoFocus(false);
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent();
        if parent.button1:IsEnabled() then
            parent.button1:Click();
        end
    end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};
