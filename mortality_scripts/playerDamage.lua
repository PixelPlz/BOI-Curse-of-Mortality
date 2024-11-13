local mod = CurseOfMortality

local Settings = {
	KeeperSafeguard = 1,
	MaxMantleUses = 7,
	MantleSoundDelay = 7,
}



-- Make sure self-damage items don't increase the damage count
local damageFlagBlacklist = {
	DamageFlag.DAMAGE_CLONES, -- Avoid infinite loops
	DamageFlag.DAMAGE_RED_HEARTS,
	DamageFlag.DAMAGE_INVINCIBLE,
	DamageFlag.DAMAGE_IV_BAG,
	DamageFlag.DAMAGE_FAKE,
	DamageFlag.DAMAGE_NO_MODIFIERS,
	DamageFlag.DAMAGE_NO_PENALTIES,
}

function mod:NoBlacklistedDamageFlags(damageFlags)
	for i, flag in pairs(damageFlagBlacklist) do
		if (damageFlags & flag > 0) then
			return false
		end
	end
	return true
end



-- Increasing player damage
function mod:PlayerDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod:ShouldApplyCurseEffects() and damageAmount > 0
	and mod:NoBlacklistedDamageFlags(damageFlags) then
		local player = entity:ToPlayer()
		local playerIdx = player:GetPlayerIndex() + 1

		-- Make sure the player has a tracker
		if not mod.SavedData.DamageTracker[playerIdx] then
			mod.SavedData.DamageTracker[playerIdx] = 0
		end

		-- Keeper and Tainted Keeper are unaffected for the first 2 hits
		local damageCounter = mod.SavedData.DamageTracker[playerIdx]
		local damageIncrease = damageCounter

		if player:GetPlayerType() == PlayerType.PLAYER_KEEPER or player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
			damageIncrease = math.max(0, damageIncrease - Settings.KeeperSafeguard)
		end

		-- Apply the new damage amount
		damageFlags = damageFlags + DamageFlag.DAMAGE_CLONES
		entity:TakeDamage(damageAmount + damageIncrease, damageFlags, damageSource, 1)

		-- Sound
		local volume = math.min(0.8, damageCounter * 0.2)
		local pitch = math.random(90, 110) / 100
		SFXManager():Play(SoundEffect.SOUND_STATIC, volume, 0, false, pitch)

		-- Increase future damage taken
		mod.SavedData.DamageTracker[playerIdx] = mod.SavedData.DamageTracker[playerIdx] + 1
		return false
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.IMPORTANT, mod.PlayerDMG, EntityType.ENTITY_PLAYER)



-- Lost Holy Mantle limit
function mod:PlayerHandlekMantle(player)
	local effects = player:GetEffects()

	if mod:ShouldApplyCurseEffects()
	and (player:GetPlayerType() == PlayerType.PLAYER_THELOST -- The Lost
	or effects:HasNullEffect(NullItemID.ID_LOST_CURSE)) then -- Soul of the Lost
		local playerIdx = player:GetPlayerIndex() + 1
		local data = player:GetData()
		local currentMantleCount = effects:GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE)


		-- Block future Mantles if enough of them have been broken
		if mod.SavedData.LostTracker[playerIdx] and mod.SavedData.LostTracker[playerIdx] >= Settings.MaxMantleUses then
			effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE, -1)


		-- Check if a Holy Mantle has been used
		elseif data.LastMantleCount and currentMantleCount < data.LastMantleCount then
			-- Make sure the player has a tracker
			if not mod.SavedData.LostTracker[playerIdx] then
				mod.SavedData.LostTracker[playerIdx] = 0
			end

			-- Increase the tracker
			mod.SavedData.LostTracker[playerIdx] = mod.SavedData.LostTracker[playerIdx] + 1


			-- Break effects
			data.MantleBreakSound = Settings.MantleSoundDelay

			if mod.SavedData.LostTracker[playerIdx] >= Settings.MaxMantleUses then
				local color = Color(1,1,1, 1, 0.5,0.5,0.5)
				color:SetTint(1,1,1, 0.9)

				for i = 1, 6 do
					local vector = Vector.FromAngle(math.random(359)):Resized(math.random(3, 5))
					local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, BackdropType.DEPTHS, player.Position, vector, player):ToEffect()
					rocks:GetSprite():Play("rubble", true)
					rocks:GetSprite().Color = color
				end
			end
		end

		data.LastMantleCount = currentMantleCount


		-- Break sound
		if data.MantleBreakSound then
			if data.MantleBreakSound <= 0 then
				local volume = (1 / Settings.MaxMantleUses) * mod.SavedData.LostTracker[playerIdx]
				local pitch = math.random(90, 110) / 100
				SFXManager():Play(SoundEffect.SOUND_STATIC, volume, 0, false, pitch)

				data.MantleBreakSound = nil
			else
				data.MantleBreakSound = data.MantleBreakSound - 1
			end
		end
	end


	-- Indicate that Holy Mantle can be used in the Delirium fight
	if Game():GetRoom():GetFrameCount() == 1
	and BetterCurseAPI:curseIsActive(mod.CurseID) and mod:InDeliriumRoom() then
		for i = 1, Game():GetNumPlayers() do
			if mod.SavedData.LostTracker[i] and mod.SavedData.LostTracker[i] >= Settings.MaxMantleUses then
				player:SetColor(Color(1,1,1, 1, 1,1,1), 10, 1, true, false)
				SFXManager():Play(SoundEffect.SOUND_HOLY)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.PlayerHandlekMantle)