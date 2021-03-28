--[[ =========== Start:: Large_Drone_Station:: Main Script ========== --]]

local mod_name = "Large_Drone_Station"
local steamID = "1771215962"
-- local author = "RustyDios, ChoGGi, SkiRich"
-- local version ="16"

local RustyPrint = false

local ModDir = CurrentModPath

local ipTWZIcon_On 		= ModDir.. "UI/RD_WZ_On.png"
local ipTWZIcon_Locked 	= ModDir.. "UI/RD_WZ_All.png"
local ipTWZIcon_Off		= ModDir.. "UI/RD_WZ_Off.png"

--[[ =========== Start:: Large_Drone_Station:: Construct InfoPanel and Building Template ========== --]]

function OnMsg.ClassesPostprocess()
	if not BuildingTemplates.Drone_Hub_Remote then
		
		-- COLLAPSED ENTRY + TO EXPAND
		XTemplates.ipRD_DHR = PlaceObj("XTemplate",{
			comment = "Custom Built infopanel for Large Drone Stations",
			id = "ipRD_DHR",
			group = "Infopanel",
			__copy_group = "Infopanel",
			__is_kind_of = "ipBuilding",
			__content = function ()
			end,

			PlaceObj("XTemplateTemplate",{
				"comment", "ipRD_DHR",
				"__template","Infopanel",
				"Id","ipRD_DHR_Buttons",
				"LayoutMethod", "HList",
				"LayoutHSpacing",2,
				"HandleMouse",true,
				"RelativeFocusOrder","next-in-line",
				"Translate", false,
				"Title", T("<DisplayName>"),
				"Description", T("<description>"),
			},{
				PlaceObj("XTemplateGroup",{
					"comment","Group for All not destroyed Buttons", 
					"__condition",function (parent, context) 
						return not context.destroyed
					end,
				},{
					PlaceObj("XTemplateTemplate",{
						"comment", "Unpack Drones",
						"__template", "InfopanelButton",
						"Icon", "UI/Icons/IPButtons/drone_assemble.dds",
						"RolloverTitle", T("Unpack Drone"),
						"RolloverText", T("Unpack an existing Drone Prefab to build a new Drone. Drone Prefabs can be created from existing Drones. This action can be used to quickly reassign Drones between controllers.<newline><newline>Available Drone Prefabs:<right><drone(available_drone_prefabs)> "),
						"RolloverDisabledText", T("No available Drones <color em>or</em> Drones at maximum capacity"),
						"RolloverHint", T("<left_click> Unpack Drone <newline><color em>Ctrl + <left_click></color> Unpack five Drones"),
						"RolloverHintGamepad", T("<image UI/PS4/Cross.tga> Unpack Drone <newline><image UI/PS4/Square.tga> Unpack five Drones"),
						"OnContextUpdate", function (self,context,...)
							self:SetEnabled(UICity.drone_prefabs >0 and self.context:GetDronesCount() < self.context:GetMaxDrones())
						end,
						"OnPressParam","UseDronePrefab",
						"OnPress", function (self, gamepad)
							self.context:UseDronePrefab(not gamepad and IsMassUIModifierPressed())
						end,
						"AltPress",true,
						"OnAltPress", function (self,gamepad)
							if gamepad then
								self.context:UseDronePrefab(true)
							end
						end,
					}),-- end Unpack Drones

					PlaceObj("XTemplateTemplate", {
						"comment", "Pack Drone",
						"__template", "InfopanelButton",
						"Icon", "UI/Icons/IPButtons/drone_dismantle.dds",
						"RolloverTitle", T("Pack Drone for Reassignment"),
						"RolloverText", T("Recalls a Drone and packs it into a Drone Prefab. Can be used to reassign Drones between controllers."),
						"RolloverDisabledText", T("No available Drones."),
						"RolloverHint", T("<left_click> Pack Drone for reassignment <newline><color em>Ctrl + <left_click></color> Pack five Drones"),
						"RolloverHintGamepad", T(862024297340, --[[ModItemXTemplate ipRD_DHR RolloverHintGamepad]] "<image UI/PS4/Cross.tga> Pack Drone for reassignment <newline><image UI/PS4/Square.tga> Pack five Drones"),
						"OnContextUpdate", function (self, context, ...)
							self:SetEnabled(not not context:FindDroneToConvertToPrefab())
						end,
						"OnPressParam", "ConvertDroneToPrefab",
						"OnPress", function (self, gamepad)
							self.context:ConvertDroneToPrefab(not gamepad and IsMassUIModifierPressed())
						end,
						"AltPress", true,
						"OnAltPress", function (self, gamepad)
							if gamepad then
								self.context:ConvertDroneToPrefab(true)
							end
						end,
					}),--end Pack Drones

					PlaceObj("XTemplateTemplate", {
						"comment", "priority",
						"Id", "RD_DHR_idPriority",
						"Translate", false,
						"__context", function (parent, context) 
							return context:HasMember("construction_group") and context.construction_group and context.construction_group[1] or context 
						end,
						"__condition", function (parent, context) 
							return context.prio_button and not context.destroyed
						end,
						"__template", "InfopanelButton",
						"RolloverTitle", T("Change Priority"),
						"RolloverText", T("Priority affects how often this building is serviced by Drones as well as its share of Power and life support. Notifications are not shown for buildings with low priority.<newline><newline>Current priority: <em><UIPriority></em>"),
						"RolloverHintGamepad", T("<ButtonA> Change priority<newline><ButtonX> Change priority of all <display_name_pl>"),
						"OnContextUpdate", function (self, context, ...)
							self:SetVisible(not context.destroyed)
							if context.priority == 1 then
								self:SetIcon("UI/Icons/IPButtons/normal_priority.tga")
							elseif context.priority == 2 then
								self:SetIcon("UI/Icons/IPButtons/high_priority.tga")
							else
								self:SetIcon("UI/Icons/IPButtons/urgent_priority.tga")
							end
							local shortcuts = GetShortcuts("actionPriority")
							local binding = ""
							if shortcuts and (shortcuts[1] or shortcuts[2]) then
								binding = T(10950, "<newline><center><em><ShortcutName('actionPriority', 'keyboard')></em> Increase Priority")
							end
							self:SetRolloverHint(T{10951, "<left><left_click> Increase priority<right><right_click> Decrease priority<binding><newline><center><em>Ctrl + <left_click></em> Change priority of all <display_name_pl>", binding = binding})
						end,
						"OnPress", function (self, gamepad)
							PlayFX("UIChangePriority")
							self.context:TogglePriority(1, not gamepad and IsMassUIModifierPressed())
							ObjModified(self.context)
						end,
						"AltPress", true,
						"OnAltPress", function (self, gamepad)
							if gamepad then
								self.context:TogglePriority(1, true)
							else
								self.context:TogglePriority(-1, IsMassUIModifierPressed())
							end
							ObjModified(self.context)
						end,
					}),-- end prio

					PlaceObj("XTemplateTemplate", {
						"comment", "onoff, openclose",
						"__template", "InfopanelButton",
						"Id", "RD_DHR_idOnOff",
						"Icon", ModDir .. "UI/PowerOpen.dds",
						"RolloverTitle", T("Open and On/Closed and Off"),
						"RolloverText", T("Opening leaves it vulnerable to dust contamination, but allows issue of drone commands and power production. Whilst closed it cannot control drones, produces no power but is protected from dust.<newline><newline>Current status: <color em><UIOpenStatus></color>"),
						"RolloverHint", T("<left_click> Open and On/Closed and Off <newline>Ctrl + <left_click> Open and On/Closed and Off for<color em>ALL</color> Large Drone Station Hubs"),
						"RolloverHintGamepad", T("<ButtonA> Open and On/Closed and Off <newline><ButtonX> Open and On/Closed and Off for <color em>ALL</color> Large Drone Station Hubs"),
						"OnContextUpdate", function (self, context, ...)
							if context.working == true then 
								self:SetIcon(ModDir .. "UI/PowerOpen.dds")
							else 
								self:SetIcon(ModDir .. "UI/PowerClose.dds")
							end
						end,
						"OnPressParam", "ToggleWorking",
						"OnPress",function(self,gamepad)
							---
							self.context:ToggleWorking(not gamepad and IsMassUIModifierPressed())
							---
						end,
						"AltPress",true,
						"OnAltPress",function(self,gamepad)
							---
							if gamepad then
								self.context:ToggleWorking(true)
							end
							---
						end,
					}),-- end on/off
				}),--end button group 1, normal working buttons

				PlaceObj("XTemplateGroup", {
					"comment", "group for buttons, destroyed or not, salvage decides on clear/rebuild",
				}, {
					PlaceObj("XTemplateTemplate", {
						"comment", "salvage",
						"Id", "RD_DHR_idSalvage",
						"Icon", "UI/Icons/IPButtons/salvage_1.dds",
						"__template", "InfopanelButton",
						"__context_of_kind", "Demolishable",
						"__condition", function (parent, context) 
							return context:ShouldShowDemolishButton() 
						end,
						"RolloverTitle", T("Salvage"),
						"RolloverHintGamepad", T("<ButtonY> Activate"),
						"OnContextUpdate", function (self, context, ...)
							local refund = context:GetRefundResources() or empty_table
							local rollover = T("Destroy this building.")
							if IsKindOf(context, "LandscapeConstructionSiteBase") then
								self:SetRolloverTitle(T("Cancel Landscaping"))
								rollover = T("Cancel this landscaping project. The terrain will remain in its current state")
							end
							if #refund > 0 then
								rollover = rollover .. "<newline><newline>" .. T("<UIRefundRes> will be refunded upon salvage.")
							end
							self:SetRolloverText(rollover)
							context:ToggleDemolish_Update(self)
						end,
						"OnPressParam", "ToggleDemolish",
					}, {
						PlaceObj("XTemplateFunc", {
							"name", "OnXButtonDown(self, button)",
							"func", function (self, button)
								if button == "ButtonY" then
									return self:OnButtonDown(false)
								elseif button == "ButtonX" then
									return self:OnButtonDown(true)
								end
								return (button == "ButtonA") and "break"
							end,
						}),-- end salvage func a

						PlaceObj("XTemplateFunc", {
							"name", "OnXButtonUp(self, button)",
							"func", function (self, button)
								if button == "ButtonY" then
									return self:OnButtonUp(false)
								elseif button == "ButtonX" then
									return self:OnButtonUp(true)
								end
								return (button == "ButtonA") and "break"
							end,
						}),-- end salvage func b
					}),-- end salvage button

					PlaceObj("XTemplateGroup", nil, {
						PlaceObj("XTemplateTemplate", {
							"comment", "rebuild",
							"__template", "InfopanelButton",
							"FoldWhenHidden", true,
							"Icon", "UI/Icons/IPButtons/rebuild.dds",
							"RolloverTitle", T("Rebuild"),
							"RolloverText", T("Rebuild this building."),
							"RolloverHint", T("<left_click> Activate <newline><em>Ctrl + <left_click></em> Activate for all <display_name_pl>"),
							"RolloverHintGamepad", T("<ButtonA> Activate <newline><ButtonX> Activate for all <display_name_pl>"),
							"OnContextUpdate", function (self, context, ...)
								self:SetEnabled((not g_Tutorial or g_Tutorial.EnableRebuild) and not context.bulldozed)
								self:SetVisible(context.destroyed and not context.demolishing)
								XTextButton.OnContextUpdate(self, context, ...)
							end,
							"OnPressParam", "DestroyedRebuild",
							"OnPress", function (self, gamepad)
								self.context:DestroyedRebuild(not gamepad and IsMassUIModifierPressed())
							end,
							"AltPress", true,
							"OnAltPress", function (self, gamepad)
								if gamepad then
									self.context:DestroyedRebuild(true)
								end
							end,
						}),-- end rebuild button

						PlaceObj("XTemplateTemplate", {
							"comment", "clear",
							"__template", "InfopanelButton",
							"Id", "RD_DHR_idDecommission",
							"FoldWhenHidden", true,
							"Icon", "UI/Icons/IPButtons/demolition.dds",
							"RolloverTitle", T("Clear"),
							"RolloverText", T("Remove the remains of this building."),
							"RolloverDisabledText", T("You need the Decommission Protocol (Engineering) Tech to remove these building remains."),
							"OnContextUpdate", function (self, context, ...)
								self:SetEnabled(UICity:IsTechResearched("DecommissionProtocol") or false)
								self:SetVisible(context.destroyed and not context.demolishing)
								local hint = T(238148642034, "<left_click> Activate <newline><em>Ctrl + <left_click></em> Activate for all <display_name_pl>")
								local hint_gamepad = T(919224409562, "<ButtonA> Activate <newline><ButtonX> Activate for all <display_name_pl>")
								if context.bulldozed then
									hint = TLookupTag("<left_click>") .. " " .. T(3687, "Cancel")
									hint_gamepad = TLookupTag("<ButtonA>") .. " " .. T(3687, "Cancel")
								end
								self:SetRolloverHint(hint)
								self:SetRolloverHintGamepad(hint_gamepad)
								XTextButton.OnContextUpdate(self, context, ...)
								self:SetIcon(context.bulldozed and "UI/Icons/IPButtons/cancel.dds" or "UI/Icons/IPButtons/demolition.dds")
							end,
							"OnPress", function (self, gamepad)
								if self.context.bulldozed then
									self.context:CancelDestroyedClear(not gamepad and IsMassUIModifierPressed())
								else
									self.context:DestroyedClear(not gamepad and IsMassUIModifierPressed())
								end
							end,
							"AltPress", true,
							"OnAltPress", function (self, gamepad)
								if gamepad then
									if self.context.bulldozed then
										self.context:CancelDestroyedClear(true)
									else
										self.context:DestroyedClear(true)
									end
								end
							end,
						}),-- end clear button
					}),-- end salvage button
				}),-- end button group 2, salvage/demolished buttons

				PlaceObj("XTemplateTemplate", {
					"__condition", function (parent, context) 
						return not context.destroyed 
					end,
					"__template", "sectionUpgrades",
				}),-- end section upgrades

				PlaceObj("XTemplateTemplate", {
					"comment", "Drones Section",
					"__template", "InfopanelSection",
					"Icon", "UI/Icons/Sections/drone.dds",
					"TitleHAlign", "stretch",
					"Title", T("Drones<right><GetDronesCount>/<MaxDrones>"),
					"__condition", function (parent, context) 
						return not context.destroyed 
					end,
					"RolloverTitle", T("Drones Information"),
					"RolloverTranslate", false,
					"RolloverText", T("<UISectionDroneHubRollover>"),
					"OnContextUpdate", function (self, context, ...)
					end,
				}, {
					PlaceObj("XTemplateTemplate", {
						"comment", "Drones Status Panel",
						"__template", "InfopanelText",
						"Text", T("<DronesStatusText>"),
					}),-- end Drone status text
				}),-- end section drones

				PlaceObj("XTemplateTemplate", {
					"comment", "powerproduction",
					"__condition", function (parent, context) return not context.destroyed end,
					"__template", "sectionPowerProduction",
				}),-- end section pow production

				PlaceObj("XTemplateTemplate", {
					"comment", "powergrid",
					"__template", "sectionPowerGrid",
				}),-- end section power grid details

				PlaceObj("XTemplateTemplate", {
					"comment", "maintenance",
					"__context_of_kind", "RequiresMaintenance",
					"__condition", function (parent, context) return context:DoesRequireMaintenance() end,			
					"__template", "sectionMaintenance",
				}),-- end section maint

				PlaceObj("XTemplateTemplate", {
					"comment", "cold",
					"__context_of_kind", "ColdSensitive",
					"__condition", function (parent, context) return context:IsFreezing() or context.frozen end,			
					"__template", "sectionCold",
				}),-- end section cold

				PlaceObj("XTemplateTemplate", {
					"comment", "warnings",
					"__template", "sectionWarning",
				}),-- end warnings

				PlaceObj("XTemplateTemplate", {
					"comment", "warnings",
					"__template", "sectionAttention",
				}),-- end attentions

				PlaceObj("XTemplateTemplate", {
					"comment", "Extra Attention Panel - No Drones",
					"__template", "InfopanelSection",
					"Id", "RD_DHR_ExtraAttention",
					"Icon", "UI/Icons/Sections/attention.dds",
					"Title", "<center>No Drones assigned",
					"__condition", function (parent, context) 
						return not context.destroyed 
					end,
					"OnContextUpdate", function (self, context, ...)
						self:SetVisible(self.context:GetDronesCount() < 1)
					end,
				}),-- end section drones attention

				PlaceObj("XTemplateTemplate", {
					"comment", "ipTWZ copy from SkiRich- kindof",
					"__template", "InfopanelSection",
					"Id", "idTWZ_RD_LDS",
					"Icon", ipTWZIcon_On,
					"Title", T("Show Work Zone [<color em><ipTWZState></color>]"),
					"__condition", function (parent, context) 
						return not context.destroyed 
					end,
					"RolloverTitle", "Options Help",
					"RolloverText", T("Control when to display the Zone.\n<color em>On</color><right>Show if selected<left>\n<color em>Locked</color><right>Always Show<left>\n<color em>Off</color><right>Always Hide<left>"),
					"RolloverHint", T("<center><left_click> Toggle zone options."),
					"OnContextUpdate", function (self, context, ...)
						if context.ipTWZState == "On" then
							self:SetIcon(ipTWZIcon_On)
						elseif context.ipTWZState == "Locked" then
							self:SetIcon(ipTWZIcon_Locked)
						elseif context.ipTWZState == "Off" then
							self:SetIcon(ipTWZIcon_Off)
						end
					end,					
				}, {
					PlaceObj("XTemplateFunc", {
						"name", "OnMouseButtonDown(self, pos, button)",
						"parent", function (parent, context)
							return parent.parent
						end,
						"func", function (self, pos, button)
							if button == "L" then
								PlayFX("DomeAcceptColonistsChanged", "start", self.context)
								self.context:RD_ip_TWZ()
								ObjModified(self.context)
							end
						end,
					}),-- end TWZ func
				}),-- end TWZ section

				PlaceObj("XTemplateTemplate", {
					"__template", "sectionCheats",
				}),-- end section cheats

			}),-- end infopanel HList

		})-- end infopanel

		-- COLLAPSED ENTRY + TO EXPAND
		PlaceObj("BuildingTemplate",{
			"Id", "Drone_Hub_Remote",
			"Group", "Infrastructure",
			"build_category", "Infrastructure",
			"build_pos", 6,
			"template_class", "Drone_Hub_Remote",
			"ip_template", "ipRD_DHR",

			"display_name", T("Large Drone Station"),
			"display_name_pl", T("Large Drone Stations"),
			"description", T("Controls a limited number of drones in a small radius, does not work during dust storms."),
			"display_icon", ModDir .. "UI/LDR_BuildMenu.png",
			"entity", "Drone_Hub_Remote_Red",

			"pin_rollover", T("<description><newline><newline><DronesStatusText><newline><left>Drones<right><DronesCount><image UI/Icons/res_drone.dds>"),
			"pin_rollover_hint", T("<left_click> Select"),
			"pin_rollover_hint_xbox", T("<image UI/PS4/Cross.tga> View"),
			"pin_summary1", T("<DronesCount><image UI/Icons/res_drone.dds>"),

			"encyclopedia_id", "Drone_Hub_Remote",
			"encyclopedia_image", ModDir .. "UI/LDR_Encylopedia.png",
			"encyclopedia_text", T("The large drone station can issue orders to a small area around it, provides a unique 3 recharge station design.\n\n Supplies a small amount of power when open and operational, can not function currectly during dust storms."),
			
			"is_tall", true,
			"dome_forbidden", true,
			"suspend_on_dust_storm", true,

			"construction_cost_Concrete", 6000,
			"construction_cost_Metals", 9000,
			"construction_cost_Polymers", 4000,
			"construction_cost_Electronics", 2000,
			"build_points", 1500,
			"maintenance_resource_type", "Electronics",
			"maintenance_threshold_base", 200000,
			
			"show_range_class", "Drone_Hub_Remote",
			"show_range_all", true,
			"show_range", true,
			
			"starting_drones", 0,
			"electricity_production", 10000,
						
			"label1", "DroneControl",
			"label2", "OutsideBuildingWithTargets",

			"palette_color1", "outside_accent_1",
			"palette_color2", "outside_base",
			"palette_color3", "outside_metal",

			"demolish_sinking", range(1, 5),
			"demolish_tilt_angle", range(900, 1500),
			"demolish_debris", 85,
		})-- end bt

		if RustyPrint then print ("Large Drone Station :: BT & IP Added") end

	end-- end if not BT

