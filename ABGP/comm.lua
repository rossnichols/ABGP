local AceSerializer = LibStub("AceSerializer-3.0");
local LibCompress = LibStub("LibCompress");
local AddonEncodeTable = LibCompress:GetAddonEncodeTable();

local _G = _G;
local ABGP = ABGP;
local IsInGroup = IsInGroup;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local GetTime = GetTime;
local GetServerTime = GetServerTime;
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE;
local pairs = pairs;
local type = type;
local table = table;
local tostring = tostring;
local strlen = strlen;
local ipairs = ipairs;
local mod = mod;

local startTime = GetTime();
local suppressionThreshold = 60;
local alertedSlowComms = false;
local synchronousCheck = false;

local monitoringComms = false;
local bufferLength = 30;
local currentSlot = 0;
local ctlQueue = { queueing = false, start = 0, count = 0 };
local commMonitor = {};

local function GetBroadcastChannel()
    if ABGP:GetDebug("PrivateComms") then return "WHISPER", UnitName("player"); end

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT";
    elseif GetNumGroupMembers() > 0 and IsInRaid() then
        return "RAID";
    elseif IsInGroup() then
        return "PARTY";
    else
        return "WHISPER", UnitName("player");
    end
end

-- The commVersion can be revved to create a backwards-incompatible version.
local commVersion = ":3";
local function CV(str)
    return ("ABGP_%s%s"):format(str, commVersion);
end

ABGP.CommTypes = {
    ITEM_REQUEST = { name = CV("ITEM_REQUEST"), priority = "INSTANT" },
    -- itemLink: item link string
    -- requestType: string from ABGP.RequestTypes
    -- notes: string or nil
    -- equipped: array of item link strings or nil

    ITEM_PASS = { name = CV("ITEM_PASS"), priority = "INSTANT" },
    -- itemLink: item link string

    ITEM_DISTRIBUTION_OPENED = { name = CV("ITEM_DISTRIBUTION_OPENED"), priority = "INSTANT" },
    -- itemLink: item link string
    -- value: table from ABGP:GetItemValue()
    -- requestType: string from ABGP.RequestTypes

    ITEM_DISTRIBUTION_CLOSED = { name = CV("ITEM_DISTRIBUTION_CLOSED"), priority = "INSTANT" },
    -- itemLink: item link string
    -- count: number

    ITEM_DISTRIBUTION_AWARDED = { name = CV("ITEM_DISTRIBUTION_AWARDED"), priority = "ALERT" },
    -- itemLink: item link string
    -- player: string
    -- cost: number
    -- roll: number
    -- count: number
    -- requestType: string from ABGP.RequestTypes
    -- override: string
    -- count: number
    -- testItem: bool
    -- editId: number
    -- oldPlayer: string
    -- oldCost: number

    ITEM_DISTRIBUTION_TRASHED = { name = CV("ITEM_DISTRIBUTION_TRASHED"), priority = "ALERT" },
    -- itemLink: item link string
    -- count: number
    -- testItem: bool

    STATE_SYNC = { name = CV("STATE_SYNC"), priority = "ALERT" },
    -- token: unique token for the message
    -- itemDataTime: number

    ITEM_ROLLED = { name = CV("ITEM_ROLLED"), priority = "ALERT" },
    -- itemLink: item link string
    -- roll: number

    OFFICER_NOTES_UPDATED = { name = CV("OFFICER_NOTES_UPDATED"), priority = "NORMAL" },
    -- no payload

    REQUEST_PRIORITY_SYNC = { name = CV("REQUEST_PRIORITY_SYNC"), priority = "NORMAL" },
    -- no payload

    PRIORITY_SYNC = { name = CV("PRIORITY_SYNC"), priority = "BULK" },
    -- priorities: table

    BOSS_LOOT = { name = CV("BOSS_LOOT"), priority = "ALERT" },
    -- source: string
    -- items: table

    REQUEST_ITEM_DATA_SYNC = { name = CV("REQUEST_ITEM_DATA_SYNC"), priority = "NORMAL" },
    -- token: value from STATE_SYNC

    ITEM_DATA_SYNC = { name = CV("ITEM_DATA_SYNC"), priority = "BULK" },
    -- itemDataTime: number
    -- itemValues: table

    -- NOTE: these aren't versioned so they can continue to function across major changes.
    VERSION_REQUEST = { name = "ABGP_VERSION_REQUEST", priority = "NORMAL" },
    -- reset: bool or nil
    VERSION_RESPONSE = { name = "ABGP_VERSION_RESPONSE", priority = "NORMAL" },
    -- no payload
};

