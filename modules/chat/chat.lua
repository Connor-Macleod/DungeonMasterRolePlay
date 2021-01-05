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
    end,

    SYSTEM = function(message, author, guid, messageID)
        local systemInfo = ChatTypeInfo["SYSTEM"]
        local authorSeparator = " ";
        if message:sub(1, 3) == "'s " or message:sub(1, 2) == ", " then
            -- Added support for , at the start of an emote
            local authorSeparator = "";
        end
        local authorRealmName = getPlayerName(author)
        return GetPlayerLink(getPlayerName(author), DMRP.Utils.GetPlayerColoredName("CHAT_MSG_EMOTE", authorRealmName, messageID))..authorSeparator..message, systemInfo.r, systemInfo.g, systemInfo.b
    end,

    DM = function(message, author, guid, messageID)
        local systemInfo = ChatTypeInfo["DM"]
        local authorRealmName = getPlayerName(author)
        return '[Dungeon Master]['..GetPlayerLink(getPlayerName(author), DMRP.Utils.GetPlayerColoredName("CHAT_MSG_EMOTE", authorRealmName, messageID))..']: '..message, systemInfo.r, systemInfo.g, systemInfo.b
    end,
    OTHER = function(channel)
        return function( message, author, guid, messageID)
            local channelInfo = ChatTypeInfo[channel]
            local authorSeparator = " ";
            local authorRealmName = getPlayerName(author)
            return format(
                _G["CHAT_"..channel.."_GET"]..message,
                "["..GetPlayerLink(getPlayerName(author), DMRP.Utils.GetPlayerColoredName("CHAT_MSG_"..channel, authorRealmName, messageID)).."]"),
            channelInfo.r,
            channelInfo.g,
            channelInfo.b
        end
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
        getglobal(v):AddMessage(text, r, g, b, 0)
    end
end
local function fakeChatMessage(message, channel, author, guid, messageID)

    message = string.gsub(message, '%#n', '\n')

    local formatter = CHAT_TYPE[channel]
    if not formatter then
        formatter = CHAT_TYPE['OTHER'](channel)
    end

    local formattedMessage, r, g, b = formatter(message, author, guid, messageID);
    if (not formattedMessage) then
        local playerName = DMRP.Utils.GetPlayerColoredName("CHAT_MSG_"..channel, author, messageID)

        formattedMessage = "["..(playerName or author).."]" ..": "..message;
    end
    log('fm',formattedMessage)
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

local function sendDMMessage()

end

DMRP.Chat.originalSendChatMessage = SendChatMessage;
local function hookSendChatMessageFunction(message, channel, language, ...)

    if channel == 'DM' then
        return DMRP.slash.dm(message)
    end


    local awaitingResults = {};
    --get groupings
    for command in message:gmatch('%[[^%]]+%]') do
        local shouldRemove = false;
        local commandStripped = command:sub(2,-2);


        for i,v in pairs(DMRP.Utils.config.profile.rolls) do

            if string.match(commandStripped, "^"..i..' ') or string.match(commandStripped, "^"..i..'$') then

                shouldRemove = true
                local prams = DMRP.Dice.spreadSlashArgs(commandStripped)
                table.remove(prams, 1);
                if string.match(commandStripped, "adv") then
                    DMRP.Dice.diceState('advantage', 2)
                    table.insert(awaitingResults, DMRP.Dice.evalDiceRoll(i, true, prams))
                else
                    table.insert(awaitingResults, DMRP.Dice.evalDiceRoll(i, false, prams))
                end


            end

        end



        if shouldRemove then
            message = message:gsub(DMRP.Utils.escapePattern(command).." *", '')
        end
    end
    local _, defaultLanguage = GetDefaultLanguage("player")
    if language ~= defaultLanguage and channel == "SAY" or channel == "YELL" then

        local languageName = LANGUAGES[language];
        message = (languageName and ('['..(languageName)..'] ') or '')..message;

        language = defaultLanguage;
    else
    end


    if not awaitingResults[1] or channel == "SAY" or channel == "YELL" or channel == "CHANNEL" then
        log ('sending message immediately')
        DMRP.Chat.splitAndSendChat(message, channel, language, ...)
    else
        log ('sending message delayed')
        local args = {... }
        for id, props in ipairs(awaitingResults) do
            DMRP.Dice.QueueDiceRollAction(function(rollResult, rollSize, modifier)

                if not string.match(message, '%$%{result%}') and not string.match(message, '%$%{total%}') and not string.match(message, '%$%{result'..id..'%}') and not string.match(message, '%$%{total'..id..'%}') then
                    message = message.." (roll "..rollResult.."/"..rollSize+modifier..((props.adv and " adv") or '')..")"
                end

                message = message:gsub('%$%{result%}', rollResult)
                message = message:gsub('%$%{total%}', rollResult)
                message = message:gsub('%$%{max%}', rollSize)
                message = message:gsub('%$%{modifier%}', modifier)

                message = message:gsub('%$%{result'..id..'%}', rollResult)
                message = message:gsub('%$%{total'..id..'%}', rollResult)
                message = message:gsub('%$%{max'..id..'%}', rollSize)
                message = message:gsub('%$%{modifier'..id..'%}', modifier)

                if id == #awaitingResults then

                    DMRP.Chat.splitAndSendChat(message, channel, language, unpack(args));
                else


                end
            end, props.size, props.modifier)

        end

    end
