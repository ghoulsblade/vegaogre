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
	
	local xmlmain = {name="system",attr={}} -- see also SimpleXMLSaveToXMLNode
	xmlmain.attr.name			= systemname
	xmlmain.attr.background		= "backgrounds/green"
	xmlmain.attr.nearstars		= 500
	xmlmain.attr.stars			= 1000
	xmlmain.attr.starspread		= 150
	xmlmain.attr.scalesystem	= 1000
	--~ <system name="Cephid_17" background="backgrounds/green" nearstars="500" stars="1000" starspread="150" scalesystem="1000">
	
	if (system.planets and system.planets ~= "") then
		local planetnum = 0
		for ismoon,initial in string.gmatch(system.planets or "","(%**)([^%s]+)") do 
			planetnum = planetnum + 1
			local pt = gUniv_PlanetTypeByInitial[initial]
			print("planet-typed:",ismoon,initial,pt and pt.name,pt and pt.texture,pt and pt.lights)
		end
	else
		for i=1,tonumber(system.num_planets or 0) do 
			print("planet-random:",i)
		end
	end
	
	for jumpdest in string.gmatch(system.jumps,"[^ ]+") do 
		print("jump:",jumpdest)
	end
	
	-- <?xml version="1.0" ?>
	LuaXML_SaveFile(filepath,xmlmain)
	os.exit(0)
end

if (1==1) then 
	--~ LoadUniverse()
	--~ VegaGenerateSystem("/home/ghoul/.vegaogre/sectors/milky_way.xml/Crucible/Everett.system","Crucible/Everett")
	--~ os.exit(0)
end
