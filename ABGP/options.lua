local _G = _G;
local ABGP = ABGP;
local AceConfig = _G.LibStub("AceConfig-3.0");
local AceConfigDialog = _G.LibStub("AceConfigDialog-3.0");
local AceDB = _G.LibStub("AceDB-3.0");

local IsInGroup = IsInGroup;
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
            func = function() ABGP:ShowMainWindow(); end
        },
        options = {
            name = "Options",
            desc = "opens the options window (alias: config/opt)",
            type = "execute",
            func = function() ABGP:ShowOptionsWindow(); end
        },
        loot = {
            name = "Loot",
            desc = "shows the item request window",
            type = "execute",
            func = function() ABGP:ShowItemRequests(); end
        },
        import = {
            name = "Data Import",
            desc = "shows the import window",
            type = "execute",
            cmdHidden = true,
            validate = function() if not ABGP:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() ABGP:ShowImportWindow(); end
        },
        versioncheck = {
            name = "Version Check",
            desc = "checks the raid for an outdated or missing addon versions (alias: vc)",
            type = "execute",
            cmdHidden = not ABGP:IsPrivileged(),
            validate = function() if not ABGP:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() ABGP:PerformVersionCheck(); end
        },
        -- raid = {
        --     name = "Start Raid",
        --     desc = "starts a raid (for EP tracking)",
        --     type = "execute",
        --     cmdHidden = not ABGP:IsPrivileged(),
        --     validate = function() if not ABGP:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
        --     func = function() ABGP:StartRaid(); end
        -- },
    };

    -- Set up aliases
    options.opt = { hidden = true };
    for k, v in pairs(options.options) do options.opt[k] = v; end
    options.config = { hidden = true };
    for k, v in pairs(options.options) do options.config[k] = v; end
    options.vc = { hidden = true };
    for k, v in pairs(options.versioncheck) do options.vc[k] = v; end
    options.vc.cmdHidden = nil;

    AceConfig:RegisterOptionsTable(ABGP:ColorizeText(addonText), {
        type = "group",
        args = options,
    }, { "abgp" });

    local raidGroups = {
        [ABGP.RaidGroups.RED] = "Red",
        [ABGP.RaidGroups.BLUE] = "Blue",
    };

    local guiOptions = {
        b = {
            name = "General",
            type = "group",
            args = {
                show = {
                    name = "Show Window",
                    order = 1,
                    desc = "Show the main window",
                    type = "execute",
                    func = function()
                        _G.InterfaceOptionsFrame_Show(); -- it's really a toggle, calling this to hide the frame.
                        ABGP:ShowMainWindow();
                    end
                },
                priorities = {
                    name = "Preferred Priorities",
                    order = 2,
                    desc = "If any priorites are chosen here, items not matching them will be deemphasized during distribution.",
                    type = "multiselect",
                    control = "Dropdown",
                    values = self:GetItemPriorities(),
                    get = function(self, k) return ABGP.db.char.preferredPriorities[k]; end,
                    set = function(self, k, v)
                        ABGP.db.char.preferredPriorities[k] = v;
                        local usePriority = false;
                        for _, v in pairs(ABGP.db.char.preferredPriorities) do
                            if v then usePriority = true; end
                        end
                        ABGP.db.char.usePreferredPriority = usePriority;
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
                    get = function(self) return ABGP.db.char.itemHistoryLimit; end,
                    set = function(self, v) ABGP.db.char.itemHistoryLimit = v; end,
                    cmdHidden = true,
                },
                alwaysOpenWindow = {
                    name = "Always open loot UI",
                    order = 4,
                    desc = "If this is set, the loot window item will always open when loot is opened for distribution, instead of skipping some (like ones you can't use).",
                    type = "toggle",
                    get = function(self) return ABGP.db.char.alwaysOpenWindow; end,
                    set = function(self, v) ABGP.db.char.alwaysOpenWindow = v; end,
                },
            },
        },
        c = {
            name = "Raid Groups",
            type = "group",
            args = {
                raidGroup = {
                    name = "Raid Group",
                    order = 1,
                    desc = "Choose the raid group to prioritize in the UI.",
                    type = "select",
                    control = "Dropdown",
                    values = raidGroups,
                    get = function(self) return ABGP:GetRaidGroup(); end,
                    set = function(self, v) ABGP.db.char.raidGroup = v; end,
                },
                outsider = {
                    name = "Outsider",
                    order = 2,
                    desc = "Select this option if your EPGP is tracked outside your guild.",
                    type = "toggle",
                    get = function(self) return ABGP.db.char.outsider; end,
                    set = function(self, v)
                        ABGP.db.char.outsider = v;
                        ABGP:SendMessage(ABGP.CommTypes.GUILD_NOTES_UPDATED);
                    end,
                },
            },
        },
    };
    AceConfig:RegisterOptionsTable("ABGP", {
        name = ABGP:ColorizeText(addonText) .. " Options",
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
