-- scrollable list of items for trade/cargo etc
-- TODO : ScrollableList

cVegaItemList			= RegisterWidgetClass("VegaItemList"		,"Group")
cVegaItemListHeader		= RegisterWidgetClass("VegaItemListHeader"	,"Group")
cVegaItemListEntry		= RegisterWidgetClass("VegaItemListEntry"	,"Group")

-- ***** ***** ***** ***** ***** cVegaItemList

function cVegaItemList:Init (parentwidget, params)
	self.scrollpane		= self:CreateContentChild("ScrollPaneV",{w=params.w,h=params.h})
	self.vbox			= self.scrollpane:CreateContentChild("VBox",{spacer=0})
	self.on_select_item	= params.on_select_item
	self.root_headers	= {}
	self.cat_headers	= {}
	self.item_widgets	= {}
	
	-- fill list
	self:SetList(params.items or {})
end

function cVegaItemList:Clear ()
	for k,header in pairs(self.root_headers) do header:Destroy() end
	self.root_headers = {}
	self.cat_headers = {}
	self.item_widgets = {}
end

function cVegaItemList:SetList (list)
	self:Clear()
	for k,item in pairs(list or {}) do self:AddVegaItem(item) end
end

function cVegaItemList:UpdateItem (path,item)
	local widget = self.item_widgets[path]
	if (item) then 	
		if (widget) then
			widget:UpdateItem(item) -- amount changed
		else
			self:AddVegaItem(item) -- item added
		end
	else
		-- removed
		assert(widget)
		widget:Destroy()
		self.item_widgets[path] = nil
		local header = self:GetOrCreateHeaderForItemPath(path)
		if (header) then header.content:MarkForUpdateContent() end -- TODO : ugly, maybe on_destroy parent:MarkForUpdateContent ?
	end
end

function cVegaItemList:GetOrCreateHeader (path) -- header path ! not full item path, so remove itemname
	local header = self.cat_headers[path]
	if (header) then return header end
	local parentpath	= string.gsub(path,"/[^/]+$","")
	local title			= string.gsub(string.gsub(path,"^.*/",""),"_"," ") -- last part of path, replace _ with space
	local parent		= (parentpath == path) and self.vbox or self:GetOrCreateHeader(parentpath)
	--~ print("GetOrCreateHeader",depth,path)
	local header		= parent:CreateContentChild("VegaItemListHeader",{text=title,path=path})
	if (parent == self.vbox) then self.root_headers[path] = header end
	self.cat_headers[path] = header
	return header
end

function cVegaItemList:GetOrCreateHeaderForItemPath (path) return self:GetOrCreateHeader(string.gsub(path,"/[^/]+$","")) end

function cVegaItemList:AddVegaItem (item)
	local header = self:GetOrCreateHeaderForItemPath(item.path)
	self.item_widgets[item.path] = header:CreateContentChild("VegaItemListEntry",{btntext=self.params.btntext,on_select_item=self.on_select_item,item=item})
end

-- ***** ***** ***** ***** ***** cVegaItemListHeader

function cVegaItemListHeader:Init (parentwidget, params)
	local b = 2
	self.title		= self:CreateChild("Text",{text=params.text,x=b,y=b})
	self.content	= self:CreateChild("VBox",{spacer=0,x=20,y=self.title:GetHeight()+2*b}) -- x=indention, y=content pos below title
end
function cVegaItemListHeader:UpdateContent	() self:GetParent():MarkForUpdateContent() end -- cascade 
function cVegaItemListHeader:GetContent		() return self.content end


-- ***** ***** ***** ***** ***** cVegaItemListEntry

function cVegaItemListEntry:Init (parentwidget, params)
	local b = 2
	local item = self.params.item
	self.btn = self:CreateChild("Button",{label=params.btntext or "select",x=b,y=0,on_button_click=function () self.params.on_select_item(item) end})
	self.title = self:CreateChild("Text",{text="",x=b+self.btn:GetWidth()+b,y=b})
	self:UpdateItem(item)
end

function cVegaItemListEntry:UpdateItem(item)
	self.params.item = item
	local text = string.gsub(string.gsub(item.path,"^.*/",""),"_"," ").."["..item.amount.."]"
	self.title:SetText(text)
end
