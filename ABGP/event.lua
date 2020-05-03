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

local function RefreshUI()
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    if not activeWindow then return; end
    local scroll = activeWindow:GetUserData("standbyList");
    scroll:ReleaseChildren();

    for _, standby in ipairs(currentRaid.standby) do
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

function ABGP:AwardEP(ep)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    self:Alert("Awarding %d EP to the current raid!", ep);
    currentRaid.stopTime = GetServerTime();

    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end

        local player = UnitName(unit);
        currentRaid.awards[player] = (currentRaid.awards[player] or 0) + ep;
    end

    for _, player in ipairs(currentRaid.standby) do
        currentRaid.awards[player] = (currentRaid.awards[player] or 0) + ep;
    end
end

function ABGP:AddStandby(player)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    self:Notify("Adding %s to the standby list!", self:ColorizeName(player));
    table.insert(currentRaid.standby, player);
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
    else
        self:StartRaid();
    end
end

function ABGP:StartRaid()
    local raidInstance;

    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window:SetTitle(("%s Raid"):format(self:ColorizeText("ABGP")));
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raid", {
        version = math.random(),
        defaultWidth = 150,
        minWidth = 150,
        maxWidth = 150,
        defaultHeight = 255,
        minHeight = 255,
        maxHeight = 255
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

function ABGP:UpdateRaid()
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window:SetTitle(currentRaid.name);
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raidUpdate", {
        version = math.random(),
        defaultWidth = 150,
        minWidth = 150,
        maxWidth = 150,
        defaultHeight = 255,
        minHeight = 255,
        maxHeight = 255
    });
    self:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local stop = AceGUI:Create("Button");
    stop:SetFullWidth(true);
    stop:SetText("Stop");
    stop:SetCallback("OnClick", function(widget)
        _G.ABGP_RaidInfo.pastRaids = _G.ABGP_RaidInfo.pastRaids or {};
        table.insert(_G.ABGP_RaidInfo.pastRaids, 1, _G.ABGP_RaidInfo.currentRaid);
        _G.ABGP_RaidInfo.currentRaid = nil;

        self:Notify("Stopping the raid!");
        window:Hide();
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

    activeWindow = window;
    RefreshUI();
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
        self:Notify("A raid is currently in progress!");
    end
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