end-- end OnMsg.CPP

--[[ =========== Finish:: Large_Drone_Station:: Construct InfoPanel and Building Template ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Define Class ========== --]]

DefineClass.Drone_Hub_Remote = {
    __parents = {
		"DroneControl",
        "TaskRequester", 
        "ElectricityProducer",
		--"Building", -- acquired from Electricity Producer, no point in having double 
    },

	-- I tie UIWorkRadius and work_radius together on Init
	properties = {
        {template = true,id = "starting_drones",  name = T(642, "Starting Drones"),editor = "number", default = 3, modifiable = true},
		-- make sure UIWorkRadius and work_radius share the same default value
		{ template = true,id = "UIWorkRadius", name = T(643, "Range"), editor = "number", default = 12, min=6, max=18, no_edit = true, dont_save = true,}, -- prop only for UI purposes
        { template = true,id = "work_radius", editor = "number", default = 12, no_edit = true, },
	},

    --stuff from drone hub
    building_update_time = 10000,
	
	charging_stations = false,
	auto_connect_requesters_at_start = true,
	accept_requester_connects = true,
	
	total_requested_drones = 0,

	--not from drone hub but used to control numbers for DroneSwarm tech, set numbers below on init
	max_drone_amount = 0,
	swarm_drone_amount = 0,
    
    --stuff from stirling
    time_opened_start = false,
	open_close_thread = false,
	electricity_production = 10000,
    
    --need to ref the attach during anim funcs so we'll store it here 
	my_stirling = false,
	my_tower = false,
	my_ring = false,
	fx_actor_class = "DroneHub",

	--custom designed info panel
	ip_template = "ipRD_DHR",
	ipTWZState = "On",

	--initial states, I tie working and opened together on GameInit
	working = false,
	opened = false,

}
--[[ =========== Start:: Large_Drone_Station:: Init Functions ========== --]]

