--#======================#
--|Created By: Saelorable|
--|Date: 25/10/2020      |
--|Time: 16:18           |
--#======================#

DMRP.Chat = DMRP.Chat or {};

local getPlayerName = DMRP.Utils.getPlayerName;
local log = DMRP.Utils.log
local _G = _G
--listener integration
--pretty chat print
local CHAT_TYPE = {
    EMOTE = function(message, author, guid, messageID)
        local emoteInfo = ChatTypeInfo["EMOTE"]
        local authorSeparator = " ";
        if message:sub(1, 3) == "'s " or message:sub(1, 2) == ", " then
        -- Added support for , at the start of an emote
            local authorSeparator = "";
        end
        local authorRealmName = getPlayerName(author)
        return GetPlayerLink(getPlayerName(author), DMRP.Utils.GetPlayerColoredName("CHAT_MSG_EMOTE", authorRealmName, messageID))..authorSeparator..message, emoteInfo.r, emoteInfo.g, emoteInfo.b
    end
}

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function chatWindowsForChatChannel(channel)
    local frameList = {}
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = getglobal("ChatFrame"..i)
        for j,v in ipairs(chatFrame.messageTypeList) do
            if v == channel and not (has_value(frameList, "ChatFrame"..i)) then
                table.insert(frameList, "ChatFrame"..i)
            end
        end
        for j,v in ipairs(chatFrame.channelList) do
            if v == channel and not (has_value(frameList, "ChatFrame"..i)) then
                table.insert(frameList, "ChatFrame"..i)
            end
        end
    end
    return frameList
end

local function printToChatChannel(text, channel, r, g, b)
    local channelList = chatWindowsForChatChannel(channel);
    for i,v in ipairs(channelList) do
        log("printing to", v);
        getglobal(v):AddMessage(text, r, g, b, 0)
    end
end
local function fakeChatMessage(message, channel, author, guid, messageID)
    local formattedMessage, r, g, b = CHAT_TYPE[channel](message, author, guid, messageID);
    if (not formattedMessage) then
        local playerName = DMRP.Utils.GetPlayerColoredName("CHAT_MSG_"..channel, author, messageID)
        log("playerName:",playerName)
        formattedMessage = "["..(playerName or author).."]" ..": "..message;
    end
    if DMRP.Compat.listener.isLoaded() then
        DMRP.Compat.listener.addMessageToListener(message, channel, author, guid)
    end

    printToChatChannel(formattedMessage, channel, r,g,b)
end

DMRP.Chat.fakeChatMessage = fakeChatMessage;


local LANGUAGES = {
    [1] = "Orcish",
    [2] = "Darnassian",
    [3] = "Taurahe",
    [6] = "Dwarvish",
    [7] = "Common",
    [8] = "Demonic",
    [9] = "Titan",
    [10] = "Thalassian",
    [11] = "Draconic",
    [12] = "Kalimag",
    [13] = "Gnomish",
    [14] = "Zandali",
    [33] = "Forsaken",
    [35] = "Draenei",
    [36] = "Zombie",
    [37] = "Gnomish Binary",
    [38] = "Goblin Binary",
    [39] = "Gilnean",
    [40] = "Goblin",
    [42] = "Pandaren",
    [43] = "Pandaren",
    [44] = "Pandaren",
    [168] = "Sprite",
    [178] = "Shath'Yar",
    [179] = "Nerglish",
    [180] = "Moonkin",
    [181] = "Shalassian",
    [182] = "Thalassian",
    [285] = "Vulpera"
}

DMRP.Chat.nextRollMessage = nil

