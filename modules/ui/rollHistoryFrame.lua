--#======================#
--|Created By: Saelorable|
--|Date: 04/11/2020      |
--|Time: 20:08           |
--#======================#


DMRP.UI = DMRP.UI or {}
local Utils = DMRP.Utils;
local log = Utils.log;
local AceGUI = LibStub("AceGUI-3.0")


local scroll
local rollHistoryFrame
local function showHistoryFrame()


    rollHistoryFrame = AceGUI:Create("Frame")
    rollHistoryFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    rollHistoryFrame:SetTitle("Roll Status")
    rollHistoryFrame:SetStatusText("Awaiting Rolls")
    rollHistoryFrame:SetLayout("fill")
    -- rollHistoryFrame:Hide()

    scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    rollHistoryFrame:AddChild(scroll)
end


local function updateRollHistory(show)

    if (not scroll or not rollHistoryFrame) and show then

        showHistoryFrame();
    elseif not scroll or not rollHistoryFrame then

        return;
    end
    local groupSize = 0;
    local rollCount = 0;
    local sortedPlayers = {}
    local totalDamage = 0;
    scroll:ReleaseChildren()
    rollHistoryFrame:SetStatusText("Players Rolled: " .. rollCount .. " out of " .. groupSize)
    for i = 1, GetNumGroupMembers() do
        local PlayerName, rank, _, _, _, _, zone, online = GetRaidRosterInfo(i);
        if online then
            local playerDisplayName = PlayerName
            local fullPlayerName = Utils.getPlayerName(PlayerName)
            local currentlyOOCWidget
            if DMRP.Compat.TRP3.isLoaded then
                local playerInfo = DMRP.Compat.TRP3.getCharacterInfo(fullPlayerName)
                playerDisplayName = TRP3_API.register.getCompleteName(playerInfo.characteristics or {}, fullPlayerName, false)
                if playerInfo and playerInfo.character and (playerInfo.character.CU or playerInfo.character.CO) then
                    local tabs = {}
                    local addTabs = false
                    local defaultTab = ''
                    if playerInfo.character.CU and #playerInfo.character.CU > 0 then
                        table.insert(tabs, { text = "Currently", value = playerInfo.character.CU })
                        defaultTab = playerInfo.character.CU;
                        addTabs = true
                    end

                    if playerInfo.character.CO and #playerInfo.character.CO > 0 then
                        table.insert(tabs, { text = "OOC", value = playerInfo.character.CO })
                        defaultTab = playerInfo.character.CO;
                        addTabs = true
                    end


                    if (addTabs == true) then
                        currentlyOOCWidget = AceGUI:Create("TabGroup")
                        currentlyOOCWidget:SetTitle("TRP info")
                        currentlyOOCWidget:SetTabs(tabs)
                        currentlyOOCWidget:SetFullWidth(true)

                        local info = AceGUI:Create("Label")
                        info:SetText('')
                        currentlyOOCWidget:AddChild(info)
                        local function SelectGroup(container, event, group)
                            info:SetText(group)
                        end

                        currentlyOOCWidget:SetCallback("OnGroupSelected", SelectGroup)
                        -- Set initial Tab (this will fire the OnGroupSelected callback)
                        currentlyOOCWidget:SelectTab(defaultTab)
                    end
                end
            end

            if Utils.getPlayerName(PlayerName) == Utils.getPlayerName() then
                if rank == 2 or rank == 1 then
                    DMRP.playerCanDM = true
                end
            end

            local playerWidget = AceGUI:Create("InlineGroup")
            playerWidget:SetLayout("Flow")
            playerWidget:SetTitle(playerDisplayName)
            playerWidget:SetFullWidth(true)

            local RollLabel = AceGUI:Create("Label")
            RollLabel:SetText('roll pending')
            playerWidget:AddChild(RollLabel)

            local playerRoll = DMRP.Dice.latestRolls[fullPlayerName]
            if playerRoll then

                if playerRoll.modifier == 0 then
                    for i,mod in ipairs(DMRP.Dice.mods) do
                        if not mod.target or DMRP.Utils.playerInList(mod.target, fullPlayerName) then
                            playerRoll.result = playerRoll.result + mod.mod;
                            playerRoll.modifier = playerRoll.modifier + mod.mod;
                        end
                    end
                end

                RollLabel:SetText(playerRoll.result .. " (d" .. playerRoll.diceSize .. "+" .. playerRoll.modifier .. ") (nat " .. (playerRoll.result - playerRoll.modifier) .. ")")
                rollCount = rollCount + 1

                local damageTaken = 0
                local damageDealt = 0
                local information = ''
                local kills = 0

                for j, v in ipairs(playerRoll.actions) do
                    if v.hp then
                        damageTaken = damageTaken + v.hp
                    end
                    if v.dam then
                        damageDealt = damageDealt + v.dam
                    end
                    if v.kill then
                        kills = kills + v.kill
                    end
                    if v.perception then
                        if not #information == 0 then
                            information = information .. ' - '
                        end

                        information = information .. " " .. v.perception
                    end
                end
                if damageTaken < 0 then
                    local hpLabel = AceGUI:Create("Label")
                    hpLabel:SetText('Has taken ' .. damageTaken .. ' HP damage')
                    hpLabel:SetFullWidth(true)
                    playerWidget:AddChild(hpLabel)
                elseif damageTaken > 0 then
                    local hpLabel = AceGUI:Create("Label")
                    hpLabel:SetText('Has healed ' .. damageTaken .. ' HP damage')
                    hpLabel:SetFullWidth(true)
                    playerWidget:AddChild(hpLabel)
                end
                if damageDealt > 0 then
                    local damageLabel = AceGUI:Create("Label")
                    damageLabel:SetText('Has dealt ' .. damageDealt .. ' enemy damage')
                    damageLabel:SetFullWidth(true)
                    playerWidget:AddChild(damageLabel)
                elseif damageDealt < 0 then
                    local damageLabel = AceGUI:Create("Label")
                    damageLabel:SetText('Has restored ' .. damageDealt .. ' enemy damage')
                    damageLabel:SetFullWidth(true)
                    playerWidget:AddChild(damageLabel)
                end
                totalDamage = totalDamage + damageDealt;
                if kills > 0 then
                    local killLabel = AceGUI:Create("Label")
                    killLabel:SetText('Has killed ' .. kills .. ' enemies')
                    killLabel:SetFullWidth(true)
                    playerWidget:AddChild(killLabel)
                elseif kills < 0 then
                    local killLabel = AceGUI:Create("Label")
                    killLabel:SetText('Has revived ' .. kills .. ' enemies')
                    killLabel:SetFullWidth(true)
                    playerWidget:AddChild(killLabel)
                end
                if #information > 0 then
                    local infoLabel = AceGUI:Create("Label")
                    infoLabel:SetText('Has learned the following:  ' .. information)
                    infoLabel:SetFullWidth(true)
                    playerWidget:AddChild(infoLabel)
                end
            end


            local lastEmotes = AceGUI:Create("InlineGroup")
            lastEmotes:SetLayout("Flow")
            lastEmotes:SetTitle("Last Five Emotes")
            lastEmotes:SetFullWidth(true)
            playerWidget:AddChild(lastEmotes)
            if DMRP.Chat.lastEmotes[fullPlayerName] then
                for _, v in ipairs(DMRP.Chat.lastEmotes[fullPlayerName]) do
                    local emoteLabel = AceGUI:Create("Label")
                    if v.channel == 'CHAT_MSG_EMOTE' then
                        emoteLabel:SetText(playerDisplayName .. " " .. v.message)

                    else
                        emoteLabel:SetText('[' .. playerDisplayName .. "]: " .. v.message)
                    end

                    emoteLabel:SetFullWidth(true)
                    lastEmotes:AddChild(emoteLabel)
                end
            end

            if currentlyOOCWidget then
                playerWidget:AddChild(currentlyOOCWidget)
            end

            table.insert(sortedPlayers, { widget = playerWidget, roll = playerRoll })
            groupSize = groupSize + 1
        end
    end

    table.sort(sortedPlayers, function(a, b)
        if (a.roll and b.roll) then
            return a.roll.result < b.roll.result;
        end
        if not a.roll then return false end
        return true
    end)

    for i, player in ipairs(sortedPlayers) do
        scroll:AddChild(player.widget);
    end

    local status = ''
    if rollCount > 0 and rollCount < groupSize then
        status = status .. "Players Rolled: " .. rollCount .. " out of " .. groupSize
    elseif rollCount == 0 then
        status = status .. "Rolls pending"
    elseif rollCount == groupSize then

        status = status .. "Rolls complete!"
    end
    if totalDamage ~= 0 then
        if #status > 0 then
            status = status .. ' - '
        end
        status = status .. "total damage: " .. totalDamage
    end



    rollHistoryFrame:SetStatusText(status)
end

DMRP.UI.updateRollHistory = updateRollHistory

--/dm [dc 1-5 -1hp] [dc nat1 -1hp] [dc 8-16 1dam] [dc 17-20 2dam] [dc nat20 1dam] [dc 1-10 "you don't notice anything"] [dc 10-20 "you notice something"] There's an enemy! attack them!
