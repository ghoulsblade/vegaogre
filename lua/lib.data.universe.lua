-- loads sectors and data/universe/milky_way.xml
-- ./start.sh -testuniv

RegisterListener("Hook_CommandLine",function () if (gCommandLineSwitches["-testuniv"]) then print(lugrepcall(LoadUniverse)) os.exit(0) end end)

local function GetVar (node,key) for k,v in ipairs(node.var) do if (v.name == key) then return v.value end end end
local function GetJumpList (system) return explode(" ",GetVar(system,"jumps") or "") end
function LoadUniverse ()
	print("LoadUniverse")
	local filepath = gMainWorkingDir.."data/universe/milky_way.xml"
	local galaxy = EasyXMLWrap(LuaXML_ParseFile(filepath)[1])
	for k,var in ipairs(galaxy.planets[1].var) do print("var:",var.name,var.value) end
	for k,planet in ipairs(galaxy.planets[1].planet) do print("planet:",GetVar(planet,"initial"),planet.name) end
	for k,sector in ipairs(galaxy.systems[1].sector) do 
		print("sector:",sector.name) 
		for k,system in ipairs(sector.system) do print(" system",system.name,"jumps:",unpack(GetJumpList(system))) end
	end
end

