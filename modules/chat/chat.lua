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