function Drone_Hub_Remote:Init()
    self.charging_stations = {}
	self.UIWorkRadius = 12
	self.work_radius = self.UIWorkRadius

	self.max_drone_amount = 6
	self.swarm_drone_amount = (self.max_drone_amount * 5) -- default game mechanincs for Drone Swarm 20 > 100 (*5)
end

function Drone_Hub_Remote:InitAttaches()
	local station_template = ClassTemplates.Building.RechargeStation
	local platforms = self:GetAttaches("RechargeStationPlatform")

	local ccs = GetCurrentColonyColorScheme()
	local cm1, cm2, cm3, cm4 = GetBuildingColors(ccs, station_template)

	local p = 1
	for _, platform in ipairs(platforms or empty_table) do
		platform:SetEnumFlags(const.efSelectable) --so we can select the command center through the recharge station

		local spot_obj = PlaceObject("NotBuildingRechargeStation")
		spot_obj:ChangeEntity("RechargeStation")
	
		self:Attach(spot_obj, platform:GetAttachSpot())

		spot_obj:SetAttachOffset(platform:GetAttachOffset())
		spot_obj:SetAttachAngle(platform:GetAttachAngle())
		spot_obj.platform = platform
		spot_obj.hub = self
		spot_obj.working = self.working

		assert(not IsValid(self.charging_stations[p]))
		self.charging_stations[p] = spot_obj
		p = p + 1
	
		if cm1 then
			Building.SetPalette(platform, cm1, cm2, cm3, cm4)
		end
    end--end for each recharge

    self:ForEachAttach("RechargeStationPlatform", function(a)                   -- for every recharge station from attach (3) DESTROY the ground lamps                      
        a:ForEachAttach("LampGroundOuter_01",function(a2)
			a2:SetVisible(false)
			DoneObject(a2)
        end)
    end)-- end recharge station for each

    self:ForEachAttach("InvisibleObject", function(a)                          	-- for every InvisObj from auto attach (1), doing it this way or it auto attaches an actual stirling            
				
		self.my_stirling = a
        a:ChangeEntity("StirlingGenerator")                                     -- make it look like a Stirling gen          
        a.fx_actor_class = "StirlingGenerator"                                  -- make it believe it's a stirling             
                    
        a:SetScale(69)                                                          -- make it a bit smaller
        a:SetAttachOffset(5,578,-65)                                            -- set it to the entity's center point

        a:SetVisible(true)                                                      -- stop it being an invisibile object
        a:SetState("idle")

		local Sens = PlaceObject("InvisibleObject")                             -- getting sneaky, for each InvisObj, create another
		Sens:ChangeEntity("SensorTower")                                        -- make it look like a sensor tower
		Sens:SetScale(66)                                                       -- a little smaller in scale than the stirling
        Sens.fx_actor_class = "SensorTower"                                     -- make it believe it's a sensor tower
                    
            Sens:ForEachAttach("ParSystem",function(a2)                         -- even sneakier, for each flashy visual attached            
                if a2:GetParticlesName() == "SensorTower_Working" then          -- check the name for the one I want
                    a2:SetColorModifier(14554846)                               -- recolour it to a fuschia purple/ roughly same colour as most other drone effects
                else 															-- not the tower radar ping, so must be the water tower effect 
					a2:SetColorModifier(13132850)								-- set to a vibrant orange to match the stirling
				end
            end)--end par sys for each

		self:Attach(Sens)                                                        -- attach the sneaky sensor tower to the building
		self.my_tower = Sens
        Sens:SetAttachOffset(5,578,-1001)                                       -- set it to the entity's center point too.... but bury it knee deep so just the pole is sticking out

        if cm1 then
			Building.SetPalette(a, cm1, cm3, cm2, cm2)                          -- assign standard building colours that we grabbed earlier
			Building.SetPalette(Sens, cm2,cm3,cm1,cm2)
		end    
	end)-- end invis obj for each 
	
	self.fx_actor_class = "DroneHub"
	self.force_fx_work_target = self

	if RustyPrint then print("LDS :: Init Attaches Setup Run") end

