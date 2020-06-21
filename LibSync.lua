-- controller:
--     GetEntryInfo(entry): id, entryDate
--     GetSyncData(syncId): entries, baseline
--     GetSyncThreshold(): number
--     GetWorkingTable(syncId): table
--     IsProducer(player?): boolean
--     MergeEntries(syncId, merged): nil
--     PromptSetEntries(syncId, entries, baseline, sender): nil
--     PrepareEntries(entries): table
--     PrepareIds(ids, now): table
--     RebuildEntries(entries): table
--     RebuildIds(ids, now): table
--     SendComm(name, data, target?): nil
--     SetBaseline(syncId, baseline): nil
--     SetEntries(syncId, entries, baseline, sender): nil
--     WarnOutOfDate(syncId, sender): nil

local LibSync = {}

local GetTime = GetTime
local GetServerTime = GetServerTime
local pairs = pairs
local ipairs = ipairs
local next = next
local table = table


function LibSync:Sync(controller, syncId, entries, baseline)
    self:_SyncWorker(controller, syncId, entries, baseline, GetTime(), GetServerTime(), nil)
end

function LibSync:RequestEntries(controller, syncId, target)
    -- We're asking the sender for their full entries.

    controller:SendComm("ENTRIES_REPLACE_REQUEST", {
        syncId = syncId
    }, target)
end

function LibSync:HandleComm(controller, name, data, sender)
    self["_" .. name](self, controller, data, sender)
end

function LibSync:GetInvalidBaseline()
    return self._invalidBaseline
end

