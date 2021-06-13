-- controller:
--  GetLedger(): table (entries), number (baseline)
--  GetEntryDate(id): number
--  GetVersion(): any
--  IsSelf(string): boolean
--  GetTime(): number

--  SetLedger(ledger): nil
--  SetBaseline(baseline): nil
--  OnEntriesSynced(entries, source): nil

--  PrepareEntries(entries, now): table
--  PrepareIds(ids, now): table
--  RebuildEntries(entries, now): table
--  RebuildIds(ids, now): table

--  GetSyncThresholds(): number (first), number (rest)
--  CanWriteEntries(player?): boolean
--  SendComm(data, target?): nil
--  Log(fmt, ...): nil

local MAJOR, MINOR = "LibLedger", 1
local LibLedger
if _G.LibStub then
    LibLedger = _G.LibStub:NewLibrary(MAJOR, MINOR)
    if not LibLedger then return end -- This version is already loaded.
else
    LibLedger = {}
end

local math = math;
local pairs = pairs;
local bit = bit;
local next = next;
local table = table;

local _invalidBaseline = -1;

local function Hash(value)
    -- An implementation of the djb2 hash algorithm.
    -- See http://www.cs.yorku.ca/~oz/hash.html.

    local h = 5381;
    for i = 1, #value do
        h = bit.band((33 * h + value:byte(i)), 4294967295);
    end
    return h;
end

function LibLedger:Sync(controller)
    self:_SyncWorker(controller, math.random(), controller:GetTime())
end

function LibLedger:SyncNewEntries(controller, entries)
    local privileged = controller:CanWriteEntries();
    local _, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    -- Fast path to trigger a sync of newly added entries.
    -- Make sure we're allowed to send them.
    if not canSendEntries then return; end
    local now = controller:GetTime();

    self:_SendComm(controller, {
        name = "_LEDGER_MERGE",

        token = math.random(),
        baseline = baseline,
        now = now,
        version = controller:GetVersion(),

        merge = controller:PrepareEntries(entries, now),
        requested = {},
    });
end

function LibLedger:HandleComm(controller, data, sender)
    if controller:GetVersion() == data.version and not controller:IsSelf(sender) then
        controller:Log("Comm: %s from %s", data.name, sender);
        self[data.name](self, controller, data, sender);
    end
end

function LibLedger:HasValidLedger(controller)
    local _, baseline = controller:GetLedger();
    return (baseline ~= _invalidBaseline);
end

function LibLedger:SetInvalidLedger(controller)
    controller:SetBaseline(_invalidBaseline);
end

function LibLedger:_SendComm(controller, data, target)
    controller:Log("Comm: %s to %s", data.name, target or "everyone");
    controller:SendComm(data, target);
end

function LibLedger:_SyncWorker(controller, token, now)
    local privileged = controller:CanWriteEntries();
    local _, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    local commData = {
        name = "_LEDGER_SYNC",

        token = token,
        baseline = baseline,
        now = now,
        version = controller:GetVersion(),

        handled = {},
    };

    if not invalidLedger then
        local hashBuckets, idBuckets = self:_BuildSyncBuckets(controller, now);
        commData.hashes = hashBuckets;
        if canSendEntries then
            commData.ids = idBuckets;
        end
    end

    if commData.ids then
        for bucket, ids in pairs(commData.ids) do
            commData.ids[bucket] = controller:PrepareIds(ids, now);
        end
    end

    local wt = self:_GetWorkingTable(controller);
    wt.broadcastToken = token;
    wt.broadcastEntries = {};

    self:_SendComm(controller, commData);
end

function LibLedger:_BuildSyncBuckets(controller, now)
    local ledger = controller:GetLedger();
    local firstThreshold, otherThresholds = controller:GetSyncThresholds();

    local hashBuckets = {};
    local idBuckets = {};

    local bucket = 1;
    local bucketCount = 0;
    hashBuckets[bucket] = 0;
    idBuckets[bucket] = {};
    local threshold = firstThreshold;

    for i = #ledger.ids, 1, -1 do
        local id = ledger.ids[i];
        local entryDate = controller:GetEntryDate(id);
        while now - entryDate > threshold do
            controller:Log("%d ids in bucket %d", bucketCount, bucket);
            bucketCount = 0;
            bucket = bucket + 1;
            hashBuckets[bucket] = 0;
            idBuckets[bucket] = {};
            threshold = threshold + otherThresholds;
        end
        -- controller:Log("Id %s at time %d is in bucket %d", id, entryDate, bucket);

        bucketCount = bucketCount + 1;
        hashBuckets[bucket] = bit.bxor(hashBuckets[bucket], Hash(id));
        idBuckets[bucket][id] = true;
    end

    if hashBuckets[bucket] ~= 0 then
        controller:Log("%d ids in bucket %d", bucketCount, bucket);
    end

    return hashBuckets, idBuckets;
