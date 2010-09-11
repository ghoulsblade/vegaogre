-- loads sectors and data/universe/milky_way.xml
-- ./start.sh -testuniv

gUnitTypes = {}
gUniv_SectorByName = {}
gUniv_SystemByPath = {}
kJumpTextureName = "jump.texture"

RegisterListener("Hook_CommandLine",function () 
	if (gCommandLineSwitches["-testuniv"]) then 
		print(lugrepcall(function () 
			gVegaUniverseDebugNoGfx = true
			LoadUniverse() 
			VegaLoadSystem("Crucible/Cephid_17") 
			end))
		os.exit(0) 
	end
end)

local function GetVar (node,key) for k,v in ipairs(node.var) do if (v.name == key) then return v.value end end end
local function GetJumpList (system) return explode(" ",GetVar(system,"jumps") or "") end

function GetPlanetUnitTypeIDFromTexture (texture) 
	local a,b,basename = string.find(texture,"([^/.]+)[^/]*$")
	return (basename or texture).."__planets"
end
function GetUnitTypeForPlanetNode (planetnode) return gUnitTypes[GetVar(planetnode,"unit") or GetPlanetUnitTypeIDFromTexture(GetVar(planetnode,"texture") or "???") or "???"] end

function Univ_ParseVars (node) local res = {} for k,child in ipairs(node) do if (child._name == "var") then res[child.name or "?"] = child.value end end return res end

function GetVegaDataDir () return gMainWorkingDir.."data/" end
function GetVegaHomeDataDir () 
	if (not gVegaHomeDataDir) then gVegaHomeDataDir = (GetHomePath() or ".").."/.vegastrike/" end
	return gVegaHomeDataDir
end


function VegaGenerateSystem (filepath,systempath) -- systempath = sector/system e.g. "Crucible/Cephid_17"
	local system = gUniv_SystemByPath[systempath] assert(system)
	print("WARNING! VegaGenerateSystem not yet implemented")
end

function GetOrbitMeanRadiusFromNode (node) -- ri="-468434.7" rj="-361541" rk="433559.750000" si="-412172.000000" sj="300463.5" sk="-498163.5"
	local ri = tonumber(node.ri or "") or 0
	local rj = tonumber(node.rj or "") or 0
	local rk = tonumber(node.rk or "") or 0
	local si = tonumber(node.si or "") or 0
	local sj = tonumber(node.sj or "") or 0
	local sk = tonumber(node.sk or "") or 0
	return 0.5*(Vector.len(ri,rj,rk) + Vector.len(si,sj,sk))
end

function ImproveObjectName (name)
	if (not name) then return end
	name = string.gsub(name,"JumpTo","jump to ")
	name = string.gsub(name,"_"," ")
	return name
end

function FindUnitTypeFromFileValue (file) 
	if (not file) then return end
	return gUnitTypes[file] or gUnitTypes[file.."__neutral"] or gUnitTypes[GetPlanetUnitTypeIDFromTexture(file)]
end

gPlanetMatCache = {}

