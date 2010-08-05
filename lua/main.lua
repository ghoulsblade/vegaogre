-- VegaStrike port/rewrite using ogre, see README.txt
-- VegaStrike Main Website : http://vegastrike.sourceforge.net

--###############################
--###        CONSTANTS        ###
--###############################

-- Directories/Files
gMainWorkingDir     = GetMainWorkingDir and GetMainWorkingDir() or ""
gBinPath			= gMainWorkingDir.."bin/"  -- bin folder with config etc
datapath            = gMainWorkingDir.."data/"
libpath             = gMainWorkingDir.."lua/"

lugreluapath        = (file_exists(gMainWorkingDir.."mylugre") and gMainWorkingDir.."mylugre/lua/" or GetLugreLuaPath()) -- this is should also in USERHOME dir

--###############################
--###     OTHER LUA FILES     ###
--###############################

-- utils first
print("MainWorkingDir",gMainWorkingDir)
print("lugreluapath",lugreluapath)
dofile(lugreluapath .. "lugre.lua")
lugre_include_libs(lugreluapath)

--###############################
--###        FUNCTIONS        ###
--###############################

--- called from c right before Main() for every commandline argument
gCommandLineArguments = {}
gCommandLineSwitches = {}
gCommandLineSwitchArgs = {} -- gCommandLineSwitchArgs["-myoption"] = first param after -myoption
function CommandLineArgument (i,s) gCommandLineArguments[i] = s gCommandLineSwitches[s] = i gCommandLineSwitchArgs[gCommandLineArguments[i-1] or ""] = s end

function Main () 
	print("welcome to vegaogre")
end
