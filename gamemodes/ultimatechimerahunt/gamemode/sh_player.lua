
AddCSLuaFile("sh_ranks.lua");
AddCSLuaFile("sh_sprinting.lua");
AddCSLuaFile("sh_animation_controller.lua");
AddCSLuaFile("sh_uccontrol.lua");
AddCSLuaFile("sh_scared.lua");
AddCSLuaFile("sh_pancake.lua");
//AddCSLuaFile("sh_salsa.lua");

include("sh_ply_extensions.lua")
include("sh_ranks.lua")
include("sh_sprinting.lua")
include("sh_animation_controller.lua")
include("sh_ghost.lua")
include("sh_uccontrol.lua")
include("sh_scared.lua")
include("sh_pancake.lua")
//include("sh_salsa.lua")



function FreezePlayers(b)
	for k, v in ipairs(player.GetAll()) do
		if (v:IsValid() && v:Team() != TEAM_SPECTATE) then
			v.Frozen = b;
			v:Freeze(b);
		end
	end
end

function ResetPlayers()
	for k, v in ipairs(player.GetAll()) do
		if (v:IsValid() && v:Team() != TEAM_SPECTATE) then
		
			if (v:Team() == TEAM_PIGS && v:IsGhost()) then
				v:SetGhost(false);
			end
			
			if (timer.Exists(tostring(v) .. "SetGhostModels")) then
				timer.Destroy(tostring(v) .. "SetGhostModels");
			end
			
			v:Spawn();
			
		end
	end
end

function NotifyPlayers(txt)
	BroadcastLua("ShowMiddleText('" .. txt .. "')")
end



function GetUC()
	return GetGlobalEntity("UltimateChimera");
end


function GM:PlayerFootstep(ply, pos, foot, sound, volume, players)
	
	if (ply:IsUC() || ply:IsGhost()) then
		return true;
	end
	
end


function RestartAnimation(ply)
	
	//timer.Simple(.1, function()
	
		ply:AnimRestartMainSequence();
		
		net.Start("UC_RestartAnimation");
		net.WriteEntity(ply);
		net.Send(player.GetAll());
		
	//end);
	
end



if (SERVER) then

function GM:Move(ply, move)
		
	if (ply:IsGhost()) then
		
		local move = ply:GhostMove(move);
		
		return move;
		
	else

		if (ply:IsTaunting() || ply:IsBiting() || ply:IsRoaring() || (ply:IsUC() && !ply:Alive())) then
			ply:SetLocalVelocity(Vector(0, 0, 0));
			
			if (ply.LockTauntAng == nil) then
				ply.LockTauntAng = ply:EyeAngles();
			end
			
			ply:SetEyeAngles(ply.LockTauntAng);
			
			return true;
		else
			ply.LockTauntAng = nil;
			return self.BaseClass:Move(ply, move);
		end
		
	end
	
end

function GM:PlayerSwitchFlashlight(ply, SwitchOn)
	if (ply:Team() == TEAM_PIGS) then
		net.Start("SwitchLight");
		net.WriteEntity(ply);
		net.Send(player.GetAll());
	end
    return ((ply:Team() == TEAM_PIGS && !ply:IsGhost()) || !SwitchOn);
end


function GM:CanPlayerSuicide(ply)
	
	if (ply:IsGhost() || ply:IsUC() || ply:IsSalsa()) then
		return false;
	end
	ply.RespawnCheck = true;
	
	if (ply:Alive()) then
		if (IsPlaying()) then
			ply:ResetRank();
		end
		ply.Suicide = true;
		ply:Kill();
	end
	
	return false;
	
end

function GM:OnPlayerChangedTeam(ply, oldteam, newteam)
	
	ply.RespawnCheck = true;
	self.BaseClass:OnPlayerChangedTeam(ply, oldteam, newteam);
	
end