ABGP.InternalEvents = {
    ACTIVE_PLAYERS_REFRESHED = CV("ACTIVE_PLAYERS_REFRESHED"),
    ITEM_DISTRIBUTION_UNAWARDED = CV("ITEM_DISTRIBUTION_UNAWARDED"),
    ITEM_REQUESTED = CV("ITEM_REQUESTED"),
    ITEM_PASSED = CV("ITEM_PASSED"),
    ITEM_FAVORITED = CV("ITEM_FAVORITED"),
};

function ABGP:CommCallback(sent, total, logInCallback)
    if logInCallback and self:GetDebug("DebugComms") then
        self:LogDebug("COMM-CB: sent=%d total=%d", sent, total);
    end
    if sent == total then
        synchronousCheck = true;
    end
end

function ABGP:SendComm(type, data, distribution, target)
    data.type = type.name;

    local priority = data.commPriority or type.priority;
    data.commPriority = nil;

    local serialized = AceSerializer:Serialize(data);
    local compressed = LibCompress:Compress(serialized);
    local payload = AddonEncodeTable:Encode(compressed);

    if distribution == "BROADCAST" then
        distribution, target = GetBroadcastChannel();
    end
    if not distribution then return; end

    if priority == "INSTANT" and strlen(payload) > 250 then
        priority = "ALERT";
    end

    local logInCallback = false;
    if not type.name:find("VERSION") and self:GetDebug("DebugComms") then
        logInCallback = true;
        self:LogDebug("COMM-SEND: %s pri=%s dist=%s len=%d",
            type.name,
            priority,
            target and ("%s:%s"):format(distribution, target) or distribution,
            strlen(payload));
    end

    if priority == "INSTANT" then
        -- The \004 prefix is AceComm's "escape" control. Prepend it so that the
        -- payload is properly interpreted when received.
        _G.C_ChatInfo.SendAddonMessage("ABGP", "\004" .. payload, distribution, target);
        synchronousCheck = true;
    else
        synchronousCheck = false;
        local time = GetTime();
        local commCallback = function(self, sent, total)
            self:CommCallback(sent, total, logInCallback);
            local now = GetTime();
            local delay = now - time;
            if delay > 5 and now - startTime > suppressionThreshold then
                self:ErrorLogged("COMM", "An addon communication message was delayed by %.2f seconds!", delay);
                if not alertedSlowComms then
                    alertedSlowComms = true;
                    _G.StaticPopup_Show("ABGP_SLOW_COMMS");
                end
                if monitoringComms then
                    self:DumpCommMonitor();
                elseif not self:Get("commMonitoringEnabled") and not self:Get("commMonitoringTriggered") then
                    self:Notify("Enabling comms monitoring! You can disable this in the options window.");
                    self:Set("commMonitoringTriggered", true);
                    self:Set("commMonitoringEnabled", true);
                    self:SetupCommMonitor();
                end
            end

            -- for multipart messages, reset the initial time when each callback is received.
            time = now;
        end
        self:SendCommMessage("ABGP", payload, distribution, target, priority, commCallback, self);
    end

    return synchronousCheck;
end

function ABGP:OnCommReceived(prefix, payload, distribution, sender)
    local compressed = AddonEncodeTable:Decode(payload);
    local serialized = LibCompress:Decompress(compressed);
    local _, data = AceSerializer:Deserialize(serialized);

    if self:GetDebug("Verbose") then
        self:LogVerbose("COMM >>>");
        self:LogVerbose("Data from %s via %s:", sender, distribution);
        for k, v in pairs(data) do
            if type(v) == "table" then v = table.concat(v, ", "); end
            self:LogVerbose("%s: %s", k, tostring(v));
        end
        self:LogVerbose("<<< COMM");
    elseif sender ~= UnitName("player") and not data.type:find("VERSION") and self:GetDebug("DebugComms") then
        self:LogDebug("COMM-RECV: %s dist=%s sender=%s", data.type, distribution, sender);
    end

    self:SendMessage(data.type, data, distribution, sender);
end

local function GetSlot()
    local slot = mod(GetServerTime(), bufferLength) + 1;
    while currentSlot ~= slot do
        currentSlot = mod(currentSlot, bufferLength) + 1;

        commMonitor[currentSlot] = commMonitor[currentSlot] or {};
        table.wipe(commMonitor[currentSlot]);
    end

    return slot;
