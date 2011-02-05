

function SetSystemBackground (bgname) -- "backgrounds/green" or "backgrounds/starfield2" ,... ( see data/universe/background.txt )
	local tex = string.gsub(bgname or "backgrounds/green","^backgrounds/","").."_light.cube.dds"
	print("SetSystemBackground",bgname,tex)
	-- skybox
    Client_SetSkybox(GetCubicTexturedMat("skyboxbase_singlefile",tex,true) or "skybox_standard")
end

--[[ 
"backgrounds/starfield2"  
filename search "starfield2" : ./textures/backgrounds/starfield2_light.cube  (cubemap texture, 6 sides...)
content search : nowhere found except data/universe/background.txt, so it translates directly to filename  : textures/backgrounds/XXXX_light.cube
--~ cubic_texture xxxfront.png xxxback.png xxxleft.png xxxright.png xxxup.png xxxdown.png separateUV
--~ cubic_texture red_galaxy1_light.cube.dds combinedUVW
-- must rename vega .cube to .dds (which it really is) or ogre will fail to load it
]]--

