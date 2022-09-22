include("shared.lua")
include("cl_hud.lua")
include("cl_killnotices.lua")

include("cl_help.lua")
include("cl_scoreboard.lua")
include("cl_selectscreen.lua")
include("cl_splashscreen.lua")
include("cl_voice.lua")

include("vgui_vote.lua")

CreateClientConVar( "uch_music", "1", true, false )
CreateClientConVar( "uch_pigmask_thirdperson", "0", true, false )

function Initialize()
	
	self.BaseClass:Initialize();
	
end

surface.CreateFont("FRETTA_HUGE", {font = "Trebuchet MS", size = 69, weight = 700, antialias = true, additive = false});
surface.CreateFont("FRETTA_HUGE_SHADOW", {font = "Trebuchet MS", size = 69, weight = 700, antialias = true, additive = false, shadow = true});
surface.CreateFont("FRETTA_LARGE", {font = "Trebuchet MS", size = 40, weight = 700, antialias = true, additive = false});
surface.CreateFont("FRETTA_LARGE_SHADOW", {font = "Trebuchet MS", size = 40, weight = 700, antialias = true, additive = false, shadow = true});
surface.CreateFont("FRETTA_MEDIUM", {font = "Trebuchet MS", size = 19, weight = 700, antialias = true, additive = false});
surface.CreateFont("FRETTA_MEDIUM_SHADOW", {font = "Trebuchet MS", size = 19, weight = 700, antialias = true, additive = false, shadow = true});
surface.CreateFont("FRETTA_SMALL", {font = "Trebuchet MS", size = 16, weight = 700, antialias = true, additive = false});


local txtmat = surface.GetTextureID("UCH/logo/UClogo1");
local tailmat = surface.GetTextureID("UCH/logo/UClogo2");
local birdmat = surface.GetTextureID("UCH/logo/UClogo3");
local btnmat = surface.GetTextureID("UCH/logo/UClogo4");
local wingmat = surface.GetTextureID("UCH/logo/UClogo5");
local expmat = surface.GetTextureID("UCH/logo/UClogo6");

local waverot = 0;
local wavetime = (CurTime() + 6);

local function LogoThink()
	
	//waving (!)
	local t = (wavetime - CurTime());
	if (t < 0) then
		wavetime = (CurTime() + math.random(12, 24));
	end
	if (t > 1.25) then
		waverot = math.Approach(waverot, 0, (FrameTime() * 75));
	else
		local num = (16 * math.sin((CurTime() * 12)))
		waverot = math.Approach(waverot, num, (FrameTime() * 400));
	end
		
	
end
hook.Add("Think", "LogoThink", LogoThink);

function DrawLogo(x, y, size)
	
	local size = (size || 1); //if they didn't specify size, just default it to 1
	
	surface.SetDrawColor(255, 255, 255, 255);
	
	
	local txtw = ((ScrH() * .8) * size);
	local txth = (txtw * .5);
	
	
	//Wing 1
	local w = (txth * .575);
	local h = w;
	
	local deg = 8;
	local sway = (deg * math.sin((CurTime() * 1.25)));
	
	surface.SetTexture(wingmat);
	surface.DrawTexturedRectRotated((x - (txtw * .038)), (y - (txth * .205)), w, h, (-36 + sway));
	
	
	//Button
	local w = (txth * .116);
	local h = w;
	
	surface.SetTexture(btnmat);
	surface.DrawTexturedRect((x - (txtw * .0625)), (y - (txth * .27)), w, h);
	
	
	//Wing 2
	local w = (txth * .575);
	local h = w;
	
	local deg = 8;
	local sway = (deg * math.sin((CurTime() * 1)));
	
	surface.SetTexture(wingmat);
	surface.DrawTexturedRectRotated((x - (txtw * .05)), (y - (txth * .21)), w, h, (-4 + sway));
	
	
	//Tail
	local w = (txtw * .14);
	local h = (w * 4);
	local deg = 6;
	local sway = (deg * math.sin((CurTime() * 2)));
	
	surface.SetTexture(tailmat);
	surface.DrawTexturedRectRotated((x - (txtw * .255)), (y - (txth * .145)), w, h, (-6 + sway));
	
	
	//Bird
	local w = (txth * .28);
	local h = w;
	
	surface.SetTexture(birdmat);
	surface.DrawTexturedRect((x + (txtw * .146)), (y - (txth * .3575)), w, h);
	
	
	// (!)
	local w = (txth * .64);
	local h = w;
	
	surface.SetTexture(expmat);
	surface.DrawTexturedRectRotated((x + (txtw * .2425)), (y + (txth * .09)), w, h, waverot);
	
	
	//Text
	surface.SetTexture(txtmat);
	surface.DrawTexturedRect((x - (txtw * .5)), (y - (txth * .5)), txtw, txth);
	
end
function PositionScoreboard(ScoreBoard)
	
	ScoreBoard:SetSize(700, ScrH() - 100);
	ScoreBoard:SetPos((ScrW() - ScoreBoard:GetWide()) / 2, 50);
	
end
function PaintSplashScreen()
	DrawLogo((ScrW() * .5), (ScrH() * .175));
