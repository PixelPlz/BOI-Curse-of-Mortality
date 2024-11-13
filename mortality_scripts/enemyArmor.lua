local mod = CurseOfMortality

local Settings = {
	StartingAmount = 100,
	NonLayoutMulti = 0.5,
	BossMinAmount = 20,
	DecreaseRate = 0.7,
	BarScale = 0.5,
}

local barStates = {
	Idle = 0,
	Disappearing = 1,
	BossBuff = 2,
}



-- Give NPCs damage reduction
function mod:NPCInit(entity)
	if mod:ShouldApplyCurseEffects()
	and entity:IsActiveEnemy(false) and entity.CanShutDoors -- Is an active enemy
	and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then -- Not friendly
		local room = Game():GetRoom()

		-- Enemies that don't spawn as a part of the room layout start with reduced armor
		local amount = Settings.StartingAmount
		if room:GetFrameCount() > 1 then
			amount = amount * Settings.NonLayoutMulti
		end

		-- Bosses in boss rooms don't go below 20 armor
		local min = 0
		if room:GetType() == RoomType.ROOM_BOSS and entity:IsBoss() then
			min = Settings.BossMinAmount
		end

		-- Create the bar sprite
		local sprite = Sprite()
		sprite:Load("gfx/mortality_bar.anm2", true)
		sprite:Play("Idle", true)
		sprite:PlayOverlay("EyeTwitch", true)
		sprite.PlaybackSpeed = 0.5
		sprite.Scale = Vector.One * Settings.BarScale

		-- Set the data
		entity:GetData().CurseOfMortalityArmor = {
			Amount = amount,
			Minimum = min,
			BarState = barStates.Idle,
			BarSprite = sprite,
		}
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.NPCInit)



function mod:NPCRender(entity, offset)
	local data = entity:GetData()

	if mod:ShouldApplyCurseEffects() and data.CurseOfMortalityArmor then
		local armor = data.CurseOfMortalityArmor
		local renderingReflections = Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT


		-- Bar logic
		if not Game():IsPaused() and not renderingReflections then
			armor.BarSprite:Update()

			-- Slowly decrease the armor
			if armor.BarState == barStates.Idle then
				local decrease = Settings.DecreaseRate / 2
				armor.Amount = math.max(0, armor.Amount - decrease)

				-- Set the frame
				local frame = math.floor(100 - armor.Amount)
				armor.BarSprite:SetFrame(frame)

				-- If its fully decreased or the enemy dies
				if armor.Amount <= 0 or entity:IsDead() then
					-- Stay if its a valid boss
					if armor.Minimum > 0 and not entity:IsDead() then
						armor.BarState = barStates.BossBuff

					-- Disappear otherwise
					else
						armor.BarState = barStates.Disappearing
						armor.BarSprite:Play("Close", true)
						armor.BarSprite:RemoveOverlay()
					end
				end


			-- Disappearing
			elseif armor.BarState == barStates.Disappearing then
				armor.BarSprite.Color = Color.Lerp(armor.BarSprite.Color, Color.Default, 0.1)

				if armor.BarSprite:IsFinished() then
					data.CurseOfMortalityArmor = nil
					local pitch = math.random(90, 110) / 100
					SFXManager():Play(SoundEffect.SOUND_MEAT_IMPACTS, 0.25, 2, false, pitch)
				end


			-- Boss buff
			elseif armor.BarState == barStates.BossBuff then
				-- Disappear if the boss dies
				if entity:IsDead() then
					armor.BarState = barStates.Disappearing
					armor.BarSprite:Play("Close", true)
					armor.BarSprite:RemoveOverlay()

				-- Fade out
				else
					armor.BarSprite:SetAnimation("IdleBuff", false)
					armor.BarSprite.Color = Color.Lerp(armor.BarSprite.Color, Color(1,1,1, 0.25), 0.1)
				end
			end
		end


		-- Render the bar
		if data.CurseOfMortalityArmor
		and entity.Visible and entity.Color.A > 0 and entity:GetSprite().Color.A > 0 -- The entity is visible
		and not renderingReflections then -- Don't render reflections for the icon
			local yOffset = entity.Size * entity.SizeMulti.Y * entity.Scale * Settings.BarScale
			local pos = entity.Position + entity.PositionOffset + Vector(0, yOffset)
			armor.BarSprite:Render(Isaac.WorldToRenderPosition(pos) + offset)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.NPCRender)



-- Handle taking damage
function mod:NPCDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	local data = entity:GetData()

	if mod:ShouldApplyCurseEffects() and data.CurseOfMortalityArmor
	and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		damageFlags = damageFlags + DamageFlag.DAMAGE_CLONES
		entity:GetData().redamaging = true -- Retribution bullshit fix...

		-- Apply the new damage amount
		local armor = data.CurseOfMortalityArmor
		local damageReduction = armor.Minimum + (100 - armor.Minimum) / 100 * armor.Amount
		local damageMulti = (100 - damageReduction) / 100
		entity:TakeDamage(damageAmount * damageMulti, damageFlags, damageSource, 1)

		entity:GetData().redamaging = false
		return false
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.IMPORTANT, mod.NPCDMG)