local setting_spawn_mult = settings.startup["entrenched-enemies-base-spawn-multiplier"].value
local setting_health_mult = settings.startup["entrenched-enemies-base-health-multiplier"].value
local setting_regen_mult = settings.startup["entrenched-enemies-base-regen-multiplier"].value

-- anything that can spawn units
local spawner_type = "unit-spawner"
for k, v in pairs(data.raw[spawner_type]) do
  local cd = v.spawning_cooldown
  local max_hp = v.max_health
  local hp_regen = v.healing_per_tick
  ---@type data.EnemySpawnerPrototype
  local spawner = data.raw[spawner_type][k]
  if cd then
    for i, j in pairs(cd) do
      if spawner.spawning_cooldown ~= nil then
        spawner.spawning_cooldown[i] = j / setting_spawn_mult
      end
    end
  end
  if spawner.max_health ~= nil then
    spawner.max_health = max_hp * setting_health_mult
  end
  if spawner.healing_per_tick ~= nil then
    spawner.healing_per_tick = hp_regen * setting_regen_mult
  end
  data.raw[spawner_type][k] = spawner
end

-- lets upgrade all the worms now
local turret_type = "turret"
for k, v in pairs(data.raw[turret_type]) do
  if v.subgroup ~= "enemies" then
    goto continue_turret
  end
  if v.impact_category ~= "organic" then
    goto continue_turret
  end
  local max_hp = v.max_health
  local hp_regen = v.healing_per_tick
  data.raw[turret_type][k].max_health = max_hp * setting_health_mult
  data.raw[turret_type][k].healing_per_tick = hp_regen * setting_regen_mult
  ::continue_turret::
end

-- demolisher time :)
local setting_speed_mult_demolisher = settings.startup["entrenched-enemies-demolisher-speed-multiplier"].value
local setting_health_mult_demolisher = settings.startup["entrenched-enemies-demolisher-health-multiplier"].value
local setting_regen_mult_demolisher = settings.startup["entrenched-enemies-demolisher-regen-multiplier"].value
local setting_attack_range_mult_demolisher = settings.startup["entrenched-enemies-demolisher-attack-range-multiplier"]
.value
local setting_attack_cooldown_mult_demolisher = settings.startup
["entrenched-enemies-demolisher-attack-cooldown-multiplier"].value
local setting_attack_variance_demolisher = settings.startup["entrenched-enemies-demolisher-attack-variance-multiplier"]
.value

local demolisher_names = { "small-demolisher", "medium-demolisher", "big-demolisher", "behemoth-demolisher" }
local function isDemolisher(name)
  local match = false
  for _, demolisher_name in ipairs(demolisher_names) do
    if demolisher_name == name then
      match = true
    end
  end
  return match
end

local function isDemolisherSegment(name)
  for _, prefix in ipairs(demolisher_names) do
    -- Check if 'name' starts with 'prefix'
    if string.sub(name, 1, #prefix) == prefix then
      return true       -- Match found, it's a demolisher segment
    end
  end
  return false   -- No match found
end

if data.raw["segmented-unit"] then
  for _, entity in pairs(data.raw["segmented-unit"]) do
    if isDemolisher(entity.name) == false then
      goto continue_segment_unit
    end
    entity.max_health = entity.max_health * setting_health_mult_demolisher
    entity.healing_per_tick = entity.healing_per_tick * setting_regen_mult_demolisher

    -- entity.patrolling_speed = entity.patrolling_speed * 1
    entity.investigating_speed = entity.investigating_speed * setting_speed_mult_demolisher
    entity.attacking_speed = entity.attacking_speed * setting_speed_mult_demolisher
    entity.enraged_speed = entity.enraged_speed * setting_speed_mult_demolisher
    entity.acceleration_rate = entity.acceleration_rate * setting_speed_mult_demolisher
    -- entity.turn_smoothing = entity.turn_smoothing / setting_speed_mult_demolisher

    if entity.revenge_attack_parameters ~= nil then
      entity.revenge_attack_parameters.range = entity.revenge_attack_parameters.range *
      setting_attack_range_mult_demolisher
      entity.revenge_attack_parameters.cooldown = entity.revenge_attack_parameters.cooldown *
      setting_attack_cooldown_mult_demolisher
      entity.revenge_attack_parameters.cooldown_deviation = tonumber(setting_attack_variance_demolisher)
    end
    if entity.attack_parameters ~= nil then
      entity.attack_parameters.range = entity.attack_parameters.range * setting_attack_range_mult_demolisher
      entity.attack_parameters.cooldown = entity.attack_parameters.cooldown * setting_attack_cooldown_mult_demolisher
      entity.attack_parameters.cooldown_deviation = tonumber(setting_attack_variance_demolisher)
    end
    ::continue_segment_unit::
  end
end
if data.raw["segment"] then
  for _, entity in pairs(data.raw["segment"]) do
    if isDemolisherSegment(entity.name) == false then
      goto continue_segment
    end
    -- check if name prefix
    entity.max_health = entity.max_health * setting_health_mult_demolisher
    ::continue_segment::
  end
end