end--end InitAttaches

--[[ =========== Finish:: Large_Drone_Station:: Init Functions ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Game Init ========== --]]

function Drone_Hub_Remote:GameInit()
	self:InitAttaches()

	--reboot and syncronise the working/open states
	self.opened = true
	self.working = self.opened
	self:SetWorking(false)
	self:SetWorking(self.working)

	--setup interactions for the two drone hub techs if they are already researched, and SpaceY commander see also OnMsg's...
	--DroneSwarm & SpaceY Start with 6		DroneSwarm OR SpaceY start with 4		Default 3
	if self.city:IsTechResearched("DroneSwarm") and GetMissionSponsor().id == "SpaceY" then 
		while #self.drones < 6 do
			self:SpawnDrone()
		end		
		self.max_drone_amount = self.swarm_drone_amount
		if RustyPrint then print("LDS :: Initial Drone Spawn :: GameInit 0 :: DroneSwarm Tech +2 :: SpaceY +4 :: Starting drones count is 6") end
		if RustyPrint then print("LDS :: Initial Drone Spawn :: DroneSwarm Tech also set max limit to",self.max_drone_amount ) end

	elseif self.city:IsTechResearched("DroneSwarm") then
		while #self.drones < 4 do
			self:SpawnDrone()
		end 
		self.max_drone_amount = self.swarm_drone_amount
		if RustyPrint then print("LDS :: Initial Drone Spawn :: GameInit 2 :: DroneSwarm Tech +2 :: NOT SpaceY :: Starting drones count is 4") end
		if RustyPrint then print("LDS :: Initial Drone Spawn :: DroneSwarm Tech also set max limit to",self.max_drone_amount ) end

	elseif GetMissionSponsor().id == "SpaceY" then
		while #self.drones < 4 do
			self:SpawnDrone()
		end 
		if RustyPrint then print("LDS :: Initial Drone Spawn :: GameInit 0 :: NOT DroneSwarm Tech :: SpaceY +4 :: Starting drones count is 4") end

	else
		while #self.drones < 3 do
			self:SpawnDrone()
		end
		if RustyPrint then print("LDS :: Initial Drone Spawn :: GameInit 3 :: NOT DroneSwarm Tech OR SpaceY :: Starting drones count is 3") end
	end
	
	-- should be handled by OnMsgTechResearched catching the BT, but just in case...
	if self.city:IsTechResearched("AutonomousHubs") then
		self.accumulate_dust = false
		self.accumulate_maintenance_points = false
		self.disable_maintenance = 1
		self.maintenance_resource_type = "no_maintenance"

		if RustyPrint then print("LDS :: AutoHubs Tech Researched :: Maintenance Disabled on GameInit") end
	end

