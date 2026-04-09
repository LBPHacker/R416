local bitx            = require("spaghetti.bitx")
local plot            = require("spaghetti.plot")
local misc            = require("spaghetti.misc")
local check           = require("spaghetti.check")
local r4_check        = require("r4.check")
local bus_termination = require("r4.comp.bus_termination")
local top             = require("r4.comp.r3_bus.generated_top")
local bottom          = require("r4.comp.r3_bus.generated_bottom")

local pt = plot.pt

local function build(params, params_name, component)
	local memory_base = params.bus_0.cpu.memory_base
	local memory_mask = params.bus_0.cpu.memory_mask

	local adapter_base = params.base_address
	local adapter_mask = 0xFC0000
	r4_check.base_address(params_name .. ".base_address", params.base_address, adapter_mask)
	local areas = {}

	if params.bus_0.cpu ~= params.bus_1.cpu or
	   params.bus_0.y + 16 ~= params.bus_1.y then
		misc.user_error(("%s.bus_0 and %s.bus_1 must be consecutive buses of the same CPU, in this order"):format(params_name, params_name))
	end

	local parts = {}
	local ucontext = plot.common_structures(parts, params.debug_stacks and true or false)
	local part        = ucontext.part
	local aray        = ucontext.aray
	local dray        = ucontext.dray
	local cray        = ucontext.cray
	local ldtc        = ucontext.ldtc

	plot.merge_parts(20, 6, parts, top.get_parts(), {})
	plot.merge_parts(20, 13, parts, bottom.get_parts(), {})

	part({ type = pt.LDTC, x = 28, y = 7, tmp = 1 })
	local r3_0 = part({ type = pt.FILT, x = 27, y = 8 })
	part({ type = pt.LDTC, x = 31, y = 8, life = 1 })
	local r3_1 = part({ type = pt.FILT, x = 31, y = 9 })
	part({ type = pt.LDTC, x = 30, y = 12, tmp = 1 })
	part({ type = pt.LDTC, x = 29, y = 10 })
	part({ type = pt.LDTC, x = 29, y = 11 })
	part({ type = pt.FILT, x = 28, y = 12 })

	for x = 30, 47 do
		for y = 10, 11 do
			part({ type = pt.FILT, x = x, y = y })
		end
	end
	part({ type = pt.FILT, x = 27, y = 10, ctype = 0x10000000 })
	part({ type = pt.FILT, x = 27, y = 11, ctype = 0x10000000 })
	for x = 48, 50 do
		for y = 8, 11 do
			part({ type = pt.FILT, x = x, y = y })
		end
	end
	ldtc(47, r3_0.y, r3_0.x, r3_0.y)
	ldtc(47, r3_1.y, r3_1.x, r3_1.y)

	do
		part({ type = pt.INSL, x = 11, y =  0 })
		part({ type = pt.FILT, x = 0, y = 0 })
		part({ type = pt.FILT, x = 0, y = 3 })
		part({ type = pt.FILT, x = 0, y = 4 })
		local termination_0_parts = {}
		bus_termination.build_internal(termination_0_parts, {
			debug_stacks = params.debug_stacks,
			memory_base  = memory_base,
			memory_mask  = memory_mask,
		})
		plot.merge_parts(1, 0, parts, termination_0_parts)
	end
	do
		part({ type = pt.INSL, x = 26, y = 16 })
		part({ type = pt.LDTC, x = 25, y = 15, life = 1 })
		for x = 0, 15 do
			part({ type = pt.FILT, x = x, y = 16 })
			part({ type = pt.FILT, x = x, y = 19 })
			part({ type = pt.FILT, x = x, y = 20 })
		end
		local termination_1_parts = {}
		bus_termination.build_internal(termination_1_parts, {
			debug_stacks = params.debug_stacks,
			memory_base  = memory_base,
			memory_mask  = memory_mask,
		})
		plot.merge_parts(16, 16, parts, termination_1_parts)
	end

	part({ type = pt.LDTC, x = 29, y = 19, life = 5 })
	local r4_4 = part({ type = pt.FILT, x = 29, y = 20 })
	ldtc(18, r4_4.y, r4_4.x, r4_4.y)

	part({ type = pt.FILT, x = 23, y = 5 })
	part({ type = pt.FILT, x = 25, y = 5 })
	part({ type = pt.FILT, x = 29, y = 5 })
	part({ type = pt.FILT, x = 32, y = 5 })
	part({ type = pt.LDTC, x = 23, y = 4, life = 3 })
	part({ type = pt.LDTC, x = 25, y = 4, life = 2 })
	part({ type = pt.LDTC, x = 29, y = 4, life = 2 })
	part({ type = pt.LDTC, x = 33, y = 4, life = 1 })
	part({ type = pt.FILT, x = 29, y = 1 })
	part({ type = pt.FILT, x = 35, y = 2 })
	part({ type = pt.FILT, x = 23, y = 0 })
	part({ type = pt.FILT, x = 25, y = 0, ctype = bitx.bor(0x10000000, adapter_base) })
	ldtc(28, 1, -1, 1)
	ldtc(34, 2, -1, 2)
	ldtc(22, 0, -1, 0)
	for y = 7, 12 do
		part({ type = pt.FILT, x = 23, y = y })
		part({ type = pt.FILT, x = 25, y = y })
	end

	local width = 51
	local height = 25

	for x = -1, width - 2 do
		part({ type = pt.DMND, x = x, y = -2        , unstack = true })
		part({ type = pt.DMND, x = x, y = -1        , unstack = true })
		part({ type = pt.DMND, x = x, y = height - 4, unstack = true })
		part({ type = pt.DMND, x = x, y = height - 3, unstack = true })
	end
	for y = -1, height - 4 do
		part({ type = pt.DMND, x = width - 2, y = y, unstack = true })
		part({ type = pt.DMND, x = width - 1, y = y, unstack = true })
		part({ type = pt.DMND, x = -2       , y = y, unstack = true })
		part({ type = pt.DMND, x = -1       , y = y, unstack = true })
	end

	for _, part in ipairs(parts) do
		part.dcolour = 0xFF007F7F
		if part.type == pt.DMND then
			part.dcolour = 0xFFFFFFFF
		end
		if part.type == pt.FILT then
			part.dcolour = 0xFF00FFFF
		end
	end

	local xoff
	if params.x.which == "left" then
		xoff = params.x.value
	else
		xoff = params.x.value - width + 1
	end
	local interface = {
		type           = "solid",
		name           = "interface",
		x              = xoff,
		y              = params.bus_0.y - 2,
		w              = width,
		h              = height,
		terminates_bus = true,
	}
	table.insert(areas, interface)
	table.insert(params.bus_0.through_areas, interface)
	table.insert(params.bus_1.through_areas, interface)
	local parts_out = {}
	plot.merge_parts(xoff, params.bus_0.y, parts_out, parts)
	return {
		parts = parts_out,
		areas = areas,
	}
end

local function param_types()
	return {
		x = {
			type = "lowhigh",
			low  = "left",
			high = "right",
		},
		bus_0 = {
			type = "cpu_bus",
		},
		bus_1 = {
			type = "cpu_bus",
		},
	}
end

return {
	build       = build,
	param_types = param_types,
}
