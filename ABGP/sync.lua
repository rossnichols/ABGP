local _G = _G;
local ABGP = _G.ABGP;
local LibLedger = _G.LibStub("LibLedger");

local UnitName = UnitName;
local GetServerTime = GetServerTime;

local controller = {
    GetLedger = function(self)
        return _G.ABGP_Data2.history.data, _G.ABGP_Data2.history.timestamp;
    end,

    GetEntryInfo = function(self, entry)
        local id, timestamp = ABGP:ParseHistoryId(entry[ABGP.ItemHistoryIndex.ID]);
        return id, timestamp;
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

    SendComm = function(self, typ, data, target)
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
        return entries;
    end,

    PrepareIds = function(self, ids, now)
        return ids;
    end,

    RebuildEntries = function(self, entries, now)
        return entries;
    end,

    RebuildIds = function(self, ids, now)
        return ids;
    end,
};

local function ShouldSync()
    return ABGP:Get("syncEnabled") and not ABGP:Get("outsider");
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