end

--[[ =========== Finish:: Large_Drone_Station:: Game Init ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Skin Systems ========== --]]

local Drone_Hub_Remote_Skins = {
	"Drone_Hub_Remote_Red",
	"Drone_Hub_Remote_Orange",
	"Drone_Hub_Remote_Warm",
	"Drone_Hub_Remote_Neutral",
	"Drone_Hub_Remote_Cool",
	"Drone_Hub_Remote_Cyan"
}

-- make the ip paintbrush show up and cycle skins
function Drone_Hub_Remote:GetSkins()
	return Drone_Hub_Remote_Skins
end

-- cycle through the skins and set the correct visual states to the new attaches etc
function Drone_Hub_Remote:OnSkinChanged(skin, palette) 
	Building.OnSkinChanged(self, skin, palette)
	self:InitAttaches()
    self:OnChangeState()
end

--[[ =========== Finish:: Large_Drone_Station:: Skin Systems ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Common/Other Function ========== --]]

--ensures all extra attaches/extra recharge stations are removed too
function Drone_Hub_Remote:Done()
	for _, station in ipairs(self.charging_stations) do
		DoneObject(station)
	end

	if self.my_ring then
		DoneObject(self.my_ring)
		self.my_ring = nil
	end
end

--spawn drones only if less than max drones
function Drone_Hub_Remote:SpawnDrone()
	if #self.drones >= self:GetMaxDrones() then
		return false
	end
	local drone = self.city:CreateDrone()
	drone:SetHolder(self)
	drone:SetCommandCenter(self)
	return true
