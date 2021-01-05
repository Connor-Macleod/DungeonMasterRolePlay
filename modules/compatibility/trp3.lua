--#======================#
--|Created By: Saelorable|
--|Date: 27/10/2020      |
--|Time: 18:43           |
--#======================#


DMRP.Compat = DMRP.Compat or {};
DMRP.Compat.TRP3 = DMRP.Compat.TRP3 or {}
local Utils = DMRP.Utils;
local log = Utils.log;


local function replaceStat(string)
    for command in string:gmatch('%$%{[Dd][Mm][Rr][Pp]:[^%}]+%}') do
        local commandStripped = command:sub(8, -2);
        local arguments = DMRP.Dice.spreadSlashArgs(commandStripped)

        local tracker = DMRP.Tracker.checkTracker(arguments[1])
        if tracker then
            if arguments[2] and  arguments[2]:match('^[\'"]')  and  arguments[2]:match('[\'"]$') then
                arguments[2] = arguments[2]:sub(2, -2);
            end
            local shieldColour
            local trackerColour = string.format("|c%.2x%.2x%.2x%.2x", tracker.amountColour[4]*255, tracker.amountColour[1]*255, tracker.amountColour[2]*255, tracker.amountColour[3]*255)
            if tracker.shield and tracker.shield > 0 then
                shieldColour = string.format("|c%.2x%.2x%.2x%.2x", tracker.shieldColour[4]*255, tracker.shieldColour[1]*255, tracker.shieldColour[2]*255, tracker.shieldColour[3]*255)
            end


            local replacement = trackerColour..tracker.current..(tracker.shield and tracker.shield > 0 and (shieldColour.."+"..tracker.shield..'|r') or '')..'/'..tracker.max..'|r'

            string = string:gsub(DMRP.Utils.escapePattern(command), replacement)
        end
    end
    return string;
end
DMRP.Compat.TRP3.replaceStat = replaceStat;

local function hook()

    local originalRegisterPrefix = AddOn_TotalRP3.Communications.registerSubSystemPrefix
    AddOn_TotalRP3.Communications.registerSubSystemPrefix = function(event, callback, handlerID)
        log(event)
        if event == "GI" then
            originalRegisterPrefix(event, function(informationType, senderID,...)
                log(informationType, senderID)
                local playerAPI = TRP3_API.register.player;
                local getCharExchangeData = playerAPI.getCharacteristicsExchangeData;
                local getAboutExchangeData = playerAPI.getAboutExchangeData;
                local getMiscExchangeData = playerAPI.getMiscExchangeData;
                local Comm = AddOn_TotalRP3.Communications;


                local getCharacterExchangeData = TRP3_API.dashboard.getCharacterExchangeData;
                local getCompanionData = TRP3_API.companions.player.getCompanionData;
                local COMPANION_PREFIX = "comp_";
                local INFO_TYPE_SEND_PREFIX = "SI";
                local INFO_TYPE_SEND_PRIORITY = Comm.PRIORITIES.LOW;

                local data;
                if informationType == TRP3_API.register.registerInfoTypes.CHARACTERISTICS then
                    data = getCharExchangeData();
                elseif informationType == TRP3_API.register.registerInfoTypes.ABOUT then
                    data = getAboutExchangeData();
                elseif informationType == TRP3_API.register.registerInfoTypes.MISC then
                    data = getMiscExchangeData();
                elseif informationType == TRP3_API.register.registerInfoTypes.CHARACTER then
                    data = getCharacterExchangeData();
                elseif informationType:sub(1, COMPANION_PREFIX:len()) == COMPANION_PREFIX then
                    local v = informationType:sub(COMPANION_PREFIX:len() + 1, COMPANION_PREFIX:len() + 1);
                    local profileID = informationType:sub(COMPANION_PREFIX:len() + 2);
                    data = getCompanionData(profileID, v);
                end

                local moddedData = {}
                for orig_key, orig_value in pairs(data) do
                    moddedData[orig_key] = orig_value
                end
                log(data)
                if data.CO then
                    moddedData.CO = replaceStat(data.CO)
                    log('OOC',moddedData.CO)
                end
                if data.CU then
                    moddedData.CU = replaceStat(data.CU)
                    log('Currently',moddedData.CU)
                end
                if moddedData then
                    AddOn_TotalRP3.Communications.sendObject(INFO_TYPE_SEND_PREFIX, {informationType, moddedData}, senderID, INFO_TYPE_SEND_PRIORITY, nil, true);
                else
                    AddOn_TotalRP3.Communications.sendObject(INFO_TYPE_SEND_PREFIX, {informationType, data}, senderID, INFO_TYPE_SEND_PRIORITY, nil, true);
                end
            end, handlerID)
        else
            originalRegisterPrefix(event, callback, handlerID)
        end

    end

