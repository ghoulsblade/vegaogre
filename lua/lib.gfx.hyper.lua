-- hyperspeed graphical effect
-- tex : data/hyperspeed.dds  nat : hyperspeedmat


cHyperGfx = CreateClass()

RegisterListener("Hook_VegaInit",function () gHyperGfx = cHyperGfx:New() end)



function cHyperGfx:Init ()
	self.lastmovet = 0
	self.dx = 0
	self.dy = 0
	self.dz = 1
	RegisterStepper(function () self:Step() end)
	RegisterListener("Hook_PlayerHyperMoveStep",function (...) self:PlayerHyperMoveStep(...) end) 
	
	InvokeLater(1000,function () Player_SelectNextNavTarget() ToggleAutoPilot() end) -- easy testing
end

function cHyperGfx:PlayerHyperMoveStep (dx,dy,dz)
	self.lastmovet = gMyTicks
	self.dx = dx
	self.dy = dy
	self.dz = dz
end


function cHyperGfx:Step ()
	local fadet = 1000
	local age = gMyTicks - self.lastmovet
	local f = (age > fadet) and 0 or (1 - age/fadet)
	--~ print("cHyperGfx",f)
	local bActive = true
	
	if (bActive) then 
		local gfx = self.gfx
		if (not gfx) then gfx = GetPlayerMoveLoc().gfx:CreateChild() self.gfx = gfx end
		
		if (not gfx.bHyperInit) then 
			gfx.bHyperInit = true
			if (1 == 1) then 
				gfx:SetMesh(CreateTunnelMesh("hyperspeedmat"))
			else 
				local r = 7
				local res = 51 -- 31
				local steps_h,steps_v,cx,cy,cz = res,res,r,r,r
				gfx:SetMesh(MakeSphereMesh(steps_h,steps_v,cx,cy,cz))
				gfx:GetEntity():setMaterialName("hyperspeedmat")
			end
			-- Ogre::MovableObject::setRenderQueueGroup(uint8 queueID)  see RenderQueue for details , see RenderQueueGroupID enum (OgreRenderQueue.h)
			gfx:GetEntity():setRenderQueueGroup(RENDER_QUEUE_6) -- one after default
		end
		
		gfx:SetOrientation(Quaternion.getRotation(0,0,1,self.dx,self.dy,self.dz))
		
	end
	
end

-- ***** ***** ***** ***** ***** tunnelgfx


function CreateTunnelMeshGeometry ()
	local vb0 = cVertexBuffer:New()
	local ib = cIndexBuffer:New()
	
	local function vertex	(x,y,z,u,v)	vb0:Vertex(x,y,z,u,v) end
	local function tri		(a,b,c)		ib:MultiIndex(a,b,c) end
	-- geometry (normals ? nah..)
	local e = 1/256
	local s = -10
	vertex( 0, 0,-4*s,	  0*e,128*e)
	
	vertex( 0, s, 0,	200*e, 91*e)
	vertex( s, 0, 0,	200*e,128*e)
	vertex( 0,-s, 0,	200*e,160*e)
	vertex(-s, 0, 0,	200*e,128*e)
	
	vertex( 0, 0, s,	250*e,128*e)
	tri(0,1,2)
	tri(0,2,3)
	tri(0,3,4)
	tri(0,4,1)
	
	tri(5,2,1)
	tri(5,3,2)
	tri(5,4,3)
	tri(5,1,4)
	
	vb0:CheckSize()
	return vb0,ib,4*s
end

function CreateTunnelMesh (msMatName,szMeshName,...)
	msMatName = msMatName or "basewhitenolighting"
	szMeshName = szMeshName or "myTunnelMesh"
	local pMesh = MeshManager_createManual(szMeshName) -- 	Ogre::MeshPtr
	
	-- create submesh
	local sub = pMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(msMatName)
	sub:setUseSharedVertices(false)
	
	sub:setOperationType(OT_TRIANGLE_LIST)
	
	local vb0,ib,r = CreateTunnelMeshGeometry(...)
	
	local vertexData = CreateVertexData()
	local indexData = CreateIndexData()
	sub:setVertexData(vertexData)
	sub:setIndexData(indexData)
	
	local vdecl = cVertexDecl:New()
	vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
	--~ vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
	vdecl:addElement(0,VET_FLOAT2,VES_TEXTURE_COORDINATES)
	--~  TODO : if (bUseColors)		offset += decl.addElement(0, offset, VET_COLOUR, VES_DIFFUSE).getSize()      autoorganize position!!!
	
	vertexData:setVertexDecl(vdecl:GetOgreVertexDecl())
	vertexData:createAndBindVertexBuffer(vb0:GetVertexSize(),vb0:GetVertexNum(),HBU_STATIC_WRITE_ONLY,false,0) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
	indexData:createAndBindIndexBuffer(IT_32BIT,ib:GetIndexNum(),HBU_STATIC_WRITE_ONLY) -- (iIndexType,iNumIndexes,iUsage,bUseShadowBuffer=false)
	
	vertexData:setVertexStart(0)
	indexData:setIndexStart(0)
	vertexData:setVertexCount(vb0:GetVertexNum())
	indexData:setIndexCount(ib:GetIndexNum())
	
	vertexData:writeToVertexBuffer(vb0:GetFIFO(),0)
	indexData:writeToIndexBuffer(ib:GetFIFO()) 
	
	--~ calculate bounds,  todo : calc for whole mesh, not only for this submesh
	pMesh:_setBounds({-r,-r,-r,r,r,r},false)
	pMesh:_setBoundingSphereRadius(r)
	
	vb0:Destroy()
	ib:Destroy()
	
	return szMeshName
end