end
SendChatMessage = hookSendChatMessageFunction;

local function splitChat(message, channel, language, target, ...)
    if channel == 'DM' then

        local everyoneHasDMRP = false;

        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i)
                local name = DMRP.Utils.getPlayerName(name);

                local status = DMRP.comms.getPlayerStatus(name);

                if not status.version then
                    everyoneHasDMRP = false
                end
            end
        end

        if everyoneHasDMRP then


            return;
        end

        channel = (IsInRaid() and 'RAID_WARNING') or (IsInGroup() and 'PARTY') or 'EMOTE'
        if channel == 'EMOTE' then message = "|| "..message end
    end

    local messageLength = 0;
    local hashashn = false
    if type(message) == 'string' then
        messageLength = #message
        if string.match(message, '%#n') then
            hashashn = true
        end

    else
        for i,msg in ipairs(message) do
            messageLength = messageLength + #msg
            if string.match(msg, '%#n') then
                hashashn = true
            end
        end
    end
    local messages = {}
    local i = 1;
    if messageLength >= 250 or hashashn then
        local words = {}
        if type(message) == 'string' then
            words = DMRP.Dice.spreadSlashArgs(message);
        else
            words = message
        end
        for j, msg in ipairs(words) do
            -- TODO: WIP! support #n for newlines and multi newlines for rejoining later! with not-too-obscrutive [n1/5] or [2p2/5]
            if string.match(msg, '%#n') then
                msg=msg.."#n"
                local blanks = 0;
                local lastPart;
                local lines = {}
                for line in string.gmatch(msg, "(.-)#n") do
                    table.insert(lines, line)
                end
                for lineNumber, line in ipairs(lines) do
                    if line == '' then
                        blanks = blanks+1
                    end

                    if blanks>0 and line ~= '' then
                        messages[i] = (messages[i] and messages[i]..' '..((blanks>1 and blanks) or '')..'»') or '';
                        blanks = 0
                        i = i+1
                        messages[i] = line..' '..((blanks>1 and blanks) or '')..'»';
                    elseif line ~= '' then
                        messages[i] = messages[i] and (messages[i]..' '..line..' '..((blanks>1 and blanks) or '')..'»') or line..' '..((blanks>1 and blanks) or '')..'»';

                        if lineNumber~=#lines then
                            i = i+1
                        end
                    end
                    lastPart = line
                end
                blanks = blanks - 1;
                if blanks>0 and lastPart=='' then
                    messages[i] = messages[i] and messages[i]..' '..((blanks>1 and blanks) or '')..'»'  or lastPart;
                    i = i+1
                else
                    messages[i] = (messages[i] or '»'):sub(1, -3);
                end
            else
                local punctuation = msg:sub(-2,-1)
                if messages[i] and (#(messages[i]..msg) > 200 or ((punctuation=="." or punctuation=="," or punctuation==";" or punctuation==":" or punctuation=="?" or punctuation=="!") and #(messages[i]..msg) > 150)) then
                    messages[i] = messages[i]..' '
                    i = i+1
                end
                messages[i] = messages[i] and messages[i].." "..msg or msg;
            end

        end
        if messages[i] then
            messages[i] = messages[i] ..' '
        end
    else
        if type(message) == 'string' then
            messages = {message}
        else
            local msgString = ''

            for j,msg in ipairs(message) do
                msgString = msgString ..' '.. msg
            end
            messages = {msgString .. ''}

        end
    end

    for i,v in ipairs(messages) do
        if i > 1 then
            v= '» '..v;
        end
        if i<#messages then
            v = v..'»';
        end
        messages[i] = v;
    end

    return messages, i
end

DMRP.Chat.splitChat = splitChat

local queueHandler = CreateFrame("frame")
local messageQueue = {}
local lastMessage = ''
local function queueMessages(messages, channel, language, target, ...)

    local totalCount = #messages

    for j,v in ipairs(messages) do
        table.insert(messageQueue, function ()

            --we restore the original SendChatMessage function while chomp is queing up messages
            SendChatMessage = DMRP.Chat.originalSendChatMessage;
            lastMessage = v;
            AddOn_Chomp.SendChatMessage(v, channel, language, target, nil, "DMRP", nil, nil)
            table.remove(messageQueue, 1)
            SendChatMessage = hookSendChatMessageFunction
        end)
    end
    messageQueue[1]();
    queueHandler:RegisterEvent("CHAT_MSG_"..channel)
    queueHandler:SetScript("OnEvent", function(self, event, message, player,...)
        if event == "CHAT_MSG_"..channel then
            if message == lastMessage and messageQueue[1] then
                messageQueue[1]();
            end
            if #messageQueue <= 0 then
                queueHandler:UnregisterEvent("CHAT_MSG_"..channel)
                queueHandler:SetScript("OnEvent", function() end)
            end

        end
    end)

end

local function splitAndSendChat(message, channel, language, target, ...)
    if channel == 'DM' then

        local everyoneHasDMRP = false;

        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i)
                local name = DMRP.Utils.getPlayerName(name);

                local status = DMRP.comms.getPlayerStatus(name);

                if not status.version then
                    everyoneHasDMRP = false
                end
            end
        end

        if everyoneHasDMRP then


            return;
        end

        channel = (IsInRaid() and 'RAID_WARNING') or (IsInGroup() and 'PARTY') or 'EMOTE'
        if channel == 'EMOTE' then message = "|| "..message end
    end
    local messages, totalCount = splitChat(message, channel, language, target, ...)
    log(channel)
    if channel == 'SAY' or channel == 'YELL' or channel == 'CHANNEL' then
        for i,v in ipairs(messages) do
            SendChatMessage = DMRP.Chat.originalSendChatMessage;
            AddOn_Chomp.SendChatMessage(v, channel, language, target, nil, "DMRP", nil, nil)
            SendChatMessage = hookSendChatMessageFunction
        end
    else
        queueMessages(messages, channel, language, target, ...)
    end
