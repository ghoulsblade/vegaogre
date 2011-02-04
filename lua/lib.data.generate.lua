-- generate xml file
-- filepath=~/.vegastrike/sectors/milky_way.xml/Crucible/Cardell.system   systempath=Crucible/Cardell

kVegaOgreStarSystemRandomGenVersion = 2

function VegaGenerateSystem (filepath,systempath) -- systempath = sector/system e.g. "Crucible/Cephid_17"
	assert(not file_exists(filepath)) -- don't overwrite
	local system = gUniv_SystemByPath[systempath] assert(system) -- entry from milky_way.xml or similar
	print("WARNING! VegaGenerateSystem not yet fully implemented",filepath,systempath,system)
	--~ for k,v in pairs(system) do print("system:",k,v) end
	--[[
		<system name="Everett"><var name="planets" value="v am"/>
			<var name="data" value="-212090610"/>
			<var name="faction" value="klkk"/>
			<var name="luminosity" value="0"/>
			<var name="num_gas_giants" value="2"/>
			<var name="num_moons" value="1"/>
			<var name="num_natural_phenomena" value="0"/>
			<var name="num_planets" value="2"/>
			<var name="planetlist" value=""/>
			<var name="sun_radius" value="16600.000000"/>
			<var name="xyz" value="458.345985 -313.414374 260.599833"/>
			<var name="jumps" value="Crucible/Enyo Crucible/Elohim Crucible/Exile Crucible/Cardell Crucible/Stirling Crucible/Maat Crucible/Cephid_17"/>
		</system>
	]]--
	
	local a,b,sectorname,systemname = string.find(systempath,"(.*)/(.*)") assert(systemname)
	
	local system_scale = 1000
	--~ local s = gCurSystemScale
	--~ local d = (GetOrbitMeanRadiusFromNode(child) or 0)*s
	
	local myplanets = {}
	
	local namelist			= GetUniverseTextList(system.namelist		,"names.txt","\n")
	local backgroundlist	= GetUniverseTextList(system.backgroundlist	,"background.txt")
	local asteroidlist		= GetUniverseTextList(system.asteroidlist	,"asteroids.txt","\n")
	
	local xmlmain = {name="system",attr={}} -- see also SimpleXMLSaveToXMLNode
	xmlmain.attr.name			= systemname
	xmlmain.attr.background		= GetRandomArrayElement(backgroundlist) or "backgrounds/green"
	xmlmain.attr.nearstars		= 500
	xmlmain.attr.stars			= 1000
	xmlmain.attr.starspread		= 150
	xmlmain.attr.scalesystem	= system_scale
	xmlmain.attr.vegaogre_xml_version	= tostring(kVegaOgreStarSystemRandomGenVersion)
	--~ <system name="Cephid_17" background="backgrounds/green" nearstars="500" stars="1000" starspread="150" scalesystem="1000">
	
	function MyMakeRandomPlanetName ()
		return GetRandomArrayElement(namelist) or ("P"..math.random(10,99))
	end
	function MyMakeRandomOrbitParams (d)
		d = d or 1000
		return d,0,0, 0,d,0
	end
	
	local earthradius = 6371.0*km/system_scale
	
	-- counter
	local objcounter = {
		gas_giants = 0,
		natural_phenomena = 0,
		planets = 0,
		moons = 0,
		starbases = 0,
		stars = 0,
	}
	
	-- make objects
	
	local function MyMakePlanet		(tex,r,orbitpos,parent_planet) -- parent_planet = parent for moon, nil otherwise
		print("MyMakePlanet",tex)
		local ri,rj,rk,si,sj,sk
		local bIsMoon = parent_planet
		if (orbitpos) then ri,rj,rk,si,sj,sk = unpack(orbitpos) else ri,rj,rk,si,sj,sk = MyMakeRandomOrbitParams(bIsMoon and (rand2f(2,5)*parent_planet.attr.radius) or (au * (rand2i(1,8) + rand2f(0.0,0.2)) / system_scale)) end
		
		local new_planet = {name="Planet",attr={
			file	= tex,
			name	= MyMakeRandomPlanetName(),
			radius	= r,
			ri=ri, rj=rj, rk=rk, si=si, sj=sj, sk=sk,
			}}
		XMLNodeAddChild(parent_planet or xmlmain,new_planet)
		table.insert(myplanets,new_planet)
	end
	local function MyMakeMoon		(tex)
		print("MyMakeMoon",tex)
		local parent = GetRandomArrayElement(myplanets)
		MyMakePlanet(tex,parent and (rand2f(0.05,0.3)*parent.attr.radius) or (earthradius * rand2f(0.2,4)),nil,parent)
	end
	local function MyMakeNebulae	(tex) print("TODO: MyMakeNebulae",tex) end 
	local function MyMakeSun		(tex) print("TODO: MyMakeSun",tex) end 
	local function MyMakeStarBase	(tex) 
		print("MyMakeStarBase",tex) 
		local file = string.gsub(tex,".*%^","") -- remove U1000^  from texname :  U1000^MiningBase U800^MiningBase
		local parent_planet = GetRandomArrayElement(myplanets)
		local bIsMoon = parent_planet
		local ri,rj,rk,si,sj,sk = MyMakeRandomOrbitParams(bIsMoon and (rand2f(4,10)*parent_planet.attr.radius) or (au * (rand2i(1,8) + rand2f(0.0,0.2)) / system_scale))
		
		--~ <Unit serial="00108" name="Serenity" file="MiningBase" faction="klkk"  >
		local node = {name="Unit",attr={
			file	= file,
			faction = system.faction,
			ri=ri, rj=rj, rk=rk, si=si, sj=sj, sk=sk,
			}}
		XMLNodeAddChild(parent_planet or xmlmain,node)
	end 
	
	-- planet list
	
	if (system.planets and system.planets ~= "") then
		for ismoon,initial in string.gmatch(system.planets or "","(%**)([^%s]+)") do 
			local pt = gUniv_PlanetTypeByInitial[initial]
			local bIsMoon = ismoon ~= ""
			print("planet-typed:",ismoon,bIsMoon,initial,pt and pt.name,pt and pt.texture,pt and pt.lights)
			if (pt) then 
				MyMakePlanet(pt.texture..".texture",earthradius * rand2f(0.2,4),nil,bIsMoon and myplanets[#myplanets])
				--~ <Planet name="Macarthur" file="planets/Lava.texture"  radius="7344485.500000" x="-6392795648.000000" y="54927466496.000000" z="-47471091712.000000" year= "36770537845.938515" day="248.644551" >
				if (bIsMoon) then objcounter.moons = objcounter.moons + 1 else objcounter.planets = objcounter.planets + 1 end
			end
		end
	end
	
	
	-- random generated by num_x
	
	local function MyRandomGen_ByNumber (title,num_required,num_cur,texlist,fun_create)
		num_required = tonumber(num_required) or 0
		print("MyRandomGen_ByNumber",title,num_required,num_cur)
		if (num_cur >= num_required) then return end
		for i=1,num_required-num_cur do fun_create(texlist and GetRandomArrayElement(texlist)) end
	end
	
	-- NOTE : planets.txt , moons.txt contain object types (textures referencing units.csv?) for random planet generation
	MyRandomGen_ByNumber("gas"		,system.num_gas_giants					,objcounter.gas_giants			,GetUniverseTextList(system.gasgiantlist,"gas_giants.txt")	,function (tex) MyMakePlanet(tex,rand2f(3,20)*earthradius) end)
	MyRandomGen_ByNumber("planet"	,system.num_planets						,objcounter.planets				,GetUniverseTextList(system.planetlist,"planets.txt")		,function (tex) MyMakePlanet(tex,rand2f(0.2,4)*earthradius) end)
	MyRandomGen_ByNumber("nebu"		,system.num_natural_phenomena			,objcounter.natural_phenomena	,GetUniverseTextList(system.nebulalist,"nebulae.txt","\n")	,function (tex) MyMakeNebulae(tex) end)
	MyRandomGen_ByNumber("moon"		,system.num_moons						,objcounter.moons				,GetUniverseTextList(system.moonlist,"moons.txt")			,function (tex) MyMakeMoon(tex) end)
	MyRandomGen_ByNumber("starbase"	,system.num_starbases or rand2i(0,3)	,objcounter.starbases			,GetUniverseTextList(system.unitlist,"smallunits.txt")		,function (tex) MyMakeStarBase(tex) end)
	MyRandomGen_ByNumber("star"		,system.num_stars						,objcounter.stars				,GetUniverseTextList(system.starlist,"stars.txt","\n")		,function (tex) MyMakeSun(tex) end)
	
	-- jumps
	
	for jumpdest in string.gmatch(system.jumps,"[^ ]+") do 
		print("jump:",jumpdest)
		local ri,rj,rk,si,sj,sk = MyMakeRandomOrbitParams(au * (rand2i(1,8) + rand2f(0.5,1.0)) / system_scale)
		local node = {name="Jump",attr={
					file		= "jump.texture",
					destination = jumpdest,
					alpha		="ONE ONE",
					name		= "Jump_To_"..string.gsub(jumpdest,".*/",""),
					radius		= 110,
					ri=ri, rj=rj, rk=rk, si=si, sj=sj, sk=sk,
					}}
		XMLNodeAddChild(xmlmain,node)
	end
	
	-- FilePutContents(filepath,'<?xml version="1.0" ?>'..LuaXML_SaveString(xmlmain))
	LuaXML_SaveFile(filepath,xmlmain)
	--~ os.exit(0)
end

if (1==2) then 
	local base = "/home/ghoul/.vegaogre/sectors/milky_way.xml/"
	LoadUniverse()
	for k,syspath in ipairs({"Crucible/Everett","Aeneth/Eilruaen"}) do 
		print("===============")
		local filepath = base..syspath..".system"
		os.remove(filepath)
		VegaGenerateSystem(filepath,syspath)
	end
	os.exit(0)
	--[[
		<system name="Everett"><var name="planets" value="v am"/>
			<var name="data" value="-212090610"/>
			<var name="faction" value="klkk"/>
			<var name="num_gas_giants" value="2"/>
			<var name="num_moons" value="1"/>
			<var name="num_natural_phenomena" value="0"/>
			<var name="num_planets" value="2"/>
			<var name="planetlist" value=""/>
			<var name="xyz" value="458.345985 -313.414374 260.599833"/>
		</system>
		]]--
end
