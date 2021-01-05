--#======================#
--|Created By: Saelorable|
--|Date: 27/10/2020      |
--|Time: 18:43           |
--#======================#


DMRP.Compat = DMRP.Compat or {};
DMRP.Compat.TRP3 = DMRP.Compat.TRP3 or {}

local Utils = DMRP.Utils;
local config, log = Utils.config, Utils.log;

local trp3IsLoaded = false;

local function isLoaded()
    if trp3IsLoaded then
        return true;
    end

    if _G.TRP3_API then
        trp3IsLoaded = true;
        return true;
    end
    return false
end
DMRP.Compat.TRP3.isLoaded = isLoaded;

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
        log("unitID", unitID)
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