function UpdateHull(ply)
	
	if (!ply:IsValid()) then
		return;
	end
	
	if (ply:IsUC()) then
		ply:SetHull(Vector(-25, -25, 0), Vector(25, 25, 55));
		ply:SetHullDuck(Vector(-25, -25, 0), Vector(25, 25, 55));
		
		ply:SetViewOffset(Vector(0, 0, 68));
		ply:SetViewOffsetDucked(Vector(0, 0, 68));
	else
		ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 55));
		ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 40));
		
		ply:SetViewOffset(Vector(0, 0, 48));
		ply:SetViewOffsetDucked(Vector(0, 0, (48 * .75)));
		
		if (ply:IsSalsa()) then
					
			ply:SetHull(Vector(-12, -12, 0), Vector(12, 12, 28));
			ply:SetHullDuck(Vector(-12, -12, 0), Vector(12, 12, 28));
			
			ply:SetViewOffset(Vector(0, 0, 28));
			ply:SetViewOffsetDucked(Vector(0, 0, 28));
			
		end 
		
		if (ply:IsGhost()) then
			
			ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 55));
			ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 55));
			
			ply:SetViewOffset(Vector(0, 0, 55));
			ply:SetViewOffsetDucked(Vector(0, 0, 55));
			
		end
		
	end
	
	timer.Simple(.1, function()
		net.Start("UpdateHulls");
		net.WriteEntity(ply);
		net.Send(player.GetAll());
	end);
	
end


function SetUC(ply)
	local uc = GetUC();
	if (ply != uc) then
		SetGlobalEntity("UltimateChimera", ply);
		ply.UCChance = -1;
	end
end

function RemoveUC()
	SetGlobalEntity("UltimateChimera", NULL);
end


