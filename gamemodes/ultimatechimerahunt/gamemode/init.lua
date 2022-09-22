AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_hud.lua");
AddCSLuaFile("cl_help.lua");
AddCSLuaFile("cl_scoreboard.lua");
AddCSLuaFile("cl_selectscreen.lua");
AddCSLuaFile("cl_splashscreen.lua");
AddCSLuaFile("sh_chataddtext.lua");
AddCSLuaFile("cl_voice.lua");
AddCSLuaFile("sh_ghost.lua");
AddCSLuaFile("sh_cache.lua");
AddCSLuaFile("cl_killnotices.lua");
AddCSLuaFile("cl_targetid.lua");
AddCSLuaFile(GM.Folder .. "/entities/entities/chimera_spawn/init.lua");

AddCSLuaFile("vgui_vote.lua")


for k, v in pairs(file.Find(GM.Folder .. "/gamemode/scoreboard/*.lua", "GAME")) do
	AddCSLuaFile("scoreboard/" .. v);
end

AddCSLuaFile("sh_ply_extensions.lua");
AddCSLuaFile("sh_player.lua");
AddCSLuaFile("sh_roundtimer.lua");

include("shared.lua")
include("sv_download.lua")
include("sv_mapcontrol.lua")

map_votetime = CreateConVar( "map_votetime", "20", { FCVAR_ARCHIVE } )
wait_time = CreateConVar( "UCH_wait_time", "60", { FCVAR_ARCHIVE }, "Time before the first round start" )
music_mode = CreateConVar( "uch_music_mode", "0", { FCVAR_ARCHIVE }, "Always use Mother music on every maps [0=Disabled (Default) 1= Enabled]" )
mount_tf2_maps = CreateConVar( "uch_tf2_maps", "0", { FCVAR_ARCHIVE }, "Allow TF2 maps to be mounted by the gamemode (TF2 must be mounted on your server) [1 = Enabled. 0 = Disabled]" )
ulx_mode = CreateConVar("uch_ulx_mode", "1", { FCVAR_ARCHIVE }, "Use ULX/Evolve Ranks on the scoreboard instead of Pigmask Ranks. If no admin mods are detected, Pigmask Ranks will be used.")

SetGlobalBool("ulx_mode",ulx_mode:GetBool())

function GM:Initialize()
	
	self.BaseClass:Initialize();
	
	timer.Simple(.1, function() RemoveDoors() end);
	
	Ending = false;
	
	NextRoundSalsa = nil;
	
	Changing = false;
	
	CanStartDead = 0;
	
	timer.Simple(.1, function() CacheStuff() end);
	
	SetState(STATE_WAITING)
	
	timer.Simple(wait_time:GetFloat(), function() 
		if (GetState() == STATE_WAITING) then
			if (EnoughPlayers() and CurTime() >= wait_time:GetFloat()) then
				StartCountdown(StartGame);
			end
		end
	end);
	
	if (string.sub( game.GetMap(),1,3) ) == "ch_" then
		maptype = 1; // We're playing on a default ch_ map
	else
		maptype = 0; // We're playing on a different map than a default ch_ map, will be used to launch the music system
	end
	
	if(music_mode:GetBool() == true) then
		timer.Simple(.1, function() RemoveAmbient(); end) // Remove every single ambient_generic on the map
	end
	
	if(IsMounted("tf") == false) then
		print("******* TF2 isn't mounted. Please mount it on your server to avoid model collision problems! *******")
	end
	
end



function GM:PlayerDisconnected(ply)
	
	local t = nil;
	local num = 0;
	if ply:Alive() then
		num = 1;
	end
	
	if (IsPlaying()) then
		
		if (ply:IsUC()) then
			t = "pigs";
		elseif (team.AlivePlayers(TEAM_PIGS) - num < 1) then
			t = "uc";
		end
		
	end
	
	if (t != nil) then
		EndCountdown(ResetGame, t);
	end
	
	PrintMessage( HUD_PRINTTALK, "Player " .. ply:Name() .. " has disconnected." )
	
end


