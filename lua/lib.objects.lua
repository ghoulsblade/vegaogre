-- objecttypes 

local kRenderQueueGroup_PlayerShip = RENDER_QUEUE_6 -- two after default

-- ***** ***** ***** ***** ***** global object list 

gObjects = {}
gNewObjects = {} -- delayed insert into the main list

function DestroyAllObjectsExceptPlayer ()
	for o,v in pairs(gObjects) do if (o ~= gPlayerShip) then o:Destroy() gObjects[o] = nil end end
	for o,v in pairs(gNewObjects) do if (o ~= gPlayerShip) then o:Destroy() gNewObjects[o] = nil end end
end

-- ***** ***** ***** ***** ***** cObject

cObject = CreateClass()
function cObject:GetClass() return "Object" end

function cObject:Init (loc,x,y,z,r)
	self:InitObj(loc,x,y,z,r)
end

function cObject:Destroy ()
	if (self.gfx) then self.gfx:Destroy() self.gfx = nil end
	destroyHudMarker(self)
	gObjects[self] = nil
	gNewObjects[self] = nil
end

function cObject:InitObj (loc,x,y,z,r)
	local gfx = loc and loc:CreateChild() or CreateRootGfx3D()
	gfx:SetPosition(x,y,z)
	self.loc = loc
	self.gfx = gfx
	self.x = x
	self.y = y
	self.z = z
	self.vx = 0
	self.vy = 0
	self.vz = 0
	self.r = r or 10
	gNewObjects[self] = true
end

function cObject:PhysStep(dt)
	local x = self.x + self.vx * dt
	local y = self.y + self.vy * dt
	local z = self.z + self.vz * dt
	self.x = x
	self.y = y
	self.z = z
	local gfx = self.gfx
	if (gfx) then gfx:SetPosition(x,y,z) end
end

function cObject:GetHUDImageName() end -- TODO : generic?

function cObject:Step() end
function cObject:HUDStep() end
function cObject:GetPos() return self.x,self.y,self.z end
function cObject:SetPos(x,y,z) self.x,self.y,self.z = x,y,z end --  self.gfx:SetPosition(x,y,z)
function cObject:SetRandomRot() self:SetRot(Quaternion.random()) end
function cObject:SetRot(w,x,y,z) self.gfx:SetOrientation(w,x,y,z) end
function cObject:GetRot() return self.gfx:GetOrientation() end

function cObject:SetScaledMesh(meshname,r)
	local gfx = self.gfx
	gfx:SetMesh(meshname)
	local s = r / gfx:GetEntity():getBoundingRadius()
	gfx:SetScale(s,s,s)
end

function cObject:CanDock (o) return false end
function cObject:DockIsJump () return false end

function cObject:MoveToNewLoc (loc)
	self.gfx:SetParent(loc.gfx)
	self.loc = loc
end 
function cObject:GetPosFromSun () 
	local p = self.loc
	return self.x+p.x,self.y+p.y,self.z+p.z
end
function cObject:GetDistToPlayer () return gPlayerShip and self:GetDistToObject(gPlayerShip) or 0 end
function cObject:GetDistToObject (o) return Vector.len(self:GetVectorToObject(o)) end

function cObject:GetNumberOfParents () local loc = self.loc  return loc and (1 + loc:GetNumberOfParents()) or 0 end

function cObject:GetVectorToObject (b)
	local a = self
	--~ print("cObject:GetVectorToObject",a:GetNameForMessageText(),b:GetNameForMessageText())
	local ax,ay,az = a.x,a.y,a.z
	local bx,by,bz = b.x,b.y,b.z
	if (a.loc ~= b.loc) then
		-- walk down until a common parent is found
		local anum = a:GetNumberOfParents()
		local bnum = b:GetNumberOfParents()
		--~ print(" parentdiffer",anum,bnum)
		while anum > bnum do  a = a.loc  anum = anum-1  ax,ay,az = ax+a.x,ay+a.y,az+a.z  end
		while bnum > anum do  b = b.loc  bnum = bnum-1  bx,by,bz = bx+b.x,by+b.y,bz+b.z  end
		--~ print(" parentdiffer done",anum,bnum)
		while (a.loc ~= b.loc) do
			--~ print("  >ab< :",a:GetNameForMessageText(),b:GetNameForMessageText())
			a = a.loc  ax,ay,az = ax+a.x,ay+a.y,az+a.z
			b = b.loc  bx,by,bz = bx+b.x,by+b.y,bz+b.z
		end
		--~ print("  =ab= :",a:GetNameForMessageText(),b:GetNameForMessageText())
	end
	return	bx - ax,
			by - ay,
			bz - az
