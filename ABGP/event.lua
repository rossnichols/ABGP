local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetServerTime = GetServerTime;
local GetNumGroupMembers = GetNumGroupMembers;
local UnitIsGroupLeader = UnitIsGroupLeader;
local GetLootMethod = GetLootMethod;
local SetLootMethod = SetLootMethod;
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
        onTimeBonus = 5,
    },
    [instanceIds.Onyxia] = {
        phase = ABGP.Phases.p1,
        name = "Onyxia's Lair",
        shortName = "Ony",
        bosses = {
            bossIds.Onyxia
        },
        awards = {
            [ABGP.RaidGroups.RED] = { ABGP.Phases.p1, ABGP.Phases.p3 },
            [ABGP.RaidGroups.BLUE] = { ABGP.Phases.p1 },
        },
    },
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
        onTimeBonus = 5,
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

    [bossIds.Onyxia] = { instance = instanceIds.Onyxia, ep = 0, name =  "Onyxia" },

    [bossIds.Razorgore]   = { instance = instanceIds.BlackwingLair, ep = 10, name = "Razorgore the Untamed" },
    [bossIds.Vaelastrasz] = { instance = instanceIds.BlackwingLair, ep = 10, name = "Vaelastrasz the Corrupt" },
    [bossIds.Broodlord]   = { instance = instanceIds.BlackwingLair, ep = 10, name = "Broodlord Lashlayer" },
    [bossIds.Firemaw]     = { instance = instanceIds.BlackwingLair, ep = 10, name = "Firemaw" },
    [bossIds.Ebonroc]     = { instance = instanceIds.BlackwingLair, ep = 10, name = "Ebonroc" },
    [bossIds.Flamegor]    = { instance = instanceIds.BlackwingLair, ep = 10, name = "Flamegor" },
    [bossIds.Chromaggus]  = { instance = instanceIds.BlackwingLair, ep = 10, name = "Chromaggus" },
    [bossIds.Nefarian]    = { instance = instanceIds.BlackwingLair, ep = 10, name = "Nefarian" },

    [bossIds.Venoxis]     = { instance = instanceIds.ZulGurub, ep = 0, name = "High Priest Venoxis" },
    [bossIds.Jeklik]      = { instance = instanceIds.ZulGurub, ep = 0, name = "High Priestess Jeklik" },
    [bossIds.Marli]       = { instance = instanceIds.ZulGurub, ep = 0, name = "High Priestess Mar'li" },
    [bossIds.Mandokir]    = { instance = instanceIds.ZulGurub, ep = 0, name = "Bloodlord Mandokir" },
    [bossIds.Madness]     = { instance = instanceIds.ZulGurub, ep = 0, name = "Edge of Madness" },
    [bossIds.Thekal]      = { instance = instanceIds.ZulGurub, ep = 0, name = "High Priest Thekal" },
    [bossIds.Gahzranka]   = { instance = instanceIds.ZulGurub, ep = 0, name = "Gahz'ranka" },
    [bossIds.Arlokk]      = { instance = instanceIds.ZulGurub, ep = 0, name = "High Priestess Arlokk" },
    [bossIds.Jindo]       = { instance = instanceIds.ZulGurub, ep = 0, name = "Jin'do the Hexxer" },
    [bossIds.Hakkar]      = { instance = instanceIds.ZulGurub, ep = 0, name = "Hakkar" },
};

local awardCategories = {
    BOSS = "BOSS",
    BONUS = "BONUS",
    ADJUST = "ADJUST",
    TRIAL = "TRIAL",
};
local awardCategoryNames = {
    [awardCategories.BOSS] = "bosses",
    [awardCategories.BONUS] = "bonus",
    [awardCategories.ADJUST] = "adjustments",
    [awardCategories.TRIAL] = "trial",
};
local awardCategoriesSorted = {
    awardCategories.BOSS,
    awardCategories.BONUS,
    awardCategories.ADJUST,
    awardCategories.TRIAL,
};

local currentInstance;
local activeWindow;
local pendingLootMethod;
local checkCombatWhilePending;