function GM:PlayerSetModel(ply)
	
	if (ply:IsUC()) then
		ply:SetModel("models/UCH/uchimeraGM.mdl");
		ply:SetSkin(0);
		ply:SetBodygroup(1, 1);
		ply:SetModelScale(1, 0);
	else
		if (ply:IsGhost()) then
			ply:SetModel("models/UCH/mghost.mdl");
			
			local b = (ply.Fancy || false);
			if (b) then
				ply:SetBodygroup(1, 1);
			else
				ply:SetBodygroup(1, 0);
			end
		else
			ply:SetModel("models/UCH/pigmask.mdl");
			ply:SetRankBodygroups();
			ply:SetRankSkin();
			ply:SetModelScale(1, 0);
		end
	end
	
end

function GM:PlayerLoadout(ply)
	
	ply:StripWeapons();
	
end


function GM:IsSpawnpointSuitable(ply, spawn, bool)
	return true;
end


function GM:PlayerSpawn(ply)
	
	ply:UnSpectate();
	
	
	if (ply:IsBot() && !ply.TakenCareOf) then
		ply.TakenCareOf = true;
		ply:SetTeam(TEAM_PIGS);
		ply:Spawn();
	end
	
	ply:Freeze(ply.Frozen);
	
	ply:SetupSpeeds();
	
	ply:SetView(48);
	ply:SetJumpPower(242);
	
	ply:SetSprinting(false);
	
	ply:SetSprint(1);
	
	ply:SetPancake(false);
	
	ply.LastUC = false;
	ply:SetNWBool("UC_Voted", false);
	
	ply:UnScare(false);
	ply:ResetUCVars();
	
	ply:SetDead(false);
	
	ply:StopTaunting();
	
	ply:SetDuckSpeed(.25); //blah hacky
	
	if (ply:Team() == TEAM_SPECTATE) then
		
		if (!ply:IsGhost()) then
			ply:SetGhost(true);
		end
		
	else
		
		if (true) then
		
			//do stuff to a player when the game starts
			if (ply:IsUC()) then
				
				if (ply:IsGhost()) then
					ply:SetGhost(false);
				end

				ply.LastUC = true;
				
				ply:SetTeam(TEAM_UC);
				ply:SetJumpPower(260);
				ply:SetSwipeMeter(1);
				ply:SendLua("LocalPlayer().SwipeMeterSmooth = 1;");
				ply:SetSprint(1);
				ply:SendLua("LocalPlayer().SprintMeterSmooth = 1;");
				
			else
				
				if (ply:Team() == TEAM_UC) then
					ply:SetTeam(TEAM_PIGS);
				end
				
				ply.UCChance = (ply.UCChance || 0);
				ply.UCChance = math.Clamp((ply.UCChance + 1), 1, 10);
				
				if (CurTime() >= CanStartDead && team.AlivePlayers(TEAM_PIGS) < team.NumPlayers(TEAM_PIGS) && !ply:IsGhost()) then
					ply:SetGhost(true);
				end
				
			end
			
			if (!ply:IsGhost()) then
				if (!ply:HasCustomRank()) then
					ply:SetRank(ply.NextRank);
				end
			end
			
			ply:PlaySpawnSound();
			
		else
			NextRoundSalsa = nil;
			if (!ply:IsGhost()) then
				ply:SetGhost(true);
			end
		end
		
		if (GetState() == STATE_WAITING) then
			if (EnoughPlayers() and CurTime() >= wait_time:GetFloat()) then
				StartCountdown(StartGame);
			end
		end
		
		
	end
	/*
	if (ply.Ragdoll:IsValid()) then
		ply.Ragdoll:Remove();
	end
	*/
	hook.Call("PlayerSetModel", self, ply);
	
	UpdateHull(ply);
	
end


