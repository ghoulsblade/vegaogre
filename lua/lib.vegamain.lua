dofile(libpath .. "lib.vegautil.lua")
dofile(libpath .. "lib.hotkey.lua") -- early so key settings can use it 
dofile(libpath .. "lib.spacetest.lua")
dofile(libpath .. "lib.guitest.dragdrop.lua")
dofile(libpath .. "lib.boltmesh.lua")
dofile(libpath .. "lib.objects.lua")
dofile(libpath .. "lib.hud.marker.lua")
dofile(libpath .. "lib.hud.display.target.lua")
dofile(libpath .. "lib.hud.display.self.lua")
dofile(libpath .. "lib.hud.display.nav.lua")
dofile(libpath .. "lib.collision.lua")
dofile(libpath .. "lib.player.lua")
dofile(libpath .. "lib.autopilot.lua")
dofile(libpath .. "lib.data.unittype.lua")
dofile(libpath .. "lib.data.universe.lua")
dofile(libpath .. "lib.data.generate.lua")
dofile(libpath .. "lib.docked.lua")
dofile(libpath .. "lib.gfx.hyper.lua")
dofile(libpath .. "lib.gfx.jumppoint.lua")

sin		= math.sin
cos		= math.cos
floor	= math.floor
ceil	= math.ceil
min		= math.min
max		= math.max
gMaxFPS = 40
gHideFPS = true 


function VegaMainAddResLocs (mydatapath) 
	OgreAddResLoc(mydatapath.."."                           ,"FileSystem","General")
	OgreAddResLoc(mydatapath.."base"                        ,"FileSystem","General")
	OgreAddResLoc(mydatapath.."icons_equip"					,"FileSystem","General")
	
	for k,subpath in ipairs({"units/vessels/llama"}) do 
	--~ OgreAddResLoc(mydatapath..subpath	                     ,"FileSystem",subpath)
	end
	OgreAddResLoc(mydatapath.."units/vessels/llama"							,"FileSystem","General")
	OgreAddResLoc(mydatapath.."units/vessels/Ruizong"						,"FileSystem","General")
	OgreAddResLoc(mydatapath.."units/installations/Agricultural_Station"	,"FileSystem","General")    
	OgreAddResLoc(mydatapath.."textures/backgrounds"						,"FileSystem","General")

	local function MyAddSubDirs (base) for k,v in ipairs(dirlist(base,true,false)) do if (v ~= "." and v ~= "..") then OgreAddResLoc(base..v,"FileSystem","General") end end end
	MyAddSubDirs(mydatapath.."sprites/bases/")
	OgreAddResLoc(mydatapath.."sprites"										,"FileSystem","General")
	
	OgreAddResLoc(mydatapath.."textures"								,"FileSystem","General")
	OgreAddResLoc(mydatapath.."textures/weapons"							,"FileSystem","General")
	OgreAddResLoc(mydatapath.."textures/planets"							,"FileSystem","General")
	OgreAddResLoc(mydatapath.."textures/sol"								,"FileSystem","General")
	OgreAddResLoc(mydatapath.."textures/stars"								,"FileSystem","General")
	OgreAddResLoc(mydatapath.."gui"											,"FileSystem","General")
	OgreAddResLoc(mydatapath.."crosshair"									,"FileSystem","General")
end

function VegaMainInit()
    --~ StartMainMenu()
	BindDown("escape", function () os.exit(0) end)
	LoadUniverse()
	
	InitGuiThemes()
	MySpaceInit()
	GuiTest_InitCrossHair()
	NotifyListener("Hook_VegaInit")
end


function VegaMainStep ()
	local dt = gSecondsSinceLastFrame
	
	GuiTest_CursorCrossHair_Step() -- only moves gui widget to mousepos
	
	for o,v in pairs(gObjects) do o:Step(dt) end -- think, might modify params for physstep ( might also add new items )
	
	StepAutoPilot()
	PlayerHyperFlyStep()
	
	for o,v in pairs(gObjects) do o:PhysStep(dt) end -- move items and gfx:SetPos()
	
	--~ handleCollisionBetweenOneAndWorld(gPlayerShip, gObjects)   (do collision, might change pos and speed, so do before physstep) 
	-- deactivated until large-universe rounding errors system finished  (should be between pos+=vel and render, so intersections can be solved before being rendered)
	
	-- insert new items into main list  (can be done after physstep, since InitObj already calls gfx:SetPos())
	if (next(gNewObjects)) then local arr = gNewObjects gNewObjects = {} for o,v in pairs(arr) do gObjects[o] = true end end
	
	
	PlayerStep() -- moves cam and handles player keyboard, changes player velocity, but not position.  call before HUD stuff so cam is up to date for render
	
	NotifyListener("Hook_PlayerEffectStep") -- hyperspeed effect etc
	NotifyListener("Hook_HUDStep") -- updates special hud elements dependant on object positions that don't have auto-tracking
	
	for o,v in pairs(gObjects) do o:HUDStep(dt) end -- update hud markers, should be done AFTER moving objects and updating cam
	
	NotifyListener("Hook_PreRenderOneFrame")
	
	
    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
end

function GetHUDBaseWidget () return GetGUILayer_HUDFX() end 
