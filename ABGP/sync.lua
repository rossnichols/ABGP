local _G = _G;
local ABGP = _G.ABGP;

local UnitName = UnitName;
local GetServerTime = GetServerTime;
local ipairs = ipairs;
local pairs = pairs;
local table = table;
local next = next;
local bit = bit;
local unpack = unpack;

local requestedHistoryToken;
local requestedHistoryEntries = {};
local replaceRequestToken;
local broadcastToken;
local broadcastEntries = {};
local warnedOutOfDate;
local invalidBaseline = -1;
local syncThreshold = 10 * 24 * 60 * 60;

local function GetHistory()
    return _G.ABGP_Data2.history.data;
end

local function SetHistory(history)
    _G.ABGP_Data2.history.data = history;
end

local function GetBaseline()
    return _G.ABGP_Data2.history.timestamp;
end

local function SetBaseline(baseline)
    _G.ABGP_Data2.history.timestamp = baseline;
end

local function IsPrivileged()
    return ABGP:CanEditOfficerNotes() and not ABGP:GetDebugOpt("AvoidHistorySend");
end

local function SenderIsPrivileged(sender)
    return ABGP:CanEditOfficerNotes(sender);
end

local function MergeHistory(history, merge)
    local mergeCount = 0;
    for _, entry in pairs(merge) do
        table.insert(history, 1, entry);
        mergeCount = mergeCount + 1;
    end

    if mergeCount > 0 then
        table.sort(history, function(a, b)
            local _, aDate = ABGP:ParseHistoryId(a[ABGP.ItemHistoryIndex.ID]);
            local _, bDate = ABGP:ParseHistoryId(b[ABGP.ItemHistoryIndex.ID]);

            return aDate > bDate;
        end);
    end
    return mergeCount;
end

