
for k, v in pairs(file.Find("gamemodes/ultimatechimerahunt/gamemode/scoreboard/*.lua", "GAME")) do
	include("scoreboard/" .. v);
end

LocalPlayer().Scoreboard = nil;

function SetCenteredPosition(panel, x, y)
	
	local w, h = panel:GetSize();
	panel:SetPos((x - (w * .5)), (y - (h * .5)));
	
end


function GM:ScoreboardShow()

	local ply = LocalPlayer();

	if (!ply.Scoreboard) then
		CreateScoreboard();
	end
	
	gui.EnableScreenClicker(true);
	ply.Scoreboard:SetVisible(true);
	
	UpdateScoreboard(ply.Scoreboard)

	return true;

end

function GM:ScoreboardHide()

	local ply = LocalPlayer();
	
	if (ply.Scoreboard) then
		ply.Scoreboard:SetVisible(false);
	end
	
	gui.EnableScreenClicker(false);

	return true;

end



function CreateScoreboard()
	
	local ply = LocalPlayer();
	
	if (!ply.Scoreboard) then
		
		ply.Scoreboard = vgui.Create("UCScoreboard");
		UpdateScoreboard(ply.Scoreboard);
		
	end
	
end