end

function LibLedger:_GetWorkingTable(controller)
    self._wt = self._wt or {};
    self._wt[controller] = self._wt[controller] or {};
    return self._wt[controller];
end

function LibLedger:_LEDGER_SYNC(controller, data, sender)
    local privileged = controller:CanWriteEntries();
    local senderIsPrivileged = controller:CanWriteEntries(sender);
    local ledger, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    if data.ids then
        for bucket, ids in pairs(data.ids) do
            data.ids[bucket] = controller:RebuildIds(ids, data.now);
        end
    end

    -- First evaluate the baseline to see if the data is out of date.
    -- We can only initiate history replacements if privileged, and we'll only accept
    -- possible history replacements from privileged senders.
    if canSendEntries and data.baseline < baseline then
        -- The sender has an older baseline. They need a history replacement.
        controller:Log("Sending replace init to %s (older baseline)", sender);
        self:_SendComm(controller, {
            name = "_LEDGER_REPLACE_INIT",

            token = data.token,
            baseline = baseline,
            now = data.now,
            version = data.version,
        }, sender);
        return;
    elseif senderIsPrivileged and data.baseline > baseline then
        -- The sender has a newer baseline. We need a history replacement.
        controller:Log("Sending replace request to %s (newer baseline)", sender);
        controller:SetBaseline(_invalidBaseline);
        self:_SendComm(controller, {
            name = "_LEDGER_REPLACE_REQUEST",

            token = data.token,
            baseline = baseline,
            now = data.now,
            version = data.version,
        }, sender);
        return;
    elseif data.baseline ~= baseline or invalidLedger then
        -- Nothing more we can do with a mismatched/invalid baseline.
        return;
    end

    if not data.ids and canSendEntries then
        -- The sender sent hashes of their entries. If any of our hashes are different,
        -- we'll send them ids and they can request whatever they want.
        local hashBuckets, idBuckets = self:_BuildSyncBuckets(controller, data.now);

        for bucket, hash in pairs(hashBuckets) do
            if hash == (hashBuckets[bucket] or 0) then
                idBuckets[bucket] = nil;
            else
                controller:Log("Bucket %d from %s has a mismatched hash (no ids).", bucket, sender);
            end
        end

        if next(idBuckets) then
            local bucketCount = 0;
            for bucket, ids in pairs(idBuckets) do
                bucketCount = bucketCount + 1;
                idBuckets[bucket] = controller:PrepareIds(ids, data.now);
            end
            controller:Log("Sending sync (with ids) for %d buckets to %s", bucketCount, sender);
            self:_SendComm(controller, {
                name = "_LEDGER_SYNC",

                token = data.token,
                baseline = baseline,
                now = data.now,
                version = data.version,

                hashes = hashBuckets,
                ids = idBuckets,
                handled = {},
            }, sender);
        end
    elseif data.ids and senderIsPrivileged then
        -- The sender sent ids. First check hashes to see if we need to sync any more buckets.
        local hashBuckets, idBuckets = self:_BuildSyncBuckets(controller, data.now);

        local needsSync = false;
        local bucketCount = 0;
        local commData = {
            name = "_LEDGER_SYNC",

            token = data.token,
            baseline = baseline,
            now = data.now,
            version = data.version,

            hashes = {},
            ids = canSendEntries and {} or nil,
            handled = {},
        };
        for bucket, hash in pairs(hashBuckets) do
            commData.hashes[bucket] = hash;
            if hash == (data.hashes[bucket] or 0) then
                -- We have the same hash as the sender.
            elseif data.ids[bucket] or data.handled[bucket] then
                -- Different hash, but we've already handled this bucket.
                commData.handled[bucket] = true;
            elseif canSendEntries or data.hashes[bucket] then
                -- Different hash, hasn't been handled. Trigger a sync, and
                -- send our ids for the bucket if allowed. Note that if we aren't
                -- privileged, and the sender didn't have any entries in this
                -- bucket, there's nothing we can do.
                controller:Log("Bucket %d from %s has a mismatched hash (ids)", bucket, sender);
                needsSync = true;
                bucketCount = bucketCount + 1;
                if commData.ids then
                    commData.ids[bucket] = idBuckets[bucket];
                end
            end
        end

        if needsSync then
            if commData.ids then
                for bucket, ids in pairs(commData.ids) do
                    commData.ids[bucket] = controller:PrepareIds(ids, data.now);
                end
            end

            controller:Log("Sending sync (%s ids) for %d buckets to %s", commData.ids and "with" or "no", bucketCount, sender);
            self:_SendComm(controller, commData, sender);
        end

        -- Now go through the ids looking for ones we need, or ones to send if allowed.
        local hashBuckets, idBuckets = self:_BuildSyncBuckets(controller, data.now);
        local merge = {};
        local requested = {};
        local mergeCount = 0;
        local requestCount = 0;

        for bucket, ids in pairs(idBuckets) do
            if data.ids[bucket] then
                for id in pairs(ids) do
                    if data.ids[bucket][id] then
                        -- We both have this entry.
                        data.ids[bucket][id] = nil;
                    elseif canSendEntries then
                        -- Sender doesn't have this entry.
                        merge[id] = ledger.entries[id];
                        mergeCount = mergeCount + 1;
                    end
                end
            end
        end

        -- At this point, anything left in data.ids represents entries
        -- the sender has but we don't.
        for _, ids in pairs(data.ids) do
            for id in pairs(ids) do
                requested[id] = true;
                requestCount = requestCount + 1;
            end
        end

        if next(merge) or next(requested) then
            controller:Log("Sending %d, requesting %d entries to/from %s", mergeCount, requestCount, sender);
            self:_SendComm(controller, {
                name = "_LEDGER_MERGE",

                token = data.token,
                baseline = baseline,
                now = data.now,
                version = data.version,

                merge = controller:PrepareEntries(merge, data.now),
                requested = controller:PrepareIds(requested, data.now),
            }, sender);
        end
    end
