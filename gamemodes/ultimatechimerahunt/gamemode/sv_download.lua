
local function AddFolder(path)
	for k, v in pairs(file.Find( path .. "*", "MOD")) do
		resource.AddFile(path .. v);
	end
end

//------------------------------Gamemode--------------------

// ---- Old AddFolder for the gamemode (Broken scoreboard and missing Models Textures) you can uncomment it but it's not recommended (Those files will basically download using ressource.AddWorkshop)
/*AddFolder("sound/UCH/music/");
AddFolder("sound/UCH/music/cues/");
AddFolder("sound/UCH/music/voting/");
AddFolder("sound/UCH/custom/");
AddFolder("sound/UCH/chimera/");
AddFolder("sound/UCH/pigs/");

AddFolder("materials/UCH/");
AddFolder("materials/UCH/logo/");
AddFolder("materials/UCH/scoreboard/");
AddFolder("materials/UCH/ranks/");
AddFolder("materials/UCH/killicons/");
AddFolder("materials/UCH/hud/");

AddFolder("materials/models/uch/uchimera/");
AddFolder("materials/models/uch/pigmask/");
AddFolder("materials/models/uch/mghost/");
AddFolder("materials/models/uch/birdgib/");
AddFolder("materials/models/uch/");*/


resource.AddFile("resource/fonts/apple_kid.TTF");
resource.AddFile("resource/fonts/twoson.TTF");

resource.AddWorkshop( 385438672 ) // UCH Workshop Addon
