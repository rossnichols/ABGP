local _G = _G;
local ABGP = _G.ABGP;
local LibSerialize = _G.LibStub("LibSerialize");
local AceSerializer = _G.LibStub("AceSerializer-3.0");
local LibDeflate = _G.LibStub("LibDeflate");
local LibCompress = _G.LibStub("LibCompress");
local AddonEncodeTable = LibCompress:GetAddonEncodeTable();

local IsInGroup = IsInGroup;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local GetTime = GetTime;
local GetServerTime = GetServerTime;
local UnitAffectingCombat = UnitAffectingCombat;
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
local delayThreshold = 5;
local monitoringComms = false;
local bufferLength = 30;
local currentSlot = 0;
local ctlQueue = { queueing = false, start = 0, count = 0 };
local commMonitor = {};
local currentEncounter;
local events = {};

function ABGP:GetBroadcastChannel()
    if ABGP:GetDebugOpt("PrivateComms") then return "WHISPER", UnitName("player"); end

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

function ABGP:SetCallback(name, fn)
    events[name] = fn;
end

function ABGP:Fire(name, ...)
    local fn = events[name];
    if fn then fn(self, name, ...); end
end

-- The prefix can be revved to create a backwards-incompatible version.
function ABGP:GetCommPrefix()
    return "ABGP5";
end

-- Highest ID: 22
ABGP.CommTypes = {
    ITEM_REQUEST = { name = "ITEM_REQUEST", id = 1, priority = "INSTANT" },
    -- itemLink: item link string
    -- requestType: string from ABGP.RequestTypes
    -- notes: string or nil
    -- equipped: array of item link strings or nil
    -- selectedItem: item link string

    ITEM_PASS = { name = "ITEM_PASS", id = 2, priority = "INSTANT" },
    -- itemLink: item link string

    ITEM_REQUESTCOUNT = { name = "ITEM_REQUESTCOUNT", id = 3, priority = "ALERT" },
    -- itemLink: item link string
    -- count: number
    -- main: number
    -- off: number

    ITEM_COUNT = { name = "ITEM_COUNT", id = 4, priority = "ALERT" },
    -- itemLink: item link string
    -- count: number

    ITEM_DIST_OPENED = { name = "ITEM_DIST_OPENED", id = 5, priority = "ALERT" },
    -- itemLink: item link string
    -- value: table from ABGP:GetItemValue()
    -- requiresRoll: bool
    -- slots: array of strings
    -- count: number

    ITEM_DIST_CLOSED = { name = "ITEM_DIST_CLOSED", id = 6, priority = "ALERT" },
    -- itemLink: item link string
    -- count: number

    ITEM_AWARDED = { name = "ITEM_AWARDED", id = 7, priority = "ALERT", fireLocally = true },
    -- itemLink: item link string
    -- player: string
    -- cost: number
    -- roll: number
    -- count: number
    -- requestType: string from ABGP.RequestTypes
    -- override: string
    -- count: number
    -- testItem: bool
    -- historyId: string
    -- updateId: string
    -- awarded: number
    -- oldHistoryId: string

    ITEM_TRASHED = { name = "ITEM_TRASHED", id = 8, priority = "ALERT", fireLocally = true },
    -- itemLink: item link string
    -- count: number
    -- testItem: bool

    ITEM_REQUEST_REJECTED = { name = "ITEM_REQUEST_REJECTED", id = 22, priority = "ALERT" },
    -- itemLink: string
    -- reason: string or nil
    -- player: string

    STATE_SYNC = { name = "STATE_SYNC", id = 9, priority = "ALERT" },
    -- token: unique token for the message
    -- itemDataTime: number

    ITEM_ROLLED = { name = "ITEM_ROLLED", id = 10, priority = "ALERT" },
    -- itemLink: item link string
    -- roll: number

    GUILD_NOTES_UPDATED = { name = "GUILD_NOTES_UPDATED", id = 11, priority = "NORMAL" },
    -- no payload

    REQUEST_PRIORITY_SYNC = { name = "REQUEST_PRIORITY_SYNC", id = 12, priority = "NORMAL" },
    -- no payload

    PRIORITY_SYNC = { name = "PRIORITY_SYNC", id = 13, priority = "BULK" },
    -- priorities: table

    BOSS_LOOT = { name = "BOSS_LOOT", id = 14, priority = "ALERT" },
    -- source: string
    -- items: table

    REQUEST_ITEM_DATA_SYNC = { name = "REQUEST_ITEM_DATA_SYNC", id = 15, priority = "NORMAL" },
    -- token: value from STATE_SYNC

    ITEM_DATA_SYNC = { name = "ITEM_DATA_SYNC", id = 16, priority = "BULK" },
    -- itemDataTime: number
    -- itemValues: table

    HISTORY_SYNC = { name = "HISTORY_SYNC", id = 17, priority = "BULK" },
    -- version: from ABGP:GetVersion()
    -- token: unique token for the message
    -- baseline: number
    -- archivedCount: number
    -- now: number
    -- notPrivileged: bool
    -- ids: table OR hash: number

    HISTORY_REPLACE_INITIATION = { name = "HISTORY_REPLACE_INITIATION", id = 18, priority = "NORMAL" },
    -- token: from HISTORY_SYNC

    HISTORY_MERGE = { name = "HISTORY_MERGE", id = 19, priority = "BULK" },
    -- baseline: number
    -- now: number
    -- merge: table
    -- requested: table
    -- now: number
    -- token: from HISTORY_SYNC

    HISTORY_REPLACE = { name = "HISTORY_REPLACE", id = 20, priority = "BULK" },
    -- baseline: number
    -- history: table
    -- requested: bool

    HISTORY_REPLACE_REQUEST = { name = "HISTORY_REPLACE_REQUEST", id = 21, priority = "NORMAL" },
    -- token: from HISTORY_SYNC

    -- NOTE: these aren't versioned and use legacy encoding so they can continue to function across major changes.
    VERSION_REQUEST = { name = "ABGP_VERSION_REQUEST", priority = "NORMAL", legacy = true },
    -- reset: bool or nil
    -- version: from ABGP:GetVersion()
    VERSION_RESPONSE = { name = "ABGP_VERSION_RESPONSE", priority = "NORMAL", legacy = true },
    -- version: from ABGP:GetVersion()
};
local commIdMap = {};
for _, typ in pairs(ABGP.CommTypes) do
    if typ.id then commIdMap[typ.id] = typ.name; end