end
DMRP.Chat.splitAndSendChat = splitAndSendChat

DMRP.Chat.lastEmotes = {}
local f = CreateFrame("frame")
f:RegisterEvent("CHAT_MSG_EMOTE")
f:RegisterEvent("CHAT_MSG_RAID")
f:RegisterEvent("CHAT_MSG_RAID_LEADER")

local multipartMessages = {}
local function multipartMessageManage(chatFrame, event, message, author, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, guid, arg13, arg14 )
    --log('filtering', event, message, author, chatFrame.name)


    if ( event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_PARTY" or event == 'CHAT_MSG_PARTY_LEADER' or event == "CHAT_MSG_EMOTE") then
        for i,v in ipairs(DMRP.Chat.supressMessages) do
            if message==v then
                table.remove(DMRP.Chat.supressMessages, i)
                if event ~= 'CHAT_MSG_RAID_WARNING' then
                    table.remove(DMRP.Chat.supressRWS, i)
                end
                return true
            end
        end
    end


    log('filtering', message:sub(1, 2), message:sub(-2, -1))
    if #event > 10 and message:sub(1, 2) == '»' or message:sub(-2, -1) == '»' then
        if not chatFrame then  return true end
        log('multipartMessages start', multipartMessages)
        log('filtered', message:sub(1, 2), message:sub(-2, -1))

        log('check for start chevron', message:sub(1, 3))
        if message:sub(1, 2) == '»' then
            log('no start chevron', message:sub(4))
            message = message:sub(4);
        end

        if message:sub(-2, -1) == '»' then
            log('no end chevron', message:sub(1, -3))
            message = message:sub(1, -3);

            if message:sub(-2, -1) == '»' then
                log('no end chevron Multiline', message:sub(1, -3))
                if string.find(message:sub(1, -3), '%d$') then
                    message = message:sub(1, -3);
                    local digits = string.match(message, '%d+$');
                    log('digits', string.match(message, '%d$'), message)
                    message = string.gsub(message, '%d-$', '')
                    for i=1, tonumber(digits) do
                        message = message..'\n';
                    end
                else
                    message = message:sub(1, -3) .. '\n';
                end

            end

        else
            multipartMessages[event:sub(10)..author] = (multipartMessages[event:sub(10)..author] and multipartMessages[event:sub(10)..author]..message) or message
            log('multipart', multipartMessages)
            log('fakeChatMessage',multipartMessages[event:sub(10)..author], event:sub(10), author, guid, messageID)
            fakeChatMessage(multipartMessages[event:sub(10)..author], event:sub(10), author, guid, messageID)
            multipartMessages[event:sub(10)..author] = nil
            return true
        end


        multipartMessages[event:sub(10)..author] = (multipartMessages[event:sub(10)..author] and multipartMessages[event:sub(10)..author]..message) or message

        log('multipartMessages', multipartMessages)

        return true
    end
    return false
end


local oldRaidWarningFrame_OnEvent = RaidWarningFrame_OnEvent
function RaidWarningFrame_OnEvent(self, event, message)
    if ( event == "CHAT_MSG_RAID_WARNING" ) then
        for i,v in ipairs(DMRP.Chat.supressRWS) do
            if message==v then
                table.remove(DMRP.Chat.supressRWS, i)
                return true
            end
        end
    end
    oldRaidWarningFrame_OnEvent(self, event, message)
end


ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", multipartMessageManage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", multipartMessageManage)

