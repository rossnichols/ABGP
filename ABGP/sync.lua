local _G = _G;
local ABGP = _G.ABGP;
local LibLedger = _G.LibStub("LibLedger");

local UnitName = UnitName;
local GetServerTime = GetServerTime;
local pairs = pairs;
local table = table;
local type = type;

local controller = {
    GetLedger = function(self)
        return _G.ABGP_Data2.history.data, _G.ABGP_Data2.history.timestamp;
    end,

    GetEntryInfo = function(self, entry)
        local id = entry[ABGP.ItemHistoryIndex.ID];
        local _, entryDate = ABGP:ParseHistoryId(entry[ABGP.ItemHistoryIndex.ID]);
        return id, entryDate;
    end,

    GetVersion = function(self)
        return ABGP:GetCompareVersion();
    end,

    IsSelf = function(self, name)
        return UnitName("player") == name;
    end,

    GetTime = function(self)
        return GetServerTime();
    end,

    SetLedger = function(self, ledger)
        _G.ABGP_Data2.history.data = ledger;

        ABGP:UpdateHistory();
    end,

    SetBaseline = function(self, baseline)
        _G.ABGP_Data2.history.timestamp = baseline;
    end,

    OnEntriesSynced = function(self, entries, source)
        ABGP:UpdateHistory();
    end,

    GetSyncThresholds = function(self)
        return 10 * 24 * 60 * 60, 30 * 24 * 60 * 60;
    end,

    CanWriteEntries = function(self, name)
        if name then
            return ABGP:CanEditOfficerNotes(name);
        else
            return ABGP:CanEditOfficerNotes() and not ABGP:GetDebugOpt("AvoidHistorySend");
        end
    end,

    SendComm = function(self, data, target)
        if target then
            ABGP:SendComm(ABGP.CommTypes.HISTORY_SYNC, data, "WHISPER", target);
        else
            ABGP:SendComm(ABGP.CommTypes.HISTORY_SYNC, data, "GUILD");
        end
    end,

    Log = function(self, fmt, ...)
        ABGP:LogDebug(fmt, ...);
    end,

    PrepareEntries = function(self, entries, now)
        local copy = ABGP.tCopy(entries);
        -- Break down the history ids into their two parts.
        for _, entry in pairs(copy) do
            local player, _, entryDateOrig = ABGP:ParseHistoryId(entry[ABGP.ItemHistoryIndex.ID]);
            entry[ABGP.ItemHistoryIndex.ID] = player;
            entry[0] = entryDateOrig;
        end

        return copy;
    end,

    RebuildEntries = function(self, entries, now)
        -- Undo the changes from PrepareEntries().
        for _, entry in pairs(entries) do
            entry[ABGP.ItemHistoryIndex.ID] = ("%s:%d"):format(entry[ABGP.ItemHistoryIndex.ID], entry[0]);
            entry[0] = nil;
        end

        return entries;
    end,

    PrepareIds = function(self, ids, now)
        local decomposed = {};
        -- Break down the history ids into their two parts.
        -- Store them as an array instead of a map.
        for id in pairs(ids) do
            local player, _, entryDateOrig = ABGP:ParseHistoryId(id);
            table.insert(decomposed, player);
            table.insert(decomposed, entryDateOrig);
        end

        return decomposed;
    end,

    RebuildIds = function(self, ids, now)
        -- Undo the changes from PrepareIds().
        for i = 1, #ids - 1, 2 do
            local id = ("%s:%d"):format(ids[i], ids[i + 1]);
            ids[id] = true;
            ids[i] = nil;
            ids[i + 1] = nil;
        end

        return ids;
    end,
};

local function ShouldSync()
    return not ABGP:Get("outsider");
end

function ABGP:SyncHistory(initial)
    if not ShouldSync() then return; end

    if initial then
        self:HasCompleteHistory(self:GetDebugOpt());
    end

    LibLedger:Sync(controller);
end

function ABGP:SyncOnComm(data, distribution, sender, version)
    if not ShouldSync() then return; end

    LibLedger:HandleComm(controller, data, sender);
end

function ABGP:SyncNewEntries(entries)
    LibLedger:SyncNewEntries(controller, entries);
end

function ABGP:CommitHistory()
    self:UpdateHistory();
    if not self:GetDebugOpt("AvoidHistorySend") then
        _G.ABGP_Data2.history.timestamp = GetServerTime();

        LibLedger:Sync(controller);
    end
end

function ABGP:RebuildHistory()
    LibLedger:SetInvalidLedger(controller);
    LibLedger:Sync(controller);
end

function ABGP:HasValidHistory()
    return LibLedger:HasValidLedger(controller);
end

function ABGP:TestSerialization(input)
    local LibSerialize = _G.LibStub("LibSerialize");
    local AceSerializer = _G.LibStub("AceSerializer-3.0");
    local LibDeflate = _G.LibStub("LibDeflate");
    local LibCompress = _G.LibStub("LibCompress");
    local AddonEncodeTable = LibCompress:GetAddonEncodeTable();

    input = input or controller:PrepareEntries(_G.ABGP_Data2.history.data);
    local LibDeflate = _G.LibStub("LibDeflate");

    local serialized = LibSerialize:Serialize(input);
    self:Notify("serialized len: %d", #serialized);
    local compressed = LibDeflate:CompressDeflate(serialized);
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed);
    self:Notify("compressed/encoded lens: %d, %d", #compressed, #encoded);

    local serializedLegacy = AceSerializer:Serialize(input);
    local compressedLegacy = LibCompress:Compress(serializedLegacy);
    local encodedLegacy = AddonEncodeTable:Encode(compressedLegacy);
    self:Notify("compared to legacy of %d", encodedLegacy:len());

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