local syncTesting = false;
-- syncTesting = true;
local testUseLocalData = true;
if syncTesting then
    local localIsPrivileged, remoteIsPrivileged;
    local localHistory, remoteHistory, localBaseline, remoteBaseline;

    local privilegeCombinations = {
        { false, false, "Neither is privileged" },
        { false, true, "Remote is privileged" },
        { true, false, "Local is privileged" },
        { true, true, "Both are privileged" },
    };
    local now = GetServerTime();
    local historyCombinations = {
        { "baseline=1 #recent=2 #archived=0", 1, {
            { 1, ("Xanido:%d"):format(now), now, "Xanido", 0, "Item1" },
            { 1, ("Xanido:%d"):format(now - 1), now - 1, "Xanido", 0, "Item2" },
        }},
        { "baseline=1 #recent=2(v2) #archived=0", 1, {
            { 1, ("Xanido:%d"):format(now - 2), now - 2, "Xanido", 0, "Item3" },
            { 1, ("Xanido:%d"):format(now - 3), now - 3, "Xanido", 0, "Item4" },
        }},
        { "baseline=1 #recent=1 #archived=1", 1, {
            { 1, ("Xanido:%d"):format(now), now, "Xanido", 0, "Item1" },
            { 1, "Xanido:0", 0, "Xanido", 0, "Item3" },
        }},
        { "baseline=2 #recent=1 #archived=0", 2, {
            { 1, ("Xanido:%d"):format(now), now, "Xanido", 0, "Item1" },
        }},
        { "baseline=-1 #recent=1 #archived=0", -1, {
            { 1, ("Xanido:%d"):format(now), now, "Xanido", 0, "Item1" },
        }},
    };
    local testCases = {
        -- Both sides have same data, just varying privilege levels
        { 1, 1, 1, "Nothing should happen" }, -- 1
        { 2, 1, 1, "Nothing should happen" }, -- 2
        { 3, 1, 1, "Nothing should happen" }, -- 3
        { 4, 1, 1, "Nothing should happen" }, -- 4

        -- Each side has an entry the other side wants
        { 1, 1, 2, "Nothing should happen" }, -- 5
        { 2, 1, 2, "Local history should gain entry" }, -- 6
        { 3, 1, 2, "Remote history should gain entry" }, --7
        { 4, 1, 2, "Local and remote history should gain entry" }, --8

        -- Remote has the same baseline but an extra archived entry
        { 1, 1, 3, "Nothing should happen" }, -- 9
        { 2, 1, 3, "Local history should be replaced" }, -- 10
        { 3, 1, 3, "Nothing should happen" }, -- 11
        { 4, 1, 3, "Local history should be replaced" }, -- 12

        -- Local has the same baseline but an extra archived entry
        { 1, 3, 1, "Nothing should happen" }, -- 13
        { 2, 3, 1, "Nothing should happen" }, -- 14
        { 3, 3, 1, "Remote history should be replaced" }, -- 15
        { 4, 3, 1, "Remote history should be replaced" }, -- 16

        -- Remote has updated baseline
        { 1, 1, 4, "Nothing should happen" }, -- 17
        { 2, 1, 4, "Local history should be replaced" }, -- 18
        { 3, 1, 4, "Nothing should happen" }, -- 19
        { 4, 1, 4, "Local history should be replaced" }, -- 20

        -- Local has updated baseline
        { 1, 4, 1, "Nothing should happen" }, -- 21
        { 2, 4, 1, "Nothing should happen" }, -- 22
        { 3, 4, 1, "Remote history should be replaced" }, -- 23
        { 4, 4, 1, "Remote history should be replaced" }, -- 24

        -- Remote has invalid baseline
        { 1, 1, 5, "Nothing should happen" }, -- 25
        { 2, 1, 5, "Nothing should happen" }, -- 26
        { 3, 1, 5, "Remote history should be replaced" }, -- 27
        { 4, 1, 5, "Remote history should be replaced" }, -- 28

        -- Local has invalid baseline
        { 1, 5, 1, "Nothing should happen" }, -- 29
        { 2, 5, 1, "Local history should be replaced" }, --30
        { 3, 5, 1, "Nothing should happen" }, --31
        { 4, 5, 1, "Local history should be replaced" }, -- 32
    };

    function ABGP:RunHistorySyncTest(index)
        local testCase = testCases[index];
        local privIndex, localIndex, remoteIndex, outcome = unpack(testCase);
        self:Notify("|cff00ff00SYNCTEST|r: Expected outcome: %s", outcome);

        self:Notify("|cff00ff00SYNCTEST|r: %s", privilegeCombinations[privIndex][3]);
        localIsPrivileged = privilegeCombinations[privIndex][1];
        remoteIsPrivileged = privilegeCombinations[privIndex][2];

        self:Notify("|cff00ff00SYNCTEST|r: Local history: %s", historyCombinations[localIndex][1]);
        self:Notify("|cff00ff00SYNCTEST|r: Remote history: %s", historyCombinations[remoteIndex][1]);
        localBaseline = historyCombinations[localIndex][2];
        localHistory = self.tCopy(historyCombinations[localIndex][3]);
        remoteBaseline = historyCombinations[remoteIndex][2];
        remoteHistory = self.tCopy(historyCombinations[remoteIndex][3]);

        self:ClearSyncWarnings();
        self:SyncHistory();
    end

    GetHistory = function()
        return testUseLocalData and localHistory or remoteHistory;
    end

    SetHistory = function(history)
        if testUseLocalData then
            ABGP:Notify("|cff00ff00SYNCTEST|r: Replacing local history");
            localHistory = history;
        else
            ABGP:Notify("|cff00ff00SYNCTEST|r: Replacing remote history");
            remoteHistory = history;
        end
    end

    GetBaseline = function()
        return testUseLocalData and localBaseline or remoteBaseline;
    end

    SetBaseline = function(baseline)
        if testUseLocalData then
            ABGP:Notify("|cff00ff00SYNCTEST|r: Setting local baseline to %d", baseline);
            localBaseline = baseline;
        else
            ABGP:Notify("|cff00ff00SYNCTEST|r: Setting remote baseline to %d", baseline);
            remoteBaseline = baseline;
        end
    end

    IsPrivileged = function()
        if testUseLocalData then
            return localIsPrivileged;
        else
            return remoteIsPrivileged;
        end
    end

    SenderIsPrivileged = function(sender)
        if testUseLocalData then
            return remoteIsPrivileged;
        else
            return localIsPrivileged;
        end
    end

    local OldMergeHistory = MergeHistory;
    MergeHistory = function(history, merge)
        local count = OldMergeHistory(history, merge);
        ABGP:Notify("|cff00ff00SYNCTEST|r: Adding %d entries to %s history", count, testUseLocalData and "local" or "remote");
        return count;
    end
end

