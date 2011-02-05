
function SetSystemBackground (bgname) -- "backgrounds/green" or "backgrounds/starfield2" ,... ( see data/universe/background.txt )
	bgname = bgname or "backgrounds/green"
	
	-- skybox
    Client_SetSkybox("bluesky")
	-- TODO : make proper skybox using materials, probably needs some file
end

--[[ 
"backgrounds/starfield2"  
filename search "starfield2" : ./textures/backgrounds/starfield2_light.cube  (cubemap texture, 6 sides...)
content search : nowhere found except data/universe/background.txt, so it translates directly to filename  : textures/backgrounds/XXXX_light.cube
]]--

--[[
// cubic_texture xxxfront.png xxxback.png xxxleft.png xxxright.png xxxup.png xxxdown.png separateUV

material bluesky : skyboxbase
{
	technique
	{
		pass
		{
			texture_unit
			{
				cubic_texture fiery_galaxy_light_front.png fiery_galaxy_light_back.png fiery_galaxy_light_left.png fiery_galaxy_light_right.png fiery_galaxy_light_up.png fiery_galaxy_light_down.png separateUV
				tex_address_mode clamp
			}
		}
	}
}


material skyboxbase
{
	// FIXED FUNCTION
	technique
	{
		pass
		{
			fog_override true
			lighting off
			depth_write off

			texture_unit
			{
				//filtering none
				cubic_texture stone512.dds stone512.dds stone512.dds stone512.dds stone512.dds stone512.dds separateUV
				tex_address_mode clamp
			}
		}
	}
}
]]--
