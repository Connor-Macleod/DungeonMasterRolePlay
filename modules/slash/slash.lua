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
SLASH_PERCEPTION1 = '/perception'
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

local function event(msg, editBox)
    -- handles player actions
end

SlashCmdList["EVENT"] = event

local function dm(msg, editBox)
    -- handles generic DM actions

end

SlashCmdList["DM"] = dm

local function perception(msg, editBox)
    -- handles perception rolls (not sure about this one, may kill off
end

SlashCmdList["PERCEPTION"] = perception

SlashCmdList["DMRP"] = function(msg, editBox)
    -- handles all actions
end
