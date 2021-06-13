local LibLedger = LibStub and LibStub:GetLibrary("LibLedger") or require("LibLedger")

local controllers = {};
local comms = {};

local testController = {
    GetLedger = function(self)
        return self.ledger, self.baseline;
    end,

    GetEntryDate = function(self, id)
        return self.ledger.entries[id][2];
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
    local parsedLedger = {
        entries = {},
        ids = {},
    };
    for _, entry in ipairs(ledger) do
        parsedLedger.entries[entry[1]] = entry;
        table.insert(parsedLedger.ids, entry[1]);
    end

    local controller = setmetatable({
        name = name,
        privileged = privileged,
        ledger = parsedLedger,
        baseline = baseline
    }, { __index = testController });
    controllers[name] = controller;
    return controller;
end

local a = MakeTestController("a", true, {
    { "a", 60, "The " },
    { "b", 65, "quick " },
    -- { "c", 70, "brown " },
    { "d", 75, "fox " },
    { "e", 80, "jumps " },
    -- { "f", 85, "over " },
    -- { "g", 90, "the " },
    { "h", 95, "lazy " },
    { "i", 100, "dog." },
}, 1);

local b = MakeTestController("b", true, {
    -- { "a", 60, "The " },
    { "b", 65, "quick " },
    { "c", 70, "brown " },
    { "d", 75, "fox " },
    { "e", 80, "jumps " },
    { "f", 85, "over " },
    { "g", 90, "the " },
    -- { "h", 95, "lazy " },
    -- { "i", 100, "dog." },
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
for _, id in ipairs(a.ledger.ids) do
    out = out .. a.ledger.entries[id][3];
end
testController:Log(out);
local out = "";
for _, id in ipairs(b.ledger.ids) do
    out = out .. b.ledger.entries[id][3];
end
testController:Log(out);
