local _G = _G;
local ABGP = _G.ABGP;
local AceConfig = _G.LibStub("AceConfig-3.0");
local AceConfigDialog = _G.LibStub("AceConfigDialog-3.0");
local AceDB = _G.LibStub("AceDB-3.0");

local pairs = pairs;

function ABGP:InitOptions()
    local defaults = {
        char = {
            debug = false,
            itemHistoryLimit = 5,
            raidGroup = false,
            outsider = false,
            lootShowImmediately = true,
            lootDirection = "up",
            lootDuration = 15,
            lootElvUI = true,
            commMonitoringTriggered = false,
            commMonitoringEnabled = false,
            masterLoot = true,
            minimap = {
                hide = false,
            },
        }
    };
    self.db = AceDB:New("ABGP_DB", defaults);

    local addonText = "ABGP";
    local version = self:GetVersion();
    if self:ParseVersion(version) then
        addonText = "ABGP-v" .. version;
    end
    local options = {
        show = {
            name = "Show",
            desc = "shows the main window",
            type = "execute",
            func = function() self:ShowMainWindow(); end
        },
        options = {
            name = "Options",
            desc = "opens the options window (alias: config/opt)",
            type = "execute",
            func = function() self:ShowOptionsWindow(); end
        },
        loot = {
            name = "Loot",
            desc = "shows items currently opened for distribution",
            type = "execute",
            func = function() self:ShowItemRequests(); end
        },
        import = {
            name = "Data Import",
            desc = "shows the import window",
            type = "execute",
            cmdHidden = true,
            validate = function() if not self:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() self:ShowImportWindow(); end
        },
        versioncheck = {
            name = "Version Check",
            desc = "checks the raid for an outdated or missing addon versions (alias: vc)",
            type = "execute",
            cmdHidden = not self:IsPrivileged(),
            validate = function() if not self:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() self:PerformVersionCheck(); end
        },
        comms = {
            name = "Dump Comms",
            desc = "Dumps the addon comms monitor state (alias: comm)",
            type = "execute",
            hidden = function() return not self:Get("commMonitoringEnabled"); end,
            func = function() self:DumpCommMonitor(true); end
        },
        raid = {
            name = "Start Raid",
            desc = "starts or updates a raid (for EP tracking)",
            type = "execute",
            cmdHidden = not self:IsPrivileged(),
            validate = function() if not self:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() self:ShowRaidWindow(); end
        },
    };

    local function setupAlias(existing, alias)
        options[alias] = {};
        for k, v in pairs(options[existing]) do options[alias][k] = v; end
        options[alias].hidden = true;
        options[alias].cmdHidden = nil;
    end
    setupAlias("options", "opt");
    setupAlias("options", "config");
    setupAlias("versioncheck", "vc");
    setupAlias("comms", "comm");

    AceConfig:RegisterOptionsTable(self:ColorizeText(addonText), {
        type = "group",
        args = options,
    }, { "abgp" });

    local raidGroupNames = {};
    for k, v in pairs(self.RaidGroupNames) do raidGroupNames[k] = v; end

    local guiOptions = {
        general = {
            name = "General",
            type = "group",
            order = 1,
            args = {
                show = {
                    name = "Show Window",
                    order = 1,
                    desc = "Show the main window",
                    type = "execute",
                    func = function()
                        _G.InterfaceOptionsFrame_Show(); -- it's really a toggle, calling this to hide the frame.
                        self:ShowMainWindow();
                    end
                },
                itemHistoryLimit = {
                    name = "Tooltip item history",
                    order = 2,
                    desc = "Controls the max number of item history entries to show in a tooltip when holding alt. Set to 0 to disable.",
                    type = "range",
                    min = 0,
                    max = 10,
                    step = 1,
                    get = function(info) return self.db.char.itemHistoryLimit; end,
                    set = function(info, v) self.db.char.itemHistoryLimit = v; end,
                    cmdHidden = true,
                },
                commMonitor = {
                    name = "Monitor addon comms",
                    order = 3,
                    desc = "Monitor addon communication to help diagnose delayed messages.",
                    type = "toggle",
                    get = function(info) return self.db.char.commMonitoringEnabled; end,
                    set = function(info, v) self.db.char.commMonitoringEnabled = v; self:SetupCommMonitor(); end,
                },
                minimap = {
                    name = "Minimap Icon",
                    order = 4,
                    desc = "Show the minimap icon.",
                    type = "toggle",
                    get = function(info) return not self.db.char.minimap.hide; end,
                    set = function(info, v) self.db.char.minimap.hide = not v; self:RefreshMinimapIcon(); end,
                },
                masterLoot = {
                    name = "Master Loot",
                    order = 5,
                    desc = "Distribute items via master loot as they're awarded or disenchanted.",
                    type = "toggle",
                    hidden = function() return not self:IsPrivileged(); end,
                    get = function(info) return self.db.char.masterLoot; end,
                    set = function(info, v) self.db.char.masterLoot = v; end,
                },
            },
        },
        raidGroups = {
            name = "Raid Groups",
            type = "group",
            order = 2,
            args = {
                raidGroup = {
                    name = "Raid Group",
                    order = 1,
                    desc = "Choose the raid group to prioritize in the UI.",
                    type = "select",
                    control = "Dropdown",
                    values = raidGroupNames,
                    get = function(info) return self:GetPreferredRaidGroup(); end,
                    set = function(info, v) self.db.char.raidGroup = v; end,
                },
                outsider = {
                    name = "Outsider",
                    order = 2,
                    desc = "Select this option if your EPGP is tracked outside your guild.",
                    type = "toggle",
                    get = function(info) return self.db.char.outsider; end,
                    set = function(info, v)
                        self.db.char.outsider = v;
                        self:SendMessage(self.CommTypes.OFFICER_NOTES_UPDATED);
                    end,
                },
            },
        },
        loot = {
            name = "Loot",
            type = "group",
            order = 3,
            args = {
                show = {
                    name = "Show loot immediately",
                    order = 1,
                    desc = "Show popups when the loot is initially discovered, rather than waiting for it to be distributed.",
                    type = "toggle",
                    get = function(info) return self.db.char.lootShowImmediately; end,
                    set = function(info, v) self.db.char.lootShowImmediately = v; end,
                },
                duration = {
                    name = "Popup duration",
                    order = 2,
                    desc = "Sets how long the boss loot popups will be shown, if the item doesn't get opened for distribution.",
                    type = "range",
                    min = 5,
                    max = 30,
                    step = 1,
                    get = function(info) return self.db.char.lootDuration; end,
                    set = function(info, v) self.db.char.lootDuration = v; end,
                    cmdHidden = true,
                },
                theme = {
                    name = "Use ElvUI theme",
                    order = 3,
                    desc = "Make the loot popups match ElvUI. You must reload your UI after changing this setting.",
                    type = "toggle",
                    hidden = function() return (_G.ElvUI == nil); end,
                    get = function(info) return self.db.char.lootElvUI; end,
                    set = function(info, v) self.db.char.lootElvUI = v; end,
                },
                direction = {
                    name = "Direction",
                    order = 4,
                    desc = "Choose which direction new loot popups are added.",
                    type = "select",
                    control = "Dropdown",
                    values = { up = "Up", down = "Down" },
                    get = function(info) return self.db.char.lootDirection; end,
                    set = function(info, v) self.db.char.lootDirection = v; self:RefreshLootFrames(); end,
                },
                test = {
                    name = "Test",
                    order = 7,
                    desc = "Show test loot popups.",
                    type = "execute",
                    func = function() self:ShowTestLoot(); end
                },
            },
        },
    };
    AceConfig:RegisterOptionsTable("ABGP", {
        name = self:ColorizeText(addonText) .. " Options",
        type = "group",
        args = guiOptions,
    });
    self.OptionsFrame = AceConfigDialog:AddToBlizOptions("ABGP");
end

function ABGP:ShowOptionsWindow()
    _G.InterfaceOptionsFrame_Show();
    _G.InterfaceOptionsFrame_OpenToCategory(self.OptionsFrame);
end

function ABGP:Get(k)
    return self.db.char[k];
end

function ABGP:Set(k, v)
    self.db.char[k] = v;
end
