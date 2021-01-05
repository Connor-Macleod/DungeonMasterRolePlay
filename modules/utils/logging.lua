--#======================#
--|Created By: Saelorable|
--|Date: 24/10/2020      |
--|Time: 14:07           |
--#======================#

DMRP = DMRP or {}

DMRP.Utils = DMRP.Utils or {};

local function isArray(tbl)
    local numKeys = 0
    for _, _ in pairs(tbl) do
        numKeys = numKeys+1
    end
    local numIndices = 0
    for _, _ in ipairs(tbl) do
        numIndices = numIndices+1
    end
    return numKeys == numIndices
end

local function expandTable(table, indent)
    indent = indent or 0
    local stringValue = '\n';
    for i=0, indent do
        stringValue = stringValue.." "
    end
    if isArray(table) then stringValue = '[\n'; else stringValue = '{\n'; end
    indent = indent + 4
    for i=0, indent do
        stringValue = stringValue.." "
    end
    for i,v in pairs(table) do
        if type(i) == "string" then i= "\""..i.."\"" end
        if type(v) == "string" then v= "\""..v.."\"" end
        if type(i) == "userdata" then i= "userdata" end
        if type(v) == "userdata" then v= "userdata" end
        if type(v) == "table" then v = expandTable(v, indent+4) end
        if type(i) == "table" then i = expandTable(i, indent+4) end
        if type(v) == "function" then v = "function()" end
        if type(v) == "boolean" then v = v and "true" or "false" end
        if type(v) == "null" then v = 'null' end
        stringValue = stringValue .. i .. ": " .. v.. ",\n";
        for i=0, indent do
            stringValue = stringValue.." "
        end
    end
    if stringValue:len()>2 then
        stringValue = stringValue:sub(1,-3);
    end
    if isArray(table) then stringValue = stringValue.. ']' else stringValue = stringValue.. '}' end
    return stringValue;
end


local AceGUI = LibStub("AceGUI-3.0")
local loggingFrame
local text
local debugText = ''
local function updateDebugFrame()
    if loggingFrame then
        text:SetText(debugText)
    else
        loggingFrame = AceGUI:Create("Frame")
        loggingFrame:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            loggingFrame = nil
        end)
        loggingFrame:SetTitle("debug")
        text = AceGUI:Create("MultiLineEditBox")
        text:SetText(debugText)
        text:SetFullWidth(true)
        text:DisableButton(true)
        text:SetNumLines(29)
        loggingFrame:AddChild(text)
    end
end


local function log(...)
    local printString = '';
    for i,v in pairs({...}) do
        local addString = ''
        if type(v)=='table'then
            addString = expandTable(v)
        elseif type(v)=='function' then
            addString = 'function('..tostring(v)..')';
        else
            addString = tostring(v)
        end
        printString = printString .. addString .. " - "
    end
    --print("[DMRP:DEBUG]"..printString);

    debugText = debugText..'Debug:'..printString..'\n'

    if #debugText > 5000 then
        debugText = debugText:sub(#debugText - 5000)
    end
    if DMRP.Utils.config and DMRP.Utils.config.global.debug then
        updateDebugFrame()
    end
end
DMRP.Utils.log = log;




