local _G = _G;
local ABGP = _G.ABGP;
local AceConfig = _G.LibStub("AceConfig-3.0");
local AceConfigDialog = _G.LibStub("AceConfigDialog-3.0");
local AceDB = _G.LibStub("AceDB-3.0");
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetServerTime = GetServerTime;
local GetAutoCompleteResults = GetAutoCompleteResults;
local AUTOCOMPLETE_FLAG_IN_GUILD = AUTOCOMPLETE_FLAG_IN_GUILD;
local AUTOCOMPLETE_FLAG_NONE = AUTOCOMPLETE_FLAG_NONE;
local pairs = pairs;
local time = time;
local ipairs = ipairs;
local tonumber = tonumber;
local type = type;
local date = date;

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
            autoDistribute = false,
            raidDisenchanters = "",
            raidMules = "",
            syncEnabled = true,
            syncVerbose = false,
            strictOnTime = false,
            altShowsPrerelease = false,
            minimap = {
                hide = false,
            },
        },
        global = {
            raidDisenchanters = "",
            raidMules = "",
            autoMLItems = "word of thawing\n" ..
                          "wartorn plate scrap\n" ..
                          "wartorn chain scrap\n" ..
                          "wartorn leather scrap\n" ..
                          "wartorn cloth scrap",
        },
    };
    self.db = AceDB:New("ABGP_DB", defaults);

    local old = self:Get("raidDisenchanters");
    local new = self:GetGlobal("raidDisenchanters");
    if old ~= "" and new == "" then
        self:SetGlobal("raidDisenchanters", old);
    end

    local old = self:Get("raidMules");
    local new = self:GetGlobal("raidMules");
    if old ~= "" and new == "" then
        self:SetGlobal("raidMules", old);
    end

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
                    },
                },
            },
        },
        -- raidGroups = {
        --     name = "",
        --     type = "group",
        --     inline = true,
        --     order = 2,
        --     args = {
        --         header2 = {
        --             order = 1,
        --             type = "header",
        --             name = "Raid Group",
        --         },
        --         desc2 = {
        --             order = 2,
        --             type = "description",
        --             name = "Your raid group is generally determined from your guild rank.",
        --         },
        --         settings = {
        --             name = " ",
        --             type = "group",
        --             inline = true,
        --             order = 3,
        --             args = {
        --                 raidGroup = {
        --                     name = "Raid Group",
        --                     order = 1,
        --                     desc = "Choose the raid group to prioritize in the UI.",
        --                     type = "select",
        --                     control = "Dropdown",
        --                     values = raidGroupNames,
        --                     get = function(info) return self:GetPreferredRaidGroup(); end,
        --                     set = function(info, v) self.db.char.raidGroup = v; end,
        --                 },
        --                 outsider = {
        --                     name = "Outsider",
        --                     order = 2,
        --                     desc = "Select this option if your EPGP is tracked outside your guild.",
        --                     type = "toggle",
        --                     get = function(info) return self.db.char.outsider; end,
        --                     set = function(info, v)
        --                         self.db.char.outsider = v;
        --                         self:Fire(self.CommTypes.GUILD_NOTES_UPDATED);
        --                     end,
        --                 },
        --             },
        --         },
        --     },
        -- },
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
                        minimapAlert = {
                            name = "Minimap Alert",
                            order = 6,
                            desc = "Show an alert on the minimap icon when you've hidden items that are open for distribution.",
                            type = "toggle",
                            disabled = function() return self.db.char.minimap.hide; end,
                            get = function(info) return not self.db.char.minimap.hide and self.db.char.minimapAlert; end,
                            set = function(info, v) self.db.char.minimapAlert = v; self:RefreshMinimapIcon(); end,
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
                    name = "EPGP history is kept up to date by syncing new entries from officers on login. If your local history is more than 10 days out of date, it will need a complete rebuild.",
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
                    hidden = function() return self:HasValidHistory(); end,
                    args = {
                        status = {
                            order = 1,
                            type = "description",
                            name = "You currently need a full history rebuild.",
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
                            desc = "Trigger a sync.",
                            type = "execute",
                            disabled = function() return not self.db.char.syncEnabled; end,
                            func = function() self:SyncHistory(); end,
                        },
                        rebuild = {
                            name = "Rebuild",
                            order = 3,
                            desc = "Trigger a complete rebuild of your history.",
                            type = "execute",
                            disabled = function() return not self.db.char.syncEnabled; end,
                            func = function() self:RebuildHistory(); end,
                        },
                        -- verbose = {
                        --     name = "Verbose",
                        --     order = 4,
                        --     desc = "When enabled, you'll see messages in your chat frame when you receive new synced entries.",
                        --     type = "toggle",
                        --     disabled = function() return not self.db.char.syncEnabled; end,
                        --     get = function(info) return self.db.char.syncEnabled and self.db.char.syncVerbose; end,
                        --     set = function(info, v) self.db.char.syncVerbose = v; end,
                        -- },
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
                        addPlayer = {
                            name = "Add Player",
                            order = 1,
                            desc = "Add a player into the EPGP system.",
                            type = "execute",
                            func = function() ABGP:ShowAddPlayerWindow(); end,
                        },
                        addTrial = {
                            name = "Add Trial",
                            order = 2,
                            desc = "Add a trial into the EPGP system.",
                            type = "execute",
                            func = function() ABGP:ShowAddTrialWindow(); end,
                        },
                        decay = {
                            name = "Decay",
                            order = 3,
                            desc = "Trigger EPGP decay. NOTE: for now this just creates a history item, it does not update officer notes. Use it after importing EPGP from the spreadsheet.",
                            type = "execute",
                            func = function() _G.StaticPopup_Show("ABGP_TRIGGER_DECAY"); end,
                        },
                        masterLoot = {
                            name = "Master Loot",
                            order = 4,
                            desc = "Distribute items via master loot as they're awarded or disenchanted.",
                            type = "toggle",
                            get = function(info) return self.db.char.masterLoot; end,
                            set = function(info, v) self.db.char.masterLoot = v; end,
                        },
                        promptRaidStart = {
                            name = "Prompt Raids",
                            order = 5,
                            desc = "Open the raid window when zoning into an instance associated with a raid.",
                            type = "toggle",
                            get = function(info) return self.db.char.promptRaidStart; end,
                            set = function(info, v) self.db.char.promptRaidStart = v; end,
                        },
                        autoDistribute = {
                            name = "Auto Distribute",
                            order = 6,
                            desc = "Automatically open items for distribution if you're the master looter.",
                            type = "toggle",
                            get = function(info) return self.db.char.autoDistribute; end,
                            set = function(info, v) self.db.char.autoDistribute = v; end,
                        },
                        -- strictOnTime = {
                        --     name = "Strict On-Time",
                        --     order = 7,
                        --     desc = "Only award the on-time bonus to raid members that are online and in your zone. Standby is unaffected.",
                        --     type = "toggle",
                        --     get = function(info) return self.db.char.strictOnTime; end,
                        --     set = function(info, v) self.db.char.strictOnTime = v; end,
                        -- },
                        altShowsPrerelease = {
                            name = "Alt shows prerelease",
                            order = 8,
                            desc = "When displaying an item tooltip, pressing alt will now show the item's prerelease value instead of its award history.",
                            type = "toggle",
                            get = function(info) return self.db.char.altShowsPrerelease; end,
                            set = function(info, v) self.db.char.altShowsPrerelease = v; end,
                        },
                        raidDisenchanters = {
                            name = "Disenchanters",
                            order = 9,
                            desc = "Specify a comma-separated list of players, in priority order, who are the raid's disenchanters. You can ML items to this person in the distribution window or by alt+clicking the item.",
                            type = "input",
                            get = function(info) return self.db.global.raidDisenchanters; end,
                            set = function(info, v) self.db.global.raidDisenchanters = v; end,
                        },
                        raidMules = {
                            name = "Mules",
                            order = 10,
                            desc = "Specify a comma-separated list of players, in priority order, who are the raid's mules. You can ML items to this person by alt+clicking the item.",
                            type = "input",
                            get = function(info) return self.db.global.raidMules; end,
                            set = function(info, v) self.db.global.raidMules = v; end,
                        },
                        autoMLItems = {
                            name = "Auto-Mule Items",
                            order = 11,
                            desc = "Specify a list of items, one per line, that should automatically be ML'd to the raid's mule.",
                            type = "input",
                            multiline = true,
                            get = function(info) return self.db.global.autoMLItems; end,
                            set = function(info, v) self.db.global.autoMLItems = v; end,
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

function ABGP:GetGlobal(k)
    return self.db.global[k];
end

function ABGP:SetGlobal(k, v)
    self.db.global[k] = v;
end

function ABGP:RefreshOptionsWindow()
    if self.OptionsFrame:IsVisible() then
        AceConfigDialog:Open("ABGP", self.OptionsFrame.obj);
    end
end

function ABGP:OptionsOnHistoryUpdate()
    self:RefreshOptionsWindow();
end

function ABGP:ShowAddTrialWindow()
    local window = AceGUI:Create("ABGP_OpaqueWindow");
    window:SetLayout("Flow");
    window:SetTitle("Add Player");
    self:OpenPopup(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:ClosePopup(widget);
        ABGP:EndWindowManagement(widget);
        AceGUI:Release(widget);
    end);

    local container = AceGUI:Create("SimpleGroup");
    container:SetFullWidth(true);
    container:SetLayout("Table");
    container:SetUserData("table", { columns = { 1.0 }});
    window:AddChild(container);

    local playerContainer = AceGUI:Create("SimpleGroup");
    playerContainer:SetFullWidth(true);
    playerContainer:SetLayout("Table");
    playerContainer:SetUserData("table", { columns = { 1.0, 1.0 }});
    container:AddChild(playerContainer);

    local playerEdit = AceGUI:Create("ABGP_EditBox");
    playerEdit:SetLabel("Player");
    playerEdit:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GUILD, AUTOCOMPLETE_FLAG_NONE);
    playerContainer:AddChild(playerEdit);
    self:AddWidgetTooltip(playerEdit, "Enter the player being added as a trial.");

    local proxyEdit = AceGUI:Create("ABGP_EditBox");
    proxyEdit:SetLabel("Proxy");
    proxyEdit:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GUILD, AUTOCOMPLETE_FLAG_NONE);
    playerContainer:AddChild(proxyEdit);
    self:AddWidgetTooltip(proxyEdit, "If the player is not in the guild, enter the name of the character in the guild that will serve as their proxy.");

    local currentRaidGroup = self:GetPreferredRaidGroup();
    local raidGroups, raidGroupNames = {}, {};
    for i, v in ipairs(ABGP.RaidGroupsSorted) do raidGroups[i] = v; end
    for k, v in pairs(ABGP.RaidGroupNames) do raidGroupNames[k] = v; end
    local groupSelector = AceGUI:Create("Dropdown");
    groupSelector:SetLabel("Raid Group");
    groupSelector:SetList(raidGroupNames, raidGroups);
    groupSelector:SetCallback("OnValueChanged", function(widget, event, value)
        currentRaidGroup = value;
    end);
    groupSelector:SetValue(currentRaidGroup);
    playerContainer:AddChild(groupSelector);
    self:AddWidgetTooltip(groupSelector, "Select the raid group with which the player is trialing.");

    local label = AceGUI:Create("ABGP_Header");
    label:SetFullWidth(true);
    label:SetText("Enter the player being added as a trial.");
    container:AddChild(label);

    local done = AceGUI:Create("Button");
    done:SetWidth(100);
    done:SetText("Done");
    done:SetUserData("cell", { align = "CENTERRIGHT" });
    done:SetCallback("OnClick", function(widget, event)
        local player = playerEdit:GetValue();
        local proxy = proxyEdit:GetValue();
        self:AddTrial(player, currentRaidGroup, proxy);
        window:Hide();
    end);
    container:AddChild(done);

    local function processPlayer()
        done:SetDisabled(true);
        groupSelector:SetDisabled(true);

        local player = playerEdit:GetValue();
        local proxy = proxyEdit:GetValue();
        player = player ~= "" and player or nil;
        proxy = proxy ~= "" and proxy or nil;
        if not player then
            label:SetText("Enter the player being added as a trial.");
            return;
        elseif self:GetGuildInfo(player) then
            -- Standard case: player has guild info
            if proxy then
                label:SetText("Players in the guild shouldn't have a proxy!");
                return true;
            end
        elseif proxy and self:GetGuildInfo(proxy) then
            -- Set the player to the proxy for calculating raid groups.
            player = proxy;
        elseif player or proxy then
            label:SetText("Couldn't find the player/proxy in the guild!");
            return true;
        else
            label:SetText("Enter the player being added as a trial.");
            return true;
        end

        local guildInfo = self:GetGuildInfo(player);
        local rank = guildInfo[2];
        local isTrial = self:IsTrial(rank);
        if not isTrial then
            label:SetText("The player doesn't have the appropriate guild rank!");
            return true;
        end

        local active = self:GetActivePlayer(player);
        if active then
            label:SetText("The player is already active!");
            return true;
        end

        label:SetText("Choose the appropriate raid group.");
        done:SetDisabled(false);
        groupSelector:SetDisabled(false);
    end
    playerEdit:SetCallback("OnValueChanged", processPlayer);
    proxyEdit:SetCallback("OnValueChanged", processPlayer);
    processPlayer();

    local height = container.frame:GetHeight() + 57;
    self:BeginWindowManagement(window, "popup", {
        defaultWidth = 400,
        defaultHeight = height,
    });
end

function ABGP:ShowAddPlayerWindow()
    local width = 400;

    local window = AceGUI:Create("ABGP_OpaqueWindow");
    window:SetWidth(width);
    window:SetLayout("Flow");
    window:SetTitle("Add Player");
    self:OpenPopup(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:ClosePopup(widget);
        ABGP:EndWindowManagement(widget);
        AceGUI:Release(widget);
    end);

    local container = AceGUI:Create("SimpleGroup");
    container:SetFullWidth(true);
    container:SetLayout("Table");
    container:SetUserData("table", { columns = { 1.0 }});
    window:AddChild(container);

    local playerContainer = AceGUI:Create("SimpleGroup");
    playerContainer:SetFullWidth(true);
    playerContainer:SetLayout("Table");
    playerContainer:SetUserData("table", { columns = { 1.0, 1.0 }});
    container:AddChild(playerContainer);

    local playerEdit = AceGUI:Create("ABGP_EditBox");
    playerEdit:SetLabel("Player");
    playerEdit:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GUILD, AUTOCOMPLETE_FLAG_NONE);
    playerContainer:AddChild(playerEdit);
    self:AddWidgetTooltip(playerEdit, "Enter the player being added into the EPGP system.");

    local proxyEdit = AceGUI:Create("ABGP_EditBox");
    proxyEdit:SetLabel("Proxy");
    proxyEdit:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GUILD, AUTOCOMPLETE_FLAG_NONE);
    playerContainer:AddChild(proxyEdit);
    self:AddWidgetTooltip(proxyEdit, "If the player is not in the guild, enter the name of the character in the guild that will serve as their proxy.");

    local dateEdit = AceGUI:Create("ABGP_EditBox");
    dateEdit:SetLabel("Date");
    dateEdit:SetCallback("OnValueChanged", function(widget, event, value)
        value = value:gsub("20(%d%d)", "%1");
        local m, d, y = value:match("^(%d+)/(%d+)/(%d+)$");
        if not m then return true; end

        local now = GetServerTime();
        local addTime = time({ year = 2000 + tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 58 });
        if addTime > now then return true; end
    end);
    dateEdit:SetValue(date("%m/%d/%y", GetServerTime() - 24 * 60 * 60));
    playerContainer:AddChild(dateEdit);
    self:AddWidgetTooltip(dateEdit, "Enter the date of their entry.");

    local playerRank = AceGUI:Create("ABGP_Header");
    playerRank:SetUserData("cell", { align = "BOTTOMLEFT" });
    playerContainer:AddChild(playerRank);

    local label = AceGUI:Create("ABGP_Header");
    label:SetFullWidth(true);
    label:SetText("Enter a player to calculate the below values.");
    container:AddChild(label);

    local epgpContainer = AceGUI:Create("InlineGroup");
    epgpContainer:SetFullWidth(true);
    epgpContainer:SetLayout("Table");
    epgpContainer:SetUserData("table", { columns = { 1.0, 1.0 }});
    container:AddChild(epgpContainer);

    local function checkNumber(widget, event, value)
        if value == nil then return; end
        if value == "" then
            widget:SetValue(nil);
            return;
        end

        value = tonumber(value);
        if type(value) ~= "number" then return true; end
        if value < 0 then return true; end
        widget:SetValue(value);
    end

    local epEdit = AceGUI:Create("ABGP_EditBox");
    epEdit:SetLabel("EP");
    epEdit:SetCallback("OnValueChanged", checkNumber);
    epgpContainer:AddChild(epEdit);
    self:AddWidgetTooltip(epEdit, "Starting EP.");

    local spacer = AceGUI:Create("Label");
    epgpContainer:AddChild(spacer);

    local gpsEdit = AceGUI:Create("ABGP_EditBox");
    gpsEdit:SetLabel("Silver GP");
    gpsEdit:SetCallback("OnValueChanged", checkNumber);
    epgpContainer:AddChild(gpsEdit);
    self:AddWidgetTooltip(gpsEdit, "Starting Silver GP.");

    local gpgEdit = AceGUI:Create("ABGP_EditBox");
    gpgEdit:SetLabel("Gold GP");
    gpgEdit:SetCallback("OnValueChanged", checkNumber);
    epgpContainer:AddChild(gpgEdit);
    self:AddWidgetTooltip(gpgEdit, "Starting Gold GP.");

    local done = AceGUI:Create("Button");
    done:SetWidth(100);
    done:SetText("Done");
    done:SetUserData("cell", { align = "CENTERRIGHT" });
    done:SetCallback("OnClick", function(widget, event)
        local player = playerEdit:GetValue();
        local proxy = proxyEdit:GetValue();
        player = player ~= "" and player or nil;
        proxy = proxy ~= "" and proxy or nil;
        local ep = epEdit:GetValue();
        local gpS = gpsEdit:GetValue();
        local gpG = gpgEdit:GetValue();

        local addDate = dateEdit:GetValue();
        local m, d, y = addDate:match("^(%d+)/(%d+)/(%d+)$");
        local addTime = time({ year = 2000 + tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 58 });

        self:AddActivePlayer(player, proxy, addTime, ep, gpS, gpG);
        window:Hide();
    end);
    container:AddChild(done);

    local function processPlayer()
        done:SetDisabled(true);
        epEdit:SetValue(0);
        gpsEdit:SetValue(0);
        gpgEdit:SetValue(0);
        epEdit:SetDisabled(true);
        gpsEdit:SetDisabled(true);
        gpgEdit:SetDisabled(true);
        playerRank:SetText("");

        local player = playerEdit:GetValue();
        local proxy = proxyEdit:GetValue();
        player = player ~= "" and player or nil;
        proxy = proxy ~= "" and proxy or nil;
        if not player then
            label:SetText("Enter a player to calculate the below values.");
            return;
        elseif self:GetGuildInfo(player) then
            -- Standard case: player has guild info
            if proxy then
                label:SetText("Players in the guild shouldn't have a proxy!");
                return true;
            end
        elseif proxy and self:GetGuildInfo(proxy) then
            -- Set the player to the proxy for calculating raid groups.
            player = proxy;
        elseif player or proxy then
            label:SetText("Couldn't find the player/proxy in the guild!");
            return true;
        else
            label:SetText("Enter a player to calculate the below values.");
            return true;
        end

        local guildInfo = self:GetGuildInfo(player);
        local rank = guildInfo[2];
        local raidGroup = self:GetRaidGroup(rank);
        if not raidGroup then
            label:SetText("The player's guild rank is invalid!");
            return true;
        end

        epEdit:SetDisabled(false);
        gpsEdit:SetDisabled(false);
        gpgEdit:SetDisabled(false);
        playerRank:SetText(rank);
        label:SetText(("Class: %s, Raid Group: %s"):format(guildInfo[5], self.RaidGroupNames[raidGroup]));

        epEdit:SetValue(0);
        gpsEdit:SetValue(0);
        gpgEdit:SetValue(0);
        done:SetDisabled(false);
    end
    playerEdit:SetCallback("OnValueChanged", processPlayer);
    proxyEdit:SetCallback("OnValueChanged", processPlayer);
    processPlayer();

    local height = container.frame:GetHeight() + 57;
    self:BeginWindowManagement(window, "popup", {
        defaultWidth = width,
        minWidth = width,
        maxWidth = width,
        defaultHeight = height,
        minHeight = height,
        maxHeight = height
    });
end

_G.StaticPopupDialogs["ABGP_TRIGGER_DECAY"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Choose the date for the decay (M/D/Y):",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    Validate = function(text)
        text = text:gsub("20(%d%d)", "%1");
        local m, d, y = text:match("^(%d+)/(%d+)/(%d+)$");
        if not m then return false, "Couldn't parse date"; end

        local now = GetServerTime();
        local decayTime = time({ year = 2000 + tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59 });
        if decayTime > now then return false, "Date must be before today"; end

        local history = ABGP:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
        for _, entry in ipairs(history) do
            local entryDate = entry[ABGP.ItemHistoryIndex.DATE];
            if entryDate < decayTime then break; end

            if entry[ABGP.ItemHistoryIndex.TYPE] == ABGP.ItemHistoryType.GPDECAY then
                return false, "A more recent decay already exists";
            end
        end

        return decayTime;
    end,
    Commit = function(decayTime)
        ABGP:HistoryTriggerDecay(decayTime);
    end,
});