end

--[[ =========== Finish:: Large_Drone_Station:: Common/Other Function ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Suspend on DustStorms ========== --]]

local suspend_reason = const.DustStormSuspendReason
function Drone_Hub_Remote:BuildingUpdate(dt, day, hour)
	--f'ing more negative logic from the game devs!.. if true(opened) and "not false" (also true, ie; dustorm active), suspend
	--auto close if open and dust storm hits
	if self.opened and not self:CanBeOpened() then
		self:SetSuspended(true,suspend_reason)
	end

	--copied from drone control!!
	assert(not self.working or self.are_requesters_connected or delta == 0) --deposits may retain us as cc, if not first tick
	self:UpdateConstructions()
	self:UpdateAllRestrictors()
	self:UpdateDeficits()
	self:UpdateHeavyLoadNotification()
end

--don't allow open during duststorms
function Drone_Hub_Remote:CanBeOpened()
	if not g_DustStorm then 
		return true 	-- not g_DustStorm 
	else
		return false 	-- g_DustStorm active, any type
	end
end

--[[ =========== Finish:: Large_Drone_Station:: Suspend on DustStorms ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Working Function ========== --]]

function Drone_Hub_Remote:OnSetWorking(working)
	if working then
		self:GatherOrphanedDrones()
		
		for _, drone in ipairs(self.drones) do
			if drone.command == "WaitingCommand" then
				drone:SetCommand("Idle")
			end
		end
	end

	--power up attached recharge stations
	for _, station in ipairs(self.charging_stations) do
		if IsValid(station) then
			station.working = working
			if IsKindOf(station, "NotBuildingRechargeStation") then
				PlayFX("Working", working and "start" or "end", station, station.platform)
			end
			if working then
				station:StartAoePulse()
				station:NotifyDronesOnRechargeStationFree()
			end
		end
	end

	--power up/down connected drones
	for i = 1, #(self.connected_task_requesters or "") do
		local bld = self.connected_task_requesters[i]
		if bld:HasMember("OnCommandCenterWorkingChanged") then
			bld:OnCommandCenterWorkingChanged(self)
		end
	end
	
	--refresh lights and power up/down electric production, refresh anim state
	self:RefreshNightLightsState()
	ElectricityProducer.OnSetWorking(self, working)	
	self:OnChangeState()