local function IsInProgress(raid)
    return (raid and raid == _G.ABGP_RaidInfo.currentRaid);
end

local function PopulateUI()
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

    local autoDistrib = activeWindow:GetUserData("autoDistrib");
    if autoDistrib then
        autoDistrib:SetValue(windowRaid.autoDistribute);
    end

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
                            ABGP:RemoveStandby(windowRaid, player);
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

    local player = UnitName("player");
    currentRaid.awards[player] = currentRaid.awards[player] or { ep = 0, categories = {} };

    local groupSize = GetNumGroupMembers();
    for i = 1, groupSize do
        local unit = "player";
        if IsInRaid() then
            unit = "raid" .. i;
        elseif i ~= groupSize then
            unit = "party" .. i;
        end

        local player = UnitName(unit);
        currentRaid.awards[player] = currentRaid.awards[player] or { ep = 0, categories = {} };
    end
end

function ABGP:IsRaidInProgress()
    return _G.ABGP_RaidInfo.currentRaid ~= nil;
end

function ABGP:AwardPlayerEP(raid, player, ep, category)
    local award = raid.awards[player];
    award.ep = award.ep + ep;
    award.categories[category] = (award.categories[category] or 0) + ep;
end

function ABGP:AwardEP(ep, category)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    self:Alert("Awarding %d EP to the current raid and standby!", ep);
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
        self:AwardPlayerEP(currentRaid, player, ep, category);
    end

    for _, player in ipairs(currentRaid.standby) do
        self:AwardPlayerEP(currentRaid, player, ep, category);
    end
end

function ABGP:AddStandby(raid, player)
    if tContains(raid.standby, player) then return; end

    if not self:GetActivePlayer(player) and not self:GetGuildInfo(player) then
        local playerLower = player:lower();
        local guildInfo = self:GetGuildInfo();
        for guildie in pairs(guildInfo) do
            if guildie:lower() == playerLower then
                player = guildie;
                break;
            end
        end
    end

    self:Notify("Adding %s to the standby list.", self:ColorizeName(player));
    if not self:GetActivePlayer(player) then
        self:Notify("WARNING: %s doesn't have any EPGP data! Any awarded EP can't be exported.", self:ColorizeName(player));
    end

    table.insert(raid.standby, player);
    raid.awards[player] = raid.awards[player] or { ep = 0, categories = {} };
    PopulateUI();
end

function ABGP:RemoveStandby(raid, player)
    self:Notify("Removing %s from the standby list.", self:ColorizeName(player));
    for i, standby in ipairs(raid.standby) do
        if standby == player then
            table.remove(raid.standby, i);
            break;
        end
    end
    PopulateUI();
end

function ABGP:SetDisenchanter(player)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    if player == "" then
        player = nil;
        self:Notify("Will not send disenchanted items to anyone.");
    else
        self:Notify("Sending disenchanted items to %s.", self:ColorizeName(player));
    end
    currentRaid.disenchanter = player;
    PopulateUI();
end

function ABGP:GetRaidDisenchanter()
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    return currentRaid.disenchanter;
end

function ABGP:SetMule(player)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    if player == "" then
        player = nil;
        self:Notify("Clearing the designated raid mule.");
    else
        self:Notify("Sending muled items to %s.", self:ColorizeName(player));
    end
    currentRaid.mule = player;
    PopulateUI();
end

function ABGP:GetRaidMule()
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    return currentRaid.mule;
end

function ABGP:ShouldAutoDistribute()
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    return currentRaid.autoDistribute;
end

