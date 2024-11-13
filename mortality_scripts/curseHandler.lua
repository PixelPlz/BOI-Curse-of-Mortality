local mod = CurseOfMortality


-- Add the curse to Curse API
local iconSprite = Sprite()
iconSprite:Load("gfx/ui/mortality_curse_icon.anm2", true)
local icon = { iconSprite, "Idle", 0, }

mod.CurseID = BetterCurseAPI:registerCurse("Curse of Mortality!", 0, false, icon)
mod.CurseBitMask = BetterCurseAPI:curseBit(mod.CurseID)



-- Don't have other curses in the Void
function mod:RemoveCurses()
	local level = Game():GetLevel()

	if level:GetAbsoluteStage() == LevelStage.STAGE7 then
		level:RemoveCurses(level:GetCurses())
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_LEVEL, CallbackPriority.LATE, mod.RemoveCurses)

-- Force the curse in the Void, even with Black Candle
function mod:Update()
	local level = Game():GetLevel()

	if level:GetAbsoluteStage() == LevelStage.STAGE7
	and mod.SavedData.DeliriumKilled ~= true then
		level:AddCurse(mod.CurseBitMask)
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, mod.Update)



-- Make the curse inert during the Delirium fight
function mod:InDeliriumRoom()
	local room = Game():GetRoom()

	if room:GetType() == RoomType.ROOM_BOSS and room:GetBossID() == BossType.DELIRIUM then
		return true
	end
	return false
end

-- Check if the curse's effects should be active
function mod:ShouldApplyCurseEffects()
	if BetterCurseAPI:curseIsActive(mod.CurseID) and not mod:InDeliriumRoom() then
		return true
	end
	return false
end



-- Update the curse icon
function mod:NewRoom()
	if BetterCurseAPI:curseIsActive(mod.CurseID) then
		for i, entry in pairs(MinimapAPI.MapFlags) do
			if entry.ID == mod.CurseID then
				entry.frame = mod:InDeliriumRoom() and 1 or 0
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.NewRoom)

-- Remove the curse when Delirium is defeated
function mod:DeliriumDeath(rng, pos)
	if mod:InDeliriumRoom() then
		mod.SavedData.DeliriumKilled = true
		BetterCurseAPI:removeCurse(mod.CurseID)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.DeliriumDeath)