function LibSync:_SyncWorker(controller, syncId, token, now, target)
    local entries, baseline = controller:GetSyncData(syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    local commData = {
        syncId = syncId,
        token = token,
        baseline = baseline,
        now = now,
        isProducer = isProducer,
    }

    local syncCount = 0
    if isProducer then
        local ids = {}
        local syncThreshold = controller:GetSyncThreshold()
        for _, entry in ipairs(entries) do
            local id, entryDate = controller:GetEntryInfo(entry)
            if now - entryDate > syncThreshold then break end

            ids[id] = true
            syncCount = syncCount + 1
        end
        commData.ids = controller:PrepareIds(ids, now)
    else
        commData.hash, syncCount = self:_BuildSyncHashData(controller, entries, baseline, now)
    end
    commData.archivedCount = #entries - syncCount

    local prepared = self:_PrepareSyncData(commData)
    controller:SendComm("ENTRIES_SYNC", prepared, target)
end

function LibSync:_ENTRIES_SYNC(controller, data, sender)
    self:_RebuildSyncData(data)
    local entries, baseline = controller:GetSyncData(data.syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    local senderIsProducer = data.isProducer and controller:IsProducer(sender)
    local syncThreshold = controller:GetSyncThreshold()
    local now = data.now

    -- If we sent a hash-based sync, producers may send us their own syncs
    -- if our hash doesn't match. To make sure we don't ask all of them for
    -- the same data, keep track of the entries we end up requesting as a
    -- result of this sync's token.
    local wt = controller:GetWorkingTable(data.syncId)
    wt.requestedEntries = wt.requestedEntries or {}
    if data.token ~= wt.requestedToken then
        table.wipe(wt.requestedEntries)
        wt.requestedToken = data.token
    end

    -- Compute the archivedCount and hash (if necessary).
    local hash, syncCount = 0, 0
    if data.hash and isProducer then
        hash, syncCount = self:_BuildSyncHashData(controller, entries, baseline, now)
    else
        for _, entry in ipairs(entries) do
            local id, entryDate = controller:GetEntryInfo(entry)
            if now - entryDate > syncThreshold then break end

            syncCount = syncCount + 1
        end
    end
    local archivedCount = #entries - syncCount

    -- First evaluate the baseline and archivedCount to see if the sender's entries are
    -- out of date. We can only initiate entry replacements as producers, and we'll only
    -- accept possible entry replacements from producers.
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
            controller:SendComm("ENTRIES_REPLACE_INITIATION", {
                syncId = data.syncId,
                token = data.token,
            }, sender)
        end
    end

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
            controller:SendComm("ENTRIES_REPLACE_REQUEST", {
                syncId = data.syncId,
                token = data.token,
            }, sender)
        end
    end

    -- A deeper sync check should only occur if the baselines and archivedCounts match.
    local checkRecent = data.baseline == baseline and data.archivedCount == archivedCount
    if not checkRecent then return end

    if data.hash and isProducer then
        -- The sender sent a hash of their recent entries. If our hash is different,
        -- we'll deliver them a sync and they can request whatever they need.
        if data.hash ~= hash then
            self:_SyncWorker(controller, data.syncId, data.token, now, sender)
        end
    elseif data.ids and senderIsProducer then
        -- The sender sent ids. We'll go through them looking for entries we need,
        -- and entries to send if we're allowed to do so.
        data.ids = controller:RebuildIds(data.ids, now)
        local merge = {}
        local sendCount, requestCount = 0, 0
        for _, entry in ipairs(entries) do
            local id, entryDate = controller:GetEntryInfo(entry)
            if now - entryDate > syncThreshold then break end

            if data.ids[id] then
                -- We both have this entry.
                data.ids[id] = nil
            elseif isProducer then
                -- Sender doesn't have this entry.
                merge[id] = entry
                sendCount = sendCount + 1
            end
        end

        -- At this point, anything left in data.ids represents entries
        -- the sender has but we don't. Request those if they exist,
        -- and send any we have they're missing. Remove ones we've
        -- already requested for this token.
        local wt = controller:GetWorkingTable(data.syncId)
        for id in pairs(data.ids) do
            if wt.requestedEntries[id] then
                -- We already requested this entry from someone.
                data.ids[id] = nil
            else
                -- We need to request this id.
                wt.requestedEntries[id] = true
                requestCount = requestCount + 1
            end
        end

        if sendCount > 0 or requestCount > 0 then
            controller:SendComm("ENTRIES_MERGE", {
                syncId = data.syncId,
                baseline = baseline,
                merge = controller:PrepareEntries(merge),
                requested = controller:PrepareIds(data.ids, now),
                now = now
            }, sender)
        end
    end
end

function LibSync:_ENTRIES_MERGE(controller, data, sender)
    local entries, baseline = controller:GetSyncData(data.syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    local senderIsProducer = data.isProducer and controller:IsProducer(sender)
    local syncThreshold = controller:GetSyncThreshold()
    local now = data.now

    if data.requested and next(data.requested) and isProducer then
        -- The sender is requesting entries from us.
        data.requested = controller:RebuildIds(data.requested, now)
        local merge = {}
        local sendCount = 0
        for _, entry in ipairs(entries) do
            local id, entryDate = controller:GetEntryInfo(entry)

            if data.requested[id] then
                -- Sender wants this entry.
                merge[id] = entry
                sendCount = sendCount + 1
            end
        end

        if sendCount > 0 then
            controller:SendComm("ENTRIES_MERGE", {
                syncId = data.syncId,
                baseline = baseline,
                merge = controller:PrepareEntries(merge),
                now = now
            }, sender)
        end
    end

    if data.merge and next(data.merge) and senderIsProducer then
        -- The sender is sharing entries. First remove the ones we already have.
        data.merge = controller:RebuildEntries(data.merge)
        for _, entry in ipairs(entries) do
            local id, entryDate = controller:GetEntryInfo(entry)
            data.merge[id] = nil
        end

        -- At this point, data.merge contains entries we don't have.
        if next(data.merge) then
            controller:MergeEntries(data.syncId, data.merge)
        end
    end
end

function LibSync:_ENTRIES_REPLACE_INITIATION(controller, data, sender)
    if not controller:IsProducer(sender) then return end

    -- The sender has determined our history is out of date and wants to give us theirs.
    -- At this point our history should not be considered as valid for sending to others.

    controller:SetBaseline(data.syncId, self._invalidBaseline)
    controller:WarnOutOfDate(data.syncId, sender)
end

function LibSync:_ENTRIES_REPLACE_REQUEST(controller, data, sender)
    local entries, baseline = controller:GetSyncData(data.syncId)
    local isProducer = baseline ~= self._invalidBaseline and controller:IsProducer()
    if not isProducer then return end

    -- The sender is asking for our entire history.

    if data.token then
        -- The sender is asking in response to our own sync. Broadcast them,
        -- so that anyone else who needs this baseline can get it. Make sure
        -- we only do this once per sync.

        local wt = controller:GetWorkingTable(data.syncId)
        if wt.replaceRequestToken == data.token then
            return
        end

        controller:SendComm("ENTRIES_REPLACE", {
            syncId = data.syncId,
            baseline = baseline,
            entries = controller:PrepareEntries(entries)
        })
    else
        -- The sender is asking in response to our initiation, which was
        -- triggered by their sync. Send to them directly.

        controller:SendComm("ENTRIES_REPLACE", {
            syncId = data.syncId,
            baseline = baseline,
            entries = controller:PrepareEntries(entries),
            initiated = true
        }, sender)
    end
end

function LibSync:_ENTRIES_REPLACE(controller, data, sender)
    if not controller:IsProducer(sender) then return end
    local _, baseline = self:GetSyncData(data.syncId)

    -- The sender is providing a replacement. Only accept it if it's a
    -- newer baseline (which is always the case if ours is invalid).
    if data.baseline <= baseline then
        return
    end

    data.entries = controller:RebuildEntries(data.entries)
    if data.initiated then
        -- We already requested this one explicitly, so we can just directly apply it.
        controller:SetEntries(data.syncId, data.entries, data.baseline, sender)
    else
        -- Not explicit - ask before applying. Our baseline should be invalid now, though,
        -- since an updated history has been discovered.
        controller:SetBaseline(data.syncId, self._invalidBaseline)
        controller:PromptSetEntries(data.syncId, data.entries, data.baseline, sender)
    end
end