DMRP.Chat.originalSendChatMessage = SendChatMessage;
local function hookSendChatMessageFunction(message, channel, language, ...)
    log(message, {...});
    local messageAwatingNextResult
    --get groupings
    for command in message:gmatch('%[[^%]]+%]') do
        local shouldRemove = false;
        local commandStripped = command:sub(2,-2);
        for i,v in pairs(DMRP.Dice.diceRollTypes) do
            if string.match(commandStripped, "^"..i) then
                shouldRemove = true
                local prams = DMRP.Dice.spreadSlashArgs(commandStripped)
                table.remove(prams, 1);
                if string.match(commandStripped, "adv") then
                    DMRP.Dice.diceState('advantage', 2)
                    v(true, prams)
                else
                    v(false, prams)
                end

                messageAwatingNextResult = true;
            end

        end

        log(commandStripped);
        log("removing", shouldRemove, DMRP.Utils.escapePattern(command));

        if shouldRemove then
            message = message:gsub(DMRP.Utils.escapePattern(command).." *", '')
        end
    end
    local _, defaultLanguage = GetDefaultLanguage("player")
    if language ~= defaultLanguage and channel == "SAY" or channel == "YELL" then
        log("changing language", GetDefaultLanguage("player"))
        local languageName = LANGUAGES[language];
        log(languageName)
        message = (languageName and ('['..(languageName)..'] ') or '')..message;

        language = defaultLanguage;
    else
        log(language, 'dosen\'t match', GetDefaultLanguage("player"))
    end


    log(message, {...});
    if not messageAwatingNextResult or channel == "SAY" or channel == "YELL" or channel == "CHANNEL" then
        log ('sending message immediately')
        DMRP.Chat.splitAndSendChat(message, channel, language, ...)
    else
        log ('sending message delayed')
        DMRP.Chat.nextRollMessage = {message, channel, language, ...}
    end
end
SendChatMessage = hookSendChatMessageFunction;

local function splitAndSendChat(message, channel, language, target, ...)
    log(message);

    local messageLength = 0;
    if type(message) == 'string' then
        messageLength = #message
    else
        for i,msg in ipairs(message) do
            messageLength = messageLength + #msg
        end
    end
    local messages = {}
    local i = 1;
    if messageLength >= 250 then
        local words = {}
        if type(message) == 'string' then
            words = DMRP.Dice.spreadSlashArgs(message);
        else
            words = message
        end
        for j, msg in ipairs(words) do
            local punctuation = msg:sub(-2,-1)
            if messages[i] and (#(messages[i]..msg) > 200 or ((punctuation=="." or punctuation=="," or punctuation==";" or punctuation==":" or punctuation=="?" or punctuation=="!") and #(messages[i]..msg) > 150)) then
                i = i+1
            end
            messages[i] = messages[i] and messages[i].." "..msg or (channel == "EMOTE" and "|| ".. msg) or msg;
        end
    else

        if type(message) == 'string' then
            messages = {message}
        else
            local msgString = ''

            for i,msg in ipairs(message) do
                msgString = msgString ..' '.. msg
            end
            messages = {msgString}

        end
    end

    --we restore the original SendChatMessage function while chomp is queing up messages
    SendChatMessage = DMRP.Chat.originalSendChatMessage;
    for j,v in ipairs(messages) do
        if i > 1 then
            v = v .. " [part " .. j .. " of " .. i .. "]";
        end
        AddOn_Chomp.SendChatMessage(v, channel, language, target, nil, "DMRP", nil, nil)
    end
    SendChatMessage = hookSendChatMessageFunction
end
DMRP.Chat.splitAndSendChat = splitAndSendChat

local function onInit()
    for i = 1, NUM_CHAT_WINDOWS do
        local editbox = _G["ChatFrame" .. i .. "EditBox"]
        editbox:SetMaxLetters( 0 )
        editbox:SetMaxBytes( 0 )
        -- A Blizzard dev added this function just for us. Without this, it
        --  would be absolute hell to get this addon to work with the default
        --  chat boxes, if not impossible. I'd have to create a whole new
        --  chatting interface.
        if editbox.SetVisibleTextByteLimit then
            editbox:SetVisibleTextByteLimit( 0 )
        end
    end
end
onInit()