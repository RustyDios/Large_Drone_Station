--[[ =========== Start:: Large_Drone_Station:: Add Entities ========== --]]

local mod_name = "Large_Drone_Station"
local steamID = "1771215962"
-- local author = "RustyDios, ChoGGi"
-- local version ="3"

--[[ =========== Start:: Add Entities ========== --]]

-- list of entities we're going to be adding
local entity_list = {
	"Drone_Hub_Remote_Red",
	"Drone_Hub_Remote_Orange",
	"Drone_Hub_Remote_Warm",
	"Drone_Hub_Remote_Neutral",
	"Drone_Hub_Remote_Cool",
	"Drone_Hub_Remote_Cyan"
}
-- getting called a bunch, so make them local
local path_loc_str = string.format("%sEntities/%s.ent",CurrentModPath,"%s")
local mod = Mods.mod_name
local EntityData = EntityData
local EntityLoadEntities = EntityLoadEntities
local SetEntityFadeDistances = SetEntityFadeDistances

-- no sense in making a new one for each entity
local EntityDataTableTemplate = {
	category_Building = true,
	entity = {
		fade_category = "Never",
		material_type = "Metal",
	},
}

-- pretty much using what happens when you use ModItemEntity
local function AddEntity(name)
	EntityData[name] = EntityDataTableTemplate
	EntityLoadEntities[#EntityLoadEntities + 1] = {
		mod,
		name,
		path_loc_str:format(name)
	}
	SetEntityFadeDistances(name, -1, -1)
end

for i = 1, #entity_list do
	AddEntity(entity_list[i])
end
--[[ =========== Finish:: Add Entities ========== --]]

--[[ =========== Finish ::Large_Drone_Station ========== --]]
