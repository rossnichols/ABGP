local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local IsInGuild = IsInGuild;
local CreateFrame = CreateFrame;
local UnitName = UnitName;
local date = date;
local time = time;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;

local activeWindow;
local widths = { 110, 100, 70, 70, 70 };
local ignoredClasses = {};

local function PopulateUI()
    if not activeWindow then return; end
    local container = activeWindow:GetUserData("priorities");
    container:ReleaseChildren();

    local priority = _G.ABGP_Data[ABGP.CurrentPhase].priority;
    for i, data in ipairs(priority) do
        if not ignoredClasses[data.class] then
            local elt = AceGUI:Create("ABGP_Player");
            elt:SetFullWidth(true);
            elt:SetData(data);
            elt:SetWidths(widths);
            elt:ShowBackground((i % 2) == 0);
            elt:SetHeight(20);
            if data.player == UnitName("player") then
                elt.frame:RequestHighlight(true);
            end

            container:AddChild(elt);
        end
    end
end

function ABGP:RefreshUI()
    PopulateUI();
end

function ABGP:CreateMainWindow()
    local window = AceGUI:Create("Window");
    window:SetTitle(("%s Player Priority"):format(self:ColorizeText("ABGP")));
    window:SetLayout("Flow");
    self:BeginWindowManagement(window, "priority", {
        version = 1,
        defaultWidth = 480,
        minWidth = 480,
        maxWidth = 480,
        defaultHeight = 500,
        minHeight = 300,
        maxHeight = 700
    });
    ABGP:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local phases = {
        [ABGP.Phases.p1] = "Phase 1/2",
        [ABGP.Phases.p3] = "Phase 3",
    };
    local phaseSelector = AceGUI:Create("Dropdown");
    phaseSelector:SetWidth(110);
    phaseSelector:SetList(phases);
    phaseSelector:SetValue(ABGP.CurrentPhase);
    phaseSelector:SetCallback("OnValueChanged", function(widget, event, value)
        ABGP.CurrentPhase = value;
        PopulateUI();
    end);
    window:AddChild(phaseSelector);

    local classSelector = AceGUI:Create("Dropdown");
    classSelector:SetWidth(110);
    local classes = {
        "DRUID",
        "HUNTER",
        "MAGE",
        "PALADIN",
        "PRIEST",
        "ROGUE",
        "WARLOCK",
        "WARRIOR",
        "ALL",
    };
    classSelector:SetList({
        DRUID = "Druid",
        HUNTER = "Hunter",
        MAGE = "Mage",
        PALADIN = "Paladin",
        PRIEST = "Priest",
        ROGUE = "Rogue",
        WARLOCK = "Warlock",
        WARRIOR = "Warrior",
        ALL = "All",
    }, classes);
    classSelector:SetMultiselect(true);

    local function showingAll()
        local hasIgnoredClass = false;
        for _, state in pairs(ignoredClasses) do
            if state then
                hasIgnoredClass = true;
                break;
            end
        end

        return not hasIgnoredClass;
    end
    local function showingNone()
        local hasShownClass = false;
        for _, class in ipairs(classes) do
            if class ~= "ALL" and not ignoredClasses[class] then
                hasShownClass = true;
                break;
            end
        end

        return not hasShownClass;
    end
    local function updateCheckboxes(widget)
        local all = showingAll();
        for _, class in ipairs(classes) do
            if class == "ALL" then
                widget:SetItemValue(class, all);
            else
                widget:SetItemValue(class, not all and not ignoredClasses[class]);
            end
        end
    end
    local function valueChangedCallback(widget, event, class, checked)
        if class == "ALL" then
            if checked then
                ignoredClasses = {};
            end
        else
            if checked then
                if showingAll() then
                    ignoredClasses = {
                        DRUID = true,
                        HUNTER = true,
                        MAGE = true,
                        PALADIN = true,
                        PRIEST = true,
                        ROGUE = true,
                        WARLOCK = true,
                        WARRIOR = true,
                    };
                end
            end
            ignoredClasses[class] = not checked;
            if showingNone() then
                ignoredClasses = {};
            end
        end

        widget:SetCallback("OnValueChanged", nil);
        updateCheckboxes(widget);
        widget:SetCallback("OnValueChanged", valueChangedCallback);
        PopulateUI();
    end
    updateCheckboxes(classSelector);
    classSelector:SetCallback("OnValueChanged", valueChangedCallback);
    classSelector:SetText("Classes");
    window:AddChild(classSelector);

    local scrollContainer = AceGUI:Create("InlineGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    window:AddChild(scrollContainer);

    local columns = { "Player", "Rank", "EP", "GP", "Priority", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights });
    scrollContainer:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("Label");
        desc:SetText(columns[i] .. "\n");
        desc:SetFontObject(_G.GameFontHighlight);
        header:AddChild(desc);
    end

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("priorities", scroll);

    return window;
end

function ABGP:ShowMainWindow()
    if activeWindow then return; end

    activeWindow = self:CreateMainWindow();
    PopulateUI();
end
