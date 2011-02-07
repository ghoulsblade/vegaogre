-- units/units.csv   and utils

gUnitTypes = {}
gUnitTypesI = {} -- ignore case (lowercase)

function MeshNameExists (meshname) print("TODO:MeshNameExists",meshname) return true end -- todo : check

function GetPlanetUnitTypeIDFromTexture (texture) 
	local a,b,basename = string.find(texture,"([^/.]+)[^/]*$")
	return (basename or texture).."__planets"
end
function GetUnitTypeForPlanetNode (planetnode) 
	return gUnitTypes[GetVegaXMLVar(planetnode,"unit") or GetPlanetUnitTypeIDFromTexture(GetVegaXMLVar(planetnode,"texture") or "???") or "???"] 
end

function FindUnitTypeFromFileValue (file,factionhint) 
	if (not file) then return end
	--~ file = string.gsub(file,"|.*","")
	file = string.gsub(file,".*|","")
	--~ print("FindUnitTypeFromFileValue",file,file.."__neutral",GetPlanetUnitTypeIDFromTexture(file))
	return	(factionhint and gUnitTypes[file.."__"..factionhint])  or gUnitTypes[file]  or gUnitTypes[file.."__neutral"]  or gUnitTypes[GetPlanetUnitTypeIDFromTexture(file)] or 
			(factionhint and gUnitTypesI[file.."__"..factionhint]) or gUnitTypesI[file] or gUnitTypesI[file.."__neutral"] -- ignore case, needed for Unit:factory,...
end


function GetUnitTypeFromSectorXMLNode (node) return FindUnitTypeFromFileValue(node.file,node.faction) end


function GetJumpDestinationFromNode (node) return node and node.destination end

function GetHUDImageFromNode_Planet (node)
	local t = GetUnitTypeFromSectorXMLNode(node)
	print("GetHUDImageFromNode_Planet",node.file,t and ((t.Hud_image == "") and "TYPE:EMPTYHUD" or t.Hud_image) or "TYPE:MISSING") 
	if (not t) then return end
	local tex = t.Hud_image
	if (tex == "") then return end
	tex = string.gsub(tex,".*/","")
	tex = string.gsub(tex,"%.sprite$",".dds") -- todo : sprite = config file...
	return tex
end

function GetHUDImageFromNode_Unit (node)
	local t = GetUnitTypeFromSectorXMLNode(node)
	if (t) then --  t.Hud_image: MininBase2-hud.spr -> MininBase2-hud.png MininBase2-hud.png	
		local filename = FindFirstFileInDir(GetVegaDataDir().."units/"..(t.Directory or ""),"hud.*%.dds") -- todo : cache result
		print("GetHUDImageFromNode_Unit : ",t.Directory,filename)
		if (filename) then return filename end
	else
		print("WARNING: GetHUDImageFromNode_Unit type not found",node and node.file)
	end
	-- node and GetHUDImageFromNode_Planet(node) or "planet-carribean-hud.dds"
	return "Agricultural_Station_Agricultural_Station-hud.png.dds"
	--[[
	MiningBase,./installations/MiningBase,MiningBase,,Installation,BASE,WRITEME,MininBase2-hud.spr,0.4,,,,,{MiningBase.bfxm;;},,
	MiningBase__aera,./factions/aera/MiningBase,MiningBase__aera,,Installation,BASE,Aera mining base,aera-mine-hud.spr,10,,,,,{miningbase.bfxm;;},
	MiningBase__pirates,./factions/pirates/MiningBase,MiningBase,,Installation,BASE,WRITEME,MiningBase-hud.spr,300,,,,,{MiningBase.bfxm;;},
	MiningBase__privateer,./factions/rlaan/MiningBase,MiningBase,,Installation,BASE,WRITEME,MiningBase3-hud.spr,3,,,,,{MiningBase.bfxm;;},,
	MiningBase__rlaan,./installations/Rlaan_Mining_Base,MiningBase__rlaan,,Installation,BASE,Rlaan Mining Base,rlaan_mining_base-hud.sprite,170,,,,,{rlaan_mining_base.bfxm;;},,

	Fighter_Barracks,./installations/Fighter_Barracks,Fighter Barracks,,Installation,BASE,WRITEME,fighter_barracks-hud.spr,3,,,,,{fighter_barracks.bfxm;;},,,,,,,
	Fighter_Barracks__aera,./factions/aera/fighter_barracks,Fighter Barracks,,Installation,BASE,WRITEME,station-hud.spr,,,,,,{fighter_barracks.bfxm;;},,,,,,,
	Fighter_Barracks__rlaan,./installations/Rlaan_Fighter_Barracks,Fighter_Barracks__rlaan,,Installation,BASE,Fighter Barracks,rlaan_fighter_barracks-hud.sprite,200,,,,,{rlaan_fighter_barracks.bfxm;;},,,,,,,


	cat data/units/installations/MiningBase/MininBase2-hud.spr
		MininBase2-hud.png MininBase2-hud.png

	]]--
