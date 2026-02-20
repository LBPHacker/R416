local plot  = require("spaghetti.plot")
local check = require("spaghetti.check")
local misc  = require("spaghetti.misc")
local cpu   = require("r4.comp.cpu")

local audited_pairs = pairs

local function run(params)
	if rawget(_G, "r4plot") then
		r4plot.unregister()
	end
	local x, y = 0, 0
	if params.x ~= nil then
		check.integer("params.x", params.x)
		x = params.x
	end
	if params.y ~= nil then
		check.integer("params.y", params.y)
		y = params.y
	end

	local parts = cpu.build_internal(params)

	if params.clear_sim then
		sim.clearSim()
	end
	for _, part in audited_pairs(parts) do
		if part.debug_dcolour then
			if params.debug_dcolours then
				part.dcolour = part.debug_dcolour
			end
			part.debug_dcolour = nil
		end
	end
	plot.create_parts(x, y, parts)
	if params.clear_sim then
		sim.paused(true)
		sim.heatSim(false)
		sim.newtonianGravity(false)
		sim.ambientHeatSim(false)
		sim.waterEqualization(0)
		sim.airMode(sim.AIR_OFF)
		sim.gravityMode(sim.GRAV_OFF)
	end

	local function unregister()
		rawset(_G, "r4plot", nil)
	end
	local r4plot = {
		unregister = unregister,
	}
	rawset(_G, "r4plot", r4plot)
	print("\bt[r4plot]\14 done")
end

return {
	run = misc.user_wrap(run),
}
