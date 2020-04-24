local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetAutoCompleteResults = GetAutoCompleteResults;
local AutoCompleteEditBox_SetAutoCompleteSource = AutoCompleteEditBox_SetAutoCompleteSource;
local AUTOCOMPLETE_FLAG_IN_GUILD = AUTOCOMPLETE_FLAG_IN_GUILD;
local AUTOCOMPLETE_FLAG_NONE = AUTOCOMPLETE_FLAG_NONE;
local pairs = pairs;
local math = math;
local ipairs = ipairs;
local table = table;
local strlen = strlen;

local instanceIds = {
    MoltenCore    = 409,
    Onyxia        = 249,
    BlackwingLair = 469,
};

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
};

local instanceInfo = {
    [instanceIds.MoltenCore]  = { phase = ABGP.Phases.p1, name = "Molten Core", bosses = {
        bossIds.Lucifron, bossIds.Magmadar, bossIds.Gehennas, bossIds.Garr, bossIds.Shazzrah,
        bossIds.Geddon, bossIds.Sulfuron, bossIds.Golemagg, bossIds.Majordomo, bossIds.Ragnaros
    }},
    [instanceIds.Onyxia] = { phase = ABGP.Phases.p1, name = "Onyxia's Lair", bosses = {
        bossIds.Onyxia
    }},
    [instanceIds.BlackwingLair] = { phase = ABGP.Phases.p3, name = "Blackwing Lair", bosses = {
        bossIds.Razorgore, bossIds.Vaelastrasz, bossIds.Broodlord, bossIds.Firemaw,
        bossIds.Ebonroc, bossIds.Flamegor, bossIds.Chromaggus, bossIds.Nefarian
    }},
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
};

function ABGP:EventOnBossKilled(bossId, name)
    self:LogDebug("%s defeated!", name);
    local info = bossInfo[bossId];
    if info then
        self:LogDebug("This boss is worth %d EP.", info.ep);
    end
end

function ABGP:EventOnZoneChanged(name, instanceId)
    self:LogDebug("Zone changed to %s!", name);
    local info = instanceInfo[instanceId];
    if info then
        self:LogDebug("This instance is associated with phase %s.", info.phase);
        self.CurrentPhase = info.phase;
    end
end

function ABGP:StartRaid()
    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("DIALOG");
    window:SetLayout("Flow");
    window:SetTitle(("%s Raid"):format(self:ColorizeText("ABGP")));
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "raid", {
        version = math.random(),
        defaultWidth = 200,
        minWidth = 200,
        maxWidth = 200,
        defaultHeight = 160,
        minHeight = 160,
        maxHeight = 160
    });
    self:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
    end);

    local name = AceGUI:Create("ABGP_EditBox");
    name:SetFullWidth(true);
    name:SetMaxLetters(32);
    name:SetLabel("Name");
    -- AutoCompleteEditBox_SetAutoCompleteSource(name.editbox, GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GUILD, AUTOCOMPLETE_FLAG_NONE);
    name:SetCallback("OnEnterPressed", function(widget)
        AceGUI:ClearFocus();
    end);
    window:AddChild(name);

    local custom = -1;
    local instances = {
        [instanceIds.MoltenCore] = instanceInfo[instanceIds.MoltenCore].name,
        [instanceIds.Onyxia] = instanceInfo[instanceIds.Onyxia].name,
        [instanceIds.BlackwingLair] = instanceInfo[instanceIds.BlackwingLair].name,
        [custom] = "Custom",
    };
    local instanceSelector = AceGUI:Create("Dropdown");
    instanceSelector:SetText("Select Instance");
    instanceSelector:SetFullWidth(true);
    instanceSelector:SetValue(custom);
    instanceSelector:SetList(instances, { instanceIds.MoltenCore, instanceIds.Onyxia, instanceIds.BlackwingLair, custom });
    instanceSelector:SetCallback("OnValueChanged", function(widget, event, value)

    end);
    window:AddChild(instanceSelector);

    local start = AceGUI:Create("Button");
    start:SetFullWidth(true);
    start:SetText("Start");
    start:SetCallback("OnClick", function(widget)

    end);
    window:AddChild(start);
end
