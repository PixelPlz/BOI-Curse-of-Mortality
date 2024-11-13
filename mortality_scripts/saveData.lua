local mod = CurseOfMortality
local json = require("json")



-- Create the trackers
function mod:ResetSaveData()
	mod.SavedData = {
		DamageTracker = {},
		LostTracker = {},
		DeliriumKilled = false,
	}
end
mod:ResetSaveData()



-- Load the trackers when continuing a run / reset them when starting a new one
function mod:LoadTrackers(isContinue)
    if not isContinue then
		mod:ResetSaveData()

    elseif mod:HasData() then
		mod.SavedData = json.decode(mod:LoadData())
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.LoadTrackers)

-- Save the trackers
function mod:SaveTrackers()
	mod:SaveData(json.encode(mod.SavedData))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.SaveTrackers)



-- Reset the damage tracker when entering a new room
function mod:ClearDamageTracker()
	mod.SavedData.DamageTracker = {}
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.ClearDamageTracker)

-- Reset all the trackers when entering a new floor
function mod:ClearLostTracker()
	mod:ResetSaveData()
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.ClearLostTracker)