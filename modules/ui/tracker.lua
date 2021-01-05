--#======================#
--|Created By: Saelorable|
--|Date: 04/11/2020      |
--|Time: 20:08           |
--#======================#


DMRP.UI = DMRP.UI or {}
local Utils = DMRP.Utils;
local log = Utils.log;

local lwin = LibStub("LibWindow-1.1")

local statusBars = {}
local framePool = {};
local function createStatusBar(tracker)

    if statusBars[tracker] then return end
    local recycle = false;
    local frame;
    if #framePool > 0 then
        recycle = true
        frame = framePool[#framePool]
        table.remove(framePool)
    else
        frame = CreateFrame("Frame", nil, UIParent)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame.clickFrame = CreateFrame("Button", nil, frame)
        frame.clickFrame.statusbar = CreateFrame("StatusBar", nil, frame.clickFrame)
        frame.clickFrame.statusbar.value = frame.clickFrame.statusbar:CreateFontString(nil, "OVERLAY")
        frame.clickFrame.statusbar.bg = frame.clickFrame.statusbar:CreateTexture(nil, "BACKGROUND")
        frame.gripL = CreateFrame("frame", nil, frame)
        frame.gripR = CreateFrame("frame", nil, frame)
        frame.gripL.bg = frame.gripL:CreateTexture(nil, "BACKGROUND")
        frame.gripR.bg = frame.gripR:CreateTexture(nil, "BACKGROUND")


    end


    lwin.RegisterConfig(frame, DMRP.Tracker.checkTracker(tracker).pos)
    lwin.RestorePosition(frame)
    lwin.MakeDraggable(frame)

    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.gripL.bg:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    frame.gripL.bg:SetVertexColor(0,0,0,0.75)
    frame.gripL:SetPoint("LEFT", frame, "LEFT")
    frame.gripR.bg:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    frame.gripR.bg:SetVertexColor(0,0,0,0.75)
    frame.gripR:SetPoint("RIGHT", frame, "RIGHT")
    frame.gripL.bg:SetAllPoints(frame.gripL)
    frame.gripR.bg:SetAllPoints(frame.gripR)

    frame.clickFrame:SetPoint("CENTER", frame, "CENTER")
    frame.clickFrame:EnableMouse(true)
    frame.clickFrame:RegisterForClicks("AnyUp")
    frame.clickFrame:SetScript("OnClick", function (self, button, down)
        if button=="LeftButton" then
            DMRP.Tracker.modifyTracker(tracker, -1, IsShiftKeyDown(), false)
        elseif button=="RightButton" then
            DMRP.Tracker.modifyTracker(tracker, 1, IsShiftKeyDown(), false)
        end

    end);

    frame.clickFrame.statusbar:SetPoint("CENTER", frame.clickFrame, "CENTER")
    frame.clickFrame.statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    frame.clickFrame.statusbar:GetStatusBarTexture():SetHorizTile(false)
    frame.clickFrame.statusbar:GetStatusBarTexture():SetVertTile(false)

    frame.clickFrame.statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    frame.clickFrame.statusbar.bg:SetAllPoints(true)

    frame.clickFrame.statusbar.value:SetPoint("CENTER", frame.clickFrame.statusbar, "CENTER")
    frame.clickFrame.statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    frame.clickFrame.statusbar.value:SetJustifyH("CENTER")
    frame.clickFrame.statusbar.value:SetShadowOffset(1, -1)

    statusBars[tracker] = frame
    DMRP.UI.updateStatusBar(tracker)
    frame:Show()
end
DMRP.UI.createStatusBar = createStatusBar

local function updateStatusBar(tracker)
    local currentTracker = DMRP.Tracker.checkTracker(tracker)
    local statusbar = statusBars[tracker];
    if not statusbar then return end
    local shieldColour = '|cFFFFFFFF'
    if currentTracker.shieldColour then
        shieldColour = string.format("|c%.2x%.2x%.2x%.2x", currentTracker.shieldColour[4]*255, currentTracker.shieldColour[1]*255, currentTracker.shieldColour[2]*255, currentTracker.shieldColour[3]*255)
    end

    local statusbarText = currentTracker.current.."/"..currentTracker.max..((currentTracker.shieldMax and currentTracker.shield > 0 and ' '..shieldColour..'(+'..currentTracker.shield..")|r") or '')
    statusbar.clickFrame.statusbar:SetMinMaxValues(0, currentTracker.max)
    statusbar.clickFrame.statusbar.value:SetText(statusbarText)
    statusbar.clickFrame.statusbar.bg:SetVertexColor(unpack(currentTracker.backColour))
    statusbar.clickFrame.statusbar:SetStatusBarColor(unpack(currentTracker.barColour))
    statusbar.clickFrame.statusbar.value:SetTextColor(unpack(currentTracker.amountColour))

    local width = currentTracker.size.width
    local height = currentTracker.size.height
    local movable = currentTracker.size.movable
    local innerWidth = width/3
    if 3*height < width then
        innerWidth = width - 2*height
    end
    if not movable then
        innerWidth = width
        statusbar.gripL:Hide()
        statusbar.gripR:Hide()
    else
        statusbar.gripL:Show()
        statusbar.gripR:Show()
    end;

    statusbar:SetWidth(width)
    statusbar:SetHeight(height)
    statusbar.gripL:SetWidth((width - innerWidth)/2)
    statusbar.gripL:SetHeight(height)
    statusbar.gripR:SetWidth((width - innerWidth)/2)
    statusbar.gripR:SetHeight(height)
    statusbar.clickFrame:SetWidth(innerWidth)
    statusbar.clickFrame:SetHeight(height)
    statusbar.clickFrame.statusbar:SetWidth(innerWidth)
    statusbar.clickFrame.statusbar:SetHeight(height)
    statusbar.gripL.bg:SetAllPoints(statusbar.gripL)
    statusbar.gripR.bg:SetAllPoints(statusbar.gripR)

    statusbar.clickFrame.statusbar:SetValue(currentTracker.current)

    lwin.RegisterConfig(statusbar, currentTracker.pos)
    lwin.RestorePosition(statusbar)
    lwin.MakeDraggable(statusbar)

end

DMRP.UI.updateStatusBar = updateStatusBar

local function statusBarExists(tracker)
    local statusbar = statusBars[tracker];
    return statusbar and true or false
end
DMRP.UI.statusBarExists = statusBarExists


local function deleteStatusBar(tracker)
    if not statusBarExists(tracker) then return; end;
    statusBars[tracker]:Hide()

    table.insert(framePool, statusBars[tracker])

    statusBars[tracker] = nil
end
DMRP.UI.deleteStatusBar = deleteStatusBar