end

function ABGP:SetupCommMonitor()
    if not self:Get("commMonitoringEnabled") then return; end
    if not monitoringComms then
        monitoringComms = true;
        self:SecureHook(_G.C_ChatInfo, "SendAddonMessage", function(prefix, msg, chatType, target)
            local slot = GetSlot();
            commMonitor[slot][prefix] = commMonitor[slot][prefix] or {};
            commMonitor[slot][prefix].count = (commMonitor[slot][prefix].count or 0) + 1;
            commMonitor[slot][prefix].len = (commMonitor[slot][prefix].len or 0) + strlen(prefix) + strlen(msg);
        end);
        if _G.ChatThrottleLib then
            self:SecureHook(_G.ChatThrottleLib, "Enqueue", function(ctl, prioname, pipename, msg)
                local now = GetTime();
                if _G.ChatThrottleLib.bQueueing and now - startTime > suppressionThreshold then
                    if not ctlQueue.queueing then
                        self:WriteLogged("COMM", "ChatThrottleLib has started queueing!");
                        self:DumpCommMonitor();
                        ctlQueue.queueing = true;
                        ctlQueue.start = now;
                        ctlQueue.count = 0;
                    end
                    ctlQueue.count = ctlQueue.count + 1;
                end
            end);
            self:SecureHookScript(_G.ChatThrottleLib.Frame, "OnUpdate", function(frame, delay)
                local now = GetTime();
                if not _G.ChatThrottleLib.bQueueing and now - startTime > suppressionThreshold and ctlQueue.queueing then
                    self:WriteLogged("COMM", "ChatThrottleLib has stopped queueing (duration=%.2fs, msgs=%d).", now - ctlQueue.start, ctlQueue.count);
                    self:DumpCommMonitor();
                    ctlQueue.queueing = false;
                end
            end);
        end

        self:ScheduleRepeatingTimer(GetSlot, bufferLength / 2);
    end
end

function ABGP:DumpCommMonitor(toChat)
    if not monitoringComms then return; end
    GetSlot();

    local logFn = toChat and "NotifyLogged" or "WriteLogged";
    if toChat then
        self:WriteLogged("COMM", "Manually triggered comm dump");
    end

    local totals = {};
    local prefixes = {};
    for i, slot in pairs(commMonitor) do
        for prefix, data in pairs(slot) do
            if not totals[prefix] then
                totals[prefix] = { count = 0, len = 0 };
                table.insert(prefixes, prefix);
            end
            totals[prefix].len = totals[prefix].len + data.len;
            totals[prefix].count = totals[prefix].count + data.count;
        end
    end

    table.sort(prefixes, function(a, b)
        return totals[a].len > totals[b].len;
    end);

    if #prefixes > 0 then
        self[logFn](self, "COMM", " Traffic in the last %d seconds:", bufferLength);
        for i, prefix in ipairs(prefixes) do
            self[logFn](self, "COMM", "  %s: %d bytes over %d msgs", prefix, totals[prefix].len, totals[prefix].count);
        end
    else
        self[logFn](self, "COMM", " No traffic in the last %d seconds.", bufferLength);
    end

    local ctl = _G.ChatThrottleLib;
    if ctl and ctl.bQueueing then
        self[logFn](self, "COMM", " Queued traffic:");
        for prioname, Prio in pairs(ctl.Prio) do
            local ring = Prio.Ring;
            local head = ring.pos;
            local pipe = ring.pos;
            while pipe do
                local name = pipe.name;
                local count = #pipe;
                self[logFn](self, "COMM", "  %s: %d msgs at %s priority", name, count, prioname);
                pipe = pipe.next;
                if pipe == head then pipe = nil; end
            end
        end
    end
end

function ABGP:CommOnBossKilled(bossId, name)
    if not monitoringComms then return; end

    -- When a boss is killed, dump the comm monitor if CTL is currently queuing msgs.
    local ctl = _G.ChatThrottleLib;
    if ctl and ctl.bQueueing then
        self:ErrorLogged("COMM", "Addon comms after defeating %s are delayed!", name);
        self:DumpCommMonitor();
    end
end

StaticPopupDialogs["ABGP_SLOW_COMMS"] = {
    text = ("%s: your addon communication is delayed! Consider reloading your UI (and reporting this)."):format(ABGP:ColorizeText("ABGP")),
    button1 = "Reload",
    button2 = "Close",
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    exclusive = true,
    showAlert = true,
    OnAccept = ReloadUI,
};
