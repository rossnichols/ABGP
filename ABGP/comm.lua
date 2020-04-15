local AceSerializer = LibStub("AceSerializer-3.0");
local LibCompress = LibStub("LibCompress");
local AddonEncodeTable = LibCompress:GetAddonEncodeTable();

local _G = _G;
local ABGP = ABGP;
local IsInGroup = IsInGroup;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInRaid = IsInRaid;
local UnitName = UnitName;
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE;
local pairs = pairs;
local type = type;
local table = table;
local tostring = tostring;
local strlen = strlen;

local function GetBroadcastChannel()
    if ABGP.PrivateComms then return "WHISPER", UnitName("player"); end

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT";
    elseif GetNumGroupMembers() > 0 and IsInRaid() then
        return "RAID";
    elseif IsInGroup() then
        return "PARTY";
    elseif ABGP.Debug then
        return "WHISPER", UnitName("player");
    end
end

-- The commVersion can be revved to create a backwards-incompatible version.
local commVersion = ":2";
local function CV(str)
    return str .. commVersion;
end

ABGP.CommTypes = {
    ITEM_REQUEST = { name = CV("ABGP_ITEM_REQUEST"), priority = "INSTANT" },
    -- itemLink: item link string
    -- requestType: string from ABGP.RequestTypes
    -- notes: string or nil
    -- equipped: array of item link strings or nil

    ITEM_PASS = { name = CV("ABGP_ITEM_PASS"), priority = "INSTANT" },
    -- itemLink: item link string

    ITEM_DISTRIBUTION_OPENED = { name = CV("ABGP_ITEM_DISTRIBUTION_OPENED"), priority = "INSTANT" },
    -- itemLink: item link string
    -- value: table from ABGP:GetItemValue()
    -- requestType: string from ABGP.RequestTypes

    ITEM_DISTRIBUTION_CLOSED = { name = CV("ABGP_ITEM_DISTRIBUTION_CLOSED"), priority = "INSTANT" },
    -- itemLink: item link string
    -- count: number

    ITEM_DISTRIBUTION_AWARDED = { name = CV("ABGP_ITEM_DISTRIBUTION_AWARDED"), priority = "ALERT" },
    -- itemLink: item link string
    -- player: string
    -- cost: number
    -- roll: number
    -- count: number
    -- requestType: string from ABGP.RequestTypes
    -- override: string
    -- count: number
    -- testItem: bool

    ITEM_DISTRIBUTION_TRASHED = { name = CV("ABGP_ITEM_DISTRIBUTION_TRASHED"), priority = "ALERT" },
    -- itemLink: item link string
    -- count: number
    -- testItem: bool

    ITEM_DISTRIBUTION_CHECK = { name = CV("ABGP_ITEM_DISTRIBUTION_CHECK"), priority = "ALERT" },
    -- itemLink: optional item link string

    ITEM_DISTRIBUTION_CHECK_RESPONSE = { name = CV("ABGP_ITEM_DISTRIBUTION_CHECK_RESPONSE"), priority = "ALERT" },
    -- itemLink: item link string
    -- valid: bool

    ITEM_ROLLED = { name = CV("ABGP_ITEM_ROLLED"), priority = "ALERT" },
    -- itemLink: item link string
    -- roll: number

    OFFICER_NOTES_UPDATED = { name = CV("ABGP_OFFICER_NOTES_UPDATED"), priority = "NORMAL" },
    -- no payload

    REQUEST_PRIORITY_SYNC = { name = CV("ABGP_REQUEST_PRIORITY_SYNC"), priority = "NORMAL" },
    -- no payload

    PRIORITY_SYNC = { name = CV("ABGP_PRIORITY_SYNC"), priority = "NORMAL" },
    -- priorities: table

    BOSS_LOOT = { name = CV("ABGP_BOSS_LOOT"), priority = "ALERT" },
    -- source: string
    -- items: table

    -- NOTE: these aren't versioned so they can continue to function across major changes.
    VERSION_REQUEST = { name = "ABGP_VERSION_REQUEST", priority = "NORMAL" },
    -- reset: bool or nil
    VERSION_RESPONSE = { name = "ABGP_VERSION_RESPONSE", priority = "NORMAL" },
    -- no payload
};

ABGP.InternalEvents = {
    ACTIVE_PLAYERS_REFRESHED = "ABGP_ACTIVE_PLAYERS_REFRESHED",
};

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
    self:LogVerbose("Sending comm (len:%d, priority:%s): %s", strlen(payload), priority, payload);

    if priority == "INSTANT" then
        -- The \004 prefix is AceComm's "escape" control. Prepend it so that the
        -- payload is properly interpreted when received.
        _G.C_ChatInfo.SendAddonMessage("ABGP", "\004" .. payload, distribution, target);
    else
        self:SendCommMessage("ABGP", payload, distribution, target, priority);
    end
end

function ABGP:OnCommReceived(prefix, payload, distribution, sender)
    local compressed = AddonEncodeTable:Decode(payload);
    local serialized = LibCompress:Decompress(compressed);
    local _, data = AceSerializer:Deserialize(serialized);

    if self.Verbose then
        self:LogVerbose("COMM >>>");
        self:LogVerbose("Data from %s via %s:", sender, distribution);
        for k, v in pairs(data) do
            if type(v) == "table" then v = table.concat(v, ", "); end
            self:LogVerbose("%s: %s", k, tostring(v));
        end
        self:LogVerbose("<<< COMM");
    end

    self:SendMessage(data.type, data, distribution, sender);
end
