local AceSerializer = LibStub("AceSerializer-3.0");
local LibCompress = LibStub("LibCompress");
local AddonEncodeTable = LibCompress:GetAddonEncodeTable();

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
    ITEM_REQUEST = CV("ABGP_ITEM_REQUEST"),
    -- itemLink: item link string
    -- requestType: string from ABGP.RequestTypes
    -- notes: string or nil
    -- equipped: array of item link strings

    ITEM_PASS = CV("ABGP_ITEM_PASS"),
    -- itemLink: item link string

    ITEM_DISTRIBUTION_OPENED = CV("ABGP_ITEM_DISTRIBUTION_OPENED"),
    -- itemLink: item link string
    -- value: table from ABGP:GetItemValue()
    -- requestType: string from ABGP.RequestTypes

    ITEM_DISTRIBUTION_CLOSED = CV("ABGP_ITEM_DISTRIBUTION_CLOSED"),
    -- itemLink: item link string

    ITEM_DISTRIBUTION_AWARDED = CV("ABGP_ITEM_DISTRIBUTION_AWARDED"),
    -- itemLink: item link string
    -- player: string
    -- cost: number
    -- roll: number
    -- count: number
    -- requestType: string from ABGP.RequestTypes
    -- override: string

    ITEM_DISTRIBUTION_CHECK = CV("ABGP_ITEM_DISTRIBUTION_CHECK"),
    -- itemLink: optional item link string

    ITEM_DISTRIBUTION_CHECK_RESPONSE = CV("ABGP_ITEM_DISTRIBUTION_CHECK_RESPONSE"),
    -- itemLink: item link string
    -- valid: bool

    ITEM_DISTRIBUTION_TRASHED = CV("ABGP_ITEM_DISTRIBUTION_TRASHED"),
    -- itemLink: item link string

    ITEM_ROLLED = CV("ABGP_ITEM_ROLLED"),
    -- itemLink: item link string
    -- roll: number

    OFFICER_NOTES_UPDATED = CV("ABGP_OFFICER_NOTES_UPDATED"),
    -- no payload

    -- NOTE: these aren't versioned so they can continue to function across major changes.
    VERSION_REQUEST = "ABGP_VERSION_REQUEST",
    -- reset: bool or nil
    VERSION_RESPONSE = "ABGP_VERSION_RESPONSE",
    -- no payload
};

ABGP.InternalEvents = {
    ACTIVE_PLAYERS_REFRESHED = "ABGP_ACTIVE_PLAYERS_REFRESHED",
};

function ABGP:SendComm(type, data, distribution, target)
    data.type = type;
    data.version = self:GetVersion();

    local serialized = AceSerializer:Serialize(data);
    local compressed = LibCompress:Compress(serialized);
    local payload = AddonEncodeTable:Encode(compressed);

    if distribution == "BROADCAST" then
        distribution, target = GetBroadcastChannel();
    end

    if distribution then
        self:SendCommMessage("ABGP", payload, distribution, target);
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
