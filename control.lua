script.on_init(function() end)

script.on_event(defines.events.on_biter_base_built, function(event)
	qualitySpawnEntity(event.entity)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
	local surface = event.surface
	local area = event.area

	-- Check if there are any enemy bases in this newly generated chunk
	for _, entity in pairs(surface.find_entities_filtered({ area = area, force = "enemy" })) do
		if entity.type == "unit-spawner" or entity.type == "turret" then -- This checks for biter nests and worms
			qualitySpawnEntity(entity)
		end
	end
end)

---@param entity LuaEntity lua entity to try and respawn at higher quality
function qualitySpawnEntity(entity)
	if entity.quality.next == nil then
		return
	end
	-- calculate bonus quality based on distance from spawn. so as you get further away
	-- the enemies slowly all become higher quality
	local chunkDistance = math.max(entity.position.x, entity.position.y) / 32
	local cfg_quality_per_chunk = settings.startup["entrenched-enemies-quality-upgrade-chance-per-chunk"].value
	local AdditionalQuality = chunkDistance * cfg_quality_per_chunk

	local Quality = entity.quality

	local surface = entity.surface.name
	local roll = 0
	local targetRoll = settings.startup["entrenched-enemies-base-upgrade-percent"].value

	while Quality.next ~= nil do
		roll = math.random()
		if roll <= math.min(targetRoll + AdditionalQuality, 1) then
			Quality = Quality.next
		else
			break
		end
		-- remove all additionalQuality that would be required for 100% roll
		-- thus over distance we help guarantee all spawns will be a certain tier
		-- while also showing slow progression to always being the next tier until
		-- all additional quality chance is removed
		AdditionalQuality = math.max(0, AdditionalQuality - (1 - targetRoll))
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
