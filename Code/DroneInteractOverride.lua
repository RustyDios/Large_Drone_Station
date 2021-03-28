 --[[ =========== Start:: Large_Drone_Station:: Drone Interactions Override ========== --]]

local mod_name = "Large_Drone_Station"
local steamID = "1771215962"
-- local author = "RustyDios, SkiRich"
-- local version ="2"

local RustyPrint = false

--[[ =========== Start:: Large_Drone_Station:: Function Override for Selection ========== --]]

function OnMsg.ClassesBuilt()

	if RustyPrint then print  ("Large Drone Station detected:: Updating Drone Interaction commands with code from RustyDios") end
	ModLog ("Large Drone Station detected:: Updating Drone Interaction commands with code from RustyDios")

	local RDOverride_Drone_CanInteractWithObject = Drone.CanInteractWithObject
    function Drone:CanInteractWithObject(obj)

		if obj and obj:IsKindOf("Drone_Hub_Remote") then
			-- in selection mode, found a drone_hub_remote that is our command center and told to go there to recharge
			if (self.interaction_mode == false or self.interaction_mode == "default" or self.interaction_mode == "move") and obj == self.command_center and obj.working then
				return true, T{9633, "<UnitMoveControl('ButtonA',interaction_mode)>: Recharge self", self}

			-- in selection mode, found a drone_hub_remote that is NOT our command center and told to make it our command center, if not full
			elseif (self.interaction_mode == false or self.interaction_mode == "default" or self.interaction_mode == "move") and obj ~= self.command_center then 
				if not obj:CanHaveMoreDrones() then
					return false, T(4401, "<red>At full capacity</red>"), true
				else
					return true, T{9632, "<UnitMoveControl('ButtonY',interaction_mode)>: Assign to this command center",self}
				end	
			elseif self.interaction_mode == "reassign" or self.interaction_mode == "reassign_all" then
				if obj ~= self.command_center and obj.can_control_drones then
					if obj:CanHaveMoreDrones() then
						return true, T{4400, "<UnitMoveControl('ButtonA',interaction_mode)>: Assign to this command center",self}
					else
						return false, T(4401, "<red>At full capacity</red>")
					end
				end
			elseif self.interaction_mode == "maintenance" then
				local carrying_resource = self:GetCarriedResource()
				local resource_demand_req = self:ShouldDeliverResourcesToBld(obj, self.resource)
				
				if obj.maintenance_phase then
					if obj.maintenance_resource_request == resource_demand_req then
						return true, T{4396, "<UnitMoveControl('ButtonA',interaction_mode)>: Deliver <resource(amount, resource)>", amount = self.amount, resource = self.resource, self}
					else
						local d_req = obj.maintenance_resource_request
						if d_req and (not d_req:CanAssignUnit() or d_req:GetTargetAmount() <= 0) then
							--don't show as interactable, if other drone is already working on it and the interaction itself does not interrupt it.
							return false
						end
						if obj.maintenance_phase == "demand" then
							local source = MapFindNearest(self, self, Drone_AutoFindResourceRadius, "ResourceStockpile", "ResourcePile", "SurfaceDeposit", "StorageDepot", ResourceSources_func, d_req:GetResource(), DroneResourceUnits[d_req:GetResource()])
							if not source then
								return false, T{4393, "<red>Cannot find any <resource_icon> nearby</red>", resource_icon = TLookupTag("<icon_" .. d_req:GetResource() .. ">")}, true
							end
						end
						
						return true, T{4394, "<UnitMoveControl('ButtonA',interaction_mode)>: Repair this building", self}
					end
				end			
			else -- not in selection mode ,reassign or maintenance for a drone_hub_remote, return "do nothing" we don't know what to do
				return false, ""
			end		
		else --not a Drone_hub_remote, follow old/standard rules
			return RDOverride_Drone_CanInteractWithObject(self,obj)
		end
	end -- end Drone:CanInteractWithObject

--[[ =========== Finish:: Large_Drone_Station:: Function Override for Selection ========== --]]

