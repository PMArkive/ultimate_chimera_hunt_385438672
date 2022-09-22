
surface.CreateFont("UCH_TargetID", {font = "AlphaFridgeMagnets ", size = ScreenScale(14), weight = 500, antialias = true, additive = false});
surface.CreateFont("UCH_TargetIDName", {font = "AlphaFridgeMagnets ", size = ScreenScale(10), weight = 500, antialias = true, additive = false});

function DrawTargetID()
	
	local ply = LocalPlayer();
	local tr = ply:GetEyeTrace();
	
	ply.TargetAlpha = (ply.TargetAlpha || 0);
	
	ply.TargetInfo = (ply.TargetInfo || {});
	
	if (tr.Entity:IsValid() && tr.Entity:IsPlayer() && (ply:IsGhost() || (ply:Team() == TEAM_PIGS && !tr.Entity:IsGhost() && !tr.Entity:IsUC()))) then
		
		if (ply.TargetAlpha != 255) then
			local dis = math.abs((255 - ply.TargetAlpha));
			ply.TargetAlpha = math.Approach(ply.TargetAlpha, 255, (FrameTime() * (dis * 9)));
		end
		
		if (tr.Entity != ply.TargetInfo.ply || ply.TargetInfo.ply == nil) then
			ply.TargetInfo.ply = tr.Entity;
			ply.TargetInfo.name = tr.Entity:GetName();
			ply.TargetInfo.rank = tr.Entity:GetRank();
			local r, g, b = tr.Entity:GetRankColor();
			ply.TargetInfo.clr = Color(r, g, b, 255);
		end
		
	else
		
		if (ply.TargetAlpha != 0) then
			local dis = ply.TargetAlpha;
			ply.TargetAlpha = math.Approach(ply.TargetAlpha, 0, (FrameTime() * 250));
		end
		
	end
	
	local rank, clr, name;
	
	if (!ply:IsValid()) then
		rank = (ply.TargetInfo.rank || nil);
		clr = (ply.TargetInfo.clr || nil);
		name = (ply.TargetInfo.name || nil);
	else
		local plye = player.GetByID(tr.Entity:EntIndex());
		if plye == nil || !plye:IsValid() then return end
		rank = plye:GetRank();
		local r, g, b = plye:GetRankColor();
		clr = Color(r, g, b, 255);
		name = plye:GetName();
		
		if (plye:IsGhost()) then
			if (plye:GetBodygroup(1) == 1) then
				rank = "Fancy Ghostie";
			else
				rank = "Spooky Ghostie";
			end
			clr = Color(255, 255, 255, 255);
		end
		
		if (plye:IsUC()) then
			rank = "The Ultimate Chimera";
			clr = Color(230, 30, 110, 255);
		end
		
	end
	
	if (clr == nil || rank == nil || name == nil) then
		return;
	end
	
	clr.a = ply.TargetAlpha;
	
	if (ply.TargetAlpha > 0) then
		surface.SetFont("UCH_TargetIDName");
		local _, h = surface.GetTextSize(rank);
		DrawNiceText(rank, "UCH_TargetIDName", (ScrW() * .5), (ScrH() * .55), clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ply.TargetAlpha);
		DrawNiceText(ply.TargetInfo.name, "UCH_TargetID", (ScrW() * .5), ((ScrH() * .55) + h), clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ply.TargetAlpha);
	end
	
end
