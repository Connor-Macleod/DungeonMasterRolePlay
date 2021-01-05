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
local log = Utils.log;

local currentDiceState = 'individual';
local advantageRoll = { result = 0 }
local diceAdvantage = 1;

DMRP.Dice.latestRolls = {};

local function playerInList(target, player)

    for i,targ in ipairs(target) do

        if player == targ then
            return true;
        end
    end
    return false;
end
DMRP.Utils.playerInList = playerInList


local function playerDCPasses(player, result, modifier)
    result = tonumber(result)

    if modifier == 0 then
        for i,mod in ipairs(DMRP.Dice.mods) do
            if not mod.target or playerInList(mod.target, player) then
                result = result + mod.mod;
                modifier = modifier + mod.mod;
            end
        end
    end


    local matchedActions = {}
    for i, dc in ipairs(DMRP.Dice.dcs) do
        local matchesDC = false
        local isTargetted = false;
        if dc.target then
            for i, target in ipairs(dc.target) do
                if Utils.getPlayerName(player) == Utils.getPlayerName(target) then
                    isTargetted = true
                end
            end
        end

        if not dc.target or isTargetted then

            if dc.min and dc.max and dc.min <= result and dc.max >= result then
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

        end
        if matchesDC then
            table.insert(matchedActions, dc.action);
        end
    end
    DMRP.Dice.latestRolls[Utils.getPlayerName(player)].actions = matchedActions
    return matchedActions;
end
local damageResults = {}
local killResults = {}
local hpResults = {}
local function DCAction(actions, player)
    local totalDamage = 0;
    local totalKill = 0;
    local totalHP = 0;

    if not damageResults[player] then
        damageResults[player] = {}
        killResults[player] = {}
        hpResults[player] = {}
        for i,v in ipairs(actions) do
            if v.perception then
                log (v.perception, "WHISPER", nil, Utils.getPlayerName(player))
                DMRP.Chat.splitAndSendChat(v.perception, "WHISPER", nil, Utils.getPlayerName(player))
            end
            if v.dam then
                table.insert(damageResults[player], v);
                totalDamage = totalDamage + v.dam
            end
            if v.kill then
                table.insert(killResults[player], v);
                totalKill = totalKill + v.kill
            end
            if v.hp then
                table.insert(hpResults[player], v);
                totalHP = totalHP + v.hp
            end

        end

        if totalDamage ~= 0 then
            DMRP.Chat.splitAndSendChat("You have dealt "..totalDamage.." damage this round!", "WHISPER", nil, Utils.getPlayerName(player))
        end
        if totalKill ~= 0 then
            DMRP.Chat.splitAndSendChat("You have killed "..totalKill.." enemies this round!", "WHISPER", nil, Utils.getPlayerName(player))
        end
        if totalHP ~= 0 then
            DMRP.Chat.splitAndSendChat("You have taken "..-totalHP.." damage this round!", "WHISPER", nil, Utils.getPlayerName(player))
        end
    end

end


local actionQueue = {}
local function QueueDiceRollAction(callback, size, modifier, player)
    if player then player = Utils.getPlayerName(player) end
    modifier = modifier or 0
    size = size or 20
    actionQueue[size..'+'..modifier..(player and ':'..player or '')] = actionQueue[size..'+'..modifier..(player and ':'..player or '')] or {};
    table.insert(actionQueue[size..'+'..modifier..(player and ':'..player or '')], callback);
end

DMRP.Dice.QueueDiceRollAction = QueueDiceRollAction;

local function DoDiceRollAction(total, size, modifier, player)
    if player then player = Utils.getPlayerName(player) end
    modifier = modifier or 0
    if actionQueue[size..'+'..modifier..':'..player ] then
        for i, callback in ipairs(actionQueue[size..'+'..modifier..':'..player ]) do
            callback(total, size, modifier);
            table.remove(actionQueue[size..'+'..modifier..':'..player ], i)
            return;
        end
    end
    if actionQueue[size..'+'..modifier] then
        for i, callback in ipairs(actionQueue[size..'+'..modifier]) do
            callback(total, size, modifier);
            table.remove(actionQueue[size..'+'..modifier], i)
            return;
        end
    end

