-- handles trade stuff

-- TODO : stations, loaded via .py scripts in vega original ????

function Trade_GetTradeGoodsFilePathFromUnitType (t)
	return GetVegaDataDir().."units/"..t.Directory.."/"..string.gsub(t.Directory,".*/","")
end

function Docked_InitTradeGoods (base) -- base= cStation or cPlanet	
	-- empty old tradegoods
	gTradeGoods = {} 
	
	-- get unittype of base/station/planet
	local t = base and GetUnitTypeFromSectorXMLNode(base.xmlnode) assert(t)
	
	-- get path to xml file
	local filepath = Trade_GetTradeGoodsFilePathFromUnitType(t)
	local xml = filepath and file_exists(filepath) and LuaXML_ParseFile(filepath)
	if (not xml) then print("WARNING! failed to load tradegoods for unittype",t.id,filepath) return end -- uninhabitable etc, TODO: station
	
	gTradeGoodXML = EasyXMLWrap(xml[1]) assert(gTradeGoodXML)
	local xml_hold = gTradeGoodXML.Hold[1] assert(xml_hold) -- <Hold volume="100000000000">
	local volume = tonumber(xml_hold.volume or 1000)
	print("xml_hold volume=",volume)
	for k,xml_cat in ipairs(xml_hold) do -- <Category file="Natural_Products/Food">
		local cat_file = xml_cat.file 
		local o = xml_cat.import[1] -- <import price=".75" pricestddev=".15" quantity="25" quantitystddev="25"/>
		print("+",o.price,o.pricestddev,o.quantity,o.quantitystddev,cat_file) 
	end
	--~ os.exit(0)
	
	
	--[[
	--~ for k,fieldname in pairs(gUnitTypeFieldNames) do print(" "..pad(fieldname,30),t[fieldname]) end
	id                             ocean__planets
	Directory                      ./factions/planets/ocean
	Name                           ocean
	Hud_image                      planet-ocean-hud.sprite
	Cargo_Import                   {Consumer_and_Commercial_Goods/Domestic;1;.1;1000;.100000000000023}{Consumer_and_Commercial_Goods/Electronics;1;.1;1000;.1}{Consumer_and_Commercial_Goods/Luxury;1;.1;10;.1}{Consumer_and_Commercial_Goods/Personal;1;.1;1000;.1}{Contraband/Aera;1;.1;10;.1}{Contraband/Confed;1;.1;10;.1}{Contraband/Rlaan;1;.1;10;.1}{Industrially_Manufactured_Goods/Agricultural;1;.1;10;.1}{Industrially_Manufactured_Goods/Construction;1;.1;10;.1}{Industrially_Manufactured_Goods/Recycled_Products;1;.1;10000;.1}{Industrially_Manufactured_Goods/Xenoforming;1;.1;10;.1}{Natural_Products/Food/Aera;1;.1;10000;.1}{Natural_Products/Food/Confed;1;.1;10000;.1}{Natural_Products/Food/Generic;1;.1;10000;.1}{Natural_Products/Food/Rlaan;1;.1;10000;.1}{Natural_Products/Life-forms;1;.1;1000;.1}{Natural_Products/Liquor/Confed;1;.1;100;.1}{Natural_Products/Liquor/Uln;1;.1;100;.1}{Natural_Products/Liquor;.9;.1;200;400}{Natural_Products/Plant_Products;1;.1;10;.1}{Natural_Products/Renewable_Resources;1;.1;10000;.1}{Raw_Materials/Gases;1;.1;100000;.1}{Raw_Materials/Hydrocarbons;1;.1;20000;.2}{Raw_Materials/Metals;6;.7;-100;300}{Raw_Materials/Ores;5;.4;-1000;2000}{Refined_Materials/Alloys/Aera;10;.3;-100;150}{Refined_Materials/Alloys/Confed;3;.1;100;45}{Refined_Materials/Alloys/Rlaan;2;.1;10;15}{Refined_Materials/Precious_Metals;3;.1;10;12}{Refined_Materials/Purified_and_Enhanced_Materials;1;.1;10;.1}{Refined_Materials/Radioactive_Metals;1;.1;100;.1}{Research;11;.4;-10;13}{Specialty_Goods/Augmentation;1;.1;-3;5}{Specialty_Goods/Entertainment;1;.2;100;34}{Specialty_Goods/Medical;1.25;.2;80;120}{Specialty_Goods/Pharmaceutical;1;.2;4;5}{starships/Andolian/Medium;1;;;5}{starships/Hunter/Light;1;;;5}{starships/Merchant/Light;1;;;5}{starships/Merchant/Medium;1;;;5}{starships/Regional_Guard/Light;1;;;5}{upgrades/Ammunition/Confed;1;.1;100;280}{upgrades/Ammunition/Common;1;.1;200;280}{upgrades/Ammunition/Uncommon;2;.1;60;180}{upgrades/Ammunition/Rlaan;6;.7;-10;28}{upgrades/Ammunition/Aera;13;.7;-10;28}{upgrades/Armor;1;.1;10;5}{upgrades/Capacitors/Standard;1;.1;10;5}{upgrades/Cargo;1;.1;2;1}{upgrades/ECM_Systems;1;.1;6;3}{upgrades/Jump_Drives;1;.1;4;2}{upgrades/Overdrive;1;.1;3;2}{upgrades/Passenger_Quarters;1;.1;10;2}{upgrades/Reactors/Standard;1;.1;10;5}{upgrades/Sensors/Advanced;1;.1;6;5}{upgrades/Sensors/Basic;1;.1;10;5}{upgrades/Sensors/Intermediate;1;.1;6;4}{upgrades/Shady_Mechanic;1;.1;-2;5}{upgrades/Shield_Systems/Standard_Dual_Shields;1;.1;20;5}{upgrades/Shield_Systems/Standard_Quad_Shields;1;.1;20;5}{upgrades/SPEC_Capacitors;1;.1;6;2}{upgrades/Weapons/Beam_Arrays_Light;1;.1;;5}{upgrades/Weapons/Beam_Arrays_Medium;1;.1;-3;5}{upgrades/Weapons/Mount_Enhancements;1;.1;-50;51}{upgrades/Weapons/Mounted_Guns_Light;1;.1;;4}{upgrades/Weapons/Mounted_Guns_Medium;1;.1;;3}
	Upgrade_Storage_Volume         100000000
	-- TODO : VegaStrike/data/units/factions/planets  subfolders contain buy/sell infos		cargo,ware,price
	
	<Upgrade file="confed_missions"/>
	<Upgrade file="aera_missions"/>
	<Upgrade file="iso_missions"/>
    <Upgrade file="rlaan_missions"/>
	<Upgrade file="standard_missions"/>
	]]--
	--~ for id,t in pairs(gUnitTypes) do if (t.Directory ~= "") then 
		--~ local filepath = Trade_GetTradeGoodsFilePathFromUnitType(t)
		--~ print("planet:",pad(id,30),file_exists(filepath),pad(t.Name,20),filepath,t.Directory) 
	--~ end end
	--~ os.exit(0)
end