local function Hash(value)
    -- An implementation of the djb2 hash algorithm.
    -- See http://www.cs.yorku.ca/~oz/hash.html.

    local h = 5381;
    for i = 1, #value do
        h = bit.band((33 * h + value:byte(i)), 4294967295);
    end
    return h;
end

function ABGP:BuildSyncHashData(gpHistory, now)
    local hash = 0;
    local syncCount = 0;

    local baseline = GetBaseline();
    if baseline == invalidBaseline then return hash, syncCount; end

    for _, entry in ipairs(gpHistory) do
        local id = entry[ABGP.ItemHistoryIndex.ID];
        local _, date = ABGP:ParseHistoryId(id);
        if now - date > syncThreshold then break; end

        hash = bit.bxor(hash, Hash(id));
        syncCount = syncCount + 1;
    end

    return hash, syncCount;
end

function ABGP:TriggerInitialSync()
    if not syncTesting then
        -- Print out discrepancies if debug is enabled.
        self:HasCompleteHistory(self:GetDebugOpt());
        self:HistoryTriggerSync();
    end
end

function ABGP:ClearSyncWarnings()
    warnedOutOfDate = false;
end

function ABGP:HistoryTriggerRebuild()
    self:ClearSyncWarnings();
    SetBaseline(invalidBaseline);
    self:HistoryTriggerSync();
end

function ABGP:HistoryTriggerSync()
    if self:Get("outsider") or not self:Get("syncEnabled") then return; end

    self:SyncHistory();
end

function ABGP:SyncHistory(target, token, now, remote)
    if syncTesting then testUseLocalData = not remote; end
    local privileged = IsPrivileged();
    local now = now or GetServerTime();

    local gpHistory = GetHistory();
    local baseline = GetBaseline();
    local canSendHistory = privileged and baseline ~= invalidBaseline;
    local commData = {
        token = token or GetServerTime(),
        baseline = baseline,
        archivedCount = 0,
        now = now,
        notPrivileged = (not privileged) or nil,
        remote = remote or nil, -- for testing
    };

    local syncCount = 0;
    if canSendHistory then
        commData.ids = {};
        for _, entry in ipairs(gpHistory) do
            local id = entry[self.ItemHistoryIndex.ID];
            local _, date = self:ParseHistoryId(id);
            if now - date > syncThreshold then break; end

            commData.ids[id] = true;
            syncCount = syncCount + 1;
        end
        commData.ids = self:PrepareIds(commData.ids, now);
    else
        commData.hash, syncCount = self:BuildSyncHashData(gpHistory, now);
    end

    commData.archivedCount = #gpHistory - syncCount;
    local prepared = self:PrepareSyncData(commData);
    if target then
        self:LogDebug("Sending history sync to %s: %d synced (ids), %d archived",
            self:ColorizeName(target), syncCount, commData.archivedCount);
        self:SendComm(self.CommTypes.HISTORY_SYNC, prepared, "WHISPER", target);
    else
        self:LogDebug("Sending history sync: %d synced (%s), %d archived",
            syncCount, commData.hash and "hash" or "ids", commData.archivedCount);

        broadcastToken = commData.token;
        table.wipe(broadcastEntries);
        if syncTesting then
            self:SendComm(self.CommTypes.HISTORY_SYNC, prepared, "WHISPER", UnitName("player"));
        else
            self:SendComm(self.CommTypes.HISTORY_SYNC, prepared, "GUILD");
        end
    end
end

