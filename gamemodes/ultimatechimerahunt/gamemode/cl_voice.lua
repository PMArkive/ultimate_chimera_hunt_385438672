

function GM:PlayerStartVoice(ply)
	
	self.BaseClass:PlayerStartVoice(ply);
	
	if ply == nil || !ply:IsValid() then return end
	
	ply.PiggyWiggle = true;
	
end

function GM:PlayerEndVoice(ply)
	
	self.BaseClass:PlayerEndVoice(ply);
	
	if ply == nil || !ply:IsValid() then return end
	
	ply.PiggyWiggle = false;
	
end