end
function GM:RenderScreenspaceEffects()
	
	if (LocalPlayer():IsGhost()) then
		DoGhostEffects();
	end
	
	for k, ply in pairs(player.GetAll()) do
		
		if (!LocalPlayer():IsGhost() && ply:IsGhost() || (ply:IsUC() && !ply:Alive())) then
			ply:SetRenderMode(RENDERMODE_NONE);
		else
			ply:SetRenderMode(RENDERMODE_NORMAL);
		end
		
		ply.skin, ply.bgroup, ply.bgroup2 = (ply.skin || nil), (ply.bgroup || nil), (ply.bgroup2 || nil);
	
		if (ply:Alive()) then
			ply.skin = ply:GetSkin();
			ply.bgroup = ply:GetBodygroup(1);
			ply.bgroup2 = ply:GetBodygroup(2);
		end
		
	rag = ply:GetRagdollEntity();
		if (rag != nil && rag:IsValid()) then
			if (!ply:IsUC()) then
				rag:SetSkin(ply.skin or 1);
				if(ply.bgroup != nil) then
					rag:SetBodygroup(1, ply.bgroup);
					rag:SetBodygroup(2, ply.bgroup2);
				end
				
				if (!rag.Flew && ply.RagShouldFly) then
					rag.Flew = true;
					ply.RagShouldFly = false;
					if GetUC() == nil || !GetUC():IsValid() then return end
					local dir = (GetUC():GetForward() + Vector(0, 0, .75));
					for i = 0, (rag:GetPhysicsObjectCount() - 1) do
						rag:GetPhysicsObjectNum(i):ApplyForceCenter((dir * 50000));
					end
					rag:EmitSound("UCH/pigs/squeal" .. tostring(math.random(1, 3)) .. ".mp3", 100, math.random(90, 105));
				end
				
			else
				rag:SetSkin(1);
				rag:SetBodygroup(1, 0);
			end
		end
		
		if (ply:IsPancake()) then
			ply:DoPancakeEffect();
		else
			ply.PancakeNum = 1;
			local scale = Vector( 1,1,1 )
			local mat = Matrix();
			mat:Scale( scale );
			ply:EnableMatrix( "RenderMultiply", mat );
		end
		
	end
	
end
local function MakeRagFly()
	local ply = net.ReadEntity();
	ply.RagShouldFly = true;
end
net.Receive("UCMakeRagFly", MakeRagFly);
function GM:OnPlayerChat( player, strText, bTeamOnly, bPlayerIsDead )
 
	local tab = {}
 
	if ( IsValid( player ) ) then
		if (player:IsGhost()) then
			table.insert(tab, Color(200, 200, 200));
			local str = (player:GetBodygroup(1) == 1 && "Fancy ") || "Spooky ";
			table.insert(tab, str .. player:GetName());
		else
			table.insert( tab, player )
		end
	else
		table.insert( tab, "Console" )
	end
 
	table.insert( tab, Color( 255, 255, 255 ) )
	table.insert( tab, ": "..strText )
 
	chat.AddText( unpack(tab) )
 
	return true
 
end
function GM:PrePlayerDraw(ply)
	
	if (!LocalPlayer():IsGhost() && ply:IsGhost() || (ply:IsUC() && !ply:Alive()) || (ply:IsGhost() && ply:GetModel() != "models/uch/mghost.mdl")) then
		return true;
	end
	
end
function GM:KeyPress(ply, key)
	if (!ply:IsGhost() && (key == IN_ATTACK || key == IN_USE)) then
		LocalPlayer().XHairAlpha = 242;
	end
end
function DoStompEffect(data)
	local ply = LocalPlayer()
	local pos = data:ReadVector()
	
	util.ScreenShake(pos, 3, 3, .5, 1);
end
usermessage.Hook( "DoStompEffect", DoStompEffect );
-- Map Voting --
local GMChooser = nil 
function GetVoteScreen()
	if ( IsValid( GMChooser ) ) then return GMChooser end
	
	GMChooser = vgui.Create( "VoteScreen" )
	return GMChooser
end
function ShowMapChooserForGamemode()
	local votescreen = GetVoteScreen()
	votescreen:ChooseMap(self)
	
	GAMEMODE:ScoreboardHide()
	if (!PlayingVoteMusic) then
		
		PlayingVoteMusic = true;
		
		local musix = (LocalPlayer().VoteMusic || "music3.mp3");
		surface.PlaySound("UCH/music/voting/" .. musix);
		
	end
	
	GAMEMODE:ScoreboardHide();
end

function ShowMiddleText(text)
	color = Color( 230, 30, 110, 255 )
	duration = 7
	fade = 0.5
	local start = CurTime()

	local function drawToScreen()
		local alpha = 255
		local dtime = CurTime() - start

		if dtime > duration then 
			hook.Remove( "HUDPaint", "UCHMiddleText" )
			return
		end

		if fade - dtime > 0 then
			alpha = (fade - dtime) / fade
			alpha = 1 - alpha
			alpha = alpha * 255
		end

		if duration - dtime < fade then 
			alpha = (duration - dtime) / fade -- 0 to 1
			alpha = alpha * 255
		end
		color.a  = alpha

		draw.DrawText( text, "UCH_KillFont3", ScrW() * 0.5, ScrH() * 0.10, color, TEXT_ALIGN_CENTER )
	end

	hook.Add( "HUDPaint", "UCHMiddleText", drawToScreen )
end
local function UMSGMusic(data)
	if GetConVarNumber("uch_music") == 1 then
		surface.PlaySound("UCH/music/rounds/music".. data:ReadString()..".mp3")
		print("launched")
	end
end
usermessage.Hook( "umsg_music", UMSGMusic );