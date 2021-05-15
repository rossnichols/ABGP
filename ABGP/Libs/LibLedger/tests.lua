

-- TEST --

local controllers = {};
local comms = {};

local testController = {
    GetLedger = function(self)
        return self.ledger, self.baseline;
    end,

    GetEntryInfo = function(self, entry)
        return entry[1], entry[2];
    end,

    GetVersion = function(self)
        return 1;
    end,

    IsSelf = function(self, name)
        return self.name == name;
    end,

    GetTime = function(self)
        return 100;
    end,

    SetLedger = function(self, ledger)
        self.ledger = ledger;
    end,

    SetBaseline = function(self, baseline)
        self.baseline = baseline;
    end,

    GetSyncThresholds = function(self)
        return 3, 5;
    end,

    CanWriteEntries = function(self, name)
        name = name or self.name;
        return controllers[name].privileged;
    end,

    OnEntriesSynced = function(self, entries, source)

    end,

    SendComm = function(self, data, target)
        table.insert(comms, { data = data, target = target, sender = self.name });
    end,

    Log = function(self, fmt, ...)
        print(fmt:format(...));
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
}

local function MakeTestController(name, privileged, ledger, baseline)
    local controller = setmetatable({
        name = name,
        privileged = privileged,
        ledger = ledger,
        baseline = baseline
    }, { __index = testController });
    controllers[name] = controller;
    return controller;
end

local a = MakeTestController("a", true, {
    { "a", 100, "The " },
    { "b", 95, "quick " },
    -- { "c", 90, "brown " },
    -- { "d", 85, "fox " },
    { "e", 80, "jumps " },
    { "f", 75, "over " },
    -- { "g", 70, "the " },
    { "h", 65, "lazy " },
    { "i", 60, "dog." },
}, 1);

local b = MakeTestController("b", true, {
    -- { "a", 100, "The " },
    -- { "b", 95, "quick " },
    { "c", 90, "brown " },
    { "d", 85, "fox " },
    { "e", 80, "jumps " },
    { "f", 75, "over " },
    { "g", 70, "the " },
    { "h", 65, "lazy " },
    -- { "i", 60, "dog." },
}, 1);

testController:Log("Starting...");
LibLedger:Sync(a);
while next(comms) do
    local comm = table.remove(comms, 1);

    if comm.target then
        testController:Log("Comm:%s to:%s from:%s", comm.data.name, comm.target, comm.sender);
        LibLedger:HandleComm(controllers[comm.target], comm.data, comm.sender);
    else
        for _, controller in pairs(controllers) do
            testController:Log("Comm:%s to:%s from:%s", comm.data.name, controller.name, comm.sender);
            LibLedger:HandleComm(controller, comm.data, comm.sender);
        end
    end
end

local out = "";
for _, entry in ipairs(a.ledger) do
    out = out .. entry[3];
end
testController:Log(out);
local out = "";
for _, entry in ipairs(b.ledger) do
    out = out .. entry[3];
end
testController:Log(out);
