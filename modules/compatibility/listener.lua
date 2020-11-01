--#======================#
--|Created By: Saelorable|
--|Date: 31/10/2020      |
--|Time: 17:08           |
--#======================#


DMRP.Compat = DMRP.Compat or {};
DMRP.Compat.listener = DMRP.Compat.listener or {}
local Utils = DMRP.Utils

local getPlayerName = DMRP.Utils.getPlayerName;

local listenerIsLoaded = false
local function isLoaded()
    if listenerIsLoaded then
        return true;
    end

    if _G.ListenerAddon then
        listenerIsLoaded = true;
        return true;
    end
    return false
end
DMRP.Compat.listener.isLoaded = isLoaded;



local function addMessageToListener(message, channel, author, guid)
    if not Utils.config.showInListener then return end
    local author = getPlayerName(author)
    ListenerAddon:OnChatMsg("CHAT_MSG_"..channel, message, author, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, guid, nil, nil)
end
DMRP.Compat.listener.addMessageToListener = addMessageToListener
