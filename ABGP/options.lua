local _G = _G;
local ABGP = ABGP;
local AceConfig = _G.LibStub("AceConfig-3.0");
local AceConfigDialog = _G.LibStub("AceConfigDialog-3.0");
local AceDB = _G.LibStub("AceDB-3.0");

local pairs = pairs;

function ABGP:InitOptions()
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

    local defaults = {
        char = {
            usePreferredPriority = false,
            preferredPriorities = {},
        }
    };
    self.db = AceDB:New("ABGP_DB", defaults);

    local guiOptions = {
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
            values = {
                ["Druid (Heal)"] = "Druid (Heal)",
                ["KAT4FITE"] = "KAT4FITE",
                ["Hunter"] = "Hunter",
                ["Mage"] = "Mage",
                ["Paladin (Holy)"] = "Paladin (Holy)",
                ["Paladin (Ret)"] = "Paladin (Ret)",
                ["Priest (Heal)"] = "Priest (Heal)",
                ["Priest (Shadow)"] = "Priest (Shadow)",
                ["Rogue"] = "Rogue",
                ["Slicey Rogue"] = "Slicey Rogue",
                ["Stabby Rogue"] = "Stabby Rogue",
                ["Warlock"] = "Warlock",
                ["Tank"] = "Tank",
                ["Metal Rogue"] = "Metal Rogue",
                ["Progression"] = "Progression",
                ["Garbage"] = "Garbage",
            },
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