f:SetScript("OnEvent", function(self, event, message, player,...)



    if event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then

        local fullPlayerName = DMRP.Utils.getPlayerName(player)

        DMRP.Chat.lastEmotes[fullPlayerName] = DMRP.Chat.lastEmotes[fullPlayerName] or {};
        if (DMRP.Chat.lastEmotes[fullPlayerName][5]) then
            table.remove(DMRP.Chat.lastEmotes[fullPlayerName], 1);
        end
        table.insert(DMRP.Chat.lastEmotes[fullPlayerName], {message = message, channel = event});

        DMRP.UI.updateRollHistory();
    end




end)

--the next few lines are hacking into how Blizz sets up chat channels, in  order to create our own
ChatTypeInfo["DM"]	= { sticky = 1, flashTab = true, flashTabOnGeneral = true }

ChatFrame_SetupListProxyTable(ChatTypeInfo)

ChatTypeInfo["DM"].r = 200/255
ChatTypeInfo["DM"].g = 162/255
ChatTypeInfo["DM"].b = 200/255
ChatTypeInfo["DM"].id = 11
ChatFrame_ImportListToHash(ChatTypeInfo);

SlashCmdList["DM"] = true

_G["CHAT_DM_SEND"] = 'Dungeon Master: '

ChatTypeGroup['DM'] = {

    "CHAT_MSG_DM",
}

local oldChangeChatColor = ChangeChatColor;
function ChangeChatColor(channel, r,g,b)
    if channel == 'DM' then
        ChatTypeInfo["DM"].r = r
        ChatTypeInfo["DM"].g = g
        ChatTypeInfo["DM"].b = b
        return;
    end
    oldChangeChatColor(channel, r,g,b)
end

CHAT_CONFIG_CHAT_LEFT[12] = {
    type = "DM",
    checked = function () return IsListeningForMessageType("DM"); end;
    func = function (self, checked)
        local chatFrame = FCF_GetCurrentChatFrame();
        local messageTypeList = FCF_GetCurrentChatFrame().messageTypeList;
        if checked then
            table.insert(messageTypeList, 'DM')
        else
            for index, value in pairs(messageTypeList) do
                if value=='DM' then
                    table.remove(messageTypeList, index)
                end
            end
        end
        DMRP.Utils.config.profile.enabledChatFrames[chatFrame:GetID()] = checked

    end;
    text = 'Dungeon Master'
};

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

local oldChatEdit_OnEnterPressed = ChatEdit_OnEnterPressed
function ChatEdit_OnEnterPressed(self)
    if IsShiftKeyDown() then
        self:Insert('#n')
        return
    end

    oldChatEdit_OnEnterPressed(self)
end
