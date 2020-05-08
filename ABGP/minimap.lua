local _G = _G;
local ABGP = _G.ABGP;
local LibDataBroker = _G.LibStub("LibDataBroker-1.1");
local LibDBIcon = _G.LibStub("LibDBIcon-1.0");

local table = table;

local minimapIcon;

function ABGP:InitMinimapIcon()
    local obj = LibDataBroker:NewDataObject("ABGP", {
        icon = "Interface\\AddOns\\ABGP\\Assets\\lobster.tga",
        OnClick = function(frame, button) self:OnIconClick(frame, button); end,
        OnTooltipShow = function(tooltip) self:OnIconTooltip(tooltip); end,
    });
    LibDBIcon.RegisterCallback(self, "LibDBIcon_IconCreated", "OnIconCreated");
    LibDBIcon:Register("ABGP", obj, self.db.char.minimap);
end

function ABGP:RefreshMinimapIcon()
    LibDBIcon:Refresh("ABGP", self.db.char.minimap);
end

function ABGP:OnIconCreated(event, frame, name)
    if name ~= "ABGP" then return; end

    minimapIcon = frame;
    -- frame:SetScale(5);
    frame.icon:SetSize(18, 18);
end

function ABGP:MinimapOnDistOpened(data, distribution, sender)
    if not minimapIcon then return; end

    minimapIcon[self:HasActiveItems() and "LockHighlight" or "UnlockHighlight"](minimapIcon);
end

function ABGP:MinimapOnDistClosed(data, distribution, sender)
    if not minimapIcon then return; end

    minimapIcon[self:HasActiveItems() and "LockHighlight" or "UnlockHighlight"](minimapIcon);
end

function ABGP:OnIconClick(frame, button)
    if button == "LeftButton" then
        self:ShowMainWindow();
    elseif button == "RightButton" then
        local context = {
            {
                text = "Show Window",
                func = function() self:ShowMainWindow(); end,
                notCheckable = true
            },
            {
                text = "Show Options",
                func = function() self:ShowOptionsWindow(); end,
                notCheckable = true
            },
        };
        if self:IsPrivileged() then
            table.insert(context, {
                text = self:IsRaidInProgress() and "Manage Raid" or "Start Raid",
                func = function() self:ShowRaidWindow(); end,
                notCheckable = true
            });
        end
        if self:HasActiveItems() then
            table.insert(context, {
                text = "Show Open Items",
                func = function() self:ShowItemRequests(); end,
                notCheckable = true
            });
        end
        table.insert(context, { text = "Cancel", notCheckable = true });
        self:ShowContextMenu(context, frame);
    end
end

function ABGP:OnIconTooltip(tooltip)
    local header = ("%s v%s"):format(self:ColorizeText("ABGP"), self:GetVersion());
    tooltip:AddLine(header, 1, 1, 1);
    tooltip:AddLine("Left-click to show the main window.");
    tooltip:AddLine("Right-click for more options.");
end
