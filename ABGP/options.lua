local _G = _G;
local ABGP = ABGP;
local AceConfig = _G.LibStub("AceConfig-3.0");
local AceConfigDialog = _G.LibStub("AceConfigDialog-3.0");
local AceDB = _G.LibStub("AceDB-3.0");

local pairs = pairs;

function ABGP:InitOptions()
    local defaults = {
        char = {
            usePreferredPriority = false,
            preferredPriorities = {},
            itemHistoryLimit = 3,
            raidGroup = false,
            outsider = false,
            alwaysOpenWindow = true,
            showLootFrames = true,
            lootDirection = "up",
            lootDuration = 15,
            lootElvUI = true,
            lootShowToasts = true,
            lootIntegration = true,
            commMonitoringTriggered = false,
            commMonitoringEnabled = false,
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
            desc = "shows the item request window",
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
            desc = "Dumps the addon comms monitor state",
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

    -- Set up aliases
    options.opt = { hidden = true };
    for k, v in pairs(options.options) do options.opt[k] = v; end
    options.config = { hidden = true };
    for k, v in pairs(options.options) do options.config[k] = v; end
    options.vc = { hidden = true };
    for k, v in pairs(options.versioncheck) do options.vc[k] = v; end
    options.vc.cmdHidden = nil;

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
                priorities = {
                    name = "Preferred Priorities",
                    order = 2,
                    desc = "If any priorites are chosen here, items not matching them will be deemphasized during distribution.",
                    type = "multiselect",
                    control = "Dropdown",
                    values = self:GetItemPriorities(),
                    get = function(info, k) return self.db.char.preferredPriorities[k]; end,
                    set = function(info, k, v)
                        self.db.char.preferredPriorities[k] = v;
                        local usePriority = false;
                        for _, v in pairs(self.db.char.preferredPriorities) do
                            if v then usePriority = true; end
                        end
                        self.db.char.usePreferredPriority = usePriority;
                    end,
                    cmdHidden = true,
                },
                itemHistoryLimit = {
                    name = "Tooltip item history",
                    order = 3,
                    desc = "Controls the max number of item history entries to show in a tooltip when holding alt. Set to 0 to disable.",
                    type = "range",
                    min = 0,
                    max = 10,
                    step = 1,
                    get = function(info) return self.db.char.itemHistoryLimit; end,
                    set = function(info, v) self.db.char.itemHistoryLimit = v; end,
                    cmdHidden = true,
                },
                alwaysOpenWindow = {
                    name = "Always show distrib",
                    order = 4,
                    desc = "If this is set, the request window will always open when loot is opened for distribution, instead of skipping some (like ones you can't use).",
                    type = "toggle",
                    get = function(info) return self.db.char.alwaysOpenWindow; end,
                    set = function(info, v) self.db.char.alwaysOpenWindow = v; end,
                },
                commMonitor = {
                    name = "Monitor addon comms",
                    order = 5,
                    desc = "Monitor addon communication to help diagnose delayed messages.",
                    type = "toggle",
                    get = function(info) return self.db.char.commMonitoringEnabled; end,
                    set = function(info, v) self.db.char.commMonitoringEnabled = v; self:SetupCommMonitor(); end,
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
                    name = "Show boss loot",
                    order = 1,
                    desc = "Show loot items when a boss is killed.",
                    type = "toggle",
                    get = function(info) return self.db.char.showLootFrames; end,
                    set = function(info, v) self.db.char.showLootFrames = v; end,
                },
                toasts = {
                    name = "Show loot toasts",
                    order = 2,
                    desc = "Show a toast when you are awarded an item.",
                    type = "toggle",
                    get = function(info) return self.db.char.lootShowToasts; end,
                    set = function(info, v) self.db.char.lootShowToasts = v; end,
                },
                integration = {
                    name = "Request integration",
                    order = 3,
                    desc = "Request items directly from the loot item frame.",
                    type = "toggle",
                    get = function(info) return self.db.char.lootIntegration; end,
                    set = function(info, v) self.db.char.lootIntegration = v; end,
                },
                theme = {
                    name = "Use ElvUI theme",
                    order = 4,
                    desc = "Make the boss loot item UI match ElvUI. You must reload your UI after changing this setting.",
                    type = "toggle",
                    hidden = function() return (_G.ElvUI == nil); end,
                    get = function(info) return self.db.char.lootElvUI; end,
                    set = function(info, v) self.db.char.lootElvUI = v; end,
                },
                direction = {
                    name = "Direction",
                    order = 5,
                    desc = "Choose which direction new boss loot items are added.",
                    type = "select",
                    control = "Dropdown",
                    values = { up = "Up", down = "Down" },
                    get = function(info) return self.db.char.lootDirection; end,
                    set = function(info, v) self.db.char.lootDirection = v; self:RefreshLootFrames(); end,
                },
                duration = {
                    name = "Item duration",
                    order = 6,
                    desc = "Sets how long the boss loot items will be shown.",
                    type = "range",
                    min = 5,
                    max = 30,
                    step = 1,
                    get = function(info) return self.db.char.lootDuration; end,
                    set = function(info, v) self.db.char.lootDuration = v; end,
                    cmdHidden = true,
                },
                test = {
                    name = "Test",
                    order = 7,
                    desc = "Show test boss loot items.",
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
