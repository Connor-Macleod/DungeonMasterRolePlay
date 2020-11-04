--#======================#
--|Created By: Saelorable|
--|Date: 25/10/2020      |
--|Time: 11:49           |
--#======================#

local Utils = DMRP.Utils
local Dice = DMRP.Dice
local log = Utils.log;
local config = Utils.config
log("init slash");


SLASH_DMRP1, SLASH_DMRP2 = '/dmrp', '/dungeonmasteroleplay'
SLASH_ROLLEX1, SLASH_ROLLEX2 = '/!roll', '/roll!'
SLASH_DM1 = '/dm'
SLASH_DC1 = '/dc'
--SLASH_PERCEPTION1 = '/perception'
SLASH_EVENT1, SLASH_EVENT2 = '/event', '/ev'



local function spreadSlashArgs(text)
    local argList, inQuotes, counter, firstQuotes = {}, false, 1, false;
    log("text:", text)
    for i in string.gmatch(text, "%S+") do
        if string.match(i, [=[^["'%[]]=]) then inQuotes = true; firstQuotes = true end
        log("Loopstate:", i, inQuotes)
        if not inQuotes then
            argList[counter] = i
            counter = counter + 1
        else
            if firstQuotes then
                argList[counter] = i
            else
                argList[counter] = argList[counter] .. ' ' .. i
            end
        end
        firstQuotes = false;
        if string.match(i, [=[["'%]]$]=]) then inQuotes = false end
    end
    log("argList:", argList)
    return argList;
end

DMRP.Dice.spreadSlashArgs = spreadSlashArgs

DMRP.Dice.diceRollTypes = {
    freeform = function(advantage)
        DMRP.Dice.doDiceRoll();
        if (advantage) then
            DMRP.Dice.doDiceRoll();
            log('rolling with advantage')
        else
            log('rolling')
        end
    end,
    dc = function(advantage)
        DMRP.Dice.doDiceRoll();
        if (advantage) then
            DMRP.Dice.doDiceRoll();
            log('rolling with advantage')
        else
            log('rolling')
        end
    end,
    heal = function(advantage)
        DMRP.Dice.doDiceRoll(4);
        log('heal advantage', advantage)
        if (advantage) then
            DMRP.Dice.doDiceRoll(4);
            log('rolling with advantage')
        else
            log('rolling')
        end
    end,
    roll = function(advantage, prams)
        local i = 1;
        if prams[i] == 'advantage' or prams[i] == 'adv' then i = i + 1 end
        local size = prams[i] or 20; i = i + 1
        local modifier = prams[i] or 0

        log('advantage', advantage)
        DMRP.Dice.doDiceRoll(size, 1, modifier);
        if (advantage) then
            DMRP.Dice.doDiceRoll(size, 1, modifier);
            log('rolling with advantage')
        else
            log('rolling')
        end
    end
}
local function rollex(msg, editBox)
    log("rollingDie")
    -- does rolls
    if type(msg) == 'string' then
        msg = spreadSlashArgs(msg)
    end
    log("message:", msg)
    if not msg[1] then
        log("setting rolltype to freeform")
        --if there's a DC awaiting, we do a dc roll
        --msg[1] = "dc"
        --otherwise we default do a freeform roll
        msg[1] = "freeform"
    end
    local advantage = false;
    if msg[1] == 'advantage' or msg[2] == 'advantage' or msg[1] == 'adv' or msg[2] == 'adv' then
        advantage = true
        Dice.diceState('advantage', 2)
    end
    if DMRP.Dice.diceRollTypes[msg[1]] then DMRP.Dice.diceRollTypes[msg[1]](advantage, msg) else DMRP.Dice.diceRollTypes['roll'](advantage, msg); end
end

SlashCmdList["ROLLEX"] = rollex

local function stripChars(str)
    str = string.lower(str);
    local tableAccents = {}
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["œ"] = "oe"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["ÿ"] = "y"
    local normalizedString = ''

    for strChar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
        if tableAccents[strChar] ~= nil then
            normalizedString = normalizedString .. tableAccents[strChar]
        else
            normalizedString = normalizedString .. strChar
        end
    end
    return normalizedString
end

local function findplayer(player)
    --TODO: implement this, a function that will first check for an exact match, then a match ignoring any accents,
    --    then a partial match, ignoring accents. prioritising the start of a name. LATER; implement the ability to
    --    save shorthands against players

    -- for now, we assume player is a %t targetted player, and therefore just get realm name.
    if (UnitInRaid(player)) then
        return DMRP.Utils.getPlayerName(player);
    end


    for i = 1, GetNumRaidMembers() do
        local playerName = GetRaidRosterInfo(i);
        if string.match(playerName, player) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end


    for i = 1, GetNumRaidMembers() do
        local playerName = GetRaidRosterInfo(i);
        if stripChars(playerName) == stripChars(player) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end


    for i = 1, GetNumRaidMembers() do
        local playerName = GetRaidRosterInfo(i);
        if string.match("^" .. stripChars(playerName), stripChars(player)) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end

    for i = 1, GetNumRaidMembers() do
        local playerName = GetRaidRosterInfo(i);
        if string.match(stripChars(playerName), stripChars(player)) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end

    return nil
end

local function registerDC(command, DCs)
    local args = spreadSlashArgs(command);

    local DC = args[1];
    local action = args[2];
    if not action then action, player = player, nil end -- we shuffle along the player arg as it's optional while action is not.
    local range = { min = nil, max = nil, nat = nil, action = nil, target = nil }
    local natural = string.match(DC, "nat([+-]?[0-9]+)")
    local lt = string.match(DC, "<=([+-]?[0-9]+)")
    local lt = string.match(DC, "<([+-]?[0-9]+)") and string.match(DC, "<([+-]?[0-9]+)") - 1 or lt
    local gt = string.match(DC, ">=([+-]?[0-9]+)")
    local gt = string.match(DC, ">([+-]?[0-9]+)") and string.match(DC, ">([+-]?[0-9]+)") + 1 or gt
    local rangemin, rangemax = string.match(DC, "([+-]?[0-9]+)-([+-]?[0-9]+)")
    if natural then
        range.nat = tonumber(natural)
    elseif lt then
        range.max = tonumber(lt)
    elseif gt then
        range.min = tonumber(gt)
    elseif rangemin and rangemax then
        range.min = tonumber(rangemin)
        range.max = tonumber(rangemax)
    end

    local hp = string.match(args[2], "([+-]?[0-9]+)hp")
    local dam = string.match(args[2], "([+-]?[0-9]+)dam")
    local dam = string.match(args[2], "([+-]?[0-9]+)dmg") or dam
    local kill = string.match(args[2], "([+-]?[0-9]+)kill")
    local kill = string.match(args[2], "([+-]?[0-9]+)kills") or kill

    log("action: ",hp, dam, kill, args[2])

    if hp then
        range.action = { hp = tonumber(hp) }
    elseif dam then
        range.action = { dam = tonumber(dam) }
    elseif kill then
        range.action = { kill = tonumber(kill) }
    else
        range.action = { perception = args[2] }
    end

    if args[3] then
        range.target = {};
        for i, player in ipairs(args) do
            if i > 2 then
                local targetPlayer = findplayer(player)
                if targetPlayer then
                    range.target.insert = targetPlayer;
                end
            end
        end
    end
    -- DC nat1 -2hp
    -- DC <3 -1hp
    -- DC >5 1dmg
    -- DC >8 2dmg
    -- DC >12 3dmg
    -- DC >=20 Kill

    -- DC <8 "Nothing seems strange"

    return range;
end


local function event(msg, editBox)
    -- handles player actions
end

SlashCmdList["EVENT"] = event

DMRP.Dice.dcs = {};
local function dm(msg, editBox)
    -- handles generic DM actions

    DMRP.Dice.resetDice();

    for command in msg:gmatch('%[[^%]]+%]') do
        log("matched command", command)
        local shouldRemove = false;
        local commandStripped = command:sub(2, -2);
        local commandProcessing = commandStripped;
    log(string.lower(commandProcessing):sub(1, 1))
        if string.lower(commandProcessing):sub(1, 2) == "dc" then
            log("matched DC", commandProcessing)
            shouldRemove = true
            table.insert(DMRP.Dice.dcs, registerDC(commandProcessing:sub(3, -1), DMRP.Dice.dcs))
        end


        log("removing", shouldRemove, DMRP.Utils.escapePattern(command));

        if shouldRemove then
            msg = msg:gsub(DMRP.Utils.escapePattern(command) .. " *", '')
        end
    end

    DMRP.Chat.splitAndSendChat(msg, "RAID_WARNING");

    log('dcs', DMRP.Dice.dcs)
    local DCsMessages = {'Dice Check: '};
    for i,dc in ipairs(DMRP.Dice.dcs) do
        if not dc.action.perception and ((dc.action.dam and dc.action.dam ~= 0) or (dc.action.kill and dc.action.kill ~=0) or (dc.action.hp and dc.action.hp ~=0)) then
            local DCsMessage = "{"
            if dc.min and dc.max then
                DCsMessage = DCsMessage..'if you roll between '..dc.min..' and '..dc.max..', '
            elseif dc.min then
                DCsMessage = DCsMessage..'if you roll '..dc.min..' or above, '
            elseif dc.max then
                DCsMessage = DCsMessage..'if you roll '..dc.max..' or below, '
            end
            if dc.action.dam and dc.action.dam > 0 then
                DCsMessage = DCsMessage..'deal '..dc.action.dam..' damage'
            elseif dc.action.dam and dc.action.dam < 0 then
                DCsMessage = DCsMessage..'your opponent restores '..-dc.action.dam..' health'
            elseif dc.action.hp and dc.action.hp > 0 then
                DCsMessage = DCsMessage..'you restore '..dc.action.hp..' health'
            elseif dc.action.hp and dc.action.hp < 0 then
                DCsMessage = DCsMessage..'you take '..-dc.action.hp..' damage'
            elseif dc.action.kill and dc.action.kill > 0 then
                DCsMessage = DCsMessage..'you kill '..dc.action.hp..' enemies'
            end
            DCsMessage = DCsMessage .. "}"
            table.insert(DCsMessages, DCsMessage);
        end
    end
    for i,dc in ipairs(DMRP.Dice.dcs) do
        if dc.action.perception and not DCsMessages[2] then
            table.insert(DCsMessages, "perception roll!");
        end
    end


    DMRP.Chat.splitAndSendChat(DCsMessages, 'RAID_WARNING')

end

SlashCmdList["DM"] = dm
--[[
local function perception(msg, editBox)
    -- handles perception rolls (not sure about this one, may kill off)
end
SlashCmdList["PERCEPTION"] = perception
--]]

SlashCmdList["DMRP"] = function(msg, editBox)
    -- handles all actions
end
