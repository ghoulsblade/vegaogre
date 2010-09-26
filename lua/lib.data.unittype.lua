-- units/units.csv   and utils


function GetPlanetUnitTypeIDFromTexture (texture) 
	local a,b,basename = string.find(texture,"([^/.]+)[^/]*$")
	return (basename or texture).."__planets"
end
function GetUnitTypeForPlanetNode (planetnode) 
	return gUnitTypes[GetVegaXMLVar(planetnode,"unit") or GetPlanetUnitTypeIDFromTexture(GetVegaXMLVar(planetnode,"texture") or "???") or "???"] 
end

function FindUnitTypeFromFileValue (file) 
	if (not file) then return end
	--~ file = string.gsub(file,"|.*","")
	file = string.gsub(file,".*|","")
	--~ print("FindUnitTypeFromFileValue",file,file.."__neutral",GetPlanetUnitTypeIDFromTexture(file))
	return gUnitTypes[file] or gUnitTypes[file.."__neutral"] or gUnitTypes[GetPlanetUnitTypeIDFromTexture(file)]
end


function GetUnitTypeFromSectorXMLNode (node) return FindUnitTypeFromFileValue(node.file) end


function GetJumpDestinationFromNode (node) return node and node.destination end

function GetHUDImageTexFromNode (node)
	local t = GetUnitTypeFromSectorXMLNode(node)
	print("GetHUDImageTexFromNode",node.file,t and ((t.Hud_image == "") and "TYPE:EMPTYHUD" or t.Hud_image) or "TYPE:MISSING") 
	if (not t) then return end
	local tex = t.Hud_image
	if (tex == "") then return end
	tex = string.gsub(tex,".*/","")
	tex = string.gsub(tex,"%.sprite$",".dds") -- todo : sprite = config file...
	return tex
end


function LoadUnitTypes ()
	local filepath = GetVegaDataDir().."units/units.csv"
	local iLineNum = 0
	for line in io.lines(filepath) do 
		iLineNum = iLineNum + 1
		local csv = ParseCSVLine(line)
		if (iLineNum > 3) then 
			local o = {}
			o.id,o.Directory,o.Name,o.STATUS,o.Object_Type,o.Combat_Role,o.Textual_Description,o.Hud_image,o.Unit_Scale,
				o.Cockpit,o.CockpitX,o.CockpitY,o.CockpitZ,o.Mesh,o.Shield_Mesh,o.Rapid_Mesh,o.BSP_Mesh,o.Use_BSP,o.Use_Rapid,o.NoDamageParticles,
				o.Mass,o.Moment_Of_Inertia,o.Fuel_Capacity,o.Hull,
				o.Armor_Front_Top_Right,o.Armor_Front_Top_Left,o.Armor_Front_Bottom_Right,o.Armor_Front_Bottom_Left,o.Armor_Back_Top_Right,o.Armor_Back_Top_Left,o.Armor_Back_Bottom_Right,o.Armor_Back_Bottom_Left,
				o.Shield_Front_Top_Right,o.Shield_Back_Top_Left,o.Shield_Front_Bottom_Right,o.Shield_Front_Bottom_Left,o.Shield_Back_Top_Right,o.Shield_Front_Top_Left,o.Shield_Back_Bottom_Right,o.Shield_Back_Bottom_Left,
				o.Shield_Recharge,o.Shield_Leak,o.Warp_Capacitor,o.Primary_Capacitor,o.Reactor_Recharge,o.Jump_Drive_Present,o.Jump_Drive_Delay,o.Wormhole,
				o.Outsystem_Jump_Cost,o.Warp_Usage_Cost,o.Afterburner_Type,o.Afterburner_Usage_Cost,o.Maneuver_Yaw,o.Maneuver_Pitch,o.Maneuver_Roll,
				o.Yaw_Governor,o.Pitch_Governor,o.Roll_Governor,
				o.Afterburner_Accel,o.Forward_Accel,o.Retro_Accel,o.Left_Accel,o.Right_Accel,o.Top_Accel,o.Bottom_Accel,
				o.Afterburner_Speed_Governor,o.Default_Speed_Governor,o.ITTS,o.Radar_Color,o.Radar_Range,o.Tracking_Cone,o.Max_Cone,o.Lock_Cone,
				o.Hold_Volume,o.Can_Cloak,o.Cloak_Min,o.Cloak_Rate,o.Cloak_Energy,o.Cloak_Glass,o.Repair_Droid,o.ECM_Rating,o.ECM_Resist,o.Ecm_Drain,
				o.Hud_Functionality,o.Max_Hud_Functionality,o.Lifesupport_Functionality,o.Max_Lifesupport_Functionality,o.Comm_Functionality,o.Max_Comm_Functionality,
				o.FireControl_Functionality,o.Max_FireControl_Functionality,o.SPECDrive_Functionality,o.Max_SPECDrive_Functionality,o.Slide_Start,o.Slide_End,
				o.Activation_Accel,o.Activation_Speed,o.Upgrades,o.Prohibited_Upgrades,o.Sub_Units,o.Sound,o.Light,o.Mounts,o.Net_Comm,o.Dock,o.Cargo_Import,o.Cargo,
				o.Explosion,o.Num_Animation_Stages,o.Upgrade_Storage_Volume,o.Heat_Sink_Rating,o.Shield_Efficiency,o.Num_Chunks,o.Chunk_0,o.Collide_Subunits,o.Spec_Interdiction,o.Tractorability
				= unpack(csv)
			local id = o.id or "???"
			assert(not gUnitTypes[id])
			gUnitTypes[id] = o
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

