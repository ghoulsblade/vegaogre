-- loads sectors and data/universe/milky_way.xml
-- ./start.sh -testuniv

RegisterListener("Hook_CommandLine",function () if (gCommandLineSwitches["-testuniv"]) then print(lugrepcall(LoadUniverse)) os.exit(0) end end)

local function GetVar (node,key) for k,v in ipairs(node.var) do if (v.name == key) then return v.value end end end
local function GetJumpList (system) return explode(" ",GetVar(system,"jumps") or "") end


function LoadUniverse ()
	print("LoadUniverse")
	local filepath = gMainWorkingDir.."data/units/units.csv"
	for line in io.lines(filepath) do 
		local o = {}
		local csv = ParseCSVLine(line)
		--~ o.csv = csv
		o.codename,o.Directory,o.Name,o.STATUS,o.Object_Type,o.Combat_Role,o.Textual_Description,o.Hud_image,o.Unit_Scale,
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
		if (string.find(o.codename or "???","__planets$")) then 
		--~ if (string.find(o.codename or "???","planet")) then 
			print("o.codename",o.codename)
			--~ for k,v in pairs(o) do print(o.codename,k,v) end
			--~ os.exit(0)
		end
	end
	--[[
	parse cargo import : 
	
	Dirt__planets   Cargo_Import    {Consumer_and_Commercial_Goods/Domestic;1;.1;2;2}{Consumer_and_Commercial_Goods/Electronics;1;.1;;}{Industrially_Manufactured_Goods/Agricultural;.8;.2;26;12}{Industrially_Manufactured_Goods/Construction;.8;.2;17;5}{Industrially_Manufactured_Goods/Electronics;1.1;.1;1;1}{Industrially_Manufactured_Goods/Manufacturing;1.1;.1;10;4}{Industrially_Manufactured_Goods/Mining;.8;.2;25;15}{Industrially_Manufactured_Goods/Power_Utilities;.8;.2;35;12}{Industrially_Manufactured_Goods/Recycled_Products;1.2;.1;10;7}{Natural_Products/Life-forms;1;.1;;}{Natural_Products/Liquor;1.3;.2;;}{Natural_Products/Renewable_Resources;1.1;.2;15;5}{Raw_Materials/Gases;1.2;.2;10;5}{Raw_Materials/Hydrocarbons;.8;.2;;}{Raw_Materials/Industrial_Gems;1.2;.2;12;3}{Raw_Materials/Metals;.8;.1;;}{Raw_Materials/Stone;1.2;.2;16;15}{Refined_Materials/Chemicals;1.2;.2;8;2}{Refined_Materials/Precious_Metals;1.1;.2;12;5}{Refined_Materials/Purified_and_Enhanced_Materials;1;.1;1;1}{Refined_Materials/Radioactive_Metals;.8;.1;;}{Specialty_Goods/Entertainment;1;.1;1;1}{Specialty_Goods/Medical;1.1;.1;5;3}{starships/Andolian/Medium;1;;24;5}{starships/Andolian/Medium;1;;12;4}{starships/Confed/Heavy;1;;3;2}{starships/Confed/Light;1;;24;5}{starships/Confed/Medium;1;;12;4}{starships/Highborn/Heavy;1;;3;2}{starships/Hunter/Heavy;1;;3;2}{starships/Hunter/Light;1;;24;5}{starships/Hunter/Medium;1;;12;3}{starships/ISO/Heavy;1;;3;2}{starships/ISO/Medium;1;;36;8}{starships/Merchant/Heavy;1;;3;2}{starships/Merchant/Light;1;;24;5}{starships/Merchant/Light_Capship;1;;-24;30}{starships/Merchant/Medium;1;;12;4}{starships/Regional_Guard/Heavy;1;;3;2}{starships/Regional_Guard/Light;1;;24;5}{starships/Regional_Guard/Medium;1;;12;4}{upgrades/Ammunition/Common;1;.1;160;40}{upgrades/Ammunition/Uncommon;3;.9;60;140}{upgrades/Ammunition/Confed;2;.3;20;30}{upgrades/Armor;1;.1;10;5}{upgrades/Capacitors/Standard;1;.1;10;5}{upgrades/ECM_Systems;1;.1;3;1}{upgrades/Jump_Drives;1;.1;12;3}{upgrades/Overdrive;1;.1;3;2}{upgrades/Reactors/Standard;1;.1;10;5}{upgrades/Repair_Systems;1;.1;5;3}{upgrades/Sensors/Advanced;1;.1;-8;10}{upgrades/Sensors/Basic;1;.1;6;2}{upgrades/Sensors/Intermediate;1;.1;2;1}{upgrades/Shield_Systems/Standard_Dual_Shields;1;.1;20;5}{upgrades/Shield_Systems/Standard_Quad_Shields;1;.1;20;5}{upgrades/Weapons/Beam_Arrays_Heavy;1;.1;3;2}{upgrades/Weapons/Beam_Arrays_Light;1;.1;24;5}{upgrades/Weapons/Beam_Arrays_Medium;1;.1;12;4}{upgrades/Weapons/Mount_Enhancements;1;.1;-24;30}{upgrades/Weapons/Mounted_Guns_Heavy;1;.1;3;2}{upgrades/Weapons/Mounted_Guns_Light;1;.1;24;6}{upgrades/Weapons/Mounted_Guns_Medium;1;.1;12;5}
	]]--
	--[[
	local filepath = gMainWorkingDir.."data/universe/milky_way.xml"
	local galaxy = EasyXMLWrap(LuaXML_ParseFile(filepath)[1])
	for k,var in ipairs(galaxy.planets[1].var) do print("var:",var.name,var.value) end
	for k,planet in ipairs(galaxy.planets[1].planet) do print("planet:",GetVar(planet,"initial"),planet.name) end
	for k,sector in ipairs(galaxy.systems[1].sector) do 
		print("sector:",sector.name) 
		for k,system in ipairs(sector.system) do print(" system",system.name,"jumps:",unpack(GetJumpList(system))) end
	end
	]]--
end

