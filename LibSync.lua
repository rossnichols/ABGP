-- controller:
--  GetHistory(syncId): table
--  GetBaseline(syncId): number
--  GetEntryInfo(entry): id, entryDate

--  SetHistory(syncId, history): nil
--  SetBaseline(syncId, baseline): nil
--  AddHistory(syncId, added): nil
--  PromptSetSetHistory(syncId, history, baseline, sender): nil

--  PrepareHistoryMap(history): table
--  PrepareHistoryList(history): table
--  PrepareIds(ids, now): table
--  RebuildHistoryMap(history): table
--  RebuildHistoryList(history): table
--  RebuildIds(ids, now): table

--  GetSyncThreshold(): number
--  GetWorkingTable(syncId): table
--  IsProducer(player?): boolean
--  SendComm(typ, data, target?): nil
--  WarnOutOfDate(syncId, sender): nil

local LibHistorySync = {}

local GetServerTime = GetServerTime or os.time
local pairs = pairs
local ipairs = ipairs
local next = next
local table = table
local math = math


function LibHistorySync:Sync(controller, syncId)
    self:_SyncWorker(controller, syncId, math.random(), GetServerTime(), nil)
end

function LibHistorySync:RequestHistory(controller, syncId, target)
    -- We're asking the target for their full history.

    self:_SendComm("HISTORY_REPLACE_REQUEST", {
        syncId = syncId
    }, target)
end

function LibHistorySync:ConfirmSetHistory(controller, syncId, history, baseline)
    controller:SetHistory(syncId, history)
    controller:SetBaseline(syncId, baseline)
end

function LibHistorySync:HandleComm(controller, typ, data, sender)
    self["_" .. typ](self, controller, data, sender)
end

function LibHistorySync:GetInvalidBaseline()
    return self._invalidBaseline
end

local function Hash(value)
    -- An implementation of the djb2 hash algorithm.
    -- See http://www.cs.yorku.ca/~oz/hash.html.

    local h = 5381
    for i = 1, #value do
        h = bit.band((33 * h + value:byte(i)), 4294967295)
    end
    return h
end