end

function LibLedger:_LEDGER_MERGE(controller, data, sender)
    local privileged = controller:CanWriteEntries();
    local senderIsPrivileged = controller:CanWriteEntries(sender);
    local ledger, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    if data.baseline ~= baseline then return; end

    data.merge = controller:RebuildEntries(data.merge, data.now);
    data.requested = controller:RebuildIds(data.requested, data.now);

    if next(data.requested) and canSendEntries then
        -- The sender is requesting entries.
        local merge = {};
        local mergeCount = 0;
        for id in pairs(data.requested) do
            if ledger.entries[id] then
                merge[id] = ledger.entries[id];
                mergeCount = mergeCount + 1;
            end
        end

        local wt = self:_GetWorkingTable(controller);
        if data.token == wt.broadcastToken then
            -- The sender is requesting entries due to our own sync broadcast.
            -- Since there may be multiple people that all need these entries,
            -- broadcast them instead of directly sending them. Keep track of
            -- the broadcasted entries so we only send them once.
            for id in pairs(merge) do
                if wt.broadcastEntries[id] then
                    merge[id] = nil;
                    mergeCount = mergeCount - 1;
                else
                    wt.broadcastEntries[id] = true;
                end
            end

            if next(merge) then
                controller:Log("Broadcasting %d entries", mergeCount);
                self:_SendComm(controller, {
                    name = "_LEDGER_MERGE",

                    token = data.token,
                    baseline = baseline,
                    now = data.now,
                    version = controller:GetVersion(),

                    merge = controller:PrepareEntries(merge, data.now),
                    requested = {},
                });
            end
        else
            -- The sender is requesting entries we've told them about.
            controller:Log("Sending %d entries to %s", mergeCount, sender);
            self:_SendComm(controller, {
                name = "_LEDGER_MERGE",

                token = data.token,
                baseline = baseline,
                now = data.now,
                version = controller:GetVersion(),

                merge = controller:PrepareEntries(merge, data.now),
                requested = {},
            }, sender);
        end
    end

    if next(data.merge) and senderIsPrivileged then
        -- The sender is sharing entries. First remove the ones we already have.
        for id in pairs(data.merge) do
            if ledger.entries[id] then
                data.merge[id] = nil;
            end
        end

        -- At this point, data.merge contains entries we don't have. Add them
        -- to the ledger and then sort it by date.
        if next(data.merge) then
            local mergeCount = 0;
            for id, entry in pairs(data.merge) do
                ledger.entries[id] = entry;
                table.insert(ledger.ids, id);
                mergeCount = mergeCount + 1;
            end

            table.sort(ledger.ids, function(a, b)
                local aDate = controller:GetEntryDate(a);
                local bDate = controller:GetEntryDate(b);
                if aDate == bDate then
                    return a < b;
                else
                    return aDate < bDate;
                end
            end);
            controller:Log("Received %d entries from %s", mergeCount, sender);
            controller:OnEntriesSynced(data.merge, sender);
        end
    end
