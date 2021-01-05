--#======================#
--|Created By: Saelorable|
--|Date: 25/10/2020      |
--|Time: 02:15           |
--#======================#


DMRP = DMRP or {}

DMRP.Utils = DMRP.Utils or {};
local Utils = DMRP.Utils
Utils.config = Utils.config or {};
local log = Utils.log;
local LibStub = LibStub
DMRP.Utils.version = GetAddOnMetadata("DungeonMasterRolePlay", "Version")

local unpack = unpack or table.unpack

function DMRP.addon:OnInitialize()
    local defaultConfig = {
        global = { debug = false },
        profile = {
            rollType = 'ingame',
            showInListener = true,
            rolls = {
                roll = {name='Default Roll',size = 20, targetable = false, advantageable = true},
                heal = {name='Healing Roll',size = 4, targetable = true, advantageable = true},
            },
            trackerBars = {
                hp = {
                    name = 'HP',
                    max = 10,
                    current = 10,
                    shield = 0,
                    shieldMax = 4,
                    shown = false,
                    shieldColour = { 0.529, 0.808, 0.922, 1 },
                    barColour = { 0, 0.65, 0, 1 },
                    backColour = { 0, 0.35, 0, 0.75 },
                    amountColour = { 0, 1, 0, 1 },
                    size = { width = 200, height = 20, movable = false },
                    pos = {},
                },
                mana = {
                    name = 'MP',
                    max = 100,
                    current = 100,
                    shown = false,
                    shieldColour = { 0.529, 0.922, 0.808, 1 },
                    barColour = { 0, 0, 0.65, 1 },
                    backColour = { 0, 0, 0.35, 0.75 },
                    amountColour = { 0, 0, 1, 1 },
                    size = { width = 200, height = 20, movable = false },
                    pos = {},
                },
            },
            shortCodes = {
                natHp = "[dc nat1 -1hp]",
                natDam = "[dc nat20 1dam]",
                nat = "[dc nat1 -1hp] [dc nat20 1dam]",
                easyAtk = "[dc 8-14 1dam] [dc 15-18 2dam] [dc >18 3dam]",
                medAtk = "[dc 12-17 1dam] [dc >17 2dam]",
                hardAtk = "[dc >17 1dam]",
                easyDef = "[dc <5 -1hp]",
                medDef = "[dc <3 -2hp] [dc 3-8 -1hp]",
                hardDef = "[dc <3 -3hp] [dc 3-5 -2hp] [dc 5-12 -1hp]",
                easyKill = "[dc 8-14 1kill] [dc 15-18 2kill] [dc >18 3kill]",
                medKill = "[dc 12-17 1kill] [dc >17 2kill]",
                hardKill = "[dc >17 1kill]",
            },
            enabledChatFrames = {
                [1] = true
            }
        }
    }
    self.db = LibStub("AceDB-3.0"):New("DMRPConfig", defaultConfig, true)
    DMRP.Utils.config = self.db
    log ('DMRP loaded', DMRP.Utils.version)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self:RefreshConfig();

    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfig:RegisterOptionsTable("DMRP", function()
        local availableRolls = {
            ingame = 'ingame Rolls (|cFFFFFF00/roll|r)',
        }
        if DMRP.Compat.TRP3.isLoaded() then
            availableRolls.trp3 = 'TRP3 Rolls (|cFFFFFF00/trp3 roll|r)'
        end

        local trackerBars = {
            name = 'Add/Edit stat bars';
            order = 1,
            type = "group",
            inline = true,
            args = {}
        }
        for i, v in pairs(DMRP.Utils.config.profile.trackerBars) do
            local thisBar = {
                name = 'Tracker: ' .. v.name,
                type = "group",
                args = {
                    name = {
                        name = 'Tracker Name',
                        desc = 'The name of the tracker!',
                        type = 'input',
                        order = 1,
                        get = function() return v.name end,
                        set = function(_, val)
                            v.name = val
                        end
                    },
                    id = {
                        name = 'Tracker ID',
                        desc = 'an identifier for slash commands to reference this tracker. if you\'re not sure what this is, leave it as the default',
                        type = 'input',
                        order = 2,
                        pattern = '^[0-9a-zA-Z_]*$',
                        usage = 'tracker ID must consist only of letters, numbers and underscores. leave blank to autopopulate',
                        get = function() return i end,
                        set = function(_, val)
                            if val == '' then
                                val = string.gsub(v.name, "[^0-9a-zA-Z_]", "_")
                            end

                            DMRP.UI.deleteStatusBar(i)
                            DMRP.Utils.config.profile.trackerBars[val] = DMRP.Utils.config.profile.trackerBars[i];
                            DMRP.Utils.config.profile.trackerBars[i] = nil;
                            DMRP.UI.createStatusBar(val)
                        end
                    },
                    max = {
                        name = 'Tracker Maximum',
                        desc = 'The maximum value for the tracker. changing this will reset the bar to it\'s maximum value',
                        type = 'input',
                        width = 'full',
                        order = 3,
                        validate = function(_, val)
                            if not string.find(val, '^%d*$') then
                                return 'Overcharge Maximum must be a number!'
                            end
                            if tonumber(val) <= 0 then
                                return 'Overcharge Maximum must be a positive value.'
                            end
                            return true
                        end,
                        get = function() return tostring(v.max) end,
                        set = function(_, val)
                            v.max = tonumber(val)
                            v.current = tonumber(val)
                            DMRP.UI.updateStatusBar(i);
                        end
                    },
                    shield = {
                        name = 'Overcharge',
                        desc = 'if this bar can be overcharged. I.e. a shield for hp bars, or conjured ammunition for an ammo bar',
                        type = 'toggle',
                        order = 4,
                        get = function() return v.shieldMax and v.shieldMax > 0 end,
                        set = function(_, val)
                            if val then
                                v.shieldMax = 4;
                                v.shield = 0;
                                v.shieldColour = { 0.529, 0.808, 0.922 }
                            else
                                v.shieldMax = nil;
                                v.shield = nil;
                                v.shieldColour = nil;
                            end
                            DMRP.UI.updateStatusBar(i);
                        end
                    },
                    statusBar = {
                        name = 'Tracker Display Settings',
                        type = "group",
                        order = 7,
                        args = {
                            showBar = {
                                name = 'Show Tracker',
                                desc = 'Should this tracker be visible?',
                                type = 'toggle',
                                width = 'full',
                                order = 1,
                                get = function() return v.shown end,
                                set = function(_, val)
                                    v.shown = val
                                    if val and not DMRP.UI.statusBarExists(i) then
                                        DMRP.UI.createStatusBar(i)
                                    else
                                        DMRP.UI.deleteStatusBar(i)
                                    end
                                    DMRP.UI.updateStatusBar(i);
                                end
                            },
                            barWidth = {
                                name = 'Tracker length',
                                desc = 'Adjust the width of this tracker',
                                type = 'range',
                                width = 'full',
                                order = 2,
                                min = 20,
                                max = 1080,
                                softMax = 500,
                                step = 1,
                                bigStep = 10,
                                get = function() return v.size.width end,
                                set = function(_, val)
                                    v.size.width = val
                                    DMRP.UI.updateStatusBar(i);
                                end
                            },
                            barHeight = {
                                name = 'Tracker Height',
                                desc = 'Adjust the height of this tracker',
                                type = 'range',
                                width = 'full',
                                order = 3,
                                min = 1,
                                max = 500,
                                softMax = 100,
                                step = 1,
                                bigStep = 1,
                                get = function() return v.size.height end,
                                set = function(_, val)
                                    v.size.height = val
                                    DMRP.UI.updateStatusBar(i);
                                end
                            },
                            moveBar = {
                                name = 'Make Tracker Movable',
                                desc = 'Show a grip on the sides of this bar to move it',
                                type = 'toggle',
                                width = 'full',
                                order = 4,
                                get = function() return v.size.movable end,
                                set = function(_, val)
                                    v.size.movable = val;
                                    DMRP.UI.updateStatusBar(i);
                                end
                            },
                            barColour = {
                                name = 'Bar Colour',
                                desc = 'The colour of the displayed bar',
                                order = 5,
                                type = 'color',
                                hasAlpha = true,
                                get = function()
                                    if v.barColour then
                                        return unpack(v.barColour)
                                    end
                                end,
                                set = function(_, r, g, b, a)
                                    v.barColour = { r, g, b, a }
                                    DMRP.UI.updateStatusBar(i);
                                end,
                            },
                            backColour = {
                                name = 'Bar background Colour',
                                desc = 'The colour of the displayed bar',
                                order = 6,
                                type = 'color',
                                hasAlpha = true,
                                get = function()
                                    if v.backColour then
                                        return unpack(v.backColour)
                                    end
                                end,
                                set = function(_, r, g, b, a)
                                    v.backColour = { r, g, b, a }
                                    DMRP.UI.updateStatusBar(i);
                                end,
                            },
                            amountColour = {
                                name = 'Tracker Amount Colour',
                                desc = 'The colour of the text on the bar',
                                order = 7,
                                type = 'color',
                                hasAlpha = true,
                                get = function()
                                    if v.amountColour then
                                        return unpack(v.amountColour)
                                    end
                                end,
                                set = function(_, r, g, b, a)
                                    v.amountColour = { r, g, b, a }
                                    DMRP.UI.updateStatusBar(i);
                                end,
                            },
                        }
                    },
                    code = {
                        name = 'Tracker Code',
                        desc = 'Copy and paste this into your about or currently to display this tracker',
                        type = 'input',
                        width = 'full',
                        order = -2,
                        get = function() return '${DMRP:' .. i .. '}' end,
                        set = function(_, val)
                        end
                    },
                    removeTracker = {
                        name = 'Delete Tracker',
                        type = 'execute',
                        confirm = true,
                        confirmText = 'Deleting a tracker is permanent. are you sure you want to continue?',
                        order = -1,
                        func = function()
                            DMRP.UI.deleteStatusBar(i)
                            DMRP.Utils.config.profile.trackerBars[i] = nil;
                        end
                    }
                }
            }

            if v.shieldMax then
                thisBar.args['maxShield'] = {
                    name = 'Overcharge Maximum',
                    desc = 'The maximum value for overcharge',
                    type = 'input',
                    order = 5,
                    validate = function(_, val)
                        if not string.find(val, '^%d*$') then
                            return 'Overcharge Maximum must be a number!'
                        end
                        if tonumber(val) <= 0 then
                            return 'Overcharge Maximum must be a positive value.'
                        end
                        return true
                    end,
                    get = function() return tostring(v.shieldMax) end,
                    set = function(_, val)
                        v.shieldMax = tonumber(val)
                        if v.shield > tonumber(val) then
                            v.shield = tonumber(val);
                        end
                    end
                }

                thisBar.args.statusBar.args['shieldColour'] = {
                    name = 'Overcharge Colour',
                    desc = 'The colour of the overcharge amount',
                    order = 8,
                    type = 'color',
                    get = function()
                        if v.shieldColour then
                            return unpack(v.shieldColour)
                        end
                    end,
                    set = function(_, r, g, b, a)
                        v.shieldColour = { r, g, b, a }
                        DMRP.UI.updateStatusBar(i);
                    end,
                }
            end

            trackerBars.args[i] = thisBar
        end
        local function rollPreset(preset, name)
            local preset = {
                name = "Roll Preset: "..preset.name,
                type = "group",
                desc = "Modify this preset",
                order = (name=='roll' and 1) or 10,
                args = {
                    name = {
                        name = 'Roll Preset Name',
                        desc = 'The name of the cide preset!',
                        type = 'input',
                        order = 1,
                        get = function() return preset.name end,
                        set = function(_, val)
                            preset.name = val
                        end
                    },
                    id = {
                        name = 'Preset ID',
                        desc = 'the ID of this tracker. What you type into the /roll! command or at the start of a [roll] inline',
                        type = 'input',
                        order = 2,
                        pattern = '^[0-9a-zA-Z_]*$',
                        usage = 'preset ID must consist only of letters, numbers and underscores. leave blank to autopopulate',
                        disabled=name=='roll',
                        get = function() return name end,
                        set = function(_, val)
                            if val == '' then
                                val = string.gsub(preset.name, "[^0-9a-zA-Z_]", "_")
                            end

                            DMRP.Utils.config.profile.rolls[val] = DMRP.Utils.config.profile.rolls[name];
                            DMRP.Utils.config.profile.rolls[name] = nil;
                        end
                    },
                    size = {
                        name = 'Dice size',
                        desc = 'The size of the dice used for this roll type',
                        type = 'input',
                        width = 'full',
                        order = 4,
                        validate = function(_, val)
                            if not string.find(val, '^%d*$') then
                                return 'Dice size must be a number!'
                            end
                            if tonumber(val) <= 0 then
                                return 'Dice size must be a positive value.'
                            end
                            return true
                        end,
                        get = function() return tostring(preset.size) end,
                        set = function(_, val)
                            preset.size = tonumber(val)
                        end
                    },

                    macros = {
                        name = 'Usage Examples',
                        desc = 'usage examples',
                        type = 'group',
                        order = -2,
                        args = {
                            regularInline = {
                                name = 'Regular usage example',
                                desc = 'You can copy and paste this into your message to use this dice roller',
                                type = 'input',
                                order = 1,
                                get = function() return '[' .. name .. ']' end,
                                set = function(_, val)
                                end
                            },
                            advantageInline = {
                                name = 'Advantage usage example',
                                desc = 'You can copy and paste this into your message to use this dice roller with advantage',
                                type = 'input',
                                order = 2,
                                get = function() return '[' .. name .. ' adv]' end,
                                set = function(_, val)
                                end
                            },



                            macroChar = {
                                name = UnitName("player")..' Specific Macro',
                                desc = 'creates a macro under the '..UnitName("player")..' specific Macros tab of the macro screen',
                                type = 'execute',
                                width = 'full',
                                order = 3,
                                func = function()
                                    CreateMacro('DMRP Roll: '..preset.name, 'INV_MISC_DICE_02', '/roll!'..((name ~= 'roll' and (' '..name)) or ''), true)
                                end
                            },
                            macroGlobal = {
                                name = 'General Macro',
                                desc = 'creates a macro under the General Macros tab of the macro screen',
                                type = 'execute',
                                width = 'full',
                                order = 4,
                                func = function()
                                    CreateMacro('DMRP Roll: '..preset.name, 'INV_MISC_DICE_02', '/roll!'..((name ~= 'roll' and (' '..name)) or ''), false)
                                end
                            },
                            macroCharAdv = {
                                name = UnitName("player")..' Specific Macro with advantage',
                                desc = 'creates a macro under the '..UnitName("player")..' specific Macros tab of the macro screen to roll with advantage',
                                type = 'execute',
                                width = 'full',
                                order = 5,
                                func = function()
                                    CreateMacro('DMRP Roll advantage: '..preset.name, 'INV_MISC_DICE_02', '/roll!'..((name ~= 'roll' and (' '..name)) or '')..' adv', true)
                                end
                            },
                            macroGlobalAdv = {
                                name = 'General Macro with advantage',
                                desc = 'creates a macro under the General Macros tab of the macro screen to roll with advantage',
                                type = 'execute',
                                width = 'full',
                                order = 6,
                                func = function()
                                    CreateMacro('DMRP Roll advantage: '..preset.name, 'INV_MISC_DICE_02', '/roll!'..((name ~= 'roll' and (' '..name)) or '')' adv', false)
                                end
                            }
                        }
                    }
                }
            }
            if name=='roll' then
                preset.args.info = {
                    name= 'The default roll preset, \'roll\` cannot be removed or renamed as it is used for default roll functionality.',
                    type='description',
                    order = 3,
                }
            else
                preset.args.info = {
                    name= 'remove preset',
                    order = -1,
                    type = 'execute',
                    confirm = true,
                    confirmText = 'Deleting a preset is permanent. are you sure you want to continue?',
                    order = -1,
                    func = function()
                        DMRP.Utils.config.profile.rolls[i] = nil;
                    end
                }

            end

            return preset;
        end
        local rollPresets = {
            name = "Dice Presets",
            type = "group",
            desc = "Presets for quick /roll! commands and inline rolls",
            inline=true,
            order = 2,
            args = {

            }
        }


        for i, v in pairs(DMRP.Utils.config.profile.rolls) do
            rollPresets.args[i] = rollPreset(v,i)
        end

        local optsTable = {
            type = 'group',
            name = 'DungeonMasterRolePlay',
            args = {
                dice = {
                    name = "Dice Rolling",
                    type = "group",
                    desc = "Manage dice defaults and settings",
                    order = 1,
                    args = {
                        rollingType = {
                            name = 'Roll system',
                            type = 'select',
                            order = 1,
                            desc = "DMRP can be customised to use different rolling behaviours. by default it uses the ingame /roll command. however, if you have TRP3 installed, it can use their dice functionality. \nRegardless of chosen behaviour, both types of rolls are detected |cFFFFFF00even if you do not have TRP3 installed|r.",
                            get = function() return DMRP.Utils.config.profile.rollType end,
                            set = function(_, val) DMRP.Utils.config.profile.rollType = val end,
                            values = availableRolls,
                        },
                        showInListener = {
                            name = 'Show Rolls in Listener',
                            type = 'toggle',
                            order = 1,
                            desc = "Enable this to show our roll formatting in listener. this includes a single display for advantage rolls. You can disable built in rolls in the listner menu, under filters.",
                            get = function() return DMRP.Utils.config.profile.showInListener end,
                            set = function(_, val) DMRP.Utils.config.profile.showInListener = val end
                        },
                        presets = rollPresets,
                        addTracker = {
                            name = 'Add Roll Preset',
                            type = 'execute',
                            order = 3,
                            func = function()
                                local id = "preset";
                                local i = 1;
                                while DMRP.Utils.config.profile.rolls[id .. i] do
                                    i = i + 1;
                                end
                                DMRP.Utils.config.profile.rolls[id .. i] = {
                                    name = 'Roll Preset - ' .. i,
                                    size = 20,
                                    targetable = false,
                                    advantageable = true
                                }
                            end
                        }
                    }
                },
                trackers = {
                    name = "Resource Bars",
                    type = "group",
                    desc = "Customise and configure resource Bars",
                    order = 2,
                    args = {
                        trackerBars = trackerBars,
                        addTracker = {
                            name = 'Add Tracker',
                            type = 'execute',
                            order = 2,
                            func = function()
                                local id = "tracker";
                                local i = 1;
                                while DMRP.Utils.config.profile.trackerBars[id .. i] do
                                    i = i + 1;
                                end
                                DMRP.Utils.config.profile.trackerBars[id .. i] = {
                                    name = 'Tracker Bar - ' .. i,
                                    max = 10,
                                    current = 10,
                                    shown = false,
                                    shieldColour = { 0.529, 0.808, 0.922, 1 },
                                    barColour = { 0, 0.65, 0, 1 },
                                    backColour = { 0, 0.35, 0, 0.75 },
                                    amountColour = { 0, 1, 0, 1 },
                                    size = { width = 200, height = 20, movable = false },
                                    pos = {},
                                }
                            end
                        }
                    }
                },
                --[[
                dming={
                    name = "DMing",
                    type = "group",
                    desc = "Manage Dungeon master settings, such as dice check defaults",
                    order = 3,
                    args={
                        -- more options go here
                    }
                }, --]] --
                profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(DMRP.Utils.config),
            }
        }


        if IsControlKeyDown() and IsAltKeyDown() then
            optsTable.args.debug = {
                name = "Debug Options",
                type = "group",
                desc = "options for debugging! if you don't know how you found this you probably shouldn't be in here.",
                order = 0,
                args = {
                    debugLogging = {
                        name = 'Enable Debug Logging',
                        type = 'toggle',
                        desc = "debug logging for developers. there's a lot of mess in here.",
                        get = function() return DMRP.Utils.config.global.debug end,
                        set = function(_, val) DMRP.Utils.config.global.debug = val end,
                    },
                }
            }
        end


        if DMRP.Compat.TRP3.isLoaded() then
            optsTable.args.trackers.args['preview'] = {
                name = "Tracker Preview",
                type = "group",
                desc = "Preview Trackers in Currently and Ic",
                inline = true,
                order = 3,
                args = {
                    CUPreview = {
                        name = 'Preview Currently',
                        type = 'execute',
                        order = 1,
                        width = 'full',
                        confirm = function()
                            local charinfo = DMRP.Compat.TRP3.getCharacterInfo(TRP3_API.globals.player_id)

                            return '|cFFFFFF00Currently:|r\n'..DMRP.Compat.TRP3.replaceStat(charinfo.character.CU);
                        end,
                        func = function()
                        end
                    },
                    COPreview = {
                        name = 'Preview OOC',
                        type = 'execute',
                        width = 'full',
                        order = 2,
                        confirm = function()
                            local charinfo = DMRP.Compat.TRP3.getCharacterInfo(TRP3_API.globals.player_id)

                            return '|cFFFFFF00OOC:|r\n'..DMRP.Compat.TRP3.replaceStat(charinfo.character.CO);
                        end,
                        func = function()
                        end
                    }
                }
            }
        end

        return optsTable
    end);
    AceConfigDialog:AddToBlizOptions("DMRP", "DMRP");


end


local f = CreateFrame("frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, message, addonContent,...)
    if event == 'PLAYER_ENTERING_WORLD' then

        for i, v in pairs(DMRP.Utils.config.profile.enabledChatFrames) do
            local chatFrame = _G["ChatFrame"..i]

            if v then
                table.insert(chatFrame.messageTypeList, 'DM')

            end
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = getglobal("ChatFrame"..i)

    end
end)

function DMRP.addon:RefreshConfig()

    for i, v in pairs(DMRP.Utils.config.profile.trackerBars) do
        if v.shown then
            DMRP.UI.createStatusBar(i)
        else
            DMRP.UI.deleteStatusBar(i)
        end
    end
end

