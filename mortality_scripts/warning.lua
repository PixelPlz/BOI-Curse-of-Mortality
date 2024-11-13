local mod = CurseOfMortality

local warningText = {
	"--------------------------------------------------",
	mod.Name .. " could not initialize properly!",
	"Make sure both MinimapAPI and Better CurseAPI are enabled!",
	"--------------------------------------------------",
}



-- Log + console error
for i, line in pairs(warningText) do
	Isaac.DebugString(line)
	print(line)
end

-- In-game error
function mod:DependencyWarning()
	local textX = Isaac.GetScreenWidth() / 5 - 10
	local textY = Isaac.GetScreenHeight() / 3
	local textScale = 1
	local textNewLineY = 16

	for i, line in pairs(warningText) do
		Isaac.RenderScaledText(line, textX, textY + i * textNewLineY, textScale, textScale, 255,0,0,1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.DependencyWarning)