end

--[[ =========== Finish:: Large_Drone_Station:: Working Function ========== --]]

--[[ =========== Start:: Large_Drone_Station:: On.Msg's ========== --]]

function OnMsg.DepositsSpawned()
	if UICity then
		local arr = UICity.labels.Drone_Hub_Remote --template name label
		
		for i = 1, #(arr or empty_table) do
			if arr[i].are_requesters_connected then
				arr[i]:ReconnectTaskRequesters()
			else
				arr[i]:ConnectTaskRequesters()
			end
		end
	end
end

function OnMsg.TechResearched(tech_id,city)
	--if RustyPrint then print("Large Drone Station :: A tech was researched",tech_id) end -- don't really need to know ALL the tech.ids researched


	-- TECH :: update max drone value on research of Drone Swarm for all existing LDS, spawn code also covered in GameInit for new ones
	if tech_id == "DroneSwarm" then
		city:ForEachLabelObject("Drone_Hub_Remote", function(r)
			r.max_drone_amount = r.swarm_drone_amount
		end)

		if RustyPrint then print("LDS ::",tech_id,"Detected :: Spawn amount will be adjusted on Init") end
	end

	-- TECH :: update dust/mp/maint section for all existing LDS, also covered in GameInit for new ones, and open/close 
	if tech_id == "AutonomousHubs" then
		city:ForEachLabelObject("Drone_Hub_Remote", function(r)
			r.accumulate_dust = false 
			r.accumulate_maintenance_points = false
			r.disable_maintenance = 1
			r.maintenance_resource_type = "no_maintenance"

		end)

		--function CreateLabelModifier(id, label, property, amount, percent), this correctly adjust the BT texts as well
		CreateLabelModifier("RD_DHR_AutonomousHubs","Drone_Hub_Remote","disable_maintenance",1,0)

		if RustyPrint then print("LDS ::",tech_id,"Detected :: stopped dust build, removed maintenance section, adjusted BTs for rollover displays in Build Menu")  end
	end

end

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "Drone_Hub_Remote"
end

--[[ =========== Finish:: Large_Drone_Station:: On.Msg's ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Visual State Functions ========== --]]

--control what to do in open/close state, self:SetUIWorkRadius, naturally calls SetWorkRadius to match
function Drone_Hub_Remote:OnChangeState()

	if self:IsOpened() then
		--opened state
		self:SetBase("electricity_production", self:GetClassValue("electricity_production"))
		self:SetUIWorkRadius(12)
		if self.ipTWZState == "Off" then
			self:SetUIWorkRadius(0)
			self:SetWorkRadius(12)
		end

		self.my_stirling.fx_actor_class = "Rover"
		PlayFX("RoverUnsiege","start",self.my_stirling)                         --flashy visuals
		self.my_stirling.fx_actor_class = "StirlingGenerator"
		PlayFX("Working","start",self.my_tower)
				
		self.my_tower:ForEachAttach("ParSystem",function(a2)                -- even sneakier, for each flashy visual attached            
			if a2:GetParticlesName() == "SensorTower_Working" then          -- check the name for the one I want
				a2:SetColorModifier(14554846)								-- recolour it to a fuschia purple/ roughly same colour as most other drone effects
			else -- not the tower bleep, so must be the water tower effect/which is the top light bulb 
				a2:SetColorModifier(13132850)
			end
		end)--end par sys for each			
	else
		--closed state
		self:SetBase("electricity_production",0)
		self:SetUIWorkRadius(0)
		
		self.my_tower:ForEachAttach("ParSystem",function(a2)                -- destroy the sensor tower anim            
				DoneObject(a2)		
		end)--end par sys for each
	end

	if self.city:IsTechResearched("AutonomousHubs") then 		--ensure we account for free maintenance after build/tech/open/close
		self.accumulate_dust = false 
		self.accumulate_maintenance_points = false
	else
		self.accumulate_dust = self:IsOpened() 
		self.accumulate_maintenance_points = self:IsOpened()	
	end
	
	self:UpdateAnim()
	self:RefreshNightLightsState()
	UpdateHexRanges(UICity, self.class)
	RebuildInfopanel(self)
end

function Drone_Hub_Remote:UpdateAnim()
	DeleteThread(self.open_close_thread)
	self.open_close_thread = CreateGameTimeThread(function()
		local anim = self.my_stirling:GetStateText()
		if anim ~= "idle" and anim ~= "idleOpened" then
			Sleep(self:TimeToAnimEnd())
		end
		local opened = self:IsOpened()
		local current_state = GetStateName(self.my_stirling:GetState())
		if opened and current_state == "idleOpened"
			or not opened and current_state == "idle" then return end --don't transition if already in desired state
		
		PlayFX("StirlingGenerator", opened and "open_start" or "close_start", self.my_stirling)
		local new_anim = opened and "opening" or "closing" 
		if new_anim ~= anim then
			self.my_stirling:SetAnim(1, new_anim)
		end
		
		local t = self:TimeToMoment(1, "Hit")
		if t == 0 then
			t = self:TimeToMoment(1, "Hit", 2)
		end
		if t then
			Sleep(t)
		end
		PlayFX("StirlingGenerator", "hit-moment", self.my_stirling)
		Sleep(self:TimeToAnimEnd())
		if opened then
			--opened state
			self.my_stirling:SetAnim(1, "idleOpened")
			self.my_tower:SetState("working")
		else
			--closed state
			self.my_stirling:SetAnim(1, "idle")
			self.my_tower:SetState("idle")
		end
		PlayFX("StirlingGenerator", opened and "open" or "close", self.my_stirling)
	end)-- end GameTime Thread
end

--change states
function Drone_Hub_Remote:SetOpenState(opened)
	if self:RepairNeeded() then
		return
	end
	if opened and not self:CanBeOpened() then
		return
	end
	if self.opened == (opened or false) then
		return
	end
	self.opened = opened
	self:OnChangeState()
end

--[[ =========== Finish:: Large_Drone_Station:: Visual State Functions ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Info & Infopanel Functions ========== --]]

--overwrites the signs to not be visible, power grid connected to demander/charger and no Control Center sign, also maint section if AutoHubs
function Drone_Hub_Remote:ShouldShowNotConnectedToPowerGridSign()
end

function Drone_Hub_Remote:ShouldShowNoCCSign()
end

--used for the button to spawn more drones if it can
function Drone_Hub_Remote:CanHaveMoreDrones()
	return #self.drones < self:GetMaxDrones()
end

--max drones display and used for if droneswarm active to change display
function Drone_Hub_Remote:GetMaxDrones()
	return self.max_drone_amount
end

function Drone_Hub_Remote:GetUISectionDroneHubRollover()
	return table.concat({
		T{293, "Low Battery<right><drone(DischargedDronesCount)>", self},
		T{294, "Broken<right><drone(BrokenDronesCount)>", self},
		T{295, "Idle<right><drone(IdleDronesCount)>", self},
		}, "<newline><left>")
end

function Drone_Hub_Remote:IsOpened()
	return self.opened and self.working
end

function Drone_Hub_Remote:GetUIOpenStatus()
	return self:IsOpened() and T(7356, "Open") or not self:CanBeOpened() and T("Suspended by Storm") or T(7357, "Closed")
end

--[[ =========== Finish:: Large_Drone_Station:: Info & Infopanel Functions ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Hex Ring Functions ========== --]]

function Drone_Hub_Remote:GetSelectionRadiusScale()
	if not IsValid(self) and CityConstruction[UICity].template_obj == self then
		--self == ClassTemplates.Building.Drone_Hub_Remote
		return self.UIWorkRadius
	else
		return self.UIWorkRadius
	end
end

-- infopanel logic code to interact with selected obj code .			.. Toggle Work Zones idea/images and help from SkiRich
function Drone_Hub_Remote:RD_ip_TWZ()

	if self.ipTWZState == "On" then 			--default individual toggles...if on & pressed cycle to display:Locked
		self:SetUIWorkRadius(12)
		HideHexRanges(UICity, self.class)
		
		if not self.my_ring then
			local obj = RangeHexMultiSelectRadius:new()
			self.my_ring = obj
			
			self.my_ring:SetScale(self.UIWorkRadius)
			self.my_ring:SetPos(self:GetPos():SetStepZ())
			for i = 1, #self.my_ring.decals do
				self.my_ring.decals[i]:SetColorModifier(13113750) --colour our fake placed hex ring a kinda fuschia purple
			end	
			if Rustyprint then print ("LDS :: locked ring created, coloured and set for this LDS") end
		end

		UpdateHexRanges(UICity, self.class)
		ShowHexRanges(UICity, self.class)
		self.ipTWZState = "Locked"

	elseif self.ipTWZState == "Locked" then 	--don't hide on deselection ... if locked & pressed cycle to display:off
		self:SetUIWorkRadius(0)
		self:SetWorkRadius(12)
		HideHexRanges(UICity, self.class)
			DoneObject(self.my_ring)
			self.my_ring = nil
		UpdateHexRanges(UICity, self.class)
		HideHexRanges(UICity, self.class)
		self.ipTWZState ="Off"

	elseif self.ipTWZState == "Off" then 		--don't show on select .. if off & pressed cycle to display:on
		if self:IsOpened() then
			self:SetUIWorkRadius(12)
			HideHexRanges(UICity, self.class)
			UpdateHexRanges(UICity, self.class)
			ShowHexRanges(UICity, self.class)
		end
		self.ipTWZState = "On"
	end
end

--[[ =========== Finish:: Large_Drone_Station:: Hex Ring Functions ========== --]]

-- function ShowHexRanges(city, class, cursor_obj, bind_func, single_obj)

--[[ =========== Finish:: Large_Drone_Station:: Main Script ========== --]]
