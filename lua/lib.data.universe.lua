-- loads sectors and data/universe/milky_way.xml
-- ./start.sh -testuniv

RegisterListener("Hook_CommandLine",function () if (gCommandLineSwitches["-testuniv"]) then print(lugrepcall(LoadUniverse)) os.exit(0) end end)
	
function LoadUniverse ()
	print("LoadUniverse")
	local filepath = gMainWorkingDir.."data/universe/milky_way.xml"
	local galaxy = EasyXMLWrap(LuaXML_ParseFile(filepath)[1])
	for k,var in ipairs(galaxy.planets[1].var) do print("var:",var.name,var.value) end
	for k,planet in ipairs(galaxy.planets[1].planet) do print("planet:",planet.name) end
	for k,sector in ipairs(galaxy.systems[1].sector) do print("sector:",sector.name) end
end

