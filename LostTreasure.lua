local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")
local LMP = LibStub:GetLibrary("LibMapPins-1.0")
local LOST_TREASURE = ZO_Object:Subclass()

local AddonName = "LostTreasure" 
local Author = "CrazyDutchGuy"


LT =
{	
	defaults = 
	{
		showtreasureswithoutmap = false,
        pinFilter = true, -- For LMP to toggle on WorldMap
	}
}

local pinLayout_Treasure = 
{ 
		level = 40,		
		texture = "LostTreasure/Icons/map.dds",
		size = 32,	
}

--Handles info on TreasureMap
local function GetInfoFromTag(pin)
	local _, pinTag = pin:GetPinTypeAndTag()
	
	return pinTag[LOST_TREASURE_INDEX.MAP_NAME] 
end

--Creates ToolTip from treasure info
local pinTooltipCreator = {
	creator = function(pin)		
        local _, pinTag = pin:GetPinTypeAndTag()		
		InformationTooltip:AddLine(pinTag[LOST_TREASURE_INDEX.MAP_NAME], "", ZO_HIGHLIGHT_TEXT:UnpackRGB())--name color
        InformationTooltip:AddLine(string.format("%.2f",pinTag[LOST_TREASURE_INDEX.X]*100).."x"..string.format("%.2f",pinTag[LOST_TREASURE_INDEX.Y]*100), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())--name color
	end,
	tooltip = InformationTooltip,
}
	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function hasMap(mapName, mapTexture)  	
    for i=1,GetNumViewableTreasureMaps() do
        local name, textureName  = GetTreasureMapInfo(i)  -- This will most likely return a localized name, use the texturename instead ? ...            
        local mapTextureName = string.match(textureName, "%w+/%w+/%w+/(.+)%.dds")
        if mapTexture then
        	if mapTextureName == mapTexture then
        		return true
        	end
        else        	
        	if name == mapName then 
           		return true
        	end
        end
    end
    return false
end

local function pinCreator_Treasure(pinManager)
         
    local data = LOST_TREASURE_DATA[GetCurrentMapZoneIndex()]
    if GetMapType() == 1 then  --subzone in the current map, derive info from texture instead of mapname to avoid issues with french and german clients
    	local subzone = string.match(GetMapTileTexture(), "%w+/%w+/%w+/(%w+)_%w+_%d.dds")
    	data = LOST_TREASURE_DATA[subzone]
    end
    
    if not data then
        return
    end
           
    for _, pinData in pairs(data) do
	    if LT.SavedVariables.showtreasureswithoutmap == true then
            LMP:CreatePin( AddonName.."MapPin", pinData, pinData[LOST_TREASURE_INDEX.X], pinData[LOST_TREASURE_INDEX.Y],nil)
		else
		    if hasMap(pinData[LOST_TREASURE_INDEX.MAP_NAME],pinData[LOST_TREASURE_INDEX.TEXTURE]) then 		    	
		        LMP:CreatePin( AddonName.."MapPin", pinData, pinData[LOST_TREASURE_INDEX.X], pinData[LOST_TREASURE_INDEX.Y],nil)
            end
		end	
    end
end
	
local function ShowTreasure()	
    LMP:RefreshPins(AddonName.."MapPin" )
end

local function GetWithoutMap()
	return LT.SavedVariables.showtreasureswithoutmap
end

local function SetWithoutMap()
    LT.SavedVariables.showtreasureswithoutmap = not LT.SavedVariables.showtreasureswithoutmap
    ShowTreasure()
end

function LOST_TREASURE:EVENT_SHOW_TREASURE_MAP(event, treasureMapIndex)
	ShowTreasure()
	--
	--  Temporary till all textures are known ...
	--	
	local name, textureName  = GetTreasureMapInfo(treasureMapIndex)  -- This will most likely return a localized name, use the texturename instead ? ...            
    local mapTextureName = string.match(textureName, "%w+/%w+/%w+/(.+)%.dds")
    for _, v in pairs(LOST_TREASURE_DATA) do
    	for _, v in pairs(v) do    	
    		if mapTextureName == v[LOST_TREASURE_INDEX.TEXTURE] then
    			return
    		end
    	end
    end
    d("Sending update to addon author for map " .. name )
    RequestOpenMailbox()        
    SendMail("@CrazyDutchGuy", "Lost Treasure 1.8 :  ".. name,  name .. "::" .. textureName .."::" .. mapTextureName)  
end


function LOST_TREASURE:EVENT_ADD_ON_LOADED(event, name)
   	if name == AddonName then 

   		EVENT_MANAGER:RegisterForEvent(AddonName, EVENT_SHOW_TREASURE_MAP, function(...) LOST_TREASURE:EVENT_SHOW_TREASURE_MAP(...) end)	

   		LT.SavedVariables = ZO_SavedVars:New("LOST_TREASURE_SV", 5, nil, LT.defaults)		
   		
   		LMP:AddPinType(AddonName.."MapPin", pinCreator_Treasure, nil, pinLayout_Treasure, pinTooltipCreator)
        LMP:AddPinFilter(AddonName.."MapPin", "Lost Treasure Maps", false, LT.SavedVariables, "pinFilter")

		if GetWithoutMap() then
			ShowTreasure()
		end
	
		local addonMenu = LAM:CreateControlPanel(AddonName.."OptionsPanel", "Lost Treasure")
		LAM:AddHeader(addonMenu, AddonName.."OptionsHeader", "Settings")
		LAM:AddCheckbox(addonMenu, AddonName.."showallmaps", "Show All Treasure Maps ", "Show/hide All Treasure Map Locations.", GetWithoutMap, SetWithoutMap)
		LAM:AddHeader(addonMenu, AddonName.."DescriptionHeader", "Description")
		LAM:AddDescription(addonMenu, AddonName.."_Description", "Icons will show on map only if the treasure map is used from your inventory.")
		LAM:AddHeader(addonMenu, AddonName.."InfoHeader", "Info")
		LAM:AddDescription(addonMenu, AddonName.."Author", "Author: " .. Author )

		EVENT_MANAGER:UnregisterForEvent(AddonName, EVENT_ADD_ON_LOADED)

	end
end

function TreasureMap_OnInitialized()	
	EVENT_MANAGER:RegisterForEvent(AddonName, EVENT_ADD_ON_LOADED, function(...) LOST_TREASURE:EVENT_ADD_ON_LOADED(...) end)
end