end
local function diceRollMessage(playerName, rollResult, rollSize, modifier)
    if (tonumber(rollSize) == 20) then
        local DCPasses = playerDCPasses(playerName, rollResult, modifier);
        DCAction(DCPasses, playerName);
    end

    DoDiceRollAction(rollResult, rollSize, modifier, playerName)
end

local function reportDiceRolls(author, rollResult, rollSize, modifier)
    local playerName = Utils.getPlayerName(author)
    if currentDiceState == 'advantage' and playerName == Utils.getPlayerName() then
        if tonumber(rollResult) > advantageRoll.result then
            advantageRoll = {result = tonumber(rollResult), diceSize = rollSize, modifier = modifier, diceCount = 1, actions = ((DMRP.Dice.latestRolls[playerName] and DMRP.Dice.latestRolls[playerName].actions) or {})}
        end
        diceAdvantage = diceAdvantage - 1;
        if diceAdvantage < 1 then
            DMRP.Dice.latestRolls[playerName] = advantageRoll;
            diceAdvantage = 1;
            currentDiceState = 'individual'
            chatMessage("rolls "..advantageRoll.result.." on a d"..advantageRoll.diceSize .. (advantageRoll.modifier == 0 and "" or ((advantageRoll.modifier > 0 and "+" or "-")..advantageRoll.modifier)).." with advantage.", "SYSTEM",author)

            diceRollMessage(playerName, advantageRoll.result, advantageRoll.diceSize, advantageRoll.modifier)

            advantageRoll = {result= 0 }

        end
    else
        DMRP.Dice.latestRolls[playerName] = {result = rollResult, diceSize = rollSize, modifier = modifier, diceCount = 1, actions = (DMRP.Dice.latestRolls[playerName] and DMRP.Dice.latestRolls[playerName].actions) or {}}
        chatMessage("rolls "..rollResult.." on a d"..rollSize .. (modifier == 0 and "" or ((modifier > 0 and "+" or "-")..modifier)), "SYSTEM", author)
        diceRollMessage(playerName, rollResult, rollSize, modifier)
    end
    DMRP.UI.updateRollHistory();
end


ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(chatFrame, event, message, author, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, guid, arg13, arg14)
    local author, rollResult, rollMin, rollMax = string.match(message, "(.+) rolls (%d+) %((%d+)-(%d+)%)")
    if author then
        local modifier = rollMin - 1
        local rollSize = rollMax - modifier
        reportDiceRolls(author, rollResult, rollSize, modifier);
        return true
    end
    return false
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
    if deserializedContent.modulePrefix == 'DISN' then
        reportDiceRolls(sender, deserializedContent.data.t, deserializedContent.data.d, deserializedContent.data.m)
    else
    end
end
if not AddOn_Chomp.IsAddonPrefixRegistered(PROTOCOL_PREFIX) then

    AddOn_Chomp.RegisterAddonPrefix(PROTOCOL_PREFIX, TRPDiceRollHandler, PROTOCOL_SETTINGS)
else

    AddOn_Chomp.HookAddonPrefix(PROTOCOL_PREFIX, TRPDiceRollHandler)
end

local function resetDice()
    DMRP.Dice.latestRolls = {};
    DMRP.Dice.dcs = {};
    damageResults = {};
    killResults = {}
    hpResults = {}


    for i,mod in ipairs(DMRP.Dice.mods) do
        mod.roundCount = mod.roundCount - 1
        if mod.roundCount == 0 then
            table.remove(DMRP.Dice.mods, i)
        end
    end
end
DMRP.Dice.resetDice = resetDice;

local function doDiceRoll(size, count, modifier)
    size = tonumber(size) or 20;
    count = tonumber(count) or 1;
    modifier = tonumber(modifier) or 0;

    if DMRP.addon.db.profile.rollType == 'ingame' then
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

    currentDiceState = state
    if state == 'advantage' then
        diceAdvantage = counter;
    end

end
DMRP.Dice.diceState = diceState;