GM.Name 	= "Ultimate Chimera Hunt";
GM.Author 	= "Aska, FluxMage, and Schythed";
GM.Email 	= "";
GM.Website 	= "";
DeriveGamemode("base")

include("sh_player.lua")
include("sh_chataddtext.lua")
include("sh_roundtimer.lua")
include("sh_cache.lua");

//Gamemode variables
CountdownStartTime = 4; //time in seconds the countdown lasts before a game starts
CountdownEndTime = 10; //time in seconds the countdown lasts before a game ends/resets

CustomRanksAllowed = false;

NumPlayers = 1;


//Player variables
SprintRecharge = .0062;
SprintDrain = .015;
DJump_Penalty = .042;


TEAM_PIGS = 1;
TEAM_UC = 2;
TEAM_SPECTATE = 3;


//states
STATE_WAITING = 1;
STATE_COUNTDOWN = 2;
STATE_PLAYING = 3;
STATE_ENDCOUNTDOWN = 4;

PrecacheParticleSystem("sprint_dust");
PrecacheParticleSystem("uch_ghost_smoke");


function GM:CreateTeams()
	
	team.SetUp(TEAM_PIGS, "Pigmasks", Color(225, 150, 150), true);
	team.SetSpawnPoint(TEAM_PIGS, {"info_player_start", "info_player_terrorist", "info_player_counterterrorist", "info_player_teamspawn"});
		
	team.SetUp(TEAM_UC, "Ultimate Chimera", Color(230, 30, 110, 255), false);
	team.SetSpawnPoint(TEAM_UC, {"info_player_start", "info_player_terrorist", "info_player_counterterrorist"});
	
	team.SetUp(TEAM_SPECTATE, "Spectators", Color(225, 225, 225), true);
	team.SetSpawnPoint(TEAM_SPECTATE, {"info_player_start", "info_player_terrorist", "info_player_counterterrorist", "info_player_teamspawn"});

end

function SetState(state)
	SetGlobalInt("GamemodeState", state);
end

function GetState()
	return GetGlobalInt("GamemodeState", STATE_WAITING);
end

function IsPlaying()
	return (GetState() == STATE_PLAYING);
end


function CustomRanks()
	SetGlobalBool("CustomRanks", self.CustomRanksAllowed);
	return GetGlobalBool("CustomRanks", false);
end


function GM:Think()
	
	GAMEMODE.BaseClass:Think()
	
	if (SERVER) then
		SprintThink();
		ScareThink();
		UCThink();
		JumpThink();
		
		RoundTimeThink();
		
		for k, v in pairs(player.GetAll()) do
			if (v:Team() == TEAM_PIGS && !v:IsGhost() && !v:HasCustomRank() && !v:IsSalsa()) then
				v:MakePiggyNoises();
			end
		end
		
		CheckForBrokenTimers();
		
		if (ShouldMapChange) then
			if (CurTime() >= WaitForMapChange) then
				WaitForMapChange = (CurTime() + 100);
				RunConsoleCommand("changegamemode", (NextMap || GetRandomGamemodeMap()), "ultimatechimerahunt");
			end
		end
		
		for k, ply in pairs(player.GetAll()) do
			if (ply:WaterLevel() > 0) then
				
				if (ply:IsOnGround() && ply:WaterLevel() <= 2) then
					if (ply:GetNetworkedBool("Swimming", false)) then
						ply:SetNetworkedBool("Swimming", false);
					end
				else
					if (!ply:GetNetworkedBool("Swimming", false)) then
						ply:SetNetworkedBool("Swimming", true);
					end
				end
				
			else
				
				if (ply:GetNetworkedBool("Swimming", false)) then
					ply:SetNetworkedBool("Swimming", false);
				end
				
			end
		end
		
	end
	
end
//hook.Add("Think", "GAMEMODE_Think", Think)

/*function GM:ShouldCollide(ent1, ent2)
	
	if (IsValid(ent1) && IsValid(ent2)) then
		if (GetGlobalEntity("UltimateChimera"):IsValid()) then
			if ((ent1 == GetGlobalEntity("UltimateChimera") && !ent1:Alive()) || (ent2 == GetGlobalEntity("UltimateChimera") && !ent2:Alive())) then
				return false;
			end
		end
		
		if (ent1:IsPlayer() && ent2:IsPlayer()) then
			if (ent1:Team() == ent2:Team()) then
				return false;
			end
			if (ent1:IsPancake() || ent2:IsPancake()) then
				return false;
			end
		end
		if ((ent1:GetNetworkedBool("UCGhost", false) || ent2:GetNetworkedBool("UCGhost", false))) then
			return false;
		end
		//if (((ent1:GetClass() == "prop_ragdoll" && ent1.CollideVar) && !ent2:IsWorld()) || ((ent2:GetClass() == "prop_ragdoll" && ent2.CollideVar) && !ent1:IsWorld())) then
		//	return false;
		//end
	
	end
	
	return true
	
end*/

function ShouldCollideHook(ent1, ent2)
	
	if (IsValid(ent1) && IsValid(ent2)) then
		if ((ent1:GetNWBool("UCGhost", false) || ent2:GetNWBool("UCGhost", false))) then
			return false;
		end
		if (ent1:IsPlayer() && ent2:IsPlayer()) then
			if (ent1:Team() == ent2:Team()) then
				return false;
			end
		end

	end	
end
hook.Add( "ShouldCollide", "ShouldCollideHook", ShouldCollideHook )



function team.AlivePlayers(t)
	local num = 0;
	for k, v in pairs(team.GetPlayers(t)) do
		if (v:Alive() && !v:IsGhost()) then
			num = (num + 1);
		end
	end
	return num;
end

function team.NumPlayersNotBots(t)
	local num = 0;
	for k, v in pairs(team.GetPlayers(t)) do
		if (!v:IsBot()) then
			num = (num + 1);
		end
	end
	return num;
end

function GetTimeLimit()

	return 20 * 60; -- FORMAT: Minutes * seconds
	
end


function GetGameTimeLeft()

	local EndTime = GetTimeLimit()
	
	return EndTime - CurTime()

end