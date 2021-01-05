--#======================#
--|Created By: Saelorable|
--|Date: 25/10/2020      |
--|Time: 16:18           |
--#======================#

DMRP.Tracker = DMRP.Tracker or {};
local Utils = DMRP.Utils
local log = Utils.log;

local function modifyTracker(tracker, amount, shield, bypassShield)


    amount = tonumber(amount);
    if DMRP.addon.db.profile.trackerBars[tracker] then
        local trackerTbl = DMRP.addon.db.profile.trackerBars[tracker]
        if shield and trackerTbl.shieldMax then

            trackerTbl.shield = trackerTbl.shield + amount;
            if trackerTbl.shield < 0 then trackerTbl.shield = 0 end
            if trackerTbl.shield > trackerTbl.shieldMax then trackerTbl.shield = trackerTbl.shieldMax end
        elseif amount < 0 then

            if trackerTbl.shield and trackerTbl.shield > 0 then
                trackerTbl.shield = trackerTbl.shield + amount -- we're reducing, but we already know amount is a negative
                if trackerTbl.shield < 0 then
                    trackerTbl.current = trackerTbl.current + trackerTbl.shield;
                    trackerTbl.shield = 0;
                end
            else
                trackerTbl.current = trackerTbl.current + amount
            end
        else

            trackerTbl.current = trackerTbl.current + amount
        end
        if trackerTbl.current < 0 then trackerTbl.current = 0 end
        if trackerTbl.current > trackerTbl.max then trackerTbl.current = trackerTbl.max end
        DMRP.UI.updateStatusBar(tracker)

        if DMRP.Compat.TRP3.isLoaded() then
            local profile = TRP3_API.profile.getProfileByID(TRP3_API.profile.getPlayerCurrentProfileID());

            profile.player.character.v = TRP3_API.utils.math.incrementNumber(profile.player.character.v or 1, 2);
            TRP3_API.events.fireEvent(TRP3_API.events.REGISTER_DATA_UPDATED,
                TRP3_API.globals.player_id, TRP3_API.profile.getPlayerCurrentProfileID(), "character");
        end

        return trackerTbl;
    else



    end
end
DMRP.Tracker.modifyTracker = modifyTracker;

local function checkTracker(tracker)
    if DMRP.addon.db.profile.trackerBars[tracker] then
        return DMRP.addon.db.profile.trackerBars[tracker]
    else



    end
end

DMRP.Tracker.checkTracker = checkTracker

local function heal(amount)
    modifyTracker('hp', amount, false)
end
local function sheild(amount)
    modifyTracker('hp', amount, true)
end
local function damage(amount)
    modifyTracker('hp', -amount)
end

DMRP.Tracker.heal = heal;
DMRP.Tracker.sheild = sheild;
DMRP.Tracker.damage = damage;