function NewUC()
	
	local uc = GetUC();
	
	RemoveUC();
	
	local tbl, plys = {}, player.GetAll();
	for k, v in ipairs(plys) do
		
		v.UCChance = (v.UCChance || 1);
		
		if (v != uc && v.UCChance > 0 && v:Team() == TEAM_PIGS && v != NextRoundSalsa && !v:IsSalsa()) then
			
			for i = 1, v.UCChance do
				table.insert(tbl, v);
			end
			
		end
		
	end
	
	if (#tbl < 1) then
		return;
	end
	
	local ply = table.Random(tbl);
	
	SetUC(ply);
	NotifyPlayers(ply:Name() .. " is the new Ultimate Chimera");
	
end



function GM:PlayerUse(ply, ent)
	
	if (ply:IsGhost()) then
		return false;
	end
	
	return true;
	
end



function GM:EntityTakeDamage(ent, dmginfo)
	
	local amount = dmginfo:GetDamage()
	if (ent:IsPlayer()) then
		if (ent:IsUC() || ent:IsGhost() || ent:IsSalsa() || (ent:Health() - amount) <= 0) then
			
			if (ent:IsUC() && amount > 100) then
				ent:Kill();
			end
			if (ent:Alive() && !ent:IsUC() && (ent:Health() - amount) <= 0) then
				ent:Kill();
			end
			
			dmginfo:ScaleDamage(0);
		end
	end
	
end



function GM:PlayerDeathSound()
	return true;
end


local function GetFallDamage(ply, vel)
	
	if (ply:IsGhost()) then
		return false;
	end
	if (ply:IsSalsa()) then
		ply:EmitSound("UCH/salsa/squeal.mp3", 75, math.random(94, 105));
		return false;
	end
	if (ply:IsUC()) then
		return 0;
	end
	
end
hook.Add("GetFallDamage", "GAMEMODE_GetFallDamage", GetFallDamage);




else
	
	
	
	
local function TauntAngSafeGuard(ply)
	if (ply.TauntAng == nil) then
		local ang = ply:EyeAngles();
		ang.p = 45;
		ply.TauntAng = ang;
	end
end


function ShouldDrawLocalPlayer()
	
	if ((LocalPlayer():IsUC() && LocalPlayer():Alive()) || LocalPlayer():IsTaunting() || LocalPlayer():IsScared()) then
		return true;
	end
	
	return false;
	
end
hook.Add("ShouldDrawLocalPlayer", "GAMEMODE_ShouldDrawLocalPlayer", ShouldDrawLocalPlayer)

	
function InputMouseApply(cmd, x, y, ang)

	local ply = LocalPlayer();

	if (ply:IsTaunting() || ply:IsRoaring()) then
	
		TauntAngSafeGuard(ply);
		
		local ang = ply.TauntAng;
		
		local y = (x * -GetConVar("m_yaw"):GetFloat());
		
		ang.y = (ang.y + y)
		//ang = ang:GetAngle();
		
		ang.p = 16;
		
		ply.TauntAng = ang;
		
		return true
	
	end
	
	if (ply:IsBiting() || (ply:IsUC() && !ply:Alive())) then
		return true;
	end

end
hook.Add("InputMouseApply", "GAMEMODE_InputMouseApply", InputMouseApply)



local function ThirdPersonCamera(ply, pos, ang, fov, dis)
	local view = {};
	
	local dir = ang:Forward();
	
	local tr = util.QuickTrace(pos, (dir * -dis), player.GetAll());
	
	local trpos = tr.HitPos;
	
	if (tr.Hit) then
		trpos = (trpos + (dir * 20));
	end
	
	view.origin = trpos;
	
	view.angles = (ply:GetShootPos() - trpos):Angle();
	
	view.fov = fov;

	return view;
end

function CalcView(ply, pos, ang, fov)
	
	if ply == nil then return end
	local tang = ply.TauntAng;
	
	if (ply:IsTaunting() || ply:IsRoaring()) then
		
		TauntAngSafeGuard(ply);
		
		local view = {};
		
		local dir = tang:Forward();
		
		local tr = util.QuickTrace(pos, (dir * -115), player.GetAll());
		
		local trpos = tr.HitPos;
		
		if (tr.Hit) then
			trpos = (trpos + (dir * 20));
		end
		
		view.origin = trpos;
		
		view.angles = (ply:GetShootPos() - trpos):Angle();
		
		view.fov = fov;

		return view;
		
	else
		
		if (tang != nil) then
			
			if (!ply:IsUC()) then
				tang.p = 0;
			end
			
			tang.r = 0;
			ply:SetEyeAngles(tang);
			
			ply.TauntAng = nil;
			
		end
		
		if (ply:IsScared()) then
			return ThirdPersonCamera(ply, pos, ang, fov, 100);
		end
		
		if (ply:IsGhost()) then
			
			local num = 3;
			
			local view = {};
			
			local bob = (math.sin((CurTime() * num)) * 2);
			
			view.origin = Vector(pos.x, pos.y, (pos.z + bob));
			view.angles = ang;
			view.fov = fov;
			return view;
			
		end
		
	end
	
	if (ply:IsUC()) then
		
		if (ply:Alive()) then
			return ThirdPersonCamera(ply, pos, ang, fov, 125);
		else
			local followang = ang;
		
			local rag = ply:GetRagdollEntity();
			GAMEMODE.UCRagdoll = rag;
			if (rag != nil && rag:IsValid()) then
				local pos = (ply:GetPos() - (ply:GetForward() * 800));
				followang = ((rag:GetPos() - Vector(0, 0, 100)) - pos):Angle();
			end
			
			local view = {};
			view.origin = (pos + Vector(0, 0, 25));
			view.angles = followang;
			view.fov = fov;
			
			return view;
		end
		
	end
	
	
	return {ply, pos, ang, fov};
	
	
end
hook.Add("CalcView", "GAMEMODE_CalcView", CalcView)


local function RestartAnimation()
	
	local ply = net.ReadEntity();
	if ply == nil || !ply:IsValid() then return end
	ply:AnimRestartMainSequence();
	
end
net.Receive("UC_RestartAnimation", RestartAnimation);

	
local function UpdateHulls()

	local ply = net.ReadEntity();
	
	if (!ply:IsValid()) then
		return;
	end
	
	if (ply:IsUC()) then
		ply:SetHull(Vector(-25, -25, 0), Vector(25, 25, 55));
		ply:SetHullDuck(Vector(-25, -25, 0), Vector(25, 25, 55));
		
		ply:SetViewOffset(Vector(0, 0, 68));
		ply:SetViewOffsetDucked(Vector(0, 0, 68));
	else
		ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 55));
		ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 40));
		
		ply:SetViewOffset(Vector(0, 0, 48));
		ply:SetViewOffsetDucked(Vector(0, 0, (48 * .75)));
		
		if (ply:IsSalsa()) then
					
			ply:SetHull(Vector(-12, -12, 0), Vector(12, 12, 28));
			ply:SetHullDuck(Vector(-12, -12, 0), Vector(12, 12, 28));
			
			ply:SetViewOffset(Vector(0, 0, 28));
			ply:SetViewOffsetDucked(Vector(0, 0, 28));
			
		end 
		
		if (ply:IsGhost()) then
			
			ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 55));
			ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 55));
			
			ply:SetViewOffset(Vector(0, 0, 55));
			ply:SetViewOffsetDucked(Vector(0, 0, 55));
			
		end
		
	end
	
end
net.Receive("UpdateHulls", UpdateHulls);

	
	
end