end

function LibLedger:_LEDGER_REPLACE_INIT(controller, data, sender)
    local privileged = controller:CanWriteEntries();
    local senderIsPrivileged = controller:CanWriteEntries(sender);
    local _, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    -- The sender is telling us they can give us an updated ledger.
    if not senderIsPrivileged or data.baseline <= baseline then return; end

    -- At this point, our ledger shouldn't be considered as valid.
    controller:SetBaseline(_invalidBaseline);

    -- We only want to request a new ledger once.
    local wt = self:_GetWorkingTable(controller);
    if data.token == wt.replaceInitToken then return; end
    wt.replaceInitToken = data.token;

    controller:Log("Requesting ledger from %s", sender);
    self:_SendComm(controller, {
        name = "_LEDGER_REPLACE_REQUEST",

        token = data.token,
        baseline = baseline,
        now = data.now,
        version = data.version,
    }, sender)
end

function LibLedger:_LEDGER_REPLACE_REQUEST(controller, data, sender)
    local privileged = controller:CanWriteEntries();
    local senderIsPrivileged = controller:CanWriteEntries(sender);
    local ledger, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    -- The sender is asking for our entire ledger.
    if not canSendEntries or data.baseline >= baseline then return; end
    local wt = self:_GetWorkingTable(controller);

    if data.token and data.token == wt.broadcastToken then
        -- The sender is asking in response to our own sync. Send it broadly,
        -- in case other folks need it as well. Only do this once.
        if data.token == wt.replaceRequestToken then return; end
        wt.replaceRequestToken = data.token;

        controller:Log("Broadcasting ledger (via %s)", sender);
        self:_SendComm(controller, {
            name = "_LEDGER_REPLACE",

            token = data.token,
            baseline = baseline,
            now = data.now,
            version = data.version,

            entries = controller:PrepareEntries(ledger.entries, data.now),
            baseline = baseline
        });
    else
        -- The sender is asking in response to our initiation, which was
        -- triggered by their sync. Send to them directly.

        controller:Log("Sending ledger to %s", sender);
        self:_SendComm(controller, {
            name = "_LEDGER_REPLACE",

            token = data.token,
            baseline = baseline,
            now = data.now,
            version = data.version,

            entries = controller:PrepareEntries(ledger.entries, data.now),
            baseline = baseline
        }, sender);
    end
end

function LibLedger:_LEDGER_REPLACE(controller, data, sender)
    local privileged = controller:CanWriteEntries();
    local senderIsPrivileged = controller:CanWriteEntries(sender);
    local _, baseline = controller:GetLedger();
    local invalidLedger = (baseline == _invalidBaseline);
    local canSendEntries = privileged and not invalidLedger;

    -- The sender has given us an updated ledger.
    if not senderIsPrivileged or data.baseline <= baseline then return; end

    controller:Log("Got new ledger from %s", sender);
    local newLedger = {
        entries = controller:RebuildEntries(data.entries, data.now),
        ids = {},
    };
    for id in pairs(newLedger.entries) do
        table.insert(newLedger.ids, id);
    end
    table.sort(newLedger.ids, function(a, b)
        local aDate = controller:GetEntryDate(a);
        local bDate = controller:GetEntryDate(b);
        if aDate == bDate then
            return a < b;
        else
            return aDate < bDate;
        end
    end);

    controller:SetLedger(newLedger);
    controller:SetBaseline(data.baseline);
end

return LibLedger;