function ABGP:EventOnBossKilled(bossId, name)
    self:LogVerbose("%s defeated!", name);

    -- Check for info about the boss and an in-progress raid.
    local info = bossInfo[bossId];
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not (currentRaid and info) then return; end

    -- Check that the boss is for this raid.
    local raidInstance = currentRaid.instanceId;
    if info.instance ~= raidInstance then return; end

    if info.ep > 0 and not currentRaid.bossKills[info.name] then
        self:LogDebug("This boss is worth %d EP [BossKill].", info.ep);
        self:AwardEP(info.ep, awardCategories.BOSS);
        currentRaid.bossKills[info.name] = GetServerTime();
    end

    -- See if we killed the final boss of the current raid.
    local bosses = instanceInfo[raidInstance].bosses;
    if bosses[#bosses] == bossId then
        self:UpdateRaid();
    end
end

function ABGP:EventOnBossLoot(data, distribution, sender)
    local currentRaid = _G.ABGP_RaidInfo.currentRaid;
    if not currentRaid then return; end

    local instance = instanceInfo[currentRaid.instanceId];
    if not instance then return; end

    local info, bossId;
    for _, id in ipairs(instance.bosses) do
        if bossInfo[id].name == data.name then
            bossId = id;
            info = bossInfo[id];
        end
    end
    if not info then return; end

    if info.ep > 0 and not currentRaid.bossKills[info.name] then
        self:LogDebug("This boss is worth %d EP [BossLoot].", info.ep);
        self:AwardEP(info.ep, awardCategories.BOSS);
        currentRaid.bossKills[info.name] = GetServerTime();
    end

    -- See if we killed the final boss of the current raid.
    local bosses = instance.bosses;
    if bosses[#bosses] == bossId then
        self:UpdateRaid();
    end
end

function ABGP:EventOnZoneChanged(name, instanceId)
    self:LogDebug("Zone changed to %s[%d]!", name, instanceId);
    currentInstance = instanceId;
    local info = instanceInfo[instanceId];
    if info then
        self:LogDebug("This instance is associated with phase %s.", info.phase);
        self.CurrentPhase = info.phase;

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
    local raidInstance, raidPhase;

    if activeWindow then activeWindow:Hide(); end

    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window:SetTitle(("%s Raid"):format(self:ColorizeText("ABGP")));
    window.frame:SetFrameStrata("MEDIUM"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raid", {
        version = 1,
        defaultWidth = 200,
        minWidth = 200,
        maxWidth = 200,
        defaultHeight = 300,
        minHeight = 300,
        maxHeight = 300
    });
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local custom = -1;
    local instances = {
        [instanceIds.MoltenCore] = instanceInfo[instanceIds.MoltenCore].name,
        [instanceIds.BlackwingLair] = instanceInfo[instanceIds.BlackwingLair].name,
        [instanceIds.Onyxia] = instanceInfo[instanceIds.Onyxia].name,
        [instanceIds.ZulGurub] = instanceInfo[instanceIds.ZulGurub].name,
        [custom] = "Custom",
    };
    local instanceSelector = AceGUI:Create("Dropdown");
    instanceSelector:SetFullWidth(true);
    instanceSelector:SetLabel("Instance");
    instanceSelector:SetList(instances, { instanceIds.MoltenCore, instanceIds.BlackwingLair, instanceIds.Onyxia, instanceIds.ZulGurub, custom });
    instanceSelector:SetCallback("OnValueChanged", function(widget, event, value)
        raidInstance = value;

        local shortName = "Raid";
        local raidGroupEP = window:GetUserData("raidGroupEP");
        local selectors = window:GetUserData("raidGroupSelectors");
        local phaseSelector = window:GetUserData("phaseSelector");
        local phase;

        if instanceInfo[value] then
            shortName = instanceInfo[value].shortName;
            for raidGroup, awards in pairs(instanceInfo[value].awards) do
                table.wipe(raidGroupEP[raidGroup]);
                for _, phase in ipairs(awards) do
                    raidGroupEP[raidGroup][phase] = true;
                end
                selectors[raidGroup]:UpdateCheckboxes();
            end
            phase = instanceInfo[value].phase;
        else
            for raidGroup in pairs(self.RaidGroups) do
                table.wipe(raidGroupEP[raidGroup]);
                raidGroupEP[raidGroup][self.CurrentPhase] = true;
                selectors[raidGroup]:UpdateCheckboxes();
            end
            phase = self.CurrentPhase;
        end
        phaseSelector:SetValue(phase);
        phaseSelector:Fire("OnValueChanged", phase);
        window:GetUserData("nameEdit"):SetValue(instances[raidInstance]);
    end);
    window:AddChild(instanceSelector);
    self:AddWidgetTooltip(instanceSelector, "If a preset instance is chosen, EP will automatically be recorded for boss kills.");

    local name = AceGUI:Create("ABGP_EditBox");
    name:SetFullWidth(true);
    name:SetMaxLetters(32);
    name:SetLabel("Name");
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
    self:AddWidgetTooltip(phaseSelector, "Choose the phase in which this raid will be displayed in the main window.");

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
        self:AddWidgetTooltip(epSelector, "Choose the phase(s) into which EP should be awarded for this raid group.");
    end

    local start = AceGUI:Create("Button");
    start:SetFullWidth(true);
    start:SetText("Start");
    start:SetCallback("OnClick", function(widget)
        _G.ABGP_RaidInfo.currentRaid = {
            instanceId = raidInstance,
            phase = raidPhase,
            name = name:GetText(),
            raidGroupEP = raidGroupEP,
            awards = {},
            standby = {},
            bossKills = {},
            startTime = GetServerTime(),
            stopTime = GetServerTime(),
            disenchanter = nil,
            autoDistribute = false,
            mule = nil,
        };
        EnsureAwardsEntries();
        if instanceInfo[raidInstance] and instanceInfo[raidInstance].onTimeBonus then
            local bonus = instanceInfo[raidInstance].onTimeBonus;
            _G.StaticPopup_Show("ABGP_CONFIRM_BONUS_EP", bonus, "on-time bonus", bonus);
        end
        self:Notify("Starting a new raid!");
        window:Hide();
        self:UpdateRaid();
    end);
    window:AddChild(start);
    self:AddWidgetTooltip(start, "Start the raid.");

    local startingValue = instanceInfo[currentInstance] and currentInstance or custom;
    instanceSelector:SetValue(startingValue);
    instanceSelector:Fire("OnValueChanged", startingValue);

    -- local addStandby = AceGUI:Create("Button");
    -- addStandby:SetFullWidth(true);
    -- addStandby:SetText("Add Standby");
    -- addStandby:SetCallback("OnClick", function(widget)
    --     _G.StaticPopup_Show("ABGP_ADD_STANDBY", nil, nil, windowRaid);
    -- end);
    -- window:AddChild(addStandby);
    -- self:AddWidgetTooltip(addStandby, "Add a player to the standby list.");

    -- local elt = AceGUI:Create("ABGP_Header");
    -- elt:SetFullWidth(true);
    -- elt:SetText("Current standby list:");
    -- window:AddChild(elt);

    -- local scrollContainer = AceGUI:Create("SimpleGroup");
    -- scrollContainer:SetFullWidth(true);
    -- scrollContainer:SetFullHeight(true);
    -- scrollContainer:SetLayout("Fill");
    -- window:AddChild(scrollContainer);

    -- local scroll = AceGUI:Create("ScrollFrame");
    -- scroll:SetLayout("List");
    -- scrollContainer:AddChild(scroll);
    -- window:SetUserData("standbyList", scroll);

    activeWindow = window;
    window.frame:Raise();
end

function ABGP:UpdateRaid(windowRaid)
    windowRaid = windowRaid or _G.ABGP_RaidInfo.currentRaid;
    if not windowRaid then return; end

    if activeWindow then activeWindow:Hide(); end

    -- Fixup the raid if it's using the older data format.
    for player, award in pairs(windowRaid.awards) do
        if type(award) == "number" then
            windowRaid.awards[player] = { ep = 0, categories = {} };
        end
    end

    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window:SetTitle(windowRaid.name);
    window.frame:SetFrameStrata("MEDIUM"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raidUpdate", {
        version = 1,
        defaultWidth = 175,
        minWidth = 175,
        maxWidth = 175,
        defaultHeight = 375,
        minHeight = 375,
        maxHeight = 450
    });
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        local popup = widget:GetUserData("popup");
        if popup then popup:Hide(); end
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    if IsInProgress(windowRaid) then
        local stop = AceGUI:Create("Button");
        stop:SetFullWidth(true);
        stop:SetText("Stop");
        stop:SetCallback("OnClick", function(widget)
            _G.ABGP_RaidInfo.pastRaids = _G.ABGP_RaidInfo.pastRaids or {};

            local currentRaid = _G.ABGP_RaidInfo.currentRaid;
            _G.ABGP_RaidInfo.currentRaid = nil;
            for player, award in pairs(currentRaid.awards) do
                if award.ep == 0 then currentRaid.awards[player] = nil; end
            end
            if next(currentRaid.awards) then
                self:Notify("Stopping the raid!");
                table.insert(_G.ABGP_RaidInfo.pastRaids, 1, currentRaid);
                window:Hide();
                self:UpdateRaid(windowRaid);
            else
                self:Notify("No EP awarded in this raid. It has been deleted.");
                window:Hide();
            end
        end);
        window:AddChild(stop);
        self:AddWidgetTooltip(stop, "Stop the raid.");

        local epCustom = -1;
        local epValues = { [5] = 5, [10] = 10, [epCustom] = "Custom" };
        local epValuesSorted = { 5, 10, epCustom };
        local epSelector = AceGUI:Create("Dropdown");
        epSelector:SetFullWidth(true);
        epSelector:SetText("Award Bonus EP");
        epSelector:SetList(epValues, epValuesSorted);
        epSelector:SetCallback("OnValueChanged", function(widget, event, value)
            widget:SetValue(nil);
            widget:SetText("Award Bonus EP");
            if value == epCustom then
                _G.StaticPopup_Show("ABGP_AWARD_EP");
            else
                _G.StaticPopup_Show("ABGP_CONFIRM_BONUS_EP", value, "manual", value);
            end
        end);
        window:AddChild(epSelector);
        self:AddWidgetTooltip(epSelector, "Select an amount of EP to the raid and standby list.");

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
            lootSelector:SetValue(lootMethod);
            lootSelector:SetText(lootValues[lootMethod]);
            lootSelector:SetList(lootValues);
            lootSelector:SetCallback("OnValueChanged", function(widget, event, value)
                pendingLootMethod = value;
                checkCombatWhilePending = not UnitAffectingCombat("player");
                self:ChangeLootMethod();
            end);
            window:AddChild(lootSelector);
            self:AddWidgetTooltip(lootSelector, "Select the loot method.");
        end
    end

    if not IsInProgress(windowRaid) or self:GetDebugOpt("DebugRaidUI") then
        local export = AceGUI:Create("Button");
        export:SetFullWidth(true);
        export:SetText("Export");
        export:SetCallback("OnClick", function(widget)
            self:ExportRaid(windowRaid);
        end);
        window:AddChild(export);
        self:AddWidgetTooltip(export, "Open the window to export this raid's EP in the spreadsheet.");
    end

    if not IsInProgress(windowRaid) and self:GetDebugOpt("DebugRaidUI") and not self:IsRaidInProgress() then
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
        self:AddWidgetTooltip(restart, "Mark the raid as current again.");
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
        popup:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget);
            ABGP:ClosePopup(widget);
            window:SetUserData("popup", nil);
        end);
        local popupWidth = 240;
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

            elt = AceGUI:Create("ABGP_EditBox");
            elt:SetFullWidth(true);
            elt:SetValue(windowRaid.awards[player].ep);
            elt:SetCallback("OnValueChanged", function(widget, event, value)
                value = tonumber(value);
                if type(value) == "number" and value >= 0 and math.floor(value) == value then
                    self:AwardPlayerEP(windowRaid, player, value - windowRaid.awards[player].ep, awardCategories.ADJUST);
                    self:Notify("EP for %s set to %d.", self:ColorizeName(player), value);
                else
                    self:Error("Invalid value!");
                    return true;
                end
            end);
            scroll:AddChild(elt);
        end

        window:SetUserData("popup", popup);
    end);
    window:AddChild(manageEP);
    self:AddWidgetTooltip(manageEP, "Open the window to individually manage everyone's awarded EP.");

    if IsInProgress(windowRaid) then
        local autoDistrib = AceGUI:Create("CheckBox");
        autoDistrib:SetFullWidth(true);
        autoDistrib:SetLabel("Auto Distribution");
        autoDistrib:SetCallback("OnValueChanged", function(widget, event, value)
            windowRaid.autoDistribute = value;
        end);
        window:AddChild(autoDistrib);
        window:SetUserData("autoDistrib", autoDistrib);
        self:AddWidgetTooltip(autoDistrib, "If enabled, items will be automatically opened for distribution when loot popups are created.");

        if self:Get("masterLoot") then
            local disenchanter = AceGUI:Create("ABGP_EditBox");
            disenchanter:SetFullWidth(true);
            disenchanter:SetLabel("Disenchanter");
            disenchanter:SetCallback("OnValueChanged", function(widget, event, value)
                self:SetDisenchanter(value);
            end);
            disenchanter:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE);
            window:AddChild(disenchanter);
            window:SetUserData("disenchanter", disenchanter);
            self:AddWidgetTooltip(disenchanter, "Choose the player to whom disenchanted items, or ones you alt+ctrl+click, will get ML'd.");

            local mule = AceGUI:Create("ABGP_EditBox");
            mule:SetFullWidth(true);
            mule:SetLabel("Raid Mule");
            mule:SetCallback("OnValueChanged", function(widget, event, value)
                self:SetMule(value);
            end);
            mule:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE);
            window:AddChild(mule);
            window:SetUserData("mule", mule);
            self:AddWidgetTooltip(mule, "Choose the player to whom items you alt+shift+click will get ML'd.");
        end
    else
        local delete = AceGUI:Create("Button");
        delete:SetFullWidth(true);
        delete:SetText("Delete");
        delete:SetCallback("OnClick", function(widget)
            _G.StaticPopup_Show("ABGP_DELETE_RAID", nil, nil, windowRaid);
        end);
        window:AddChild(delete);
        self:AddWidgetTooltip(delete, "Delete the raid.");
    end

    local addStandby = AceGUI:Create("Button");
    addStandby:SetFullWidth(true);
    addStandby:SetText("Add Standby");
    addStandby:SetCallback("OnClick", function(widget)
        _G.StaticPopup_Show("ABGP_ADD_STANDBY", nil, nil, windowRaid);
    end);
    window:AddChild(addStandby);
    self:AddWidgetTooltip(addStandby, "Add a player to the standby list.");

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

    window:SetUserData("raid", windowRaid);
    activeWindow = window;
    window.frame:Raise();
    PopulateUI();
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
    local window = AceGUI:Create("ABGP_OpaqueWindow");
    window.frame:SetFrameStrata("DIALOG");
    window:SetTitle("Export");
    window:SetHeight(450);
    window:SetLayout("Flow");
    window:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget);
        ABGP:ClosePopup(widget);
    end);
    ABGP:OpenPopup(window);

    local raidDate = date("%m/%d/%y", windowRaid.startTime); -- https://strftime.org/

    local sortedPlayers = {};
    for player in pairs(windowRaid.awards) do
        table.insert(sortedPlayers, player);
    end
    table.sort(sortedPlayers);

    local tableContainer = AceGUI:Create("SimpleGroup");
    tableContainer:SetFullWidth(true);
    tableContainer:SetFullHeight(true);
    tableContainer:SetLayout("ABGP_Table");
    local nPhases = #self.PhasesSorted;
    local columns = {};
    for i = 1, nPhases do table.insert(columns, 1 / nPhases); end
    tableContainer:SetUserData("table", { columns = columns, rows = { 1.0 } });
    window:AddChild(tableContainer);

    for _, phase in ipairs(self.PhasesSorted) do
        local text = "";
        local i = 1;
        for _, player in ipairs(sortedPlayers) do
            local award = windowRaid.awards[player];
            local epgp = self:GetActivePlayer(player);

            -- The player will be exported for this phase if:
            -- a. They are active in this phase, and their raid group gives them EP for this phase, or
            -- b. The phase matches the raid's phase (but their award will be 0)
            local ep, info;
            local exported = false;
            if epgp and epgp[phase] then
                local raidGroup = epgp.epRaidGroup;
                if windowRaid.raidGroupEP[raidGroup] and windowRaid.raidGroupEP[raidGroup][phase] then
                    exported = true;
                    if epgp.trial then
                        ep = 0;
                        info = "No EP (trial)";
                    else
                        ep = award.ep;
                        local breakdown = {};
                        for _, cat in ipairs(awardCategoriesSorted) do
                            if award.categories[cat] then
                                table.insert(breakdown, ("%d (%s)"):format(award.categories[cat], awardCategoryNames[cat]));
                            end
                        end
                        info = table.concat(breakdown, ", ");
                    end
                end
            end
            if not exported and windowRaid.phase == phase then
                exported = true;
                ep = 0;
                info = "No EP (non-raider)";
                self:Notify("%s earned %d EP but was exported as 0 (non-raider in %s).",
                    self:ColorizeName(player), award.ep, self.PhaseNames[phase]);
            end

            if exported then
                text = text .. ("%s%d\t%s\t%s\t%s\t\t%s"):format(
                    (i == 1 and "" or "\n"), ep, windowRaid.name, player, raidDate, info);
                i = i + 1;
            end
        end

        local edit = AceGUI:Create("MultiLineEditBox");
        edit:SetFullWidth(true);
        edit:SetFullHeight(true);
        edit:SetUserData("cell", { align = "fill" });
        edit:SetLabel(self.PhaseNames[phase]);
        edit:SetText(text);
        edit:DisableButton(true);
        tableContainer:AddChild(edit);
        edit:HighlightText();
        edit:SetCallback("OnEditFocusGained", function(widget)
            widget:HighlightText();
        end);
    end

    window.frame:Raise();
