--#======================#
--|Created By: Saelorable|
--|Date: 24/11/2020      |
--|Time: 19:53           |
--#======================#

DMRP.comms = DMRP.comms or {};
local log = DMRP.Utils.log
DMRP.Chat = DMRP.Chat or {};
DMRP.Chat.supressMessages = DMRP.Chat.supressMessages or {}
DMRP.Chat.supressRWS = DMRP.Chat.supressRWS or {}


local myRaid = {}

local function defaultInfo(grpRank)
    return {
        version = false,
        canDM = grpRank and grpRank ~= 0 or false,
        isDM = grpRank and grpRank == 2 or grpRank == 3 or false
    }
end

local function myInfo()
    local _, rank
    if UnitInRaid("player") then
        _, rank = GetRaidRosterInfo(UnitInRaid("player"))
    elseif UnitIsGroupLeader('player') then
        rank = 3;
    else
        rank = false;
    end

    local info = defaultInfo(rank);
    info.version = DMRP.Utils.version
    return info
end

local function updateGroupStatus()

    local channel = (IsInRaid() and 'RAID') or (IsInGroup() and 'PARTY') or 'WHIPSER'

    local target = channel=='WHISPER' and DMRP.Utils.getPlayerName(GetUnitName("target", true)) or nil

    AddOn_Chomp.SmartAddonMessage('DMRPping', myInfo(), channel, target, {serialize = true})

    for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i)
        local name = DMRP.Utils.getPlayerName(name);
        if not myRaid[name] or not myRaid[name].version then myRaid[name] = defaultInfo(rank) end

        DMRP.Utils.getPlayerGuidCached(name, UnitGUID('raid'..i));


    end
end

local function updatePlayerStatus(player, updateObj)
    if not myRaid[player] then
        myRaid[player] = defaultInfo()
    end

    for i, v in pairs(updateObj) do
        myRaid[player][i] = v;
    end

end
DMRP.comms.updateGroupStatus = updateGroupStatus

local function receiveInfo(isPing)
    return function (prefix, data, channel, sender, target, zoneChannelID, localID, name, instanceID )
        updatePlayerStatus(sender, data)
        if not isPing then
            AddOn_Chomp.SmartAddonMessage('DMRPinfo', myInfo(), 'WHISPER', sender, {serialize = true})
        end
    end
end

local function getPlayerStatus(player)
    local player = DMRP.Utils.getPlayerName(player)
    return myRaid[player]
end
DMRP.comms.getPlayerStatus = getPlayerStatus

local prefixSettings = {
    fullMsgOnly = false,
    validTypes = {
        ["table"] = true,
    },
}

AddOn_Chomp.RegisterAddonPrefix('DMRPping', receiveInfo(true), prefixSettings)
AddOn_Chomp.RegisterAddonPrefix('DMRPinfo', receiveInfo(true), prefixSettings)

AddOn_Chomp.RegisterAddonPrefix('DMRPdm', function(prefix, data, channel, sender, target, zoneChannelID, localID, name, instanceID, reportID, ...)


    if DMRP.slash.nextDMMessages then DMRP.slash.nextDMMessages() end

    local messagesToSupress = DMRP.Chat.splitChat(data.mainMessage)

    for i,v in ipairs(messagesToSupress) do
        table.insert(DMRP.Chat.supressMessages, v)
        table.insert(DMRP.Chat.supressRWS, v)
    end

    if data.dcs then
        table.insert(DMRP.Chat.supressMessages, "dice check! please roll 20!")
        table.insert(DMRP.Chat.supressRWS, "dice check! please roll 20!")
    end


    DMRP.Chat.fakeChatMessage(data.mainMessage, 'DM', sender, DMRP.Utils.getPlayerGuidCached(sender), DMRP.Utils.getPlayerGuidCached)


end, prefixSettings)


local f = CreateFrame("frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, message, addonContent,...)
    if event == "GROUP_ROSTER_UPDATE" then

        updateGroupStatus();
    elseif event == 'PLAYER_ENTERING_WORLD' then
        if UnitInRaid("player") or UnitInParty('player') then
            updateGroupStatus();
        end
        DMRP.Utils.getPlayerGuidCached(name, UnitGUID('player'));
    end
end)

