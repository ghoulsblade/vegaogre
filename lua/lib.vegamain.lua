dofile(libpath .. "lib.spacetest.lua")
dofile(libpath .. "lib.guitest.dragdrop.lua")
dofile(libpath .. "lib.boltmesh.lua")
dofile(libpath .. "lib.objects.lua")
dofile(libpath .. "lib.hud.marker.lua")
dofile(libpath .. "lib.hud.display.target.lua")
dofile(libpath .. "lib.hud.display.self.lua")
dofile(libpath .. "lib.collision.lua")
dofile(libpath .. "lib.player.lua")
dofile(libpath .. "lib.autopilot.lua")


sin = math.sin
cos = math.cos
gMaxFPS = 40
gHideFPS = true 

-- earth: real:8light hours, vega:1:10: 48 light-minutes = 864.000.000.000 meters.  also: 
light_second = 300*1000*1000 -- 300 mio m/s
light_minute = 60*light_second -- 18.000.000.000 in meters
local vega_factor = 1/10 -- ... useme ? 
au = 150*1000*1000* 1000 * vega_factor    -- (roughly 1 earth-sun distance)
km = 1000

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
	
	OgreAddResLoc(mydatapath.."textures/weapons"							,"FileSystem","General")
	OgreAddResLoc(mydatapath.."textures/planets"							,"FileSystem","General")
	OgreAddResLoc(mydatapath.."gui"											,"FileSystem","General")
	OgreAddResLoc(mydatapath.."crosshair"									,"FileSystem","General")
end

function VegaMainInit()
    --~ StartMainMenu()
	BindDown("escape", function () os.exit(0) end)
	
	InitGuiThemes()
	MySpaceInit()
	GuiTest_InitCrossHair()
end


function VegaMainStep ()
	local dt = gSecondsSinceLastFrame
	
	GuiTest_CursorCrossHair_Step() -- only moves gui widget to mousepos
	
	for o,v in pairs(gObjects) do o:Step(dt) end -- think, might modify params for physstep ( might also add new items )
	
	for o,v in pairs(gObjects) do o:PhysStep(dt) end -- move items and gfx:SetPos()
	
	--~ handleCollisionBetweenOneAndWorld(gPlayerShip, gObjects)   (do collision, might change pos and speed, so do before physstep) 
	-- deactivated until large-universe rounding errors system finished  (should be between pos+=vel and render, so intersections can be solved before being rendered)
	
	-- insert new items into main list  (can be done after physstep, since InitObj already calls gfx:SetPos())
	if (next(gNewObjects)) then local arr = gNewObjects gNewObjects = {} for o,v in pairs(arr) do gObjects[o] = true end end
	
	
	PlayerStep() -- moves cam and handles player keyboard, changes player velocity, but not position.  call before HUD stuff so cam is up to date for render
	
	NotifyListener("Hook_HUDStep") -- updates special hud elements dependant on object positions that don't have auto-tracking
	
	for o,v in pairs(gObjects) do o:HUDStep(dt) end -- update hud markers, should be done AFTER moving objects and updating cam
	
	NotifyListener("Hook_PreRenderOneFrame")
	
	
    if (gbNeedCorrectAspectRatio) then
		gbNeedCorrectAspectRatio = false
		local vp = GetMainViewport()
		GetMainCam():SetAspectRatio(vp:GetActualWidth() / vp:GetActualHeight())
	end
end