function ABGP:HistoryOnSync(data, distribution, sender, version)
    if self:GetCompareVersion() ~= version then return; end
    self:RebuildSyncData(data);
    if syncTesting then testUseLocalData = data.remote; end
    if self:Get("outsider") or not self:Get("syncEnabled") then return; end
    if sender == UnitName("player") and not syncTesting then return; end

    if data.token ~= requestedHistoryToken then
        table.wipe(requestedHistoryEntries);
        requestedHistoryToken = data.token;
    end

    local senderIsPrivileged = SenderIsPrivileged(sender) and not data.notPrivileged;
    local history = GetHistory();
    local baseline = GetBaseline();
    local canSendHistory = IsPrivileged() and baseline ~= invalidBaseline;
    local now = data.now;

    -- Compute the archivedCount and hash (if necessary).
    local hash, syncCount = 0, 0;
    if data.hash and canSendHistory then
        hash, syncCount = self:BuildSyncHashData(history, now);
    else
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            local _, date = self:ParseHistoryId(id);
            if now - date > syncThreshold then break; end

            syncCount = syncCount + 1;
        end
    end
    local archivedCount = #history - syncCount;

    -- First evaluate the baseline and archivedCount to see if the data is out of date.
    -- We can only initiate history replacements if privileged, and we'll only accept
    -- possible history replacements from privileged senders.
    if canSendHistory then
        if data.baseline < baseline then
            -- The sender has an older baseline. They need a history replacement.
            self:LogDebug("Sending history replace init to %s (old baseline)",
                self:ColorizeName(sender));
            self:SendComm(self.CommTypes.HISTORY_REPLACE_INITIATION, {
                token = data.token,
                remote = not data.remote, -- for testing
            }, "WHISPER", sender);
        elseif data.baseline == baseline and data.archivedCount < archivedCount then
            -- The sender has fewer archived entries than us. They need a history replacement.
            self:LogDebug("Sending history replace init to %s (fewer archived)",
                self:ColorizeName(sender));
            self:SendComm(self.CommTypes.HISTORY_REPLACE_INITIATION, {
                token = data.token,
                remote = not data.remote, -- for testing
            }, "WHISPER", sender);
        end
    end

    if senderIsPrivileged then
        if data.baseline > baseline then
            -- The sender has a newer baseline. We need a history replacement.
            SetBaseline(invalidBaseline);
            self:LogDebug("Updated baseline found from %s",
                self:ColorizeName(sender));
            self:SendComm(ABGP.CommTypes.HISTORY_REPLACE_REQUEST, {
                token = data.token,
                remote = not data.remote, -- for testing
            }, "WHISPER", sender);
        elseif data.baseline == baseline and data.archivedCount > archivedCount then
            -- The sender has more archived entries than us. We need a history replacement.
            SetBaseline(invalidBaseline);
            self:LogDebug("More archived entries found from %s",
                self:ColorizeName(sender));
            self:SendComm(ABGP.CommTypes.HISTORY_REPLACE_REQUEST, {
                token = data.token,
                remote = not data.remote, -- for testing
            }, "WHISPER", sender);
        end
    end

    -- A deeper sync check should only occur if the baselines and archivedCounts match.
    local checkRecent = data.baseline == baseline and data.archivedCount == archivedCount;
    if not checkRecent then return; end

    if data.hash and canSendHistory then
        -- The sender sent a hash of their recent entries. If our hash is different,
        -- we'll deliver them a sync and they can request whatever they need.
        if data.hash ~= hash then
            self:LogVerbose("Mismatched hash from %s, %s vs. %s, now=%d",
                self:ColorizeName(sender), data.hash, hash, now);
            self:SyncHistory(sender, data.token, now, not data.remote);
        end
    elseif data.ids and senderIsPrivileged then
        -- The sender sent ids. We'll go through them looking for entries we need,
        -- and entries to send if we're allowed to do so.
        self:RebuildIds(data.ids, now);
        local merge = {};
        local sendCount, requestCount = 0, 0;
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            local _, date = self:ParseHistoryId(id);
            if now - date > syncThreshold then break; end

            if data.ids[id] then
                -- We both have this entry.
                data.ids[id] = nil;
            elseif canSendHistory then
                -- Sender doesn't have this entry.
                merge[id] = entry;
                sendCount = sendCount + 1;
            end
        end

        -- At this point, anything left in data.ids represents entries
        -- the sender has but we don't. Request those if they exist,
        -- and send any we have they're missing. Remove ones we've
        -- already requested for this token.
        for id in pairs(data.ids) do
            if requestedHistoryEntries[id] then
                -- We already requested this entry from someone.
                data.ids[id] = nil;
            else
                -- We need to request this id.
                requestedHistoryEntries[id] = true;
                requestCount = requestCount + 1;
            end
        end
        if sendCount > 0 or requestCount > 0 then
            if sendCount > 0 then
                self:LogDebug("Sending %d history entries to %s",
                    sendCount, self:ColorizeName(sender));
            end
            if requestCount > 0 then
                self:LogDebug("Requesting %d history entries from %s",
                    requestCount, self:ColorizeName(sender));
            end
            self:SendComm(self.CommTypes.HISTORY_MERGE, {
                baseline = baseline,
                merge = self:PrepareHistory(merge),
                requested = self:PrepareIds(data.ids, now),
                now = now,
                token = data.token,
                remote = not data.remote, -- for testing
            }, "WHISPER", sender);
        end
    end
