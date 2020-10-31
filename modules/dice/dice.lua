--#======================#
--|Created By: Saelorable|
--|Date: 24/10/2020      |
--|Time: 12:39           |
--#======================#

DMRP.Dice = DMRP.Dice or {};
local chatMessage = DMRP.Chat.fakeChatMessage;

local libSerializer = LibStub:GetLibrary("AceSerializer-3.0");
local CreateFrame = CreateFrame;
local Utils = DMRP.Utils;
local config, log = Utils.config, Utils.log;

local currentDiceState = 'advantage';
local advantageRoll = { result = 0 }
local diceAdvantage = 1;

log("init dice");

local lastRolls = {};
local function reportDiceRolls(author, rollResult, rollSize, modifier)
    local playerName = Utils.getPlayerName(author)
    if currentDiceState == 'advantage' and playerName == Utils.getPlayerName() then
        if tonumber(rollResult) > advantageRoll.result then
            advantageRoll = {result = tonumber(rollResult), diceSize = rollSize, modifier = modifier, diceCount = 1}
        end
        diceAdvantage = diceAdvantage - 1;
        if diceAdvantage < 1 then
            lastRolls[playerName] = advantageRoll;
            diceAdvantage = 1;
            currentDiceState = 'individual'
            chatMessage("rolls "..advantageRoll.result.." on a d"..advantageRoll.diceSize .. (advantageRoll.modifier == 0 and "" or ((advantageRoll.modifier > 0 and "+" or "-")..advantageRoll.modifier)).." with advantage.", "EMOTE",author)
            advantageRoll = {result= 0}
        end
    else
        lastRolls[playerName] = {result = rollResult, diceSize = rollSize, modifier = modifier, diceCount = 1}
        chatMessage("rolls "..rollResult.." on a d"..rollSize .. (modifier == 0 and "" or ((modifier > 0 and "+" or "-")..modifier)), "EMOTE", author)
    end
end


local f = CreateFrame("frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
f:SetScript("OnEvent", function(self, event, message, addonContent,...)
    if event == "CHAT_MSG_SYSTEM" then
        log(event, message, addonContent,...)
        local author, rollResult, rollMin, rollMax = string.match(message, "(.+) rolls (%d+) %((%d+)-(%d+)%)")
        if author then
            local modifier = rollMin - 1
            local rollSize = rollMax - modifier
            reportDiceRolls(author, rollResult, rollSize, modifier);
        end
    elseif event == "CHAT_MSG_ADDON" then
        if message == 'TRP3.3' then
            log('unlogged addon', event, message, addonContent,...)
            local _, deserializedContent = libSerializer:Deserialize(addonContent)
            log('unlogged addon', event, message, deserializedContent,...)
        end


    end
end)



local function resetDice()
    lastRolls = {};
end
DMRP.Dice.resetDice = resetDice;

local function doDiceRoll(size, count, modifier)
    size = tonumber(size) or 20;
    count = tonumber(count) or 1;
    modifier = tonumber(modifier) or 0;

    if config.rollType == 'ingame' then
        for i=1,count do
            RandomRoll(modifier+1, size+modifier)
        end
    else
        for i=1,count do
            TRP3_API.slash.rollDices('1d'..size.."+"..modifier);
        end
    end
end
DMRP.Dice.doDiceRoll = doDiceRoll;

local function diceState(state, counter)
    log('dice state set to', state, 'with special value', counter)
    currentDiceState = state
    if state == 'advantage' then
        diceAdvantage = counter;
    end

end
DMRP.Dice.diceState = diceState;