function VegaGetTexNameFromFileParam (fileparam)
	local params = {} for param in string.gmatch(fileparam,"[^|]+") do table.insert(params,param) end
	local lastparam = params[#params]
	if (not lastparam) then print("VegaGetTexNameFromFileParam ERROR: no last param") return "carribean1.dds" end -- "oceanBase.dds"
	-- lastparam=planets/ocean.texture
	lastparam = string.gsub(lastparam,"%.texture$",".dds")
	lastparam = string.gsub(lastparam,"^.*/","")
	print("VegaGetTexNameFromFileParam",lastparam," from ",fileparam)
	return lastparam
	-- planetfile=planets/oceanBase.texture|planets/ocean.texture
	-- atmosfile=sol/earthcloudmaptrans2.texture
	--~ data/textures/planets/oceanBase.dds
	--~ data/textures/planets/ocean.dds
end

function GetPlanetMaterialNameFromNode (node) 	
	--~ if (1 == 1) then return CloneMaterial("planetbase") end
	local planetfile = node.file
	local atmosfile = node.Atmosphere and node.Atmosphere[1] -- <Atmosphere file="sol/earthcloudmaptrans2.texture" alpha="SRCALPHA INVSRCALPHA" radius="5020.0"/>
	atmosfile = atmosfile and atmosfile.file
	
	local cachename = planetfile..(atmosfile and (",a="..atmosfile) or "")
	local mat = gPlanetMatCache[cachename] if (mat ~= nil) then return mat end
	
	print("GetPlanetMaterialName",planetfile,atmosfile)
	-- data/sectors/Crucible/Cephid_17.system : 
	-- <Planet name="Cephid_17 A" 	file="stars/white_star.texture" Red="0.95" Green="0.93" Blue="0.64" ReflectNoLight="true" light="0">
	-- <Planet name="Atlantis" 		file="planets/oceanBase.texture|planets/ocean.texture" ....>       
	-- <Planet name="Phillies" 		file="planets/rock.texture">
	-- <Planet name="Cephid_17 B" 	file="stars/red_star.texture"  Red="0.950000" Green="0.207289" Blue="0.119170" ReflectNoLight="true" light="1">
	-- <Planet name="Wiley" 		file="planets/molten.texture"   >
	-- <Planet name="Broadway" 		file="sol/ganymede.texture|planets/rock.texture"  >
	
	local tex_ground	= VegaGetTexNameFromFileParam(planetfile)
	local tex_clouds	= atmosfile and VegaGetTexNameFromFileParam(atmosfile)

	if (tex_clouds) then 
		mat = CloneMaterial("planetbase_ground_cloud") -- pass1=base pass2=light pass3=cloud
		SetTexture(mat,tex_ground,0,0,0)
		SetTexture(mat,tex_clouds,0,1,0)
	else 
		mat = CloneMaterial("planetbase_ground") -- pass1=base pass2=cloud
		SetTexture(mat,tex_ground,0,0,0)
	end
	gPlanetMatCache[cachename] = mat
	return mat
end

gSpawnSystemEntryID = 0
function SpawnSystemEntry (child,parentloc,depth)
	gSpawnSystemEntryID = gSpawnSystemEntryID + 1
	if (child._name == "Light") then return end
	if (child._name == "Fog") then return end     
	if (child._name == "Atmosphere") then return end  
	assert(parentloc)
	local s = gCurSystemScale
	local d = (GetOrbitMeanRadiusFromNode(child) or 0)*s
	local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
	local loc = gVegaUniverseDebugNoGfx and {} or VegaSpawnMajorLoc(parentloc,x,y,z,child.name)
	local r = child.radius and tonumber(child.radius)
	if (r) then r = r * s end
	local file = child.file
	local unittype = FindUnitTypeFromFileValue(file)
	local dbg_unitname = unittype and unittype.id or (file and ("NOTFOUND:"..GetPlanetUnitTypeIDFromTexture(file)))
	print(string.rep("+",depth),gSpawnSystemEntryID,pad(child._name or "",10),pad(child.name or "",10),pad(floor(d),10),pad(tostring(r and floor(r)),10),pad(dbg_unitname,20),child.file)
	local unitid = child.file
	
	if (not gVegaUniverseDebugNoGfx) then
		--~ destination="Crucible/Stirling" faction="klkk"
		local obj
		if (child._name == "Unit") then
			obj = cStation:New(loc,0,0,0	,r or 400,"agricultural_station.mesh")
		elseif (child._name == "Asteroid") then
			obj = cPlanet:New(loc,0,0,0,10,"planetbase_ground")  -- TODO!
		elseif (child.file == kJumpTextureName or child._name == "Jump") then
			obj = cPlanet:New(loc,0,0,0,10,"planetbase_ground")  -- TODO!
		elseif (child._name == "Planet") then
			obj = cPlanet:New(loc,0,0,0	,r or 6371.0*km,GetPlanetMaterialNameFromNode(child))
		end
		if (obj) then 
			obj:SetRandomRot()
			obj.name = ImproveObjectName(child.name)
			--~ obj.name = "["..gSpawnSystemEntryID.."]"..obj.name
			loc.primary_object = obj
			obj.orbit_master = parentloc and parentloc.primary_object
			RegisterNavTarget(obj)
		end
	end
	
	for k,subchild in ipairs(child) do SpawnSystemEntry(subchild,loc,depth+1) end
end

--[[
SpawnSystemEntry        Asteroid                        0               AFieldJumpThin
SpawnSystemEntry        Planet          JumpTo17-ar     0               jump.texture
SpawnSystemEntry        Planet          Cephid_17 A     0               stars/white_star.texture
SpawnSystemEntry        Planet          Atlantis        162788240       planets/oceanBase.texture|planets/ocean.texture
SpawnSystemEntry        Planet          Phillies        723268          planets/rock.texture
SpawnSystemEntry        Planet          JumpToEnyo      829181          jump.texture
SpawnSystemEntry        Planet          JumpToCardell   660457          jump.texture
SpawnSystemEntry        Unit            Ataraxia        61717           Fighter_Barracks
SpawnSystemEntry        Planet          JumpToOldziey   145266170       jump.texture
SpawnSystemEntry        Unit            Plainfield      35369           Relay
SpawnSystemEntry        Planet          JumpToEverett   149724056       jump.texture
SpawnSystemEntry        Planet          JumpToStirling  142012802       jump.texture
SpawnSystemEntry        Planet          Cephid_17 B     4574264635      stars/red_star.texture
SpawnSystemEntry        Planet          Wiley           177492695       planets/molten.texture
SpawnSystemEntry        Unit            Serenity        44024           MiningBase
SpawnSystemEntry        Planet          Broadway        120320579       sol/ganymede.texture|planets/rock.texture
]]--

function VegaLoadSystem (systempath) -- systempath = sector/system e.g. "Crucible/Cephid_17"
	print("VegaLoadSystem start",systempath)
	local univ_system = gUniv_SystemByPath[systempath] assert(univ_system)
	local filepath1 = GetVegaDataDir().."sectors/"..systempath..".system"
	local filepath2 = GetVegaHomeDataDir().."sectors/milky_way.xml/"..systempath..".system"
	local exists1 = file_exists(filepath1)
	local exists2 = file_exists(filepath2)
	if (exists1 and exists2) then print("WARNING! VegaLoadSystem : both filepaths exist",filepath1,filepath2) end
	local filepath = (exists1 and filepath1) or (exists2 and filepath2)
	if (not filepath) then
		filepath = filepath2
		VegaGenerateSystem(filepath,systempath)
		if (not file_exists(filepath)) then print("WARNING! VegaLoadSystem : failed to generate new system") return end
	end
	local system = EasyXMLWrap(LuaXML_ParseFile(filepath)[1]) assert(system)
	
	gCurSystemScale = tonumber(system.scalesystem or "") or 1
	print("system:",filepath,system.name,system.background,gCurSystemScale) --~ "Cephid_17","backgrounds/green","1000"
	
	local system_root_loc = gVegaUniverseDebugNoGfx and {} or VegaSpawnSystemRootLoc()
	for k,child in ipairs(system) do 
		SpawnSystemEntry(child,system_root_loc,0)
	end
	-- file="stars/white_star.texture" -> white_star__planets
	--~ for ismoon,initial in string.gmatch(system.planets or "","(%*?)([^%s]+)") do 
		--~ print("planet:",ismoon,initial)
	--~ end
end

--[[
		<system name="Cephid_17"><var name="planets" value="mol *r v a bs gd bd *r gg gg fr"/>
			<var name="data" value="-932898433"/>
			<var name="faction" value="klkk"/>
			<var name="luminosity" value="0"/>
			<var name="num_gas_giants" value="0"/>
			<var name="num_moons" value="2"/>
			<var name="num_natural_phenomena" value="2"/>
			<var name="num_planets" value="3"/>
			<var name="planetlist" value=""/>
			<var name="sun_radius" value="16600.000000"/>
			<var name="xyz" value="389.551310 -309.661278 348.064561"/>
			<var name="jumps" value="Crucible/17-ar Crucible/Stirling Crucible/Cardell Crucible/Enyo Crucible/Everett Crucible/Oldziey"/>
		</system>
]]--

function LoadUniverse ()
	print("LoadUniverse")
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
	--~ print()
	--~ print("milky_way.planet:",pad("NAME",30),pad("TEXTURE",30),"INITIAL")
	local filepath = GetVegaDataDir().."universe/milky_way.xml"
	gGalaxy = EasyXMLWrap(LuaXML_ParseFile(filepath)[1])
	for k,sector in ipairs(gGalaxy.systems[1].sector) do 
		gUniv_SectorByName[sector.name] = sector 
		for k,system in ipairs(sector.system) do gUniv_SystemByPath[sector.name.."/"..system.name] = Univ_ParseVars(system) end
	end
	
	--~ for k,var in ipairs(gGalaxy.planets[1].var) do print("var:",var.name,var.value) end
	--~ for k,planet in ipairs(gGalaxy.planets[1].planet) do 
		--~ local o = GetUnitTypeForPlanetNode(planet)
		--~ print("milky_way.planet:",pad(planet.name,30),pad(GetVar(planet,"texture"),30),GetVar(planet,"initial"),pad(o.id,20),o.Hud_image)
	--~ end
	--~ for k,sector in ipairs(gGalaxy.systems[1].sector) do 
		--~ print("sector:",sector.name) 
		--~ for k,system in ipairs(sector.system) do print(" system",system.name,"jumps:",unpack(GetJumpList(system))) end
	--~ end
	
end