end

function ABGP:HistoryOnReplaceInit(data, distribution, sender, version)
    if self:GetCompareVersion() ~= version then return; end
    if syncTesting then testUseLocalData = data.remote; end
    if not SenderIsPrivileged(sender) then return; end

    -- The sender has determined our history is out of date and wants to give us theirs.
    -- At this point our history should not be considered as valid for sending to others.
    SetBaseline(invalidBaseline);

    self:LogDebug("History replace init received from %s",
        self:ColorizeName(sender));

    if not warnedOutOfDate then
        warnedOutOfDate = true;
        _G.StaticPopup_Show("ABGP_HISTORY_OUT_OF_DATE", ABGP:ColorizeName(sender), nil, {
            sender = sender,
            remote = data.remote, -- for testing
        });
    end
end

function ABGP:HistoryOnReplaceRequest(data, distribution, sender, version)
    if self:GetCompareVersion() ~= version then return; end
    if syncTesting then testUseLocalData = data.remote; end
    if self:GetDebugOpt("AvoidHistorySend") then return; end

    -- The sender is asking for our entire history.
    if data.token then
        -- The sender is asking in response to our own sync. Send to GUILD,
        -- so that anyone else who needs this baseline can get it.
        if replaceRequestToken == data.token then return; end
        replaceRequestToken = data.token;

        self:LogDebug("Broadcasting history to guild");
        if syncTesting then
            self:SendComm(self.CommTypes.HISTORY_REPLACE, {
                baseline = GetBaseline(),
                history = self:PrepareHistory(GetHistory()),
                remote = not data.remote, -- for testing
            }, "WHISPER", UnitName("player"));
        else
            self:SendComm(self.CommTypes.HISTORY_REPLACE, {
                baseline = GetBaseline(),
                history = self:PrepareHistory(GetHistory()),
                remote = not data.remote, -- for testing
            }, "GUILD");
        end
    else
        -- The sender is asking in response to our initiation, which was
        -- triggered by their sync. Send to them via WHISPER.
        self:LogDebug("Sending history to %s",
            self:ColorizeName(sender));
        self:SendComm(self.CommTypes.HISTORY_REPLACE, {
            baseline = GetBaseline(),
            history = self:PrepareHistory(GetHistory()),
            requested = true,
            remote = not data.remote, -- for testing
        }, "WHISPER", sender);
    end
end

local function ApplyHistoryReplacement(sender, baseline, history)
    ABGP:RebuildHistory(history);
    SetBaseline(baseline);
    SetHistory(history);
    ABGP:Fire(ABGP.InternalEvents.HISTORY_UPDATED);

    ABGP:Notify("Received complete history from %s! Breakdown: %s.",
        ABGP:ColorizeName(sender), ABGP:BreakdownHistory(history));
    local upToDate = ABGP:HasCompleteHistory(ABGP:GetDebugOpt());
    if upToDate then
        ABGP:Notify("You're now up to date!");
    end
end

function ABGP:HistoryOnReplace(data, distribution, sender, version)
    if self:GetCompareVersion() ~= version then return; end
    if syncTesting then testUseLocalData = data.remote; end
    if not SenderIsPrivileged(sender) then return; end
    if self:Get("outsider") or not self:Get("syncEnabled") then return; end
    if sender == UnitName("player") and not syncTesting then return; end

    -- Only accept newer baselines.
    local baseline = GetBaseline();
    if data.baseline <= baseline then return; end

    if data.requested then
        -- We already requested this one explicitly, so we can just directly apply it.
        ApplyHistoryReplacement(sender, data.baseline, data.history);
    else
        -- Not explicit - ask before applying. Our baseline should be invalid now, though,
        -- since an updated history has been discovered.
        SetBaseline(invalidBaseline);
        _G.StaticPopup_Show("ABGP_UPDATED_HISTORY", ABGP:ColorizeName(sender), nil, {
            sender = sender,
            baseline = data.baseline,
            history = data.history,
            remote = data.remote, -- for testing
        });
    end
end

local function RequestFullHistory(data)
    -- We're asking the sender for their full history.

    ABGP:SendComm(ABGP.CommTypes.HISTORY_REPLACE_REQUEST, {
        remote = not data.remote, -- for testing
    }, "WHISPER", data.sender);
    ABGP:Notify("Requesting full item history from %s! This could take a little while.",
        ABGP:ColorizeName(data.sender));
