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
    if diceRollTypes[msg[1]] then diceRollTypes[msg[1]](advantage, msg) else diceRollTypes['roll'](advantage, msg); end
end

SlashCmdList["ROLLEX"] = rollex

local function findplayer(player)
    --TODO: implement this, a function that will first check for an exact match, then a match ignoring any accents,
    --    then a partial match, ignoring accents. prioritising the start of a name. LATER; implement the ability to
    --    save shorthands against players

    -- TODO: also support IDs, either a didgit (position in raid) and a digit:digit (party number, position in party)
    --    in order to make this process as painless for users as possible.

    -- for now, we assume player is a %t targetted player, and therefore just get realm name.
    return DMRP.Utils.getPlayerName(player);
end

local function registerDC(command, DCs)
    local args = spreadSlashArgs(command);

    local DC = args[1];
    local action = args[2];
    if not action then action, player = player, nil end -- we shuffle along the player arg as it's optional while action is not.
    local range = {min = nil, max= nil, nat = nil , action = nil, target = nil}
    local natural = string.match(DC, "nat([+-]?[0-9]+)")
    local lt = string.match(DC, "<([+-]?[0-9]+)")
    local lt = string.match(DC, "<=([+-]?[0-9]+)") + 1
    local gt = string.match(DC, ">([+-]?[0-9]+)")
    local gt = string.match(DC, ">=([+-]?[0-9]+)") - 1
    local rangemin, rangemax = string.match(DC, "([+-]?[0-9]+)-([+-]?[0-9]+)")
    if natural then
        range.nat = natural
    elseif lt then
        range.min = lt
    elseif gt then
        range.max = gt
    elseif rangemin and rangemax then
        range.min = rangemin
        range.max = rangemax
    end

    local hp = string.match(args[2], "([+-]?[0-9]+)hp")
    local dam = string.match(args[2], "([+-]?[0-9]+)dam")
    local dam = string.match(args[2], "([+-]?[0-9]+)dmg")

    if hp then
        action = {hp = hp}
    elseif dam then
        action = {dam = dam }
    else
        action = {perception = args[2]}
    end

    if args[3] then
        range.target = {};
        for i,player in ipairs(args) do
            if i >2 then
                range.target.insert = findplayer(player);
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

local function dm(msg, editBox)
    -- handles generic DM actions


    for command in msg:gmatch('%[[^%]]+%]') do
        local shouldRemove = false;
        local commandStripped = command:sub(2,-2);
        local commandProcessing = commandStripped;
        local dcs = {};
        if string.lower(commandProcessing):sub(1,3) == "dc" then
            shouldRemove = true
            dcs.insert( registerDC(commandProcessing:sub(3,-1), dcs))
        end


        log(commandStripped);
        log("removing", shouldRemove, DMRP.Utils.escapePattern(command));

        if shouldRemove then
            msg = msg:gsub(DMRP.Utils.escapePattern(command).." *", '')
        end
    end




    DMRP.Dice.resetDice();

    DMRP.Chat.chatHook(msg, "RAID_WARNING")
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
