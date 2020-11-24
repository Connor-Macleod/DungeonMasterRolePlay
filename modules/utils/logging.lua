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

local function expandTable(table)
    local stringValue = '';
    if isArray(table) then stringValue = '['; else stringValue = '{'; end
    for i,v in pairs(table) do
        if type(i) == "string" then i= "\""..i.."\"" end
        if type(v) == "string" then v= "\""..v.."\"" end
        if type(i) == "userdata" then i= "userdata" end
        if type(v) == "userdata" then v= "userdata" end
        if type(v) == "table" then v = expandTable(v) end
        if type(i) == "table" then i = expandTable(i) end
        if type(v) == "function" then v = "function()" end
        if type(v) == "boolean" then v = v and "true" or "false" end
        if type(v) == "null" then v = 'null' end
        stringValue = stringValue .. i .. ": " .. v.. ", ";
    end
    if stringValue:len()>2 then
        stringValue = stringValue:sub(1,-3);
    end
    if isArray(table) then stringValue = stringValue.. ']' else stringValue = stringValue.. '}' end
    return stringValue;
end

local function log(...)
    if true and (not DMRP.Utils.config or not DMRP.Utils.config.debug) then return end
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
    print("[DMRP:DEBUG]"..printString);
end
DMRP.Utils.log = log;




