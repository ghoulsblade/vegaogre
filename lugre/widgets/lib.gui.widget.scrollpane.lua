-- makes contents scrollable
-- see also lib.gui.widget.lua
-- TODO : AutoScroll when adding childs ? EnsureVisible(x,y) (in child coords) ? left-top ?
-- TODO : auto show/hide scrollbars
-- TODO : drag mode when clicking background ? SetIgnoreBBoxHit(false) ?
-- TODO : scrollbar class

RegisterWidgetClass("ScrollPane")

-- params:panew/h,iScrollBarThickness
-- scrollx/y : initial scroll, defaults to 0
-- bAutoShowScrollBarH/V : automatically show/hide scrollbars as needed, defaults to true
function gWidgetPrototype.ScrollPane:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	self.content = self:_CreateChild("Group")
	params.scrollx = params.scrollx or 0
	params.scrolly = params.scrolly or 0
	if (params.bAutoShowScrollBarH == nil) then params.bAutoShowScrollBarH = true end
	if (params.bAutoShowScrollBarV == nil) then params.bAutoShowScrollBarV = true end
	self.params = params
	self:UpdateContent()
end

gWidgetPrototype.ScrollPane.CreateChild = gWidgetPrototype.Base.CreateChildPrivateNotice
function gWidgetPrototype.ScrollPane:GetContent					() return self.content end

-- access to current scroll
function gWidgetPrototype.ScrollPane:GetScrollX			() return self.params.scrollx end
function gWidgetPrototype.ScrollPane:GetScrollY			() return self.params.scrolly end
function gWidgetPrototype.ScrollPane:SetScrollX			(newval,bFromScrollCallback) self:SetScroll(newval,self:GetScrollY(),bFromScrollCallback) end
function gWidgetPrototype.ScrollPane:SetScrollY			(newval,bFromScrollCallback) self:SetScroll(self:GetScrollX(),newval,bFromScrollCallback) end
function gWidgetPrototype.ScrollPane:SetScroll			(scrollx,scrolly,bFromScrollCallback) 
	self.params.scrollx = math.max(0,math.min(self.maxscrollx,scrollx))
	self.params.scrolly = math.max(0,math.min(self.maxscrolly,scrolly))
	self.content:SetLeftTop(	-self.params.scrollx,
								-self.params.scrolly)
	if (bFromScrollCallback) then return end
	if (self.scrollbar_h) then self.scrollbar_h:SetValue(self.params.scrollx) end
	if (self.scrollbar_v) then self.scrollbar_v:SetValue(self.params.scrolly) end
end

function gWidgetPrototype.ScrollPane:CreateScrollbar	(params) 
	local widget = self:_CreateChild("ScrollBar",params)
	widget.scrollpane = self
	if (params.bVertical) then
			widget.on_scroll = function (self,newval) self.scrollpane:SetScrollY(newval,true) end
	else	widget.on_scroll = function (self,newval) self.scrollpane:SetScrollX(newval,true) end  end
	return widget
end

function gWidgetPrototype.ScrollPane:CreateScrollBarsIfNeeded	(bScrollBarH,bScrollBarV) 
	local t = self.params.iScrollBarThickness
	local w = self.params.panew
	local h = self.params.paneh
	if (bScrollBarH and (not self.scrollbar_h)) then self.scrollbar_h = self:CreateScrollbar({ bVertical=false, x=0,   y=h-t, w=w-t, h=t   }) end
	if (bScrollBarV and (not self.scrollbar_v)) then self.scrollbar_v = self:CreateScrollbar({ bVertical=true,  x=w-t, y=0,   w=t,   h=h-t }) end
end

-- creates scrollbar if needed
function gWidgetPrototype.ScrollPane:SetScrollBarHVisible		(bVisible) 
	self:CreateScrollBarsIfNeeded(bVisible,false)
	if (self.scrollbar_h) then self.scrollbar_h:SetVisible(bVisible) end
end

-- creates scrollbar if needed
function gWidgetPrototype.ScrollPane:SetScrollBarVVisible		(bVisible) 
	self:CreateScrollBarsIfNeeded(false,bVisible)
	if (self.scrollbar_v) then self.scrollbar_v:SetVisible(bVisible) end
end

-- call this when content size, own size or params change
function gWidgetPrototype.ScrollPane:UpdateContent				()
	-- calc content size and scroll params
	local w,h = self.content:GetSize() -- not clipped
	w,h = floor(w),floor(h)
	local t = self.params.iScrollBarThickness
	local areaw = self.params.panew
	local areah = self.params.paneh
	local bScrollH = false
	local bScrollV = false
	if (w > areaw) then bScrollH = true end
	if (h > areah) then bScrollV = true end
	
	
	self.maxscrollx = math.floor(math.max(0,w - self.params.panew))
	self.maxscrolly = math.floor(math.max(0,h - self.params.paneh))
	print("ScrollPane:UpdateContent cont",w,h,self.maxscrollx,self.maxscrolly)
	
	-- update scrollbars
	if (self.params.bAutoShowScrollBarH) then self:SetScrollBarHVisible(self.maxscrollx > 0) end
	if (self.params.bAutoShowScrollBarV) then self:SetScrollBarVVisible(self.maxscrolly > 0) end
	if (self.scrollbar_h) then self.scrollbar_h:SetMinMaxPageStep(0,self.maxscrollx,self.params.panew,self.params.panew*0.1) end
	if (self.scrollbar_v) then self.scrollbar_v:SetMinMaxPageStep(0,self.maxscrolly,self.params.paneh,self.params.paneh*0.1) end
	
	-- clamp/apply scroll
	self:SetClip(0,0,self.params.panew,self.params.paneh)
	self:SetScroll(self.params.scrollx,self.params.scrolly)
end

