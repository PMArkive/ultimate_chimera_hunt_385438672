
local mins = 10; //number of minutes a round lasts


function RoundTimeUp()
	local t = GetGlobalInt("RoundTimer", 0);
	if (CurTime() >= t) then
		return true;
	end
	return false;
end


if (SERVER) then



	function StartTimer()
		
		RoundTimeCheck = (CurTime() + 1);
		SetGlobalInt("RoundTimer", (CurTime() + (mins * 60)));
		
	end
	
	function AddTime(num)
		
		local t = GetGlobalInt("RoundTimer", 0);
		t = (t + num);
		
		t = math.Clamp((t - CurTime()), 0, 12.5 * 60);
		t = (CurTime() + t);
		
		SetGlobalInt("RoundTimer", t);
		
		net.Start("UpdateRoundTimer");
		net.WriteFloat(num);
		net.Send(player.GetAll());
		
	end
	
	function RoundTimeThink()
		
		RoundTimeCheck = (RoundTimeCheck || CurTime());
		
		if (CurTime() >= RoundTimeCheck) then
			RoundTimeCheck = (CurTime() + 1);
		end
		
		if (RoundTimeUp() && IsPlaying()) then
			EndCountdown(ResetGame, "tie");
		end
		
	end


else
	
	
	local sw, sh = ScrW(), ScrH();
	local timerticks = {};
	
	
	local function UpdateRoundTimer()
		local num = net.ReadFloat();
		table.insert(timerticks, {CurTime(), num});
		
		LastTimerAdd = (LastTimerAdd || 0);
		if (CurTime() >= LastTimerAdd) then
			LastTimerAdd = (CurTime() + .4);
			surface.PlaySound("UCH/music/cues/round_timer_add.mp3");
		end
	
	end
	net.Receive("UpdateRoundTimer", UpdateRoundTimer);
	
	
	function DrawTimerTicks()
		for k, v in ipairs(timerticks) do
		
			local t, num = (v[1] + 1), v[2];
			local fade = (t - CurTime());
		
			local alpha = math.Clamp(fade, 0, 255);
			DrawNiceText("+" .. tostring(num), "UCH_TargetID", ((sw * .48) - (fade * (sw * .1))), 0, Color(255, 255, 255, (alpha * 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, (alpha * 150));
			
			if (CurTime() >= t) then
				table.remove(timerticks, k);
			end
			
		end
	end
	
	
	local pemat = surface.GetTextureID("UCH/hud/pigtimee");
	local pmat = surface.GetTextureID("UCH/hud/pigtime");
	local pCmat = surface.GetTextureID("UCH/hud/pigtimec");
	local ucmat = surface.GetTextureID("UCH/hud/chimeratime");
	
	function DrawRoundTime()
		
		if (IsPlaying() || GetState() == STATE_ENDCOUNTDOWN) then
			
			local t = GetGlobalInt("RoundTimer", 0);
			local tm = math.floor(t - CurTime());
			local minute = tostring(math.floor(tm/60));
			local second = tm - minute * 60;
			if second < 10 then second = "0" .. second end -- Couldn't use string.FormattedTime, not working :C
			tm = minute .. ":" .. second;
			
			if (RoundTimeUp() || !IsPlaying()) then
				tm = "Time up!";
			end
			
			tm = string.Trim(tm);
			
			surface.SetFont("UCH_TargetID");
			local txtw, txth = surface.GetTextSize("Time up!");
			
			local x, y = (sw * .5), -(sh * .05);
			local h = (txth + -y);
			local w = (h * 2);
			
			
			local mat = pmat;
			
			local r, g, b = LocalPlayer():GetRankColorSat();

			if (LocalPlayer():GetRank() == "Colonel" && !LocalPlayer():IsGhost()) then
				mat = pCmat;
			end
			if (LocalPlayer():GetRank() == "Ensign") then
				mat = pemat;
				r, g, b = 255, 255, 255;
			end
			if (LocalPlayer():IsUC()) then
				mat = ucmat;
				r, g, b = 255, 255, 255;
			end
			if (LocalPlayer():IsGhost()) then
				mat = pmat;
				r, g, b = 255, 255, 255;
			end
			
			surface.SetTexture(mat);
			surface.SetDrawColor(Color(r, g, b, 255));
			surface.DrawTexturedRect((x - (w * .5)), 0, w, h);
			
			DrawNiceText(tm, "UCH_TargetID", (sw * .5), 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, 250);
			
			if (#timerticks > 0) then
				DrawTimerTicks();
			end
		
		end
		
	end
	
	
	
end
