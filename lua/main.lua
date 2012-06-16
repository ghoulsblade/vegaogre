-- VegaStrike port/rewrite using ogre, see README.txt
-- VegaStrike Main Website : http://vegastrike.sourceforge.net

--###############################
--###        VARS	          ###
--###############################

-- Directories/Files
gMainWorkingDir     = GetMainWorkingDir and GetMainWorkingDir() or ""
gBinPath			= gMainWorkingDir.."bin/"  -- bin folder with config etc
datapath            = gMainWorkingDir.."data/"
libpath             = gMainWorkingDir.."lua/"

lugreluapath        = (file_exists(gMainWorkingDir.."mylugre") and gMainWorkingDir.."mylugre/lua/" or GetLugreLuaPath()) -- this is should also in USERHOME dir

gFrameCounter = 0

--###############################
--###     OTHER LUA FILES     ###
--###############################

-- utils first
--~ print("MainWorkingDir",gMainWorkingDir)
--~ print("lugreluapath",lugreluapath)
dofile(lugreluapath .. "lugre.lua")
lugre_include_libs(lugreluapath)

dofile(libpath .. "lib.vegamain.lua")
dofile(libpath .. "lib.net.packet.lua")
dofile(libpath .. "lib.net.proxy.lua")
--~ dofile(libpath .. "lib.net.proxy-old.lua")
dofile(libpath .. "lib.net.servermode.lua")

--###############################
--##  OGRE RESOURCE LOCATIONS  ##
--###############################

function CollectOgreResLocs ()
    local ogreversionadd = (GetOgreVersion and GetOgreVersion() >= 0x10600) and ".ogre1.6" or ".ogre1.4"
    print("GetOgreVersion",GetOgreVersion and sprintf("0x%x",GetOgreVersion()),ogreversionadd)
    local mydatapath = gMainWorkingDir.."data/"
    OgreAddResLoc(mydatapath.."base/OgreCore.zip"           ,"Zip","Bootstrap")
	
	VegaMainAddResLocs(mydatapath) 

    print("OgreInitResLocs...")
    OgreInitResLocs()
    print("OgreInitResLocs done")
end

--#################################
--### ERROR REPORTING AND HINTS ###
--#################################

function LugreExceptionTipps (descr)
    print("#################")
    print("###  LugreExceptionTipps  ###")
    print("#################")
    print(descr)
    print("#################")
    if (StringContains(descr,"Could not load dynamic library") and StringContains(descr,"Direct3D9")) then 
        local url = "http://www.microsoft.com/downloads/details.aspx?familyid=04AC064B-00D1-474E-B7B1-442D8712D553&displaylang=en" -- aug2009
        --~ local url = "http://www.microsoft.com/downloads/details.aspx?FamilyID=886acb56-c91a-4a8e-8bb8-9f20f1244a8e&DisplayLang=en" -- nov2008
        -- old : "http://download.microsoft.com/download/5/c/8/5c8b7216-bbc2-4215-8aa5-9dfef9cdb3df/directx_aug2008_redist.exe" -- aug2008
        -- generic : http://www.microsoft.com/downloads/details.aspx?familyid=2DA43D38-DB71-4C1B-BC6A-9B6652CD92A3&displaylang=de (todo:displaylang=en?) (link to newest, but requires windows validation procedure)
        local tipp =    "Your DirectX9 version is too old to run VegaOgre.\n"..
                        "Would you like to open a browser and download an Updated Version from the following url ?\n"..url
        print(tipp)
        
        local res = LugreMessageBox(kLugreMessageBoxType_YesNo,"Update DirectX9",tipp)
        if (res == kLugreMessageBoxResult_Yes) then
            OpenBrowser(url)
        end
    end
end

--###############################
--###        FUNCTIONS        ###
--###############################

--- called from c right before Main() for every commandline argument
gCommandLineArguments = {}
gCommandLineSwitches = {}
gCommandLineSwitchArgs = {} -- gCommandLineSwitchArgs["-myoption"] = first param after -myoption
function CommandLineArgument (i,s) gCommandLineArguments[i] = s gCommandLineSwitches[s] = i gCommandLineSwitchArgs[gCommandLineArguments[i-1] or ""] = s end