end

function ABGP:HistoryOnMerge(data, distribution, sender, version)
    if self:GetCompareVersion() ~= version then return; end
    if syncTesting then testUseLocalData = data.remote; end
    local baseline = GetBaseline();
    if data.baseline ~= baseline then return; end

    local canSendHistory = IsPrivileged() and baseline ~= invalidBaseline;
    local history = GetHistory();
    local now = data.now;

    if data.requested and next(data.requested) and canSendHistory then
        -- The sender is requesting history entries.
        self:RebuildIds(data.requested, now);
        local merge = {};
        local sendCount = 0;
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            if data.requested[id] then
                -- Sender wants this entry.
                merge[id] = entry;
                sendCount = sendCount + 1;
            end
        end
        if sendCount > 0 then
            if data.token == broadcastToken then
                -- The sender is requesting entries due to our own sync broadcast.
                -- Since there may be multiple people that all need these entries,
                -- broadcast them instead of directly sending them. Keep track of
                -- the broadcasted entries so we only send them once.
                local broadcast = broadcastEntries;
                for id in pairs(merge) do
                    if broadcast[id] then
                        merge[id] = nil;
                        sendCount = sendCount - 1;
                    end
                    broadcast[id] = true;
                end

                if sendCount > 0 then
                    self:LogDebug("Sending %d history entries", sendCount);
                    if syncTesting then
                        self:SendComm(self.CommTypes.HISTORY_MERGE, {
                            baseline = baseline,
                            merge = self:PrepareHistory(merge),
                            now = now,
                            token = data.token,
                            remote = not data.remote, -- for testing
                        }, "WHISPER", UnitName("player"));
                    else
                        self:SendComm(self.CommTypes.HISTORY_MERGE, {
                            baseline = baseline,
                            merge = self:PrepareHistory(merge),
                            now = now,
                            token = data.token,
                            remote = not data.remote, -- for testing
                        }, "GUILD");
                    end
                end
            else
                self:LogDebug("Sending %d history entries to %s",
                    sendCount, self:ColorizeName(sender));
                self:SendComm(self.CommTypes.HISTORY_MERGE, {
                    baseline = baseline,
                    merge = self:PrepareHistory(merge),
                    now = now,
                    token = data.token,
                    remote = not data.remote, -- for testing
                }, "WHISPER", sender);
            end
        end
    end

    if data.merge and next(data.merge) and SenderIsPrivileged(sender) then
        -- The sender is sharing entries. First remove the ones we already have.
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            data.merge[id] = nil;
        end

        -- At this point, data.merge contains entries we don't have.
        if next(data.merge) then
            self:RebuildHistory(data.merge);
            local mergeCount = MergeHistory(history, data.merge);
            if mergeCount > 0 then
                self:Fire(self.InternalEvents.HISTORY_UPDATED);

                if self:Get("syncVerbose") then
                    self:Notify("Received %d item history entries from %s! Breakdown: %s.",
                        mergeCount, self:ColorizeName(sender), self:BreakdownHistory(data.merge));
                    local upToDate = self:HasCompleteHistory(self:GetDebugOpt());
                    if upToDate then
                        self:Notify("You're now up to date!");
                    end
                end
            end
        end
    end
end

function ABGP:HasValidBaseline()
    return _G.ABGP_Data2.history.timestamp ~= invalidBaseline;
end

function ABGP:BreakdownHistory(history)
    local types = {};
    for _, entry in pairs(history) do
        types[entry[self.ItemHistoryIndex.TYPE]] = (types[entry[self.ItemHistoryIndex.TYPE]] or 0) + 1;
    end

    local typesSorted = {
        self.ItemHistoryType.ITEM,
        self.ItemHistoryType.BONUS,
        self.ItemHistoryType.DECAY,
        self.ItemHistoryType.DELETE,
        self.ItemHistoryType.RESET,
    };

    local typeNames = {
        [self.ItemHistoryType.ITEM] = "item award(s)",
        [self.ItemHistoryType.BONUS] = "gp award(s)",
        [self.ItemHistoryType.DECAY] = "decay trigger(s)",
        [self.ItemHistoryType.DELETE] = "deletion(s)",
        [self.ItemHistoryType.RESET] = "reset(s)",
    };

    local out = {};
    for _, entryType in ipairs(typesSorted) do
        if types[entryType] then
            table.insert(out, ("%d %s"):format(types[entryType], typeNames[entryType]));
        end
    end
    return table.concat(out, ", ");
