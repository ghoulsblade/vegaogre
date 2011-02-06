
cWidgetRotateSprite	= RegisterWidgetClass("WidgetRotateSprite","Group")

-- params: w,h,rotate_ang,bDynamic,matname
function cWidgetRotateSprite:Init (parentwidget, params)
	local gfx = CreateRobRenderable2D(self.rendergroup2d)
	self.gfx = gfx 
	self:AddToDestroyList(self.gfx)
	self:SetMatname(self.params.matname)
	self:UpdateGeometry()
end
	
function cWidgetRotateSprite:SetMatname (matname)
	assert(matname)
	self.params.matname = matname
	self.gfx:SetMaterial(matname)
end

function cWidgetRotateSprite:SetRotateAng (ang) 
	self.params.rotate_ang = ang
	self:UpdateGeometry()
end

function cWidgetRotateSprite:UpdateParams (w,h,ang) 
	self.params.w = w
	self.params.h = h
	self.params.rotate_ang = ang
	self:UpdateGeometry()
end

function cWidgetRotateSprite:UpdateGeometry ()
	-- generate geometry
	local vc = 4
	local ic = 3*2
	local bDynamic,bKeepOldIndices = (self.params.bDynamic or false),false
	RobRenderable2D_Open(self.gfx,vc,ic,bDynamic,bKeepOldIndices,OT_TRIANGLE_LIST)
	local ang = self.params.rotate_ang or 0
	local w = 0.5 * (self.params.w or 0)
	local h = 0.5 * (self.params.h or 0)
	local z = 0
	local x,y = rotate2(-w,-h,ang) RobRenderable2D_Vertex(x,y,z, 0,0)
	local x,y = rotate2( w,-h,ang) RobRenderable2D_Vertex(x,y,z, 1,0)
	local x,y = rotate2(-w, h,ang) RobRenderable2D_Vertex(x,y,z, 0,1)
	local x,y = rotate2( w, h,ang) RobRenderable2D_Vertex(x,y,z, 1,1)
	RobRenderable2D_Index3(0,1,2)
	RobRenderable2D_Index3(3,2,1)
	RobRenderable2D_Close()
end
