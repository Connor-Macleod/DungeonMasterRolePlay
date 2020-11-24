--#======================#
--|Created By: Saelorable|
--|Date: 25/10/2020      |
--|Time: 11:49           |
--#======================#

local Utils = DMRP.Utils
local Dice = DMRP.Dice
local log = Utils.log;
log("init slash");


SLASH_DMRP1, SLASH_DMRP2 = '/dmrp', '/dungeonmasteroleplay'
SLASH_ROLLEX1, SLASH_ROLLEX2 = '/!roll', '/roll!'
SLASH_DM1 = '/dm'
SLASH_DC1 = '/dc'
--SLASH_PERCEPTION1 = '/perception'
SLASH_EVENT1, SLASH_EVENT2 = '/event', '/ev'



local function spreadSlashArgs(text)
    local argList, inQuotes, counter, firstQuotes = {}, false, 1, false;
    log("text:", text)
    for i in string.gmatch(text, "%S+") do
        if string.match(i, [=[^["'%[]]=]) then inQuotes = true; firstQuotes = true end
        log("Loopstate:", i, counter, inQuotes)
        if not inQuotes then
            table.insert(argList, counter, i)
            counter = counter + 1
        else
            if firstQuotes then
                table.insert(argList, counter, i)
            else
                argList[counter] = argList[counter] .. ' ' .. i
            end
        end
        firstQuotes = false;
        if string.match(i, [=[["'%]]$]=]) then inQuotes = false; counter = counter + 1 end
    end
    log("argList:", argList)
    return argList;
end

DMRP.Dice.spreadSlashArgs = spreadSlashArgs

local function evalDiceRoll(presetName, advantage, prams)
    local rollConfig = DMRP.Utils.config.profile.rolls[presetName];
    if not rollConfig then rollConfig = DMRP.Utils.config.profile.rolls['roll']; end
    local size = rollConfig.size;
    local modifier = 0;
    if prams then
        local i = 1;
        if prams[i] == 'advantage' or prams[i] == 'adv' then i = i + 1 end
        size = prams[i] or rollConfig.size; i = i + 1
        modifier = prams[i] or 0
    else

    end


    DMRP.Dice.doDiceRoll(size, 1, modifier);
    if (advantage) then
        DMRP.Dice.doDiceRoll(size, 1, modifier);
    else

    end


    return {size = size, modifier= modifier, adv = advantage}
end
DMRP.Dice.evalDiceRoll = evalDiceRoll;

local function rollex(msg, editBox)
    log("rollingDie")
    -- does rolls
    if type(msg) == 'string' then
        msg = spreadSlashArgs(msg)
    end
    log("message:", msg)
    if not msg[1] then
        log("setting rolltype to freeform")
        --if there's a DC awaiting, we do a dc roll
        --msg[1] = "dc"
        --otherwise we default do a freeform roll
        msg[1] = "freeform"
    end
    local advantage = false;
    if msg[1] == 'advantage' or msg[2] == 'advantage' or msg[1] == 'adv' or msg[2] == 'adv' then
        advantage = true
        Dice.diceState('advantage', 2)
    end
    if DMRP.Utils.config.profile.rolls[msg[1]] then evalDiceRoll(msg[1], advantage) else evalDiceRoll('roll', advantage, msg); end
end

SlashCmdList["ROLLEX"] = rollex

local function stripChars(str)
    str = string.lower(str);
    local tableAccents = {}
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["œ"] = "oe"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["ÿ"] = "y"
    local normalizedString = ''

    for strChar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
        if tableAccents[strChar] ~= nil then
            normalizedString = normalizedString .. tableAccents[strChar]
        else
            normalizedString = normalizedString .. strChar
        end
    end
    return normalizedString
end

local function findplayer(player)
    --TODO: implement this, a function that will first check for an exact match, then a match ignoring any accents,
    --    then a partial match, ignoring accents. prioritising the start of a name. LATER; implement the ability to
    --    save shorthands against players

    -- for now, we assume player is a %t targetted player, and therefore just get realm name.
    if (UnitInRaid(player)) then
        return DMRP.Utils.getPlayerName(player);
    end


    for i = 1, GetNumGroupMembers() do
        local playerName = GetRaidRosterInfo(i);
        if string.match(playerName, player) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end


    for i = 1, GetNumGroupMembers() do
        local playerName = GetRaidRosterInfo(i);
        if stripChars(playerName) == stripChars(player) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end


    for i = 1, GetNumGroupMembers() do
        local playerName = GetRaidRosterInfo(i);
        if string.match("^" .. stripChars(playerName), stripChars(player)) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end

    for i = 1, GetNumGroupMembers() do
        local playerName = GetRaidRosterInfo(i);
        if string.match(stripChars(playerName), stripChars(player)) then
            return DMRP.Utils.getPlayerName(playerName);
        end
    end

    return nil
end

local function registerDC(command, DCs)
    local args = spreadSlashArgs(command);

    log("args!!!!!", command, args);

    local DC = args[1];
    local action = args[2];

    local range = { min = nil, max = nil, nat = nil, action = nil, target = nil }
    local natural = string.match(DC, "nat([+-]?[0-9]+)")
    local lt = string.match(DC, "<=([+-]?[0-9]+)")
    local lt = string.match(DC, "<([+-]?[0-9]+)") and string.match(DC, "<([+-]?[0-9]+)") - 1 or lt
    local gt = string.match(DC, ">=([+-]?[0-9]+)")
    local gt = string.match(DC, ">([+-]?[0-9]+)") and string.match(DC, ">([+-]?[0-9]+)") + 1 or gt
    local rangemin, rangemax = string.match(DC, "([+-]?[0-9]+)-([+-]?[0-9]+)")
    if natural then
        range.nat = tonumber(natural)
    elseif lt then
        range.max = tonumber(lt)
    elseif gt then
        range.min = tonumber(gt)
    elseif rangemin and rangemax then
        range.min = tonumber(rangemin)
        range.max = tonumber(rangemax)
    end

    local hp = string.match(args[2], "([+-]?[0-9]+)hp")
    local dam = string.match(args[2], "([+-]?[0-9]+)dam")
    local dam = string.match(args[2], "([+-]?[0-9]+)dmg") or dam
    local kill = string.match(args[2], "([+-]?[0-9]+)kill")
    local kill = string.match(args[2], "([+-]?[0-9]+)kills") or kill

    log("action: ",hp, dam, kill, args[2])

    if hp then
        range.action = { hp = tonumber(hp) }
    elseif dam then
        range.action = { dam = tonumber(dam) }
    elseif kill then
        range.action = { kill = tonumber(kill) }
    else
        range.action = { perception = args[2] }
    end

    if args[3] then
        range.target = {};
        for i, player in ipairs(args) do
            if i > 2 then
                local targetPlayer = findplayer(player)
                if targetPlayer then
                    table.insert(range.target, targetPlayer);
                end
            end
        end
    end
    -- DC nat1 -2hp
    -- DC <3 -1hp
    -- DC >5 1dmg
    -- DC >8 2dmg
    -- DC >12 3dmg
    -- DC >=20 Kill

    -- DC <8 "Nothing seems strange"

    return range;
end

local function registerModifier(command)
    local args = spreadSlashArgs(command);


    local modifier = args[1];
    local count = args[2] or 1;
    local modObj = {mod = modifier, roundCount = 1}

    if args[3] then
        modObj.target = {};
        for i, player in ipairs(args) do
            if i > 2 then
                local targetPlayer = findplayer(player)
                if targetPlayer then
                    table.insert(modObj.target, targetPlayer);
                end
            end
        end
    end

    return modObj;
end


local function event(msg, editBox)
    -- handles player actions
end

SlashCmdList["EVENT"] = event

DMRP.Dice.dcs = {};
DMRP.Dice.mods = {};

local dcString = ''
local function dm(msg, editBox)
    -- handles generic DM actions

    DMRP.Dice.resetDice();
    msg = dcString .. " " ..msg
    dcString = '';
    for match in msg:gmatch('%[qdc [a-zA-Z]+%]') do
        local shorthand = string.match(match:sub(2, -2), 'qdc ([a-zA-Z]+)')
        if DMRP.addon.db.profile.shortCodes[shorthand] then
            msg = string.gsub(msg, DMRP.Utils.escapePattern(match), DMRP.addon.db.profile.shortCodes[shorthand])

        end
    end


    for command in msg:gmatch('%[[^%]]+%]') do
        log("matched command", command)
        local shouldRemove = false;
        local commandStripped = command:sub(2, -2);
        local commandProcessing = commandStripped;
        if string.lower(commandProcessing):sub(1, 2) == "dc" then
            log("matched DC", commandProcessing)
            shouldRemove = true
            table.insert(DMRP.Dice.dcs, registerDC(commandProcessing:sub(3, -1), DMRP.Dice.dcs))
        elseif string.lower(commandProcessing):sub(1, 3) == "mod" then
            log("matched modifier", commandProcessing)
            shouldRemove = true
            table.insert(DMRP.Dice.mods, registerModifier(commandProcessing:sub(4, -1), DMRP.Dice.mods))
        end
        log ("mods", DMRP.Dice.mods)

        log("removing", shouldRemove, DMRP.Utils.escapePattern(command));

        if shouldRemove then
            msg = msg:gsub(DMRP.Utils.escapePattern(command) .. " *", '')
        end
    end

    DMRP.Chat.splitAndSendChat(msg, "RAID_WARNING");

    log('dcs', DMRP.Dice.dcs)
    local DCsMessages = {};
    for i,dc in ipairs(DMRP.Dice.dcs) do
        if dc.action and not DCsMessages[1] then
            table.insert(DCsMessages, "dice check! please roll 20!");
        end
    end

    if  DCsMessages[1] then
        DMRP.Chat.splitAndSendChat(DCsMessages, 'RAID_WARNING')
    end


    local ModifierMessages = {'Modifiers: '};
    for i,mod in ipairs(DMRP.Dice.mods) do
        local ModifierMessage = "("

        if mod.target then
            for j,target in ipairs(mod.target) do
                ModifierMessage = ModifierMessage .. Ambiguate(target, "short")
                if mod.target[j+1] then
                    ModifierMessage = ModifierMessage..", "
                end
            end
            ModifierMessage = ModifierMessage..": "
        else
            ModifierMessage = ModifierMessage.."Everyone: "
        end

        ModifierMessage = ModifierMessage .. "add a modifier of "..mod.mod.." to next roll"

        ModifierMessage = ModifierMessage .. ")"
        table.insert(ModifierMessages, ModifierMessage);
    end

    if  ModifierMessages[2] then
        DMRP.Chat.splitAndSendChat(ModifierMessages, 'RAID_WARNING')
    end
end

SlashCmdList["DM"] = dm

local function dc(msg, editBox)
    -- prepare DM without sending
    if type(msg) == 'string' and spreadSlashArgs(msg)[1] == 'clear' then
        dcString = ''
    elseif type(msg) == 'string' then
        dcString = dcString .. ' ' .. msg
    end
    DMRP.Chat.fakeChatMessage(dcString, "RAID_WARNING", DMRP.Utils.getPlayerName);
end
SlashCmdList["DC"] = dc

local paused = false

SlashCmdList["DMRP"] = function(msg, editBox)
    -- handles all actions

    if type(msg) == 'string' then
        msg = spreadSlashArgs(msg)
    end

    if msg[1] == 'show' then
        DMRP.UI.updateRollHistory(true);
    elseif msg[1] == 'pause' then
        if paused then
            DMRP.Chat.splitAndSendChat('!!! -- Time resumes -- !!!', 'RAID_WARNING')
        else
            DMRP.Chat.splitAndSendChat('!!! -- Timepause Start -- !!!', 'RAID_WARNING')
        end
        paused = not paused;

    elseif msg[1] == 'roll' then
        table.remove(msg, 1)
        rollex(msg, editBox)
    elseif msg[1] == 'dm' then
        table.remove(msg, 1)
        dm(msg, editBox)
    elseif msg[1] == 'intro' then
        local introMessage = ''
        if msg[2] then
            introMessage = introMessage..'Welcome to '.. msg[2]:sub(2,-2) .. '. '
        else
            introMessage = introMessage..'Welcome to today\'s event. '
        end
        introMessage = introMessage..'I am your DM, ' .. (UnitName("player") or "Saelora")..'! Today\'s event is run with the assistance of DMRP. '
        introMessage = introMessage..'Dice rolls for Dice Checks are out of 20. Healing rolls are out of 4. '
        introMessage = introMessage..'Dice checks will be listed within curly brackets {like this}. If more than one check applies to your roll, all will apply. If modifiers are applied, they will not have impact upon checks that ask for a natural roll. '
        introMessage = introMessage..'if at any time you are unsure of the outcome of your roll. please do ask. '
        introMessage = introMessage..'you may add modifiers before the roll if you know how to do so. but if you\'re unsure, feel free to just /roll 20 and add the result after. both ways around work. '
        introMessage = introMessage..'if at any time you wish to perform a freeform emote, that is entirely fine! But please do not roll for it until prompted. (as i may miss it and assume you\'re doing a regular roll. i am a simple DM.) '
        introMessage = introMessage..'Please put 10/10 hp into your currently or about. If you hit 0HP you are unable to continue until rescued by a healer, or pulled clear of the fighting by an ally (at wich point you may return with 1hp if you so choose) '
        DMRP.Chat.splitAndSendChat(introMessage, 'RAID_WARNING')
    elseif msg[1] == 'hp' then
        log('tracking hp')
        local tracker = {}
        if msg[2] == 'dam' then
            tracker = DMRP.Tracker.damage(msg[3])
        elseif msg[2] == 'heal' then
            tracker = DMRP.Tracker.heal(msg[3])
        elseif msg[2] == 'shield' then
            tracker = DMRP.Tracker.sheild(msg[3])
        else
            DMRP.UI.createStatusBar('hp')
        end
        if not tracker or not tracker.current then
            tracker = DMRP.Tracker.checkTracker('hp')
        end
        if tracker.current and not DMRP.UI.statusBarExists('hp') then
            DMRP.Chat.fakeChatMessage('has '..tracker.current..' hitpoints out of '..tracker.max, "EMOTE", DMRP.Utils.getPlayerName());
            if tracker.shield and tracker.shield > 0 then
                DMRP.Chat.fakeChatMessage('is also shielded for '..tracker.shield..' hitpoints.', "EMOTE", DMRP.Utils.getPlayerName());
            end
        end
    end

end