end
	
function cObject:GetNameForMessageText ()  return (self.name or "").."("..self:GetClass()..")" end

function cObject:GetPosForMarker () return self.gfx:GetDerivedPosition() end

function cObject:SelectObject ()
	if (self == gSelectedObject) then return end
	local oldmarker = gSelectedObject and gSelectedObject.guiMarker
	gSelectedObject = self
	stepHudMarker(self) -- make sure self.guiMarker has been constructed, used for automatic tests
	if (self.guiMarker) then self.guiMarker:UpdateGfx() end
	if (oldmarker) then oldmarker:UpdateGfx() end
	NotifyListener("Hook_SelectObject",self)
end

function cObject:GetFileAttrTxt () return self.xmlnode and self.xmlnode.file end -- "planets/oceanBase.texture|planets/ocean.texture"
function cObject:GetFileAttrList () -- {"planets/oceanBase.texture","planets/ocean.texture"}
	local txt = self:GetFileAttrTxt() if (not txt) then return end
	local res = {} for a in string.gmatch(txt,"[^|]+") do table.insert(res,a) end return res
end
function cObject:GetFileAttrLast () local list = self:GetFileAttrList() return list and list[#list] end -- "planets/ocean.texture"
function cObject:GetFileAttrLastBase () local txt = self:GetFileAttrLast() return txt and string.gsub(string.gsub(txt,"%..*$",""),".*/","") end -- "planets/ocean.texture" -> "ocean"


-- ***** ***** ***** ***** ***** cShot

cShot = CreateClass(cObject)
function cShot:GetClass() return "Shot" end

function cShot:Init (o)
	--~ print("cShot:Init",o)
	local loc = o.loc
	local x,y,z = o:GetPos()
	local r = 1
	local w0,x0,y0,z0 = o:GetRot()
	local s = 100
	local vx,vy,vz = Quaternion.ApplyToVector(0,0,s,w0,x0,y0,z0)
	vx,vy,vz = vx+o.vx,vy+o.vy,vz+o.vz
	local dt = gSecondsSinceLastFrame
	self:InitObj(loc,x+dt*vx,y+dt*vy,z+dt*vz,r)
	self:SetScaledMesh(gBoltMeshName,r)
	self:SetRot(w0,x0,y0,z0)
	self.vx,self.vy,self.vz = vx,vy,vz
end


-- ***** ***** ***** ***** ***** cShip

cShip = CreateClass(cObject)
function cShip:GetClass() return "Ship" end

function cShip:Init (loc,x,y,z,r,meshname)
	self:InitObj(loc,x,y,z,r)
	self:SetScaledMesh(meshname or "llama.mesh",r)
end
function cShip:GetHUDImageName () return "Llama_llama-hud.png.dds" end


-- ***** ***** ***** ***** ***** cNPCShip

cNPCShip = CreateClass(cShip)
function cNPCShip:GetClass() return "NPCShip" end

function cNPCShip:Init (loc,x,y,z,r,meshname)
	cShip.Init(self,loc,x,y,z,r,meshname or "ruizong.mesh")
end

function cNPCShip:HUDStep ()
	stepHudMarker(self)
end

function cNPCShip:GetHUDImageName () return "Ruizong_ruizong-hud.image.dds" end

-- ***** ***** ***** ***** ***** cPlayerShip

cPlayerShip = CreateClass(cShip)
function cPlayerShip:GetClass() return "PlayerShip" end

function cPlayerShip:Init (x,y,z,r,meshname)
	cShip.Init(self,x,y,z,r,meshname)
	--~ self.gfx:GetEntity():setMaterialName("shader/glow")
	--~ self.gfx:GetEntity():setMaterialName("shader/gradient")
	local entity = self.gfx:GetEntity()
	local subentity = entity:getSubEntity(0)
	subentity:setCustomParameter(0, {1, 0, 0, 1})
	entity:setRenderQueueGroup(kRenderQueueGroup_PlayerShip)
	
	--~ local s = 100000
	--~ self.gfx:SetScale(s,s,s)
end
function cPlayerShip:Step ()
	
end

-- ***** ***** ***** ***** ***** cStation

cStation = CreateClass(cObject)
function cStation:GetClass() return "Station" end

function cStation:Init (loc,x,y,z,r,meshname,xmlnode)
	self:InitObj(loc,x,y,z,r)
	self:SetScaledMesh(meshname or "agricultural_station.mesh",r)
	self.xmlnode = xmlnode
	self.hudimage = GetHUDImageFromNode_Unit(self.xmlnode)
	--~ self.name = "station"
end

function cStation:CanDock (o) return true end

function cStation:HUDStep () 
	stepHudMarker(self)
end

function cStation:GetHUDImageName () return self.hudimage end

-- ***** ***** ***** ***** ***** cLocation

cLocation = CreateClass(cObject)
function cLocation:GetClass() return "Location" end

function cLocation:Init (loc,x,y,z,r,locname)
	self.locname = locname
	self:InitObj(loc,x,y,z,r)
end

function cLocation:CreateChild () return self.gfx:CreateChild() end

function cLocation:PhysStep(dt) end -- DONT MOVE GFX! (hard to find error if it resets offset)

function cLocation:SetPos(x,y,z) self.x,self.y,self.z = x,y,z self.gfx:SetPosition(x,y,z) end


-- ***** ***** ***** ***** ***** cPlanet

cPlanet = CreateClass(cObject)
function cPlanet:GetClass() return "Planet" end

function cPlanet:Init (loc,x,y,z,r,matname,xmlnode)
	self:InitObj(loc,x,y,z,r)
	local res = 51 -- 31
	local steps_h,steps_v,cx,cy,cz = res,res,r,r,r
	self.xmlnode = xmlnode
	self.hudimage = xmlnode and GetHUDImageFromNode_Planet(xmlnode) or "planet-carribean-hud.dds"
	self.gfx:SetMesh(MakeSphereMesh(steps_h,steps_v,cx,cy,cz))
	self.gfx:GetEntity():setMaterialName(matname or "planetbase_ground")
end

function cPlanet:CanDock (o) return true end

function cPlanet:HUDStep () stepHudMarker(self) end
function cPlanet:GetHUDImageName () return self.hudimage end

-- ***** ***** ***** ***** ***** cAsteroidField

cAsteroidField = CreateClass(cPlanet)
function cAsteroidField:GetClass() return "AsteroidField" end
function cAsteroidField:Init (...) cPlanet.Init(self,...) end
function cAsteroidField:GetHUDImageName () return "asteroid-hud.dds" end -- normal would be to load data/units/factions/neutral/AField/af-hud.spr cfg -> asteroid-hud.png

-- ***** ***** ***** ***** ***** cJumpPoint

cJumpPoint = CreateClass(cPlanet)
function cJumpPoint:GetClass() return "JumpPoint" end
function cJumpPoint:Init (loc,x,y,z,r,destination,xmlnode)
	self:InitObj(loc,x,y,z,r)
	self.dest = destination
	self.xmlnode = xmlnode
	self.hudimage = xmlnode and GetHUDImageFromNode_Planet(xmlnode) or "planet-carribean-hud.dds"
	JumpPointGfx_Init(self.gfx,r)
end
function cJumpPoint:GetHUDImageName () return "jump-hud.dds" end 
function cJumpPoint:Step() JumpPointGfx_Step(self.gfx) end
function cJumpPoint:CanDock (o) return true end
function cJumpPoint:DockIsJump () return true end
--~ function cJumpPoint:GetJumpTarget ()  end

-- ***** ***** ***** ***** ***** cSun

cSun = CreateClass(cPlanet)
function cSun:GetClass() return "Sun" end
function cSun:Init (...) cPlanet.Init(self,...) end
function cSun:GetHUDImageName () return "sun-hud.dds" end 
function cSun:CanDock (o) return false end

-- ***** ***** ***** ***** ***** 
