--#======================#
--|Created By: Saelorable|
--|Date: 24/10/2020      |
--|Time: 17:22           |
--#======================#


DMRP = DMRP or {}
DMRP.Utils = DMRP.Utils or {};

local log = DMRP.Utils.log

local function getPlayerName(player)

    if not player then player = GetUnitName('player', true) end

    local myRealmName = "-"..GetNormalizedRealmName()

    local fullPlayer = player


    if not string.find(player, '%-[^-]+') then
        fullPlayer = player..myRealmName
    end

    return fullPlayer
end
DMRP.Utils.getPlayerName = getPlayerName;

local GUIDs = {}
local function cacheGuid(player, guid)
    guid = guid or UnitGUID(player);
    if player and guid and not GUIDs[player] then
        GUIDs[player] = guid
    end
end

local function getPlayerGuidCached(player, guid)
    log("player1", player)
    player = getPlayerName(player);
    log("player2", player)
    cacheGuid(player, guid)
    log('guids', GUIDs)
    if GUIDs[player] then
        return GUIDs[player]
    end
    return nil
end
DMRP.Utils.getPlayerGuidCached = getPlayerGuidCached;

--this is ugly AF, but it caches GUIDs when they're available.
local function colouredNameReplacer(event, arg1,player,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,GUID)
    if player and GUID then
        getPlayerGuidCached(player, GUID);
    end
end
hooksecurefunc("GetColoredName", colouredNameReplacer)
hooksecurefunc(TRP3_API.utils, "customGetColoredName", colouredNameReplacer)

local function GetPlayerColoredName(event, player, messageID)
    log("event", event, "player", player, "id", messageID, 'guid', getPlayerGuidCached(player))
    return GetColoredName(event, nil, player, nil, nil, nil, nil, nil, nil, nil, nil, messageID or 'N/A', getPlayerGuidCached(player))
end
DMRP.Utils.GetPlayerColoredName = GetPlayerColoredName;