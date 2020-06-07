local _G = _G;
local ABGP = _G.ABGP;
local AceConfig = _G.LibStub("AceConfig-3.0");
local AceConfigDialog = _G.LibStub("AceConfigDialog-3.0");
local AceDB = _G.LibStub("AceDB-3.0");

local GetServerTime = GetServerTime;
local pairs = pairs;
local time = time;
local ipairs = ipairs;
local table = table;
local tonumber = tonumber;

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
            lootShiftAll = false,
            commMonitoringTriggered = false,
            commMonitoringEnabled = false,
            masterLoot = false,
            minimapAlert = true,
            promptRaidStart = false,
            syncEnabled = true,
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
            hidden = function() return not self:IsPrivileged(); end,
            validate = function() if not self:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() self:ShowImportWindow(); end
        },
        versioncheck = {
            name = "Version Check",
            desc = "checks the raid for an outdated or missing addon versions (alias: vc)",
            type = "execute",
            hidden = function() return not self:IsPrivileged(); end,
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
            hidden = function() return not self:IsPrivileged(); end,
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
            name = "",
            type = "group",
            inline = true,
            order = 1,
            args = {
                header = {
                    order = 1,
                    type = "header",
                    name = "General",
                },
                settings = {
                    name = " ",
                    type = "group",
                    inline = true,
                    order = 2,
                    args = {
                        minimap = {
                            name = "Minimap Icon",
                            order = 1,
                            desc = "Show the minimap icon.",
                            type = "toggle",
                            get = function(info) return not self.db.char.minimap.hide; end,
                            set = function(info, v) self.db.char.minimap.hide = not v; self:RefreshMinimapIcon(); end,
                        },
                        minimapAlert = {
                            name = "Minimap Alert",
                            order = 2,
                            desc = "Show an alert on the minimap icon when you've hidden items that are open for distribution.",
                            type = "toggle",
                            disabled = function() return self.db.char.minimap.hide; end,
                            get = function(info) return self.db.char.minimapAlert; end,
                            set = function(info, v) self.db.char.minimapAlert = v; self:RefreshMinimapIcon(); end,
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
                        commMonitor = {
                            name = "Monitor addon comms",
                            order = 4,
                            desc = "Monitor addon communication to help diagnose delayed messages.",
                            type = "toggle",
                            get = function(info) return self.db.char.commMonitoringEnabled; end,
                            set = function(info, v) self.db.char.commMonitoringEnabled = v; self:SetupCommMonitor(); end,
                        },
                    },
                },
            },
        },
        raidGroups = {
            name = "",
            type = "group",
            inline = true,
            order = 2,
            args = {
                header2 = {
                    order = 1,
                    type = "header",
                    name = "Raid Group",
                },
                desc2 = {
                    order = 2,
                    type = "description",
                    name = "Your raid group is generally determined from your guild rank.",
                },
                settings = {
                    name = " ",
                    type = "group",
                    inline = true,
                    order = 3,
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
                                self:Fire(self.CommTypes.OFFICER_NOTES_UPDATED);
                            end,
                        },
                    },
                },
            },
        },
        loot = {
            name = "",
            type = "group",
            inline = true,
            order = 4,
            args = {
                header = {
                    order = 1,
                    type = "header",
                    name = "Loot",
                },
                desc = {
                    order = 2,
                    type = "description",
                    name = "Loot popups are shown when items are opened for distribution, and optionally when they are initially discovered by looting.",
                },
                settings = {
                    name = " ",
                    type = "group",
                    inline = true,
                    order = 3,
                    args = {
                        show = {
                            name = "Show when looted",
                            order = 1,
                            desc = "Show popups when the items are initially discovered by looting, rather than waiting for them to be distributed.",
                            type = "toggle",
                            get = function(info) return self.db.char.lootShowImmediately; end,
                            set = function(info, v) self.db.char.lootShowImmediately = v; end,
                        },
                        duration = {
                            name = "Popup duration",
                            order = 2,
                            desc = "Sets how long the loot popups will be shown. If the item is opened for distribution, the popup will remain until distribution is closed.",
                            type = "range",
                            min = 5,
                            max = 30,
                            step = 1,
                            disabled = function() return not self.db.char.lootShowImmediately; end,
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
                            set = function(info, v)
                                self.db.char.lootElvUI = v;
                                _G.StaticPopup_Show("ABGP_PROMPT_RELOAD", "Changing this option requires a UI reload.");
                            end,
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
                        shiftAll = {
                            name = "Shift Closes All",
                            order = 5,
                            desc = "If enabled, shift+clicking the 'Close' button of a loot popup will close all popups, instead of just those for items you haven't requested.",
                            type = "toggle",
                            get = function(info) return self.db.char.lootShiftAll; end,
                            set = function(info, v) self.db.char.lootShiftAll = v; end,
                        },
                        test = {
                            name = "Test",
                            order = 6,
                            desc = "Show test loot popups.",
                            type = "execute",
                            func = function() self:ShowTestLoot(); end
                        },
                    },
                },
            },
        },
        sync = {
            name = "",
            type = "group",
            inline = true,
            order = 4,
            hidden = function() return self.db.char.outsider; end,
            args = {
                header = {
                    order = 1,
                    type = "header",
                    name = "History Sync",
                },
                desc = {
                    order = 2,
                    type = "description",
                    name = "EPGP history is kept up to date by syncing new entries from officers when you log in. If your local history is more than 10 days out of date, it will need a complete rebuild.",
                },
                status = {
                    name = "",
                    type = "group",
                    inline = true,
                    order = 3,
                    hidden = function() return self:HasCompleteHistory(); end,
                    args = {
                        status = {
                            order = 1,
                            type = "description",
                            name = "Your history is incomplete - it cannot fully recalculate everyone's EPGP.",
                        },
                        checkHistory = {
                            name = "See Why",
                            order = 2,
                            desc = "See a printout of all EPGP discrepancies between your history and their current value in the officer notes.",
                            type = "execute",
                            hidden = function() return self:HasCompleteHistory(); end,
                            func = function() self:HasCompleteHistory(true); end,
                        },
                    },
                },
                baseline = {
                    name = "",
                    type = "group",
                    inline = true,
                    order = 4,
                    hidden = function() return self:HasValidBaselines(); end,
                    args = {
                        status = {
                            order = 1,
                            type = "description",
                            name = function()
                                local invalidBaselines = {};
                                for _, phase in ipairs(self.PhasesSorted) do
                                    if not self:HasValidBaseline(phase) then
                                        table.insert(invalidBaselines, self.PhaseNames[phase]);
                                    end
                                end
                                return ("You currently need a full history rebuild for these phase(s): %s"):format(table.concat(invalidBaselines, ", "));
                            end,
                        },
                    },
                },
                settings = {
                    name = " ",
                    type = "group",
                    inline = true,
                    order = 5,
                    args = {
                        enabled = {
                            name = "Enabled",
                            order = 1,
                            desc = "If disabled, your history will only contain entries you personally witnessed. It may become inaccurate if those entries get edited.",
                            type = "toggle",
                            get = function(info) return self.db.char.syncEnabled; end,
                            set = function(info, v) self.db.char.syncEnabled = v; end,
                        },
                        syncNow = {
                            name = "Sync",
                            order = 2,
                            desc = "Trigger a sync now, for the last 10 days of history.",
                            type = "execute",
                            disabled = function() return not self.db.char.syncEnabled; end,
                            func = function() self:HistoryTriggerSync(); end,
                        },
                        rebuild = {
                            name = "Rebuild",
                            order = 3,
                            desc = "Trigger a complete rebuild of your history.",
                            type = "execute",
                            disabled = function() return not self.db.char.syncEnabled; end,
                            func = function() self:HistoryTriggerRebuild(); end,
                        },
                    },
                },
            },
        },
        officer = {
            name = "",
            type = "group",
            inline = true,
            order = 5,
            hidden = function() return not self:CanEditOfficerNotes(); end,
            args = {
                header = {
                    order = 1,
                    type = "header",
                    name = "Officer",
                },
                desc = {
                    order = 2,
                    type = "description",
                    name = "Special settings for officers.",
                },
                settings = {
                    name = " ",
                    type = "group",
                    inline = true,
                    order = 3,
                    args = {
                        add = {
                            name = "Add Player",
                            order = 1,
                            desc = "Add a player into the EPGP system. NOTE: for now this just creates history items, it does not update officer notes. Use it after importing EPGP from the spreadsheet.",
                            type = "execute",
                            func = function() ABGP:ShowAddPlayerWindow(); end,
                        },
                        decay = {
                            name = "Decay",
                            order = 2,
                            desc = "Trigger EPGP decay. NOTE: for now this just creates a history item, it does not update officer notes. Use it after importing EPGP from the spreadsheet.",
                            type = "execute",
                            func = function() _G.StaticPopup_Show("ABGP_TRIGGER_DECAY"); end,
                        },
                        masterLoot = {
                            name = "Master Loot",
                            order = 3,
                            desc = "Distribute items via master loot as they're awarded or disenchanted.",
                            type = "toggle",
                            get = function(info) return self.db.char.masterLoot; end,
                            set = function(info, v) self.db.char.masterLoot = v; end,
                        },
                        promptRaidStart = {
                            name = "Prompt Raids",
                            order = 4,
                            desc = "Open the raid window when zoning into an instance associated with a raid.",
                            type = "toggle",
                            get = function(info) return self.db.char.promptRaidStart; end,
                            set = function(info, v) self.db.char.promptRaidStart = v; end,
                        },
                    },
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

function ABGP:RefreshOptionsWindow()
    if self.OptionsFrame:IsVisible() then
        AceConfigDialog:Open("ABGP", self.OptionsFrame.obj);
    end
end

function ABGP:OptionsOnHistoryUpdate()
    self:RefreshOptionsWindow();
end

function ABGP:ShowAddPlayerWindow()

end

StaticPopupDialogs["ABGP_TRIGGER_DECAY"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Choose the date for the decay (M/D/Y):",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    Validate = function(text)
        text = text:gsub("20(%d%d)", "%1");
        local m, d, y = text:match("^(%d+)/(%d+)/(%d+)$");
        if not m then return false, "Couldn't parse date"; end

        local now = GetServerTime();
        local decayTime = time({ year = 2000 + tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 });
        decayTime = decayTime + (24 * 60 * 60) - 1;
        if decayTime > now then return false, "Date must be before today"; end

        for phase in pairs(ABGP.Phases) do
            local history = ABGP:ProcessItemHistory(_G.ABGP_Data[phase].gpHistory, true, true);
            for _, entry in ipairs(history) do
                local entryDate = entry[ABGP.ItemHistoryIndex.DATE];
                if entryDate < decayTime then break; end

                if entry[ABGP.ItemHistoryIndex.TYPE] == ABGP.ItemHistoryType.DECAY then
                    return false, "A more recent decay already exists";
                end
            end
        end

        return decayTime;
    end,
    Commit = function(decayTime)
        ABGP:HistoryTriggerDecay(decayTime);
    end,
});