end

local trp3IsLoaded = false;

local function isLoaded()
    if trp3IsLoaded then
        return true;
    end

    if _G.TRP3_API then
        trp3IsLoaded = true;
        hook();
        return true;
    end
    return false
end
DMRP.Compat.TRP3.isLoaded = isLoaded;


local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function()
    isLoaded();
end)

local CLASSIDS = {
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "DEATHKNIGHT",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "MONK",
    "DRUID",
    "DEMONHUNTER"
}

local function getCharacterInfo (unitID)
    if unitID == TRP3_API.globals.player_id then
        return TRP3_API.profile.getData("player");
    elseif TRP3_API.register.isUnitIDKnown(unitID) then
        return TRP3_API.register.getUnitIDCurrentProfile(unitID) or {};
    end
    return {};
end
DMRP.Compat.TRP3.getCharacterInfo= getCharacterInfo;
local function colouredNameWithoutGUID(fallback, event, arg1, unitID, arg3, arg4, arg5, arg6, arg7, channelNumber, arg9, arg10, messageID, arg12, ...)
    --This is a modified version of TRP3's GetColouredName function, functionality is similar, excepting it does not require GUID,
    -- as we'll occationally want to get a coloured name when a GUID isn't available, for example, dice rolls.

    --we grab these locally inside functions to prevent errors if we don't have TRP3
    local  unitInfoToID =  TRP3_API.utils.str.unitInfoToID;

    if TRP3_API.chat.disabledByOOC() then
        return fallback(event, arg1, unitID, arg3, arg4, arg5, arg6, arg7, channelNumber, arg9, arg10, messageID, arg12, ...);
    end


    -- Do not change stuff if the customizations are disabled for this channel or the GUID is invalid (WIM…), use the default function
    if not TRP3_API.chat.isChannelHandled(event) or not TRP3_API.chat.configIsChannelUsed(event) then
        return fallback(event, arg1, unitID, arg3, arg4, arg5, arg6, arg7, channelNumber, arg9, arg10, messageID, arg12)
    end ;

    local characterName = unitID;
    --@type ColorMixin
    local characterColor;

    -- Extract the character name and realm from the unit ID
    local character, realm = TRP3_API.utils.str.unitIDToInfo(unitID);
    if not realm then
        -- if realm is nil (i.e. globals haven't been set yet) just run the vanilla version of the code to prevent errors.
        return fallback(event, event, arg1, unitID, arg3, arg4, arg5, arg6, arg7, channelNumber, arg9, arg10, messageID, arg12);
    end
    -- Make sure we have a unitID formatted as "Player-Realm"
    unitID = DMRP.Utils.getPlayerName(character);
    ---@type Player
    local player = AddOn_TotalRP3.Player.static.CreateFromNameAndRealm(character, realm)

    local getConfigValue = TRP3_API.configuration.getValue
    -- Character name is without the server name is they are from the same realm or if the option to remove realm info is enabled
    if realm == TRP3_API.globals.player_realm_id or getConfigValue('remove_realm') then
        characterName = character;
    end

    -- Retrieve the character full RP name
    local customizedName = TRP3_API.chat.getFullnameUsingChatMethod(unitID);

    if customizedName then
        characterName = customizedName;
    end

    if GetCVar("chatClassColorOverride") ~= "1" then

        local classColour = DMRP.Utils.GetClassColourByUnitId(unitID);
        characterColor = TRP3_API.utils.color.CreateColor(classColour.r, classColour.g, classColour.b, 1)
    end

    if TRP3_API.chat.configShowNameCustomColors() then
        characterColor = player:GetCustomColorForDisplay() or characterColor;
    end

    -- If we did get a color wrap the name inside the color code
    if characterColor then
        -- And wrap the name inside the color's code
        characterName = characterColor:WrapTextInColorCode(characterName);
    end

    local OOC_INDICATOR_TEXT = TRP3_API.Ellyb.ColorManager.RED("<" .. TRP3_API.loc.CM_OOC .. "> ");
    if getConfigValue('chat_show_ooc') and not player:IsInCharacter() then
        -- Prefix name with OOC indicator.
        characterName = OOC_INDICATOR_TEXT .. characterName;
    end
    print('registering', prefix, callback)

    if getConfigValue("chat_show_icon") then
        local info = TRP3_API.utils.getCharacterInfoTab(unitID);
        if info and info.characteristics and info.characteristics.IC then
            characterName = TRP3_API.utils.str.icon(info.characteristics.IC, 15) .. " " .. characterName;
        end
    end

    return characterName;
end

DMRP.Compat.TRP3.colouredNameWithoutGUID = colouredNameWithoutGUID;