end

function ABGP:CommitHistory()
    self:Fire(self.InternalEvents.HISTORY_UPDATED);
    if not self:GetDebugOpt("AvoidHistorySend") then
        _G.ABGP_Data2.history.timestamp = GetServerTime();

        -- Since this baseline is new for everyone, send it out now.
        self:SendComm(self.CommTypes.HISTORY_REPLACE, {
            baseline = _G.ABGP_Data2.history.timestamp,
            history = self:PrepareHistory(_G.ABGP_Data2.history.data),
        }, "GUILD");
    end
end


local syncDataMap = {
    "token",
    "baseline",
    "archivedCount",
    "now",
    "notPrivileged",
    "remote",
    "ids",
    "hash",
};
local syncDataMapReversed = {};
for i, v in ipairs(syncDataMap) do syncDataMapReversed[v] = i; end

function ABGP:PrepareSyncData(data)
    -- Convert the key/value pairs to index/value pairs.
    -- Only convert the keys in the above table.
    local prepared = {};
    for k, v in pairs(data) do
        if syncDataMapReversed[k] then
            prepared[syncDataMapReversed[k]] = v;
        else
            prepared[k] = v;
        end
    end

    prepared[syncDataMapReversed.token] = prepared[syncDataMapReversed.now] - prepared[syncDataMapReversed.token];
    prepared[syncDataMapReversed.baseline] = prepared[syncDataMapReversed.now] - prepared[syncDataMapReversed.baseline];

    return prepared;
end

function ABGP:RebuildSyncData(data)
    -- Undo the changes from PrepareSyncData().
    for i in ipairs(syncDataMap) do
        if data[i] ~= nil then
            data[syncDataMap[i]] = data[i];
            data[i] = nil;
        end
    end

    data.token = data.now - data.token;
    data.baseline = data.now - data.baseline;
end

function ABGP:PrepareHistory(history)
    local copy = self.tCopy(history);
    -- Break down the history ids into their two parts.
    -- Store the player in that slot, and the difference
    -- between the date and applied date in a new key.
    -- Performing these changes helps out with serialization,
    -- which favors smaller numbers and repeated strings.
    for _, entry in pairs(copy) do
        local player, entryDate = self:ParseHistoryId(entry[self.ItemHistoryIndex.ID]);
        entry[self.ItemHistoryIndex.ID] = player;
        entry[0] = entryDate - entry[self.ItemHistoryIndex.DATE];
    end

    return copy;
end

function ABGP:RebuildHistory(history)
    -- Undo the changes from PrepareHistory().
    for _, entry in pairs(history) do
        local entryDate = entry[self.ItemHistoryIndex.DATE] + entry[0];
        entry[self.ItemHistoryIndex.ID] = ("%s:%d"):format(entry[self.ItemHistoryIndex.ID], entryDate);
        entry[0] = nil;
    end
end

function ABGP:PrepareIds(ids, now)
    local decomposed = {};
    -- Break down the history ids into their two parts.
    -- Store them as an array instead of a map, and store
    -- the date as its delta from `now`.
    for id in pairs(ids) do
        local player, entryDate = self:ParseHistoryId(id);
        table.insert(decomposed, player);
        table.insert(decomposed, now - entryDate);
    end

    return decomposed;
end

function ABGP:RebuildIds(ids, now)
    -- Undo the changes from PrepareIds().
    for i = 1, #ids - 1, 2 do
        local id = ("%s:%d"):format(ids[i], now - ids[i + 1]);
        ids[id] = true;
        ids[i] = nil;
        ids[i + 1] = nil;
    end
end

StaticPopupDialogs["ABGP_HISTORY_OUT_OF_DATE"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    exclusive = false,
    multiple = true,
    text = "Your history is out of date! Sync from %s?",
    button1 = "Sync",
    button2 = "Cancel",
    OnAccept = function(self, data)
        RequestFullHistory(data);
    end,
});

StaticPopupDialogs["ABGP_UPDATED_HISTORY"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    exclusive = false,
    multiple = true,
    text = "Updated history has been discovered from %s! Apply it?",
    button1 = "Apply",
    button2 = "Cancel",
    OnAccept = function(self, data)
        ApplyHistoryReplacement(data.sender, data.baseline, data.history);
    end,
});