function LibHistorySync:_SyncWorker(controller, syncId, token, now, target)
    local history = controller:GetHistory(syncId)
    local baseline = controller:GetBaseline(syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    local commData = {
        syncId = syncId,
        token = token,
        baseline = baseline,
        now = now,
        isProducer = isProducer,
    }

    -- Producers send a sync with a table of all their entry ids within the sync threshold.
    -- Consumers send a hash of those ids instead, to minimize the size of the sync comms
    -- in the common state of being fully caught up. We'll also send an "archived count",
    -- which is the number of entries older than the sync threshold.
    local syncCount = 0
    if isProducer then
        local ids = {}
        local syncThreshold = controller:GetSyncThreshold()
        for _, entry in ipairs(history) do
            local id, entryDate = controller:GetEntryInfo(entry)
            if now - entryDate > syncThreshold then break end

            ids[id] = true
            syncCount = syncCount + 1
        end
        commData.ids = controller:PrepareIds(ids, now)
    else
        commData.hash, syncCount = self:_BuildSyncHashData(controller, history, baseline, now)
    end
    commData.archivedCount = #history - syncCount
    self:_SendComm("HISTORY_SYNC", prepared, target)
end

function LibHistorySync:_BuildSyncHashData(controller, history, baseline, now)
    local recentHash = 0
    local archivedHash = 0
    local syncThreshold = controller:GetSyncThreshold()
    local ids = {}

    if baseline == self._invalidBaseline then return recentHash, archivedHash end

    for _, entry in ipairs(history) do
        local id, entryDate = controller:GetEntryInfo(entry)
        if now - entryDate > syncThreshold then
            archivedHash = bit.bxor(archivedHash, Hash(id))
        else
            recentHash = bit.bxor(recentHash, Hash(id))
        end
    end

    return recentHash, archivedHash
end

function LibHistorySync:_HISTORY_SYNC(controller, data, sender)
    local history = controller:GetHistory(syncId)
    local baseline = controller:GetBaseline(syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    local senderIsProducer = data.isProducer and controller:IsProducer(sender)
    local syncThreshold = controller:GetSyncThreshold()
    local now = data.now

    -- If we sent a hash-based sync, producers may send us their own syncs
    -- if our hash doesn't match. To make sure we don't ask all of them for
    -- the same data, keep track of the entries we end up requesting as a
    -- result of this sync's token.
    local wt = controller:GetWorkingTable(data.syncId)
    wt.requestedHistory = wt.requestedHistory or {}
    if data.token ~= wt.requestedToken then
        table.wipe(wt.requestedHistory)
        wt.requestedToken = data.token
    end

    -- Compute the archivedCount and hash (if necessary).
    local hash, syncCount = 0, 0
    if data.hash and isProducer then
        hash, syncCount = self:_BuildSyncHashData(controller, history, baseline, now)
    else
        for _, entry in ipairs(history) do
            local id, entryDate = controller:GetEntryInfo(entry)
            if now - entryDate > syncThreshold then break end

            syncCount = syncCount + 1
        end
    end
    local archivedCount = #history - syncCount

    -- First evaluate the baseline and archivedCount to see if the sender's history is
    -- out of date. We can only initiate history replacements as producers.
    if isProducer then
        local senderNeedsReplacement = false
        if data.baseline < baseline then
            -- The sender has an older baseline. They need a replacement.
            senderNeedsReplacement = true
        elseif data.baseline == baseline and data.archivedCount < archivedCount then
            -- The sender has fewer archived entries than us. They need a replacement.
            senderNeedsReplacement = true
        end

        if senderNeedsReplacement then
            self:_SendComm("HISTORY_REPLACE_INITIATION", {
                syncId = data.syncId,
                token = data.token,
            }, sender)
        end
    end

    -- If the sender is a producer, evaluate the baseline and archivedCount to see
    -- if our own history is out of date. , We'll only accept possible history replacements
    -- from producers.
    if senderIsProducer then
        local needReplacement = false
        if data.baseline > baseline then
            -- The sender has a newer baseline. We need a replacement.
            needReplacement = true
        elseif data.baseline == baseline and data.archivedCount > archivedCount then
            -- The sender has more archived entries than us. We need a replacement.
            needReplacement = true
        end

        if needReplacement then
            controller:SetBaseline(data.syncId, self._invalidBaseline)
            self:_SendComm("HISTORY_REPLACE_REQUEST", {
                syncId = data.syncId,
                token = data.token,
            }, sender)
        end
    end

    -- A deeper sync check should only occur if the baselines and archivedCounts match.
    if data.baseline ~= baseline or data.archivedCount ~= archivedCount then return end

    if data.hash and isProducer then
        -- The sender sent a hash of their recent entries. If our hash is different,
        -- we'll deliver them a sync with ids and they can request whatever they need.
        if data.hash ~= hash then
            self:_SyncWorker(controller, data.syncId, data.token, now, sender)
        end
    elseif data.ids and senderIsProducer then
        -- The sender sent ids. We'll go through them looking for entries we need,
        -- and entries to send if we're allowed to do so.
        data.ids = controller:RebuildIds(data.ids, now)
        local send = {}
        local sendCount, requestCount = 0, 0
        for _, entry in ipairs(history) do
            local id, entryDate = controller:GetEntryInfo(entry)
            if now - entryDate > syncThreshold then break end

            if data.ids[id] then
                -- We both have this entry.
                data.ids[id] = nil
            elseif isProducer then
                -- Sender doesn't have this entry.
                send[id] = entry
                sendCount = sendCount + 1
            end
        end

        -- At this point, anything left in data.ids represents entries
        -- the sender has but we don't. Request those if they exist,
        -- and send any we have they're missing. Remove ones we've
        -- already requested for this token.
        local wt = controller:GetWorkingTable(data.syncId)
        for id in pairs(data.ids) do
            if wt.requestedHistory[id] then
                -- We already requested this entry from someone.
                data.ids[id] = nil
            else
                -- We need to request this id.
                wt.requestedHistory[id] = true
                requestCount = requestCount + 1
            end
        end

        if sendCount > 0 or requestCount > 0 then
            self:_SendComm("HISTORY_MERGE", {
                syncId = data.syncId,
                baseline = baseline,
                sent = sendCount > 0 and controller:PrepareHistoryMap(send, now) or nil,
                requested = requestCount > 0 and controller:PrepareIds(data.ids, now) or nil,
                now = now
            }, sender)
        end
    end
end

function LibHistorySync:_HISTORY_MERGE(controller, data, sender)
    local history = controller:GetHistory(syncId)
    local baseline = controller:GetBaseline(syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    local senderIsProducer = data.isProducer and controller:IsProducer(sender)
    local syncThreshold = controller:GetSyncThreshold()
    local now = data.now

    if data.requested and isProducer then
        -- The sender is requesting entries from us.
        data.requested = controller:RebuildIds(data.requested, now)
        local send = {}
        local sendCount = 0
        for _, entry in ipairs(history) do
            local id, entryDate = controller:GetEntryInfo(entry)

            if data.requested[id] then
                -- Sender wants this entry.
                send[id] = entry
                sendCount = sendCount + 1
            end
        end

        if sendCount > 0 then
            self:_SendComm("HISTORY_MERGE", {
                syncId = data.syncId,
                baseline = baseline,
                sent = controller:PrepareHistoryMap(send, now),
                now = now
            }, sender)
        end
    end

    if data.sent and senderIsProducer then
        -- The sender is sharing entries. First remove the ones we already have.
        data.sent = controller:RebuildHistoryMap(data.sent)
        for _, entry in ipairs(history) do
            local id, entryDate = controller:GetEntryInfo(entry)
            data.sent[id] = nil
        end

        -- At this point, data.sent contains entries we don't have.
        if next(data.sent) then
            controller:AddHistory(data.syncId, data.sent)
        end
    end
end

function LibHistorySync:_HISTORY_REPLACE_INITIATION(controller, data, sender)
    if not controller:IsProducer(sender) then return end

    -- The sender has determined our history is out of date and wants to give us theirs.
    -- At this point our history should not be considered as valid for sending to others.
    controller:SetBaseline(data.syncId, self._invalidBaseline)
    controller:WarnOutOfDate(data.syncId, sender)
end

function LibHistorySync:_HISTORY_REPLACE_REQUEST(controller, data, sender)
    local history = controller:GetHistory(syncId)
    local baseline = controller:GetBaseline(syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    if not isProducer then return end

    -- The sender is asking for our entire history.
    if data.token then
        -- The sender is asking in response to our own sync. Broadcast them,
        -- so that anyone else who needs this baseline can get it. Make sure
        -- we only do this once per sync.

        local wt = controller:GetWorkingTable(data.syncId)
        if wt.replaceRequestToken == data.token then return end

        self:_SendComm("HISTORY_REPLACE", {
            syncId = data.syncId,
            baseline = baseline,
            history = controller:PrepareHistoryList(history)
        })
    else
        -- The sender is asking in response to our initiation, which was
        -- triggered by their sync. Send to them directly.

        self:_SendComm("HISTORY_REPLACE", {
            syncId = data.syncId,
            baseline = baseline,
            history = controller:PrepareHistoryList(history),
            initiated = true
        }, sender)
    end
end

function LibHistorySync:_HISTORY_REPLACE(controller, data, sender)
    if not controller:IsProducer(sender) then return end
    local baseline = controller:GetBaseline(syncId)

    -- The sender is providing a replacement. Only accept it if it's a
    -- newer baseline (which is always the case if ours is invalid).
    if data.baseline <= baseline then return end

    data.history = controller:RebuildHistoryList(data.history)
    if data.initiated then
        -- We already requested this one explicitly, so we can just directly apply it.
        controller:SetHistory(data.syncId, data.history)
        controller:SetBaseline(data.syncId, data.baseline)
    else
        -- Not explicit - ask before applying. Our baseline should be invalid now, though,
        -- since an updated history has been discovered.
        controller:SetBaseline(data.syncId, self._invalidBaseline)
        controller:PromptSetHistory(data.syncId, data.history, data.baseline, sender)
    end
end

function LibHistorySync:_SendComm(controller, typ, data, target)
    self:_SendComm(typ, data, target)
end