function GM:PlayerInitialSpawn(ply)

	self.BaseClass:PlayerInitialSpawn(ply);
	ply:SetupVariables();
	
	ply:SpectateEntity(NULL);
	ply:UnSpectate();
	
	ply:SetCustomCollisionCheck(true);
	ply:SetGhost(true);
	ply:SetCanZoom(false);
	if !ply:IsBot() then
		ply:SetTeam(TEAM_SPECTATE);
	else
		ply:SetTeam(TEAM_PIGS);
	end
	
	ply.SendLua(ply, "RunConsoleCommand('stopsound')")
	timer.Simple(1.1, function() ply.SendLua(ply, "surface.PlaySound(\"UCH/music/intro.mp3\")") end);
	timer.Simple(1.5, function() ply.SendLua(ply, "LocalPlayer().VoteMusic = \"music3.mp3\"") end);
	
	ply:SendLua("CacheStuff()");
	ply:SendLua("ShowSplash()");
	SendMapList(ply);
	SendWaitTime(ply);
	
end


function PlayerJoinTeam(ply, id)
	
	if ply:Team() == TEAM_UC then
		ply:ChatPrint(  "You cannot change teams as the Chimera!" );
		return
	end
	
	if ply.LastTeamSwitch != nil && RealTime() - ply.LastTeamSwitch < 10 then
		ply:ChatPrint( "You must wait " .. tostring(math.ceil(10 -(RealTime() - ply.LastTeamSwitch))) .. " more second(s) to switch teams!")
		return
	end
	
	local pos = ply:GetPos();
	local ang = ply:EyeAngles();
	local vel = ply:GetVelocity();

	local iOldTeam = ply:Team()
	
	if ( ply:Alive() ) then
		if (iOldTeam == TEAM_SPECTATOR || iOldTeam == TEAM_UNASSIGNED) then
			ply:KillSilent()
		else
			ply:Kill()
		end
	end

	ply:SetTeam( id )
	if iOldTeam < 4 then
		ply.LastTeamSwitch = RealTime()
	end
	
	GAMEMODE:OnPlayerChangedTeam( ply, iOldTeam, id )
	ply:Spawn();
	ply:SetPos(pos);
	ply:SetEyeAngles(ang);
	ply:SetLocalVelocity(vel);
	
end

function GM:OnPlayerChangedTeam( ply, oldteam, newteam )

	if oldteam > 3 then return end -- Just to stop from saying someone joined spectator on spawn
	chat.AddText( team.GetColor(oldteam), ply:Nick(), color_white, " joined ", team.GetColor(newteam), team.GetName(newteam) )

end

function ChangeTeam( ply, TeamID )

	PlayerJoinTeam( ply, TeamID )

end

function ChangeTeam2( length, ply )

	local TeamID = net.ReadTable()[1];
	PlayerJoinTeam( ply, TeamID )

end
util.AddNetworkString( "ChangeTeam" )
net.Receive("ChangeTeam", ChangeTeam2)

