-- loads sectors and data/universe/milky_way.xml
-- ./start.sh -testuniv
-- TODO : VegaStrike/data/units/factions/planets  subfolders contain buy/sell infos


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

-- plaintext listfiles in universe dir
gUniverseTextListCache = {}
function GetUniverseTextList (name_sys,name_default,sep) return GetUniverseTextList_One(name_sys,sep) or GetUniverseTextList_One(name_default,sep) end
function GetUniverseTextList_One (name,sep)
	if ((not name) or name == "") then return false end
	local cache = gUniverseTextListCache[name] if (cache ~= nil) then return cache end
	local plaintext = FileGetContents(GetVegaDataDir().."universe/"..name)
	if (plaintext) then 
		cache = strsplit(sep or "[ \t\n\r]+",plaintext)
	else
		cache = false
	end
	gUniverseTextListCache[name] = cache
	return cache
end

gPlanetMatCache = {}

function VegaGetTexNameFromFileParam (fileparam)
	local params = {} for param in string.gmatch(fileparam,"[^|]+") do table.insert(params,param) end
	local lastparam = params[#params]
	if (not lastparam) then print("VegaGetTexNameFromFileParam ERROR: no last param") return "carribean1.dds" end -- "oceanBase.dds"
	-- lastparam=planets/ocean.texture
	lastparam = string.gsub(lastparam,"~$","")
	lastparam = string.gsub(lastparam,"%.texture$",".dds")
	lastparam = string.gsub(lastparam,"^.*/","")
	--~ print("VegaGetTexNameFromFileParam",lastparam," from ",fileparam)
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
	
	--~ print("GetPlanetMaterialName",planetfile,atmosfile)
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

-- used by lib.system.lua
function VegaLoadSystemToXML (systempath)
	local univ_system = gUniv_SystemByPath[systempath] assert(univ_system)
	
	-- find system file or random-generate a new one from universe params
	local filepath1 = GetVegaDataDir().."sectors/"..systempath..".system"
	local filepath2 = GetVegaHomeDataDir().."sectors/milky_way.xml/"..systempath..".system"
	local filepath3 = GetVegaOgreHomeDataDir().."sectors/milky_way.xml/"..systempath..".system"
	
	local a,b,sectorname,systemname = string.find(systempath,"([^/]+)/(.*)")
	CreateDirIfNoExists(GetVegaOgreHomeDataDir().."sectors")
	CreateDirIfNoExists(GetVegaOgreHomeDataDir().."sectors/milky_way.xml")
	CreateDirIfNoExists(GetVegaOgreHomeDataDir().."sectors/milky_way.xml/"..sectorname)
	
	local exists1 = file_exists(filepath1)
	local exists2 = file_exists(filepath2)
	local exists3 = file_exists(filepath3)
	if (exists1 and exists2) then print("WARNING! VegaLoadSystem : both filepaths exist",filepath1,filepath2) end
	local filepath = (exists1 and filepath1) or (exists2 and filepath2) or (exists3 and filepath3)
	if (not filepath) then
		filepath = filepath3
		VegaGenerateSystem(filepath,systempath)
		if (not file_exists(filepath)) then print("WARNING! VegaLoadSystem : failed to generate new system") return end
	end
	local system = EasyXMLWrap(LuaXML_ParseFile(filepath)[1]) assert(system)
	if (filepath == filepath3 and tonumber(system.vegaogre_xml_version or 0) ~= kVegaOgreStarSystemRandomGenVersion) then
		print("VegaLoadSystem : old random-system-gen version detected, regenerating",system.vegaogre_xml_version,filepath3)
		VegaGenerateSystem(filepath,systempath)
		if (not file_exists(filepath)) then print("WARNING! VegaLoadSystem : failed to generate new system2") return end
		system = EasyXMLWrap(LuaXML_ParseFile(filepath)[1]) assert(system)
	end
	return system
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
	LoadUnitTypes()
	--~ print()
	--~ print("milky_way.planet:",pad("NAME",30),pad("TEXTURE",30),"INITIAL")
	local filepath = GetVegaDataDir().."universe/milky_way.xml"
	gGalaxy = EasyXMLWrap(LuaXML_ParseFile(filepath)[1])
	for k,sector in ipairs(gGalaxy.systems[1].sector) do 
		gUniv_SectorByName[sector.name] = sector 
		for k,system in ipairs(sector.system) do gUniv_SystemByPath[sector.name.."/"..system.name] = Univ_ParseVars(system) end
	end
	
	gUniv_PlanetTypeByInitial = {}
	--~ for k,var in ipairs(gGalaxy.planets[1].var) do print("var:",var.name,var.value) end
	for k,planet in ipairs(gGalaxy.planets[1].planet) do
		local p = Univ_ParseVars(planet)
		local o = GetUnitTypeForPlanetNode(planet)
		p.name = planet.name
		p.unittype = o
		gUniv_PlanetTypeByInitial[p.initial] = p
		--~ print("milky_way.planet:",pad(planet.name,30),pad(GetVegaXMLVar(planet,"texture"),30),GetVegaXMLVar(planet,"initial"),pad(o.id,20),o.Hud_image)
	end
	--~ for k,sector in ipairs(gGalaxy.systems[1].sector) do 
		--~ print("sector:",sector.name) 
		--~ for k,system in ipairs(sector.system) do print(" system",system.name,"jumps:",unpack(GetJumpList(system))) end
	--~ end
	
end

