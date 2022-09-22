surface.CreateFont("MapNames", {font = "coolvetica", size = ScreenScale(7), weight = 400, antialias = true, additive = false});


local sw, sh = ScrW(), ScrH();

local PANEL = {};


function PANEL:Init()
	
end


local function GetNiceMapName()
	
end


function PANEL:PerformLayout()

	local txt = game.GetMap();

	surface.SetFont("Default"); -- Font : ScoreboardSub
	local w, h = surface.GetTextSize(txt);
	
	self:SetSize((w * 1.32), h);
	
end


function PANEL:Paint( w, h )
	
	local w, h = self:GetSize()
	draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 100));
	local txt = game.GetMap();
	DrawNiceText(txt, "Default", (w * .5), 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, 250); -- Font : ScoreboardSub
	
end

vgui.Register("UCMapName", PANEL, "Panel");

