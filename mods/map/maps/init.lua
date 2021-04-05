bedwars_map = {}
bedwars_map.maps = {}
bedwars_map.mapdir = minetest.get_modpath(minetest.get_current_modname()) .. "/map_schems/"

function bedwars_map.load_maps()
	local idx = 1
	bedwars_map.available_maps = {}
	for _, dirname in pairs(minetest.get_dir_list(bedwars_map.mapdir, true)) do
		if dirname ~= ".git" then
			local conf = Settings(bedwars_map.mapdir .. "/" .. dirname .. "/map.conf")
			local map = bedwars_map.load_map_meta(idx, dirname, conf)
			bedwars_map.available_maps[idx] = map
			idx = idx + 1
			bedwars.log("Loaded map '" .. map.name .. "'")
		end
	end

	if not next(bedwars_map.available_maps) then
		error("No maps found in directory " .. bedwars_map.mapdir)
	end

	--[[
	-- Determine map selection mode depending on number of available maps
	-- If random, then shuffle the map selection order
	--random_selection_mode = #bedwars_map.available_maps >= (tonumber(minetest.settings:get("bedwars_map.random_selection_threshold")) or 10)
	--[[if random_selection_mode then
		shuffle_maps()
	end]]

	return bedwars_map.available_maps
end

function bedwars.init_world()
	bedwars_map.place_map(bedwars_map.available_maps[1])


	bedwars.log("Map Loaded!")
end


function bedwars_map.load_map_meta(idx, dirname, meta)
	bedwars.log("load_map_meta: Loading map meta from '" .. dirname .. "/map.conf'")

	local offset = vector.new(600 * idx, 0, 0)

	local map = {
		dirname       = dirname,
		name          = meta:get("name"),
		r             = tonumber(meta:get("r")),
		h             = tonumber(meta:get("h")),
		author        = meta:get("author"),
		offset        = offset,
		teams         = {},
	}

	map.pos1 = vector.add(offset, { x = -map.r, y = -map.h / 2, z = -map.r })
	map.pos2 = vector.add(offset, { x =  map.r, y =  map.h / 2, z =  map.r })

	-- Read teams from config
	local i = 1
	while meta:get("team." .. i) do
		local tname  = meta:get("team." .. i)
		local tcolor = meta:get("team." .. i .. ".color")
		local tpos   = minetest.string_to_pos(meta:get("team." .. i .. ".pos"))

		map.teams[tname] = {
			color = tcolor,
			pos = vector.add(offset, tpos),
		}

		i = i + 1
	end

	return map
end

function bedwars_map.place_map(map)
	local schempath = bedwars_map.mapdir .. map.dirname .. "/map.mts"
	local res = minetest.place_schematic(map.pos1, schempath, "0")

	bedwars_map.map = map

	assert(res, "Unable to place schematic, does the MTS file exist? Path: " .. schempath)

	--[[for _, value in pairs(bedwars_map.map.teams) do
		bedwars_map.place_base(value.color, value.pos)
	end]]
	-- add colored beds for each team

	minetest.after(2, function()
		local msg = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", map.name) ..
			minetest.colorize("#fcdb05", " by ") .. minetest.colorize("#f49200", map.author))
		minetest.chat_send_all(msg)
	end)

	minetest.after(10, function()
		minetest.fix_light(bedwars_map.map.pos1, bedwars_map.map.pos2)
	end)
end

minetest.register_on_mods_loaded(bedwars_map.load_maps)