function LoadingProfile (sCurAction,bIsPreOgre) end

-- called from c
--- warning ! this gets called a lot while user resizes window
function NotifyMainWindowResized (w,h) gbMainWindowResized = true end -- warning, only mark as changed, might be called more than once per frame
RegisterStepper(function () if (gbMainWindowResized) then gbMainWindowResized = false NotifyListener("Hook_MainWindowResized") end end)


--###############################
--###        MAINLOOP         ###
--###############################

function Main () 
	--~ print("welcome to vegaogre")
	--~ print("pwd on Main start:",os.getenv("PWD"))
    local luaversion = string.sub(_VERSION, 5, 7)
    --~ print("Lua version : "..luaversion)
    --~ print("Ogre platform : "..OGRE_PLATFORM)
    gMyTicks = Client_GetTicks()
	
    NotifyListener("Hook_CommandLine")
	
	-- commandline arg for server mode ? 
	local a = gCommandLineSwitchArgs["-proxy"]	if (a) then return StartProxyMode(tonumber(a)) end
	local a = gCommandLineSwitchArgs["-server"]	if (a) then return StartServerMode(tonumber(a)) end
	
    NotifyListener("Hook_PluginsLoaded")
	
    LoadingProfile("initializing Ogre",true)
	SetOgreInputOptions(gbHideMouse,gbGrabInput)
    gPreOgreTime = gLoadingProfileLastTime
    print("initializing ogre...")
    if (not gNoOgre) then
		local bAutoCreateWindow = false
		local bAutoCreateWindow = true -- standard ogre resolution chooser at first
        if (not InitOgre("VegaOgre",gOgrePluginPathOverride or lugre_detect_ogre_plugin_path(),gBinPath,bAutoCreateWindow)) then os.exit(0) end
		if (OgreCreateWindow and (not bAutoCreateWindow)) then -- new startup procedure with separate window creation to allow gfx-config
			--~ GfxConfig_Apply()
			--~ GfxConfig_PreWindowCreate()
			if (not OgreCreateWindow(false)) then os.exit(0) end
		end
        CollectOgreResLocs()
		--~ GfxConfig_PostWindowCreate()
    end
    print("initializing ogre done")
    SetCursorBaseOffset(0,0)
	
    Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
    gViewportW,gViewportH = GetViewportSize()

    NotifyListener("Hook_PreLoad")
    --~ PreLoad()
	
	dofile(libpath .. "widget.itemicon.lua")
	
    --~ BindGeneralKeys()

    NotifyListener("Hook_PostLoad")
	
	VegaMainInit()

	-- mainloop
    while (Client_IsAlive()) do 
        MainStep() 
    end
	
    NotifyListener("Hook_Terminate")
	-- avoid ogre shutdown crash, so users aren't scared by weird error message after closing
	os.exit(0)
end

function MainStep ()
	gFrameCounter = gFrameCounter + 1
	
    gViewportW,gViewportH = GetViewportSize()
    LugreStep()
	
    NotifyListener("Hook_MainStep")

    InputStep() -- generate mouse_left_drag_* and mouse_left_click_single events 
    GUIStep() -- generate mouse_enter, mouse_leave events (might adjust cursor -> before CursorStep)
    ToolTipStep() -- needs mouse_enter, should be after GUIStep
    CursorStep()
	
	VegaMainStep()
	
	-- RENDER !
    Client_RenderOneFrame()
	
	-- time/fps wait
	
    local t = Client_GetTicks()
    local iTimeSinceLastFrame = gLastFrameTime and (t - gLastFrameTime)
    
    if (gMaxFPS) then 
        local iMinTimeBetweenFrames = 1000/gMaxFPS
        Client_USleep(max(1,iMinTimeBetweenFrames - (iTimeSinceLastFrame or 0)))
    else
        Client_USleep(1) -- just 1 millisecond, but gives other processes a chance to do something
    end
    gLastFrameTime = Client_GetTicks()
end