end

ABGP.InternalEvents = {
    ACTIVE_PLAYERS_REFRESHED = "ACTIVE_PLAYERS_REFRESHED",
    ITEM_UNAWARDED = "ITEM_UNAWARDED",
    ITEM_CLOSED = "ITEM_CLOSED",
    ITEM_REQUESTED = "ITEM_REQUESTED",
    ITEM_PASSED = "ITEM_PASSED",
    ITEM_FAVORITED = "ITEM_FAVORITED",
    LOOT_FRAME_OPENED = "LOOT_FRAME_OPENED",
    LOOT_FRAME_CLOSED = "LOOT_FRAME_CLOSED",
    HISTORY_UPDATED = "HISTORY_UPDATED",
};

function ABGP:CommCallback(sent, total, logInCallback)
    if logInCallback and self:GetDebugOpt("DebugComms") then
        self:LogDebug("COMM-CB: sent=%d total=%d", sent, total);
    end
    if sent == total then
        synchronousCheck = true;
    end
end

function ABGP:Serialize(typ, data, legacy)
    if legacy then
        data.type = typ.name;
        _G.assert(data.version);
        local serialized = AceSerializer:Serialize(data);
        local compressed = LibCompress:Compress(serialized);
        return (AddonEncodeTable:Encode(compressed)), "ABGP";
    else
        local serialized = LibSerialize:Serialize(typ.id, self:GetVersion(), data);
        local compressed = LibDeflate:CompressDeflate(serialized);

        if #compressed > #serialized + 10 then
            self:LogDebug("WARNING: compressing payload for %s increased size from %d to %d!",
                data.type, #serialized, #compressed);
        elseif self:GetDebugOpt("DebugComms") then
            self:LogDebug("Serialized payload %d compressed to %d.", #serialized, #compressed);
        end

        if self:GetDebugOpt() then
            local success, _, _, dataTest = LibSerialize:Deserialize(serialized);
            if not success or type(dataTest) ~= "table" or not self.tCompare(data, dataTest) then
                _G.error("Serialization failed!");
            end
        end

        return (LibDeflate:EncodeForWoWAddonChannel(compressed)), self:GetCommPrefix();
    end
end

function ABGP:Deserialize(payload, legacy)
    if legacy then
        local compressed = AddonEncodeTable:Decode(payload);
        if not compressed then return false; end

        local serialized = LibCompress:Decompress(compressed);
        if not serialized then return false; end

        local typ, version;
        local success, data = AceSerializer:Deserialize(serialized);
        if success then
            typ = data.type;
            version = data.version;
        end
        return success, typ, version, data;
    else
        local compressed = LibDeflate:DecodeForWoWAddonChannel(payload);
        if not compressed then return false; end

        local serialized = LibDeflate:DecompressDeflate(compressed);
        if not serialized then return false; end

        local typ;
        local success, id, version, data = LibSerialize:Deserialize(serialized);
        if success then
            typ = commIdMap[id];
        end
        return success, typ, version, data;
    end
end

function ABGP:SendComm(typ, data, distribution, target)
    local priority = typ.priority;
    local payload, prefix = self:Serialize(typ, data, typ.legacy);

    if distribution == "BROADCAST" then
        distribution, target = self:GetBroadcastChannel();
    end
    if not distribution then return; end

    if priority == "INSTANT" and strlen(payload) > 250 then
        priority = "ALERT";
    end

    local logInCallback = false;
    if self:GetDebugOpt("Verbose") then
        self:LogVerbose("COMM-SEND >>>");
        self:LogVerbose("%s pri=%s dist=%s prefix=%s len=%d",
            typ.name,
            priority,
            target and ("%s:%s"):format(distribution, target) or distribution,
            prefix,
            strlen(payload));
        for k, v in pairs(data) do
            if k ~= "type" then self:LogVerbose("%s: %s", k, tostring(v)); end
        end
        self:LogVerbose("<<< COMM");
    elseif not typ.name:find("VERSION") and self:GetDebugOpt("DebugComms") then
        logInCallback = true;
        self:LogDebug("COMM-SEND: %s pri=%s dist=%s prefix=%s len=%d",
            typ.name,
            priority,
            target and ("%s:%s"):format(distribution, target) or distribution,
            prefix,
            strlen(payload));
    end

    if priority == "INSTANT" then
        -- The \004 prefix is AceComm's "escape" control. Prepend it so that the
        -- payload is properly interpreted when received.
        _G.C_ChatInfo.SendAddonMessage(prefix, "\004" .. payload, distribution, target);
        synchronousCheck = true;
    else
        synchronousCheck = false;
        local time = GetTime();
        local commCallback = function(self, sent, total)
            self:CommCallback(sent, total, logInCallback);
            if priority ~= "BULK" then
                local now = GetTime();
                local delay = now - time;
                if delay > delayThreshold and now - startTime > suppressionThreshold then
                    self:ErrorLogged("COMM", "An addon communication message was delayed by %.2f seconds!", delay);
                    if not alertedSlowComms then
                        alertedSlowComms = true;
                        _G.StaticPopup_Show("ABGP_PROMPT_RELOAD",
                            ("%s: your addon communication is delayed! Consider reloading your UI (and reporting this)."):format(ABGP:ColorizeText("ABGP")));
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
        end
        self:SendCommMessage(prefix, payload, distribution, target, priority, commCallback, self);
    end

    if typ.fireLocally then
        -- self:LogDebug("Firing comm [%s] locally.", typ.name);
        self:Fire(typ.name, data, distribution, UnitName("player"), self:GetVersion());
    end

    return synchronousCheck;
end

function ABGP:OnCommReceived(prefix, payload, distribution, sender)
    local legacy = (prefix == "ABGP");
    local success, typ, version, data = self:Deserialize(payload, legacy);
    if not success or type(data) ~= "table" then
        self:Error("Received an invalid addon comm from %s!", self:ColorizeName(sender));
        return;
    end

    if self:GetDebugOpt("Verbose") then
        self:LogVerbose("COMM-RECV >>>");
        self:LogVerbose("%s dist=%s sender=%s prefix=%s len=%s", typ, distribution, sender, prefix, payload:len());
        for k, v in pairs(data) do
            self:LogVerbose("%s: %s", k, tostring(v));
        end
        self:LogVerbose("<<< COMM");
    elseif sender ~= UnitName("player") and not typ:find("VERSION") and self:GetDebugOpt("DebugComms") then
        self:LogDebug("COMM-RECV: %s dist=%s sender=%s prefix=%s len=%s", typ, distribution, sender, prefix, payload:len());
    end

    if self.CommTypes[typ] and self.CommTypes[typ].fireLocally and sender == UnitName("player") then
        -- self:LogDebug("Received comm [%s], skipping fire (local).", typ);
        return;
    end

    self:Fire(typ, data, distribution, sender, version);
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
                if _G.ChatThrottleLib.bQueueing and now - startTime > suppressionThreshold and UnitAffectingCombat("player") then
                    if not ctlQueue.queueing then
                        local when = currentEncounter and ("during %s"):format(currentEncounter) or "in combat";
                        self:WriteLogged("COMM", "ChatThrottleLib has started queueing %s!", when);
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

function ABGP:CommOnEncounterStart(encounterId, encounterName)
    currentEncounter = encounterName;
end

function ABGP:CommOnEncounterEnd(encounterId, encounterName)
    currentEncounter = nil;
    if not monitoringComms then return; end

    -- When a boss is killed, dump the comm monitor if CTL is currently queuing msgs.
    local ctl = _G.ChatThrottleLib;
    if ctl and ctl.bQueueing then
        self:ErrorLogged("COMM", "Addon comms after %s are delayed!", encounterName);
        self:DumpCommMonitor();
    end
end

function ABGP:CommOnEnteringWorld()
    startTime = GetTime();
end

function ABGP:TestSerialization(input)
    input = input or self:PrepareHistory(_G.ABGP_Data2.history.data);
    -- input = input or _G.ABGP_Data2.p1.itemValues;
    local LibDeflate = _G.LibStub("LibDeflate");

    local serialized = LibSerialize:Serialize(input);
    self:Notify("serialized len: %d", #serialized);
    local compressed = LibDeflate:CompressDeflate(serialized);
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed);
    self:Notify("compressed/encoded lens: %d, %d", #compressed, #encoded);
    self:Notify("compared to legacy of %d", self:Serialize(input, true):len());

    local decompressed = LibDeflate:DecompressDeflate(compressed);
    local success, deserialized = LibSerialize:Deserialize(decompressed);
    self:Notify("deserialization success: %s %s", success and "true" or "false", success and "" or deserialized);

    if success then
        if type(input) == "table" then
            self:Notify("matching: %s", self.tCompare(input, deserialized) and "yes" or "no");
        else
            self:Notify("matching: %s", input == deserialized and "yes" or "no");
        end
    end
end
