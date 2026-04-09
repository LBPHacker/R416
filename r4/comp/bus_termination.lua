local bitx = require("spaghetti.bitx")
local plot = require("spaghetti.plot")

local pt = plot.pt

local function build_internal(parts, params)
	local ucontext = plot.common_structures(parts, params.debug_stacks and true or false)
	local dray = ucontext.dray
	local part = ucontext.part
	local aray = ucontext.aray
	local ldtc = ucontext.ldtc

	local source = { x = 6, y = 0 }
	ldtc(1, 0, -1, 0)
	dray(1, 0, source.x, source.y, 1, pt.METL)
	aray(1, 0, -1, 0, pt.METL, nil, 1)

	part({ type = pt.FILT, x = 2, y = 0 })
	part({ type = pt.BRAY, x = 3, y = 0, life = 1 })
	part({ type = pt.FILT, x = 4, y = 0, tmp = 1, ctype = bitx.bor(0x10000000, params.memory_mask) })
	part({ type = pt.FILT, x = 5, y = 0, tmp = 7, ctype = bitx.bor(0x10000000, params.memory_base) })
	part({ type = pt.FILT, x = 7, y = 0, tmp = 1, ctype = 0x3000000 })
	part({ type = pt.FILT, x = 8, y = 0, ctype = 0x1002FFFF })
	part({ type = pt.BRAY, x = 9, y = 0, life = 1 })

	aray(9, 2, 0, 1, pt.METL, nil, 1)
	part({ type = pt.FILT, x = 9, y = 1, ctype = 0x1000FFFF })

	part({ type = pt.FILT, x = 0, y = 3 })
	part({ type = pt.FILT, x = 1, y = 3 })
	part({ type = pt.FILT, x = 2, y = 3 })
	part({ type = pt.FILT, x = 3, y = 3 })
	part({ type = pt.FILT, x = 4, y = 3 })
	part({ type = pt.FILT, x = 5, y = 3 })
	part({ type = pt.DTEC, x = 6, y = 3, tmp2 = 3 })
	dray(source.x, 3, source.x, source.y, 1, pt.PSCN)

	part({ type = pt.FILT, x = 0, y = 4 })
	part({ type = pt.FILT, x = 1, y = 4 })
	part({ type = pt.LDTC, x = 2, y = 4, life = 1, tmp = 1 })
	part({ type = pt.FILT, x = 4, y = 4, ctype = 0x1000FFFF })
end

local function build(params)
	local parts = {}
	local ucontext = plot.common_structures(parts, params.debug_stacks and true or false)
	local part = ucontext.part

	build_internal(parts, {
		memory_mask = params.memory_mask,
		memory_base = params.memory_base,
	})

	for x = -1, 10 do
		part({ type = pt.DMND, x = x, y = -2, unstack = true })
		part({ type = pt.DMND, x = x, y = -1, unstack = true })
		part({ type = pt.DMND, x = x, y =  5, unstack = true })
		part({ type = pt.DMND, x = x, y =  6, unstack = true })
	end
	for y = -1, 5 do
		part({ type = pt.DMND, x = 10, y = y, unstack = true })
		part({ type = pt.DMND, x = 11, y = y, unstack = true })
		part({ type = pt.DMND, x = -2, y = y, unstack = true })
		part({ type = pt.DMND, x = -1, y = y, unstack = true })
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
	return parts
end

return {
	build_internal = build_internal,
	build          = build,
}
