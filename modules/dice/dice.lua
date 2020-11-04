--#======================#
--|Created By: Saelorable|
--|Date: 24/10/2020      |
--|Time: 12:39           |
--#======================#

DMRP.Dice = DMRP.Dice or {};
local chatMessage = DMRP.Chat.fakeChatMessage;

local LibDeflate = LibStub:GetLibrary("LibDeflate");
local CreateFrame = CreateFrame;
local Utils = DMRP.Utils;
local config, log = Utils.config, Utils.log;

local currentDiceState = 'individual';
local advantageRoll = { result = 0 }
local diceAdvantage = 1;

log("init dice");
local function playerDCPasses(player, result, modifier)
    result = tonumber(result)
    local matchedActions = {}
    for i, dc in ipairs(DMRP.Dice.dcs) do
        local matchesDC = false
        local isTargetted = false;
        if dc.target then
            for i, target in ipairs(dc.target) do
                if Utils.getPlayerName(player) == Utils.getPlayerName(dc.target) then
                    isTargetted = true
                end
            end
        end

        if not dc.target or isTargetted then

            log(dc, type(dc.min))
            if dc.min and dc.max and dc.min <= result and dc.max >= result then
                log(dc.min, "and", dc.max,"and", dc.min <= result, "and", dc.max >= result, dc.action)
                matchesDC = true;
            elseif dc.min and not dc.max and dc.min <= result then
                matchesDC = true;
            elseif dc.max and not dc.min and dc.max >= result then
                matchesDC = true;
            elseif dc.nat and dc.nat == result - modifier then
                matchesDC = true;
            else
                matchesDC = false;
            end
            log('matches DC?', matchesDC)
        end
        if matchesDC then
            table.insert(matchedActions, dc.action);
        end
    end
    log (matchedActions)
    return matchedActions;
end
local damageResults = {}
local function DCAction(actions, player)
    local totalDamage = 0;
    if not damageResults[player] then
        damageResults[player] = {}
        for i,v in ipairs(actions) do
            if v.perception then
                log (v.perception, "WHISPER", nil, Utils.getPlayerName(player))
                DMRP.Chat.splitAndSendChat(v.perception, "WHISPER", nil, Utils.getPlayerName(player))
            end
            if v.dam then
                damageResults[player].insert(v);
                totalDamage = totalDamage + v.dam
            end

        end
        if damageResults[player][2] then
            DMRP.Chat.splitAndSendChat("You have dealt "..totalDamage.." damage this round!", "WHISPER", nil, Utils.getPlayerName(player))
        end
    end

end

local function diceRollMessage(playerName, rollResult, rollSize, modifier)
    if (tonumber(rollSize) == 20) then
        local DCPasses = playerDCPasses(playerName, rollResult, modifier);
        DCAction(DCPasses, playerName)
    end
    if DMRP.Chat.nextRollMessage and playerName == Utils.getPlayerName() then
        if not string.match(DMRP.Chat.nextRollMessage[1], '%$%{result%}') and not string.match(DMRP.Chat.nextRollMessage[1], '%$%{total%}') then
            DMRP.Chat.nextRollMessage[1] = DMRP.Chat.nextRollMessage[1].." (roll "..rollResult.."/"..rollSize+modifier..")"
        end

        DMRP.Chat.nextRollMessage[1] = DMRP.Chat.nextRollMessage[1]:gsub('%$%{result%}', rollResult)
        DMRP.Chat.nextRollMessage[1] = DMRP.Chat.nextRollMessage[1]:gsub('%$%{total%}', rollResult)
        DMRP.Chat.nextRollMessage[1] = DMRP.Chat.nextRollMessage[1]:gsub('%$%{max%}', rollSize)
        DMRP.Chat.nextRollMessage[1] = DMRP.Chat.nextRollMessage[1]:gsub('%$%{modifier%}', modifier)
        DMRP.Chat.splitAndSendChat(unpack(DMRP.Chat.nextRollMessage));
        DMRP.Chat.nextRollMessage = nil;
    end
end


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

            diceRollMessage(playerName, advantageRoll.result, advantageRoll.diceSize, advantageRoll.modifier)

            advantageRoll = {result= 0 }

        end
    else
        lastRolls[playerName] = {result = rollResult, diceSize = rollSize, modifier = modifier, diceCount = 1}
        chatMessage("rolls "..rollResult.." on a d"..rollSize .. (modifier == 0 and "" or ((modifier > 0 and "+" or "-")..modifier)), "EMOTE", author)
        diceRollMessage(playerName, rollResult, rollSize, modifier)
    end
    DMRP.Chat.nextRollSilent = false;
end


local f = CreateFrame("frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent", function(self, event, message, addonContent,...)
    if event == "CHAT_MSG_SYSTEM" then
        log(event, message, addonContent,...)
        local author, rollResult, rollMin, rollMax = string.match(message, "(.+) rolls (%d+) %((%d+)-(%d+)%)")
        if author then
            local modifier = rollMin - 1
            local rollSize = rollMax - modifier
            reportDiceRolls(author, rollResult, rollSize, modifier);
        end

    end
end)

local PROTOCOL_PREFIX = "TRP3.3";
local PROTOCOL_SETTINGS = {
    permitUnlogged = true,
    permitLogged = true,
    permitBattleNet = true,
    fullMsgOnly = true,
    validTypes = {
        ["string"] = true,
        ["table"] = true,
    },
    broadcastPrefix = "TRP3.3"
}
local function TRPDiceRollHandler(arg1, addonContent, channel, sender)
    local decodedCompressedData = LibDeflate:DecodeForWoWChatChannel(addonContent:sub(3, -1));
    if not decodedCompressedData then return end
    local deflatedContent = LibDeflate:DecompressDeflate(decodedCompressedData);
    if not decodedCompressedData then return end
    local deserializedContent = AddOn_Chomp.Deserialize(deflatedContent);
    if not deserializedContent then return end
    log (type(deserializedContent), deserializedContent, deserializedContent.modulePrefix)
    if deserializedContent.modulePrefix == 'DISN' then
        reportDiceRolls(sender, deserializedContent.data.t, deserializedContent.data.d, deserializedContent.data.m)
    else
        log("prefix should be DISM", deserializedContent.modulePrefix)
    end
end
if not AddOn_Chomp.IsAddonPrefixRegistered(PROTOCOL_PREFIX) then
    AddOn_Chomp.RegisterAddonPrefix(PROTOCOL_PREFIX, TRPDiceRollHandler, PROTOCOL_SETTINGS)
else
    AddOn_Chomp.HookAddonPrefix(PROTOCOL_PREFIX, TRPDiceRollHandler)
end

local function resetDice()
    lastRolls = {};
    DMRP.Dice.dcs = {};
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