local cfg_quality_per_chunk = settings.startup["entrenched-enemies-quality-upgrade-chance-per-chunk"].value
local cfg_targetRoll = settings.startup["entrenched-enemies-base-upgrade-percent"].value
local cfg_qualMinimum = prototypes.quality[settings.startup["entrenched-enemies-base-qual-minimum"].value]
local cfg_regenerate = settings.startup["entrenched-enemies-base-regenerate"].value
local cfg_normal_units_only = settings.startup["entrenched-enemies-unit-spawn-no-qual"].value

script.on_init(function()
	script.on_nth_tick(1, function(event)
		script.on_nth_tick(1, nil)
		regenerate()
	end)
	storage.targetRoll = cfg_targetRoll
	storage.qual_chunk = cfg_quality_per_chunk
	storage.qual_min = cfg_qualMinimum
	storage.initial_save = true
end)

script.on_load(function()
	local roll = storage.targetRoll
	local qual_chunk = storage.qual_chunk
	local qual_min = storage.qual_min
	if not storage.initial_save then
		script.on_nth_tick(1, function(event)
			script.on_nth_tick(1, nil)
			storage.targetRoll = cfg_targetRoll
			storage.qual_chunk = cfg_quality_per_chunk
			storage.qual_min = cfg_qualMinimum
			storage.initial_save = true
		end)
		return
	end
	if not cfg_regenerate then
		return
	end
	if roll ~= cfg_targetRoll or qual_chunk ~= cfg_quality_per_chunk or qual_min.level ~= cfg_qualMinimum.level then
		-- update what we store so this doesn't happen every loop if you don't change these values
		script.on_nth_tick(1, function(event)
			script.on_nth_tick(1, nil)
			regenerate()
			storage.targetRoll = cfg_targetRoll
			storage.qual_chunk = cfg_quality_per_chunk
			storage.qual_min = cfg_qualMinimum
			storage.initial_save = true
		end)
	end
end)

function regenerate()
	game.print("entrenched enemies: Regenerating enemy bases")
	local quality = prototypes.quality["normal"]
	if quality.level < cfg_qualMinimum.level then
		quality = cfg_qualMinimum
	end
	-- loop over all entities we care about on all surfaces and change them
	for _, surface in pairs(game.surfaces) do
		for _, entity in pairs(surface.find_entities_filtered({ force = "enemy" })) do
			if entity.type == "unit-spawner" or entity.type == "turret" then -- This checks for biter nests and worms
				local newEntityprop = { name = entity.name, position = entity.position, force = entity.force }
				entity.destroy()
				-- reset to minimum quality and then reroll the math
				local newEntity = surface.create_entity({
					name = newEntityprop.name,
					position = newEntityprop.position,
					force = newEntityprop.force,
				})
				qualitySpawnEntity(newEntity, quality)
			end
		end
	end
end
script.on_event(defines.events.on_biter_base_built, function(event)
	local qual = event.entity.quality
	if qual.level < cfg_qualMinimum.level then
		qual = cfg_qualMinimum
	end
	qualitySpawnEntity(event.entity, qual)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
	local surface = event.surface
	local area = event.area

	-- Check if there are any enemy bases in this newly generated chunk
	for _, entity in pairs(surface.find_entities_filtered({ area = area, force = "enemy" })) do
		if entity.type == "unit-spawner" or entity.type == "turret" then -- This checks for biter nests and worms
			local qual = entity.quality
			if qual.level < cfg_qualMinimum.level then
				qual = cfg_qualMinimum
			end
			qualitySpawnEntity(entity, qual)
		end
	end
end)

script.on_event(defines.events.on_entity_spawned, function(event)
	if cfg_normal_units_only == false then
		return
	end
	---@type LuaEntity? lua entity to try and respawn at higher quality
	local entity = event.entity
	if entity == nil then
		return
	end
	if entity.quality.level == 0 then
		return
	end
	if event.spawner.force.name == "player" then
		return
	end
	local surface = entity.surface
	local newEntity = { name = entity.name, position = entity.position, force = entity.force }
	entity.destroy()
	game.surfaces[surface.name].create_entity({
		name = newEntity.name,
		position = newEntity.position,
		force = "enemy",
	})
end)
---@param entity LuaEntity? lua entity to try and respawn at higher quality
---@param StartingQual LuaQualityPrototype|nil default quality to use
function qualitySpawnEntity(entity, StartingQual)
	if not entity then
		return
	end
	local Quality = entity.quality
	if StartingQual ~= nil then
		Quality = StartingQual
	end
	-- calculate bonus quality based on distance from spawn. so as you get further away
	-- the enemies slowly all become higher quality
	local chunkDistance = math.max(entity.position.x, entity.position.y) / 32
	-- local cfg_quality_per_chunk = settings.startup["entrenched-enemies-quality-upgrade-chance-per-chunk"].value
	local AdditionalQuality = chunkDistance * cfg_quality_per_chunk

	local surface = entity.surface.name
	local roll = 0
	-- local targetRoll = settings.startup["entrenched-enemies-base-upgrade-percent"].value

	while Quality.next ~= nil do
		roll = math.random()
		if roll <= math.min(cfg_targetRoll + AdditionalQuality, 1) then
			Quality = Quality.next
		else
			break
		end
		-- remove all additionalQuality that would be required for 100% roll
		-- thus over distance we help guarantee all spawns will be a certain tier
		-- while also showing slow progression to always being the next tier until
		-- all additional quality chance is removed
		AdditionalQuality = math.max(0, AdditionalQuality - (1 - cfg_targetRoll))
	end

	if Quality.level == 0 then
		return
	end

	local newEntity = { name = entity.name, position = entity.position, force = entity.force }
	entity.destroy()
	game.surfaces[surface].create_entity({
		name = newEntity.name,
		position = newEntity.position,
		force = newEntity.force,
		quality = Quality,
	})
end

script.on_event(defines.events.script_raised_built, function(event)
	-- don't do anything if the entity is not made by us
	if event.mod_name and event.mod_name == "entrenched-enemies" then
		return
	end

	local entity = event.entity
	-- don't do anything if the entity is nil or invalid
	if not entity or not entity.valid then
		return
	end
	if entity.type == "unit-spawner" or entity.type == "turret" then -- This checks for biter nests and worms
		local qual = entity.quality
		if qual.level < cfg_qualMinimum.level then
			qual = cfg_qualMinimum
		end
		qualitySpawnEntity(entity, qual)
	end
end)
