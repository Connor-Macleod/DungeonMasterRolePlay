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

local function initConfig()
    local defaultConfig = {
        rollType = 'ingame',
        showInListener = true
    }
    for x,v in pairs(defaultConfig) do
        if (not DMRP.Utils.config[x]) then
            DMRP.Utils.config[x] = v;
        end
    end
    log("config:", DMRP.Utils.config)
end

initConfig();