end
function GetUnitMeshNameFromNode (node)
	local t = GetUnitTypeFromSectorXMLNode(node)
	if (t) then 
		-- o.id,o.Directory,o.Name,o.STATUS,o.Object_Type,o.Combat_Role,o.Textual_Description,o.Hud_image,o.Unit_Scale, ... o.Mesh,o.Shield_Mesh
		local meshname = string.gsub(string.gsub(t.Mesh or "","%.bfxm.*",".mesh"),"^%{","")
		print("GetUnitMeshNameFromNode",node.file,meshname)
		if (string.find(meshname,"%.mesh") and MeshNameExists(meshname)) then return meshname end
	else
		print("WARNING: GetUnitMeshNameFromNode type not found",node and node.file)
	end
	return "MiningBase.mesh"  
	--~ return GetRandomArrayElement({"starfortress","factory","asteroidfighterbase","uln_asteroid_refinery","diplomatic_center","uln_commerce_center","relay",
		--~ "rlaan_star_fortress","rlaan_medical","medical","outpost","agricultural_station","shaper_bio_adaptation","gasmine","MiningBase","Shipyard","rlaan_mining_base","commerce_center",
		--~ "civilan_asteroid_shipyard","research","rlaan_fighter_barracks","uln_refinery","rlaan_commerce_center","relaysat","fighter_barracks","refinery",})
end


function LoadUnitTypes ()
	local filepath = GetVegaDataDir().."units/units.csv"
	local iLineNum = 0
	gUnitTypeFieldNames = explode(",","id,Directory,Name,STATUS,Object_Type,Combat_Role,Textual_Description,Hud_image,Unit_Scale,"..
		"Cockpit,CockpitX,CockpitY,CockpitZ,Mesh,Shield_Mesh,Rapid_Mesh,BSP_Mesh,Use_BSP,Use_Rapid,NoDamageParticles,"..
		"Mass,Moment_Of_Inertia,Fuel_Capacity,Hull,"..
		"Armor_Front_Top_Right,Armor_Front_Top_Left,Armor_Front_Bottom_Right,Armor_Front_Bottom_Left,Armor_Back_Top_Right,Armor_Back_Top_Left,Armor_Back_Bottom_Right,Armor_Back_Bottom_Left,"..
		"Shield_Front_Top_Right,Shield_Back_Top_Left,Shield_Front_Bottom_Right,Shield_Front_Bottom_Left,Shield_Back_Top_Right,Shield_Front_Top_Left,Shield_Back_Bottom_Right,Shield_Back_Bottom_Left,"..
		"Shield_Recharge,Shield_Leak,Warp_Capacitor,Primary_Capacitor,Reactor_Recharge,Jump_Drive_Present,Jump_Drive_Delay,Wormhole,"..
		"Outsystem_Jump_Cost,Warp_Usage_Cost,Afterburner_Type,Afterburner_Usage_Cost,Maneuver_Yaw,Maneuver_Pitch,Maneuver_Roll,"..
		"Yaw_Governor,Pitch_Governor,Roll_Governor,"..
		"Afterburner_Accel,Forward_Accel,Retro_Accel,Left_Accel,Right_Accel,Top_Accel,Bottom_Accel,"..
		"Afterburner_Speed_Governor,Default_Speed_Governor,ITTS,Radar_Color,Radar_Range,Tracking_Cone,Max_Cone,Lock_Cone,"..
		"Hold_Volume,Can_Cloak,Cloak_Min,Cloak_Rate,Cloak_Energy,Cloak_Glass,Repair_Droid,ECM_Rating,ECM_Resist,Ecm_Drain,"..
		"Hud_Functionality,Max_Hud_Functionality,Lifesupport_Functionality,Max_Lifesupport_Functionality,Comm_Functionality,Max_Comm_Functionality,"..
		"FireControl_Functionality,Max_FireControl_Functionality,SPECDrive_Functionality,Max_SPECDrive_Functionality,Slide_Start,Slide_End,"..
		"Activation_Accel,Activation_Speed,Upgrades,Prohibited_Upgrades,Sub_Units,Sound,Light,Mounts,Net_Comm,Dock,Cargo_Import,Cargo,"..
		"Explosion,Num_Animation_Stages,Upgrade_Storage_Volume,Heat_Sink_Rating,Shield_Efficiency,Num_Chunks,Chunk_0,Collide_Subunits,Spec_Interdiction,Tractorability")
	
	for line in io.lines(filepath) do 
		iLineNum = iLineNum + 1
		local csv = ParseCSVLine(line)
		if (iLineNum > 3) then 
			local o = {}
			for k,fieldname in ipairs(gUnitTypeFieldNames) do o[fieldname] = csv[k] end
			local id = o.id or "???"
			assert(not gUnitTypes[id])
			gUnitTypes[id] = o
			gUnitTypesI[string.lower(id)] = o
			--~ if (string.find(id,"__planets$") or (not o.id)) then 
			--~ if (string.find(id,"planet")) then 
				--~ if (not gMyFirstPlanet) then gMyFirstPlanet = true print("units.csv.planet:",pad("ID",30),pad("Directory",30),pad("Name",25),"TYPE","Hud_image") end
				--~ print("units.csv.planet:",pad(o.id,30),pad(o.Directory,30),pad(o.Name,25),o.STATUS,o.Object_Type,o.Hud_image)
				--~ for k,v in pairs(o) do print(o.id,k,v) end
				--~ os.exit(0)
			--~ end
		end
	end
	--[[
	parse cargo import : 
	
	Dirt__planets   Cargo_Import    {Consumer_and_Commercial_Goods/Domestic;1;.1;2;2}
			{Consumer_and_Commercial_Goods/Electronics;1;.1;;}....
			{upgrades/Weapons/Mounted_Guns_Medium;1;.1;12;5}
	]]--
end

