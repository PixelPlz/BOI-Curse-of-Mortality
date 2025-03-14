CurseOfMortality = RegisterMod("Curse of Mortality", 1)
local scriptsFolder = "mortality_scripts."


-- Load scripts
if REPENTOGON and MinimapAPI and BetterCurseAPI then
	local scripts = {
		"saveData",
		"curseHandler",
		"playerDamage",
		"enemyArmor",
	}

	for i, script in pairs(scripts) do
		include(scriptsFolder .. script)
	end


-- Missing dependency warning
else
	include(scriptsFolder .. "warning")
end