-- align childs vertically

cVBox = RegisterWidgetClass("VBox","Group")

function cVBox:Init () end

function cVBox:AddChild (...) return self:CreateChildPrivateNotice(...) end
function cVBox:on_create_content_child () self:MarkForUpdateContent() end
function cVBox:AddWidget (widget) widget:SetParent(self) self:MarkForUpdateContent() return widget end

function cVBox:on_xml_create_finished () self:UpdateContent() end -- update content early for size-calc, but would also be done by MarkForUpdateContent

function cVBox:UpdateContent ()
	local y = 0
	local spacer = self.params.spacer or 0
	for k,child in ipairs(self:_GetOrderedChildList()) do
		child:SetPos(0,y)
		y = y + child:GetHeight() + spacer
	end
	self:GetParent():MarkForUpdateContent() -- cascade
end

function cVBox:UpdateLayout () assert(false,"use UpdateContent instead") end -- obsolete
