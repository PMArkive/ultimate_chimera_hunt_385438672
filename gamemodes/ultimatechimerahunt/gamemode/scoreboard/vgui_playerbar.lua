surface.CreateFont("UCPlayerName", {font = "coolvetica", size = ScreenScale(7), weight = 400, antialias = true, additive = false});

local grad = surface.GetTextureID("gui/center_gradient");
local font = "Default";

local textureTable = {}
for k, v in pairs(file.Find("materials/UCH/ranks/*.vmt", "GAME")) do
	textureTable[string.Replace(v, ".vmt", "")] = surface.GetTextureID("UCH/ranks/" .. v);
end

local sw, sh = ScrW(), ScrH();

local PANEL = {};

function PANEL:Init()

	self.Player = nil;
	self.Rank = "ensign";
	
	self.plyAvatar = vgui.Create("AvatarImage", self);
	
	self.plyName = vgui.Create("DLabel", self);
	self.plyPresses = vgui.Create("DLabel", self);
	self.plyTimesBit = vgui.Create("DLabel", self);
	self.plyPing = vgui.Create("DLabel", self);
	self.plyClass = vgui.Create("DLabel", self);
	
end


function PANEL:SetPlayer(ply)

	self.Player = ply;
	self.plyAvatar:SetPlayer(ply);
	self:UpdatePlayerData();
	
end


function PANEL:UpdatePlayerData()
	
	if (self.Player == nil || !self.Player:IsValid()) then
		self:Remove();
		return;
	end
	
	local ply = self.Player;
	local name = tostring(ply:Name());
	local presses = tostring(ply:Frags());
	local timesbit = tostring(ply:Deaths());
	local ping = tostring(ply:Ping());
	local class = ply:UCHGetUserGroup();
	
	self.plyName:SetText(name);
	self.plyPresses:SetText(presses);
	self.plyTimesBit:SetText(timesbit);
	self.plyPing:SetText(ping);
	self.plyClass:SetText(class);
	
	self.Rank = ply:GetRank():lower();
	
end


function PANEL:PerformLayout()

	local av, name, press, bit, ping, rank = self.plyAvatar, self.plyName, self.plyPresses, self.plyTimesBit, self.plyPing, self.plyRank, self.plyClass;
	
	av:SizeToContents();
	name:SizeToContents();
	press:SizeToContents();
	bit:SizeToContents();
	ping:SizeToContents();
	
	local size = 32;
	size = (size / ScrH());
	
	self.plyAvatar:SetWide((ScrH() * size));
	self.plyAvatar:SetTall(self.plyAvatar:GetWide());
	
	local w, h = self.plyAvatar:GetSize();
	
	local px, py = self:GetParent():GetPos();
	local pw, ph = self:GetParent():GetSize();
		
	self:SetSize(pw, (h * 1.2));	
	
	local x, y = self:GetPos();
	local w, h = self:GetSize();

	SetCenteredPosition(av, (w * .06), (h * .5));
	
	local avx, avy = av:GetPos();
	local avw, avh = av:GetSize();
	
	name:SetPos((avx + (avw * 1.2)), ((h * .5) - (name:GetTall() * .5)));
	
	local namex, namey = name:GetPos();
	local namew, nameh = name:GetSize();
	
	press:SetPos((w * .625), namey);
	bit:SetPos((w * .725), namey);
	ping:SetPos((w * .825), namey);
	self.plyClass:SetPos((w * .39), (namey - 5));
	
end


function PANEL:Paint( w, h )
	
	if (!self.Player:IsValid()) then
		return;
	end
	
	local w, h = self:GetSize();
	draw.RoundedBox(8, 0, 0, w, h, Color(10, 5, 2, 255));

	local a = 50;
	
	local clr = Color(200, 112, 112, 255);
	
	if (self.Player:IsAdmin()) then
		clr = Color(0, 0, 0, 255);
	end
	
	if (self.Player:IsGhost()) then
		a = 10;
		clr = Color(100, 56, 56, 255);
		
		if (self.Player:IsAdmin()) then
			clr = Color(150, 150, 150, 255);
		end
	end
	
	local num = 2;
	draw.RoundedBox(6, num, num, (w - (num * 2)), (h - (num * 2)), clr);
	
	local clr = {255, 255, 255, 255};
	
	if (self.Player == LocalPlayer()) then
		local num = ((a + (a * .5)) + (math.sin((CurTime() * 2)) * 25));
		clr = {255, 255, 255, math.Clamp(num, 12, 255)};
	else
		clr = {255, 255, 255, a};
	end
	
	/*if (self.Player:GetNWBool("UC_Voted", false)) then
		clr[2] = 150;
		clr[3] = 150;
	end*/
	
	surface.SetDrawColor(unpack(clr));
	surface.SetTexture(grad);
	surface.DrawTexturedRect(num, num, (w - (num * 2)), (h - (num * 2)));
	
	local avw, avh = self.plyAvatar:GetSize();
	
	surface.SetDrawColor(255, 255, 255, 255);
	
	local rank = self.Rank;
	if (self.Player:IsGhost() && !self.Player:HasCustomRank()) then
		rank = (rank .. "_dead");
	end
	
	surface.SetTexture(textureTable[rank]);
	surface.DrawTexturedRectRotated((w * .95), (h * .5), (avw * 1.2), (avh * 1.2), 0);
	
end

vgui.Register("UCPlayerBar", PANEL, "Panel");