end

function ABGP:EventOnGroupJoined()
    EnsureAwardsEntries();
end

function ABGP:EventOnGroupUpdate()
    EnsureAwardsEntries();
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

    if GetLootMethod() ~= pendingLootMethod and IsInGroup() and passedCombatCheck then
        if not IsRaidInCombat() then
            SetLootMethod(pendingLootMethod, UnitName("player"));
        end
        self:ScheduleTimer("ChangeLootMethod", 1);
    else
        if GetLootMethod() ~= pendingLootMethod then
            self:Notify("Giving up trying to change the loot type (entered combat or not grouped).");
        end
        pendingLootMethod = nil;
    end
end

local function ValidateEP(ep)
    ep = tonumber(ep);
    if type(ep) ~= "number" then return false, "Not a number"; end
    if math.floor(ep) ~= ep then return false, "Must be a whole number"; end

    return ep;
end

StaticPopupDialogs["ABGP_ADD_STANDBY"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Add a player to the standby list:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    autoCompleteSource = GetAutoCompleteResults,
    autoCompleteArgs = { bit.bor(AUTOCOMPLETE_FLAG_ONLINE, AUTOCOMPLETE_FLAG_INTERACTED_WITH, AUTOCOMPLETE_FLAG_IN_GUILD), bit.bor(AUTOCOMPLETE_FLAG_BNET, AUTOCOMPLETE_FLAG_IN_GROUP) },
    Commit = function(text, data)
        ABGP:AddStandby(data, text);
    end,
});
StaticPopupDialogs["ABGP_DELETE_RAID"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Delete this raid? This can't be undone!",
    button1 = "Yes",
    button2 = "No",
    showAlert = true,
    OnAccept = function(self, data)
        local raids = _G.ABGP_RaidInfo.pastRaids;
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
StaticPopupDialogs["ABGP_AWARD_EP"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Enter the amount of EP to award:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    Validate = function(text, data)
        return ValidateEP(text);
    end,
    Commit = function(ep, data)
        ABGP:AwardEP(ep, awardCategories.BONUS);
    end,
});
StaticPopupDialogs["ABGP_CONFIRM_BONUS_EP"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Award %d EP to the raid (%s)?",
    button1 = "Yes",
    button2 = "No",
    showAlert = true,
    OnAccept = function(self, data)
        ABGP:AwardEP(data, awardCategories.BONUS);
    end,
});