--[[ =========== Start:: Large_Drone_Station:: Function Override for Actual Interaction ========== --]]

	local RDOverride_Drone_InteractWithObject = Drone.InteractWithObject
	function Drone:InteractWithObject(obj, interaction_mode)

		local drop_resource = false							--these locals are set in the original file /drones.lua
		local carrying_resource = self:GetCarriedResource()	--these locals are set in the original file /drones.lua

		if obj and obj:IsKindOfClasses("Drone_Hub_Remote","DroneHub") then
			
			-- was in selection mode, with a drone_hub_remote/dronehub that is our command center and was told to go there to recharge
			if (self.interaction_mode == false or self.interaction_mode == "default" or self.interaction_mode == "move") and obj == self.command_center and obj.working then
				-- obj = FindNearestObject(obj:GetAttaches("RechargeStationBase"), self) -- original code
				-- find the nearest free charging station to this hub (one of it's attaches) and go charge at it, fixes Drones not wanting to use Free charging stations on a hub
				local nearest = MapFindNearest(obj,"RechargeStationBase",function(o) return not o.drone_charged end)
				if RustyPrint then print("hex dist",HexAxialDistance(obj,nearest)) end

				if nearest and HexAxialDistance(obj,nearest) <=1 then
					self:SetCommandUserInteraction("EmergencyPower", nearest)
					if RustyPrint then print("found a station in 1 hex grid that was not charging a drone and sent to it") end 
				else
					nearest = FindNearestObject(obj:GetAttaches("RechargeStationBase"), obj)
					self:SetCommandUserInteraction("EmergencyPower", nearest)
					if RustyPrint then print("found NO stations in 1 hex grid that was not charging a drone, sent to station hub to queue at nearest") end
				end
			-- was in selection mode, found a "hub" that is NOT our command center and told to make it our command center
			elseif (self.interaction_mode == false or self.interaction_mode == "default" or self.interaction_mode == "move") and obj ~= self.command_center and obj:CanHaveMoreDrones() then 
				drop_resource = true
				self:SetCommandCenterUser(obj)

			elseif self.interaction_mode == "reassign" then
				-- "Reassign" - assign to target hub/rover
				if obj ~= self.command_center and obj:CanHaveMoreDrones() then
					drop_resource = true
					self:SetCommandCenterUser(obj)
				end		

			elseif self.interaction_mode == "reassign_all" then
				-- "Reassign All" - assign to target hub/rover all nearby drones up to controller capacity
				if obj ~= self.command_center and obj:CanHaveMoreDrones() then
					local count = obj:GetMaxDrones() - #obj.drones - 1
					-- add more drones
					if count>0 then
						local drones = IsValid(self.command_center)	and self.command_center.drones
							 or MapGet(self:GetPos(), 100*guim,	 "Drone", function(d) 
										return d~=self and d:CanBeControlled() and obj ~= d.command_center 
									end)
						local i=#drones
						while count>0 and i>0 do
							local drone = drones[i]
							if drone ~= self and drone:CanBeControlled() then
								drone:SetCommandCenterUser(obj, true)
								count =  count -1
							end
							i = i - 1
						end
					end
					drop_resource = true
					self:SetCommandCenterUser(obj)
				end
			elseif self.interaction_mode == "maintenance" then
				-- "Maintenance" - Select a target to repair, charge or perform maintenance (including drones, rovers, etc), if target is a charger, charge self (self maintenance)
				local carrying_resource = self:GetCarriedResource()
				local resource_demand_req = self:ShouldDeliverResourcesToBld(obj, self.resource, self.amount)
				if obj.maintenance_phase then
					if obj.maintenance_phase == "work" then
						drop_resource = true
						self:SetCommandUserInteraction("Work", obj.maintenance_work_request, "repair", Min(DroneResourceUnits.repair, obj.maintenance_work_request:GetTargetAmount()))
					elseif obj.maintenance_resource_request == resource_demand_req and assign_to_req_helper(self, resource_demand_req) then
						self:SetCommandUserInteraction("Deliver", resource_demand_req, true)
					else
						drop_resource = true
						local resource = obj.maintenance_resource_request:GetResource()
						local source = MapFindNearest(self, self, Drone_AutoFindResourceRadius, "ResourceStockpile", "ResourcePile", "SurfaceDeposit", "StorageDepot", ResourceSources_func, resource, DroneResourceUnits[resource])
						if source then
							local request = GetSupplyReq(source, resource)
							self:SetCommandUserInteraction("PickUp", request, obj.maintenance_resource_request, resource, Min(DroneResourceUnits[resource], request:GetTargetAmount()))
						end
					end
					
					self:SetInteractionState(false)
				end
			else -- not in selection, maintenance or reassign for a hub, so ?
				return false, ""
			end

			--function call for dropping carried resources off before/if changing commander
			if drop_resource and carrying_resource then
				self:DropCarriedResource()
			end
		
		else --not a Drone_hub_remote or DroneHub, follow old/standard rules
			return RDOverride_Drone_InteractWithObject(self,obj)
		end
	end -- Drone:InteractWithObject

--[[ =========== Finish:: Large_Drone_Station:: Function Override for Actual Interaction ========== --]]

end -- end OnClassesBuilt  for overrides

--[[ =========== Finish:: Large_Drone_Station:: Function Overrides ========== --]]
