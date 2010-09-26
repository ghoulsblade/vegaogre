-- generate xml file
-- filepath=~/.vegastrike/sectors/milky_way.xml/Crucible/Cardell.system   systempath=Crucible/Cardell

function VegaGenerateSystem (filepath,systempath) -- systempath = sector/system e.g. "Crucible/Cephid_17"
	assert(not file_exists(filepath)) -- don't overwrite
	local system = gUniv_SystemByPath[systempath] assert(system)
	print("WARNING! VegaGenerateSystem not yet implemented",filepath,systempath,system)
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
	
	local xmlmain = {name="system",attr={}} -- see also SimpleXMLSaveToXMLNode
	xmlmain.attr.name			= systemname
	xmlmain.attr.background		= "backgrounds/green"
	xmlmain.attr.nearstars		= 500
	xmlmain.attr.stars			= 1000
	xmlmain.attr.starspread		= 150
	xmlmain.attr.scalesystem	= system_scale
	xmlmain.attr.vegaogre_xml_version	= "1"
	--~ <system name="Cephid_17" background="backgrounds/green" nearstars="500" stars="1000" starspread="150" scalesystem="1000">
	
	function MyMakeRandomPlanetName (pt)
		return "P"..math.random(10,99)
	end
	function MyMakeRandomOrbitParams (d)
		d = d or 1000
		return d,0,0, 0,d,0
	end
	
	local earthradius = 6371.0*km/system_scale
	
	local planetnum = 0
	if (system.planets and system.planets ~= "") then
		for ismoon,initial in string.gmatch(system.planets or "","(%**)([^%s]+)") do 
			planetnum = planetnum + 1
			local pt = gUniv_PlanetTypeByInitial[initial]
			print("planet-typed:",ismoon,initial,pt and pt.name,pt and pt.texture,pt and pt.lights)
			if (pt) then 
				local ri,rj,rk,si,sj,sk = MyMakeRandomOrbitParams((math.random()*0.2+1.0) * au * planetnum / system_scale)
				local node = {name="Planet",attr={
					file	= pt.texture..".texture",
					name	= MyMakeRandomPlanetName(pt),
					radius	= earthradius * (0.5 + 3*math.random()),
					ri=ri,
					rj=rj,
					rk=rk,
					si=si,
					sj=sj,
					sk=sk,
					}}
				XMLNodeAddChild(xmlmain,node)
				--~ <Planet name="Macarthur" file="planets/Lava.texture"  radius="7344485.500000" x="-6392795648.000000" y="54927466496.000000" z="-47471091712.000000" year= "36770537845.938515" day="248.644551" >
			end
		end
	else
		for i=1,tonumber(system.num_planets or 0) do 
			print("planet-random:",i)
		end
	end
	
	for jumpdest in string.gmatch(system.jumps,"[^ ]+") do 
		print("jump:",jumpdest)
		local ri,rj,rk,si,sj,sk = MyMakeRandomOrbitParams((math.random()*0.5+0.5) * au * (planetnum+1) / system_scale)
		local node = {name="Jump",attr={
					file		= "jump.texture",
					destination = jumpdest,
					alpha		="ONE ONE",
					name		= "Jump_To_"..string.gsub(jumpdest,".*/",""),
					radius		= 110,
					ri=ri,
					rj=rj,
					rk=rk,
					si=si,
					sj=sj,
					sk=sk,
					}}
		XMLNodeAddChild(xmlmain,node)
	end
	
	-- FilePutContents(filepath,'<?xml version="1.0" ?>'..LuaXML_SaveString(xmlmain))
	LuaXML_SaveFile(filepath,xmlmain)
	--~ os.exit(0)
end

if (1==1) then 
	--~ LoadUniverse()
	--~ local filepath = "/home/ghoul/.vegaogre/sectors/milky_way.xml/Crucible/Everett.system"
	--~ os.remove(filepath)
	--~ VegaGenerateSystem(filepath,"Crucible/Everett")
	--~ os.exit(0)
end