function GM:PlayerSelectSpawn(ply)
	
	if (ply:IsUC()) then
		
		local spawntype = 1;
		local map = string.Replace(game.GetMap(), " ", "")
		if (file.Exists("gamemodes/ultimatechimerahunt/content/data/UC_spawns/" .. map .. ".txt", "GAME")) then
			spawntype = 2;
		elseif (#ents.FindByClass("chimera_spawn") >= 1) then //spawn at random chimera spawn
			spawntype = 3;
		else //map not supported
			ply:ChatPrint(map .. " isn't supported by this gamemode!");
			spawntype = 1;
		end
		
		if (spawntype != 1) then
					
			if (spawntype == 2) then
				
				local map = game.GetMap();
				local file2 = file.Read("gamemodes/ultimatechimerahunt/content/data/UC_spawns/" .. map .. ".txt", "GAME");
				local file3 = string.Explode(" ", file2);
				local targ = ents.Create("info_target");
				targ:SetPos(Vector(file3[1], file3[2], file3[3]));
				targ:SetAngles(Angle(file3[4], file3[5], file3[6]));
				targ:Spawn();
				return targ;
				
			else
				
				local spawns = ents.FindByClass("chimera_spawn");
				return spawns[math.random(1, #spawns)];
				
			end
			
		end
		
	end
	
	
	if ((ply:Team() == TEAM_PIGS || ply.LastUC || ply:IsGhost()) && !ply:IsUC()) then
		return self.BaseClass:PlayerSelectSpawn(ply);
	end
	
	//TF2 maps, load from file
	//Chimera Spawn, find entity
	//Neither, map not supported
	
end


function GM:PlayerDeathThink(ply)
	
	if (IsPlaying() || GetState() == STATE_ENDCOUNTDOWN) then
		return;
	else
		self.BaseClass:PlayerDeathThink(ply);
	end
	
end

function AddPigDeadCount()

	SetGlobalInt("PigDeadCount", GetGlobalInt("PigDeadCount", 0) + 1);

end

function ResetPigDeadCount()

	SetGlobalInt("PigDeadCount", 0)

end

function GM:PlayerDeath(ply, wep, kill)

	//self.BaseClass:PlayerDeath(ply, wep, kill);
	
	ply:Freeze(false);
	ply.Frozen = false;
	
	ply:UnScare(false);
	ply:StopTaunting();
	
	ply:SetSprinting(false);
	
	ply:AddDeaths(1);
	
	timer.Simple(3,function()
		local prag = ply:GetRagdollEntity()
		if(prag != nil && ply:IsUC() == false) then
			prag:Remove()
		end		
	end)
	
	local t = nil;
	
	if (ply:Team() == TEAM_PIGS) then
	
		ply:SetGhost(true);
		
		if (!ply:IsSalsa() && team.AlivePlayers(TEAM_PIGS) <= 0 && IsPlaying()) then
			t = "uc";
		end
		
		ply:SendLua("surface.PlaySound(\"UCH/music/cues/pig_die.mp3\")");
		
		AddPigDeadCount()
		
	end
	
	if (ply:IsUC() && IsPlaying()) then
		
		t = "pigs";
		
	end
	
	if (t != nil && IsPlaying()) then
		EndCountdown(ResetGame, t);
	end
	
end


function GM:DoPlayerDeath(ply, wep, kill)
	
	//self.BaseClass:DoPlayerDeath(ply, wep, kill);
	
end



function CheckForBrokenTimers()
	
	if (TimerCheck != false && TimerCheck != true) then
		TimerCheck = true;
	end
	
	if (CurTime() >= (LastTimerCheck || 0)) then
		LastTimerCheck = (CurTime() + 2);
		if (TimerCheck) then
		
			TimerCheck = false;
			timer.Simple(1, function()
				TimerCheck = true; //We're working  :D
			end);
			
		else	//fuck, timers broke  :|
		
			LastTimerCheck = (CurTime() + 100000);
			
			local map = game.GetMap()
			chat.AddText(Color(250, 250, 250, 255), "Timer's are broken, this will be fixed at some point. Resetting map...");
			WaitForMapChange = (CurTime() + 5);
			ShouldMapChange = true;
			NextMap = map;
		
		end
	end
end



function SendKillNotice(str, ent1, ent2)
	
	net.Start("KillNotice")
	net.WriteString(str);
	net.WriteEntity(ent1);
	net.WriteEntity(ent2);
	net.Send(player.GetAll())
	
end

function DoKillNotice(ply)
	if (ply:IsUC()) then
		if (ply.Pressed && ply.Presser:IsValid()) then
			SendKillNotice("press", ply, ply.Presser);
			ply.Pressed = false;
			ply.Presser = nil;
		else
			SendKillNotice("skull", ply);
		end
	else
		//if (!ply:IsGhost()) then
			if (ply.Squished) then
				ply.Squished = false;
				SendKillNotice("pop", ply, GetUC());
				return;
			end
			if (ply.Bit) then
				ply.Bit = false;
				SendKillNotice("bite", ply, GetUC());
				return;
			end
			if (ply.Suicide) then
				ply.Suicide = false;
				SendKillNotice("suicide", ply);
				return;
			end
			SendKillNotice("skull", ply);
		//end
	end
end



function GM:EntityKeyValue(ent, key, value)
	
	//set keyvalues?  Is this needed?
	
end


function BackToWaiting()
	
	SetState(STATE_WAITING);
	RemoveUC();
	FreezePlayers(false);
	ResetPlayers();
	
end


function StartGame()
	print("StartGame")
	//start game, choose round, etc.
	
	FreezePlayers(false);
	
	for k,v in pairs(player.GetAll()) do
		v:SetDead(true)
		if(v:Team() != TEAM_SPECTATE) then
			v:SetGhost(false)
		end
	end
	timer.Simple(0.3,function()
		for k,v in pairs(player.GetAll()) do
			v:SetDead(false)
		end
	end)
	
	if (!EnoughPlayers()) then
		print("GAME TRIED TO START, NOT ENOUGH PLAYERS!");
		return;
	end
	
	CanStartDead = (CurTime() + 5);
	
	game.CleanUpMap();
	RemoveDoors();
	if(music_mode:GetBool() == true) then
		RemoveAmbient();
	end
	
	SalsaCheck();
	
	StartTimer();
	
	NewUC();
	
	Votes = 0;
	
	SetState(STATE_PLAYING);
	ResetPlayers();
	
	hook.Call("UCHStartRound", self)
	
	if(maptype == 0 || music_mode:GetBool() == true) then
		LaunchTimer()
	end
	
	//StopCountdown();
end

function LaunchTimer() // Music System Start

	local musicnumber = math.random(1,27)
	local file2 = file.Read("data/uch/music.txt", "GAME");
	local file3 = string.Explode(";", file2);
	local duration = file3[musicnumber]
	timer.Create( "MusicLoop", duration, 0, UpdateTimer)
	umsg.Start( "umsg_music" );
		umsg.String(musicnumber)
	umsg.End();
end

function UpdateTimer(var) // Music System update
	local musicnumber = math.random(1,27)
	local file2 = file.Read("data/uch/music.txt", "GAME");
	local file3 = string.Explode(";", file2);
	local duration = file3[musicnumber]
	timer.Adjust( "MusicLoop", duration, 0, UpdateTimer)
	umsg.Start( "umsg_music" );
		umsg.String(musicnumber)
	umsg.End();
end

function OnEndOfGameBaseClass()

	for k,v in pairs( player.GetAll() ) do

		v:Freeze(true)
		v:ConCommand( "+showscores" )
		
	end
	
end

function OnEndOfGame()
	
	OnEndOfGameBaseClass();
	for k, v in pairs(player.GetAll()) do
		v:SendLua("surface.PlaySound(\"UCH/music/cues/gameend.mp3\") timer.Simple(4, function() surface.PlaySound(\"UCH/music/cues/gameend.mp3\") end)");
	end
	
end

function GetWinningWant()

	local Votes = {}
	
	for k, ply in pairs( player.GetAll() ) do
	
		local want = ply:GetNWString( "Wants", nil )
		if ( want && want != "" ) then
			Votes[ want ] = Votes[ want ] or 0
			Votes[ want ] = Votes[ want ] + 1			
		end
		
	end
	
	return table.GetWinningKey( Votes )
	
end

function GetRandomMap()

	return table.Random(GetMaps())

end

function GetWinningMap()

	//if ( GAMEMODE.WinningMap ) then return GAMEMODE.WinningMap end

	local winner = GetWinningWant()
	if ( !winner ) then return GetRandomMap() end
	
	return winner
	
end

function ClearPlayerWants()

	for k, ply in pairs( player.GetAll() ) do
		ply:SetNWString( "Wants", "" )
	end
	
end

function ChangeGamemode(mp)
	
	RunConsoleCommand( "changelevel", string.sub(mp, 1, string.len(mp) - 4))
	
end

function FinishMapVote()
	
	local WinningMap = GetWinningMap()
	ClearPlayerWants()
	
	// Send bink bink notification
	BroadcastLua( "ChangingGamemode( '".. WinningMap .."' )" );

	// Start map vote?
	timer.Simple( 3, function() ChangeGamemode(WinningMap) end )
	
end

function StartMapVote()	
	
	BroadcastLua( "ShowMapChooserForGamemode()" );
	timer.Simple( map_votetime:GetFloat(), function() FinishMapVote() end )
	SetGlobalFloat( "VoteEndTime", CurTime() + map_votetime:GetFloat() )
	SetGlobalBool( "InGamemodeVote", true )

end

function EndOfGame( bGamemodeVote )

	SetGlobalBool( "IsEndOfGame", true );
	
	OnEndOfGame();
	
	if ( bGamemodeVote ) then
	
		MsgN( "Starting map voting..." )
		PrintMessage( HUD_PRINTTALK, "Starting map voting..." );
		timer.Simple( 8, function() StartMapVote() end )
		
	end

end

function IsEndOfGame()
	return GetGlobalBool( "IsEndOfGame", false );
end

function ResetGame()

	
	if (GetState() == STATE_ENDCOUNTDOWN && (GetTimeLimit() - CurTime()) <= 0) then
		EndOfGame(true);
		
		WinningTeam = (WinningTeam || nil);
		local t = WinningTeam;
		if (t != nil) then
			local music = (t == "uc" && "music1") || "music2";
			for k, v in pairs(player.GetAll()) do
				v:SendLua("LocalPlayer().VoteMusic = \"" .. music .. ".mp3\";");
			end
		end
		
		return;
	end
	
	if (IsEndOfGame()) then
		return;
	end
	/*
	local rag = GAMEMODE.UCRagdoll;
	if (GAMEMODE.UCRagdoll:IsValid()) then
		GAMEMODE.UCRagdoll:Remove();
	end
	
	local bird = GAMEMODE.BirdProp;
	if (bird:IsValid()) then
		bird:Remove();
	end
	*/
	timer.Destroy("CountdownToStart");
	timer.Destroy("CountdownToEnd");
	
	if (EnoughPlayers()) then
		
		StartGame();
	
	else
		
		BackToWaiting();
		
	end
	
	ResetPigDeadCount();
	
end


function StartCountdown(func)
	
	FreezePlayers(true);
	SetState(STATE_COUNTDOWN);
	timer.Create("CountdownToStart", CountdownStartTime, 1, func, self);
	
end


function EndCountdown(func, t)
	
	timer.Simple( CountdownEndTime - 0.6, function() FreezePlayers(true) end)
	
	NewSalsa();
	
	SetState(STATE_ENDCOUNTDOWN);
	timer.Create("CountdownToEnd", CountdownEndTime, 1, function() func() end);
	
	WinningTeam = t;
	
	local uc = GetUC();
	
	if (t == "uc") then
		for k, v in pairs(player.GetAll()) do
			if (v:IsValid()) then
			
				local music = "";
				if (v:IsUC() || v:Team() == TEAM_SPECTATE) then
					music = "chimera_win";
				else
					music = "pigs_lose";
				end
				
				v:SendLua("surface.PlaySound(\"UCH/music/cues/" .. music .. ".mp3\")");
				
			end
		end
		uc:AddFrags(2);
		hook.Call("UCHRoundEnd", self, uc);
	elseif (t == "pigs") then
		for k, v in pairs(player.GetAll()) do
			if (v:IsValid()) then
			
				local music = "";
				if (v:Team() == TEAM_PIGS || v:IsGhost()) then
					music = "pigs_win";
				else
					music = "chimera_lose";
				end
				
				v:SendLua("surface.PlaySound(\"UCH/music/cues/" .. music .. ".mp3\")");
				
			end
		end
	end
	
	if (t == "tie") then
		for k, v in pairs(player.GetAll()) do
			if (v:IsValid()) then
				
				v:Kill();
				v.NextRank = math.Clamp((v:GetRankNum() - 1), 1, 4);
				v:SendLua("surface.PlaySound(\"UCH/music/cues/round_timer.mp3\")");
				
			end
		end
	end
	
end

function StopCountdown()
	
	FreezePlayers(false);
	if (timer.Exists("CountdownToStart")) then
		timer.Destroy("CountdownToStart");
	end
	CheckForPlayers();
	
end


function EnoughPlayers()
	
	//check for the amount of players, return true if there are enough
	
	return (team.NumPlayers(TEAM_PIGS) + team.NumPlayers(TEAM_UC)) > NumPlayers;
end


function CheckForPlayers()
	
	if (team.NumPlayers(TEAM_PIGS) <= NumPlayers) then
		
		StartCountdown(BackToWaiting);
		
	end
	
end


function CountVotes()
	
	local plys = team.NumPlayersNotBots(TEAM_PIGS);
	local votes = Votes;
	
	if (votes >= math.ceil((plys * .5))) then
		chat.AddText(Color(255, 255, 255, 255), "Round restart initiated!");
		for k, v in pairs(player.GetAll()) do
			v:SendLua("surface.PlaySound(\"UCH/music/cues/new_uc_voted.mp3\")");
		end
		FreezePlayers(true);
		EndCountdown(ResetGame, "");
	end
	
end


function VoteRoundChange(ply)
	
	if (ply:GetNWBool("UC_Voted", true) || ply:IsUC() || !IsPlaying() || ply:Team() != TEAM_PIGS) then
		return;
	end
	
	ply:SetNWBool("UC_Voted", true);
	Votes = (Votes + 1);
	
	local str =  (tostring(Votes) .. "/" .. tostring(math.ceil((team.NumPlayersNotBots(TEAM_PIGS) * .5))));
	chat.AddText(Color(250, 200, 200, 255), ply:GetName(), Color(250, 250, 250, 255), " voted for a new UC.  ", Color(62, 255, 62, 255), "(" .. str .. ")");
	
	CountVotes();
	
end


local function VoteChange(ply, cmd, args)
	
	VoteRoundChange(ply);
	
end
concommand.Add("uch_vote", VoteChange);

local function SeenSplash( ply )

	if ( ply.m_bSeenSplashScreen ) then return end
	ply.m_bSeenSplashScreen = true
	
	if ( !GAMEMODE.TeamBased && !GAMEMODE.NoAutomaticSpawning ) then
		ply:KillSilent()
	end
	
end

function GM:KeyPress(ply, key)
	
	if (!ply:IsGhost() && ply:Team() == TEAM_PIGS) then
		
		SprintKeyPress(ply, key);
		
	end
	
	if (SERVER) then
	
		if (key == IN_ATTACK2 && ply:CanTaunt()) then
			
			local t, num = "taunt", 1.1;
			
			if (ply:GetRankNum() == 4) then
				t, num = "taunt2", 1;
			end
			
			ply:Taunt(t, num);
	
		end
		
		if (key == IN_USE || key == IN_ATTACK) then
			
			ply.LastPressAttempt = (ply.LastPressAttempt || 0);
			
			if (CurTime() < ply.LastPressAttempt) then
				return;
			end
			
			ply.LastPressAttempt = (CurTime() + .1);
			
			if (ply:Alive() && ply:Team() == TEAM_PIGS && !ply:IsGhost()) then
				
				if (ply:CanPressButton()) then
					local uc = GetUC();
					
					uc:EmitSound("UCH/chimera/button.mp3", 80, math.random(94, 105));
					
					uc.Pressed = true;
					uc.Presser = ply;
					
					ply:RankUp();
					uc:Kill();
					
					ply:AddFrags(1);
					hook.Call("UCHRoundEnd", self, ply);
					
				end
				
			end
		end
		
		if (ply:IsUC()) then
			UCKeyPress(ply, key);
		end
		
		if (ply:IsSalsa() && !ply:IsGhost()) then
			SalsaKeyPress(ply, key);
		end
	
	else
		
		if (!ply:IsGhost() && (key == IN_ATTACK || key == IN_USE)) then
			LocalPlayer().XHairAlpha = 242;
		end
		
	end
	
end
//hook.Add("KeyPress", "GAMEMODE_KeyPress", GAMEMODEKeyPress)

function GM:PlayerConnect( name, ip )
	PrintMessage( HUD_PRINTTALK, "Player " .. name .. " has joined the game." )
end

function VoteForChange( ply )

	if ( ply:GetNWBool( "WantsVote" ) ) then return end
	
	ply:SetNWBool( "WantsVote", true )
	
	local VotesNeeded = GetVotesNeededForChange()
	local NeedTxt = "" 
	if ( VotesNeeded > 0 ) then NeedTxt = ", Color( 80, 255, 50 ), [[ (need "..VotesNeeded.." more) ]] " end
	
	BroadcastLua( "chat.AddText( Entity("..ply:EntIndex().."), Color( 255, 255, 255 ), [[ voted to change the map]] "..NeedTxt.." )" )
	
	Msg( ply:Nick() .. " voted to change the map\n" )
	
	timer.Simple( 5, function() CountVotesForChange() end )

end

concommand.Add( "VoteForChange", function( pl, cmd, args ) VoteForChange( pl ) end )
timer.Create( "VoteForChangeThink", 10, 0, function() CountVotesForChange() end )

function GetVotesNeededForChange()

	local Fraction, NumHumans, WantsChange = GetFractionOfPlayersThatWantChange()
	local FractionNeeded = 0.7
	
	local VotesNeeded = math.ceil( FractionNeeded * NumHumans )
	
	return VotesNeeded - WantsChange

end

function GetFractionOfPlayersThatWantChange()

	local Humans = player.GetHumans()
	local NumHumans = #Humans
	local WantsChange = 0
	
	for k, player in pairs( Humans ) do
	
		if ( player:GetNWBool( "WantsVote" ) ) then
			WantsChange = WantsChange + 1
		end
		
		// Don't count players that aren't connected yet
		if ( !player:IsConnected() ) then
			NumHumans = NumHumans - 1
		end
	
	end
	
	local fraction = WantsChange / NumHumans
	
	return fraction, NumHumans, WantsChange

end

function CountVotesForChange()

	if ( InGamemodeVote() || GetGlobalBool( "IsEndOfGame", false )) then return end

	fraction = GetFractionOfPlayersThatWantChange()
	
	if ( fraction > 0.7 ) then
		EndOfGame(true)
		return false
	end
		
end

function InGamemodeVote()
	return GetGlobalBool( "InGamemodeVote", false )
end

function VotePlayMap( ply, map )
	
	if ( !map ) then return end
	if ( !InGamemodeVote() ) then return end
	if ( !IsValidMap( map ) ) then return end
	
	ply:SetNWString( "Wants", map )
	
end
concommand.Add( "votemap", function( pl, cmd, args ) VotePlayMap( pl, args[1] ) end )

function GetMaps()

	local AllMaps = file.Find("maps/*.bsp", "GAME")
	local UCHMaps = {}
	for k, v in pairs(AllMaps) do
		if string.sub(v, 1, 3) == "ch_" then
			table.insert(UCHMaps, v)
		else if string.sub(v, 1, 6) == "arena_" && mount_tf2_maps:GetFloat() == 1 then
				table.insert(UCHMaps, v)
			end
		end
	end

	return UCHMaps

end

function SendMapList(ply)

	net.Start("MapList")
		net.WriteTable(GetMaps());
	net.Send(ply);

end

function SendWaitTime(ply)

	net.Start("WaitTime")
		net.WriteFloat(wait_time:GetFloat());
	net.Send(ply);

end

function IsValidMap( map )
	
	if ( map == nil ) then return true end
	
	for _, mapname in pairs( GetMaps() ) do
		if ( mapname == map ) then return true end
	end
	
	return false
	
end

function TeamMenu( ply )

	net.Start( "TeamMenu" );
	net.Send( ply );

end
hook.Add("ShowTeam", "ShowTeamMenu", TeamMenu);

function HelpMenu( ply )

	net.Start( "HelpMenu" );
	net.Send(ply);
	
end
hook.Add("ShowHelp", "ShowHelpMenu", HelpMenu)

util.AddNetworkString("TeamMenu");
util.AddNetworkString("HelpMenu");
util.AddNetworkString("SyncSprints");
util.AddNetworkString("KillNotice");
util.AddNetworkString("UpdateRoundTimer");
util.AddNetworkString("UC_RestartAnimation");
util.AddNetworkString("SwitchLight");
util.AddNetworkString("UpdateHulls");
util.AddNetworkString("AddText");
util.AddNetworkString("TailSwipe");
util.AddNetworkString("UCMakeRagFly");
util.AddNetworkString("UCRoared");
util.AddNetworkString("FRecieveGlobalInt");
util.AddNetworkString("FRecieveGlobalEntity");
util.AddNetworkString("FRecieveGlobalBool");
util.AddNetworkString("GetRank");
util.AddNetworkString("SendRank");
util.AddNetworkString("MapList");
util.AddNetworkString("WaitTime");
util.AddNetworkString("DoStompEffect");
//util.AddNetworkString("CreateUCHRagdoll")