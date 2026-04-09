local spaghetti    = require("spaghetti")
local bitx         = require("spaghetti.bitx")
local testbed      = require("spaghetti.testbed")
local common       = require("r4.common")
local unstack_high = require("r4.comp.r3_bus.unstack_high").instantiate()

local merge32 = common.merge32
local split32 = common.split32

return testbed.module(function(params)
	return {
		tag = "bottom",
		opt_params = {
			thread_count  = 1,
			temp_initial  = 1,
			temp_final    = 0.5,
			temp_loss     = 1e-6,
			round_length  = 10000,
			seed          = { 0x56789ABC, 0x87654330 },
		},
		stacks        = 1,
		storage_slots = 18,
		work_slots    = 8,
		inputs = {
			{ name = "r4_0", index = 1, keepalive = 0x10000000, payload = 0x03FFFFFF, initial = 0x10000000 },
			{ name = "base", index = 3, keepalive = 0x10000000, payload = 0x00FFFFFC, initial = 0x10000000 },
			{ name = "r3_2", index = 5, keepalive = 0x10000000, payload = 0x00000009, initial = 0x10000000 },
			{ name = "r3_3", index = 7, keepalive = 0x00000000, payload = 0xFFFFFFFF, initial = 0x10000000, never_zero = true },
		},
		outputs = {
			{ name = "r4_3", index = 5, keepalive = 0x10000000, payload = 0x0003FFFF },
			{ name = "r4_4", index = 7, keepalive = 0x10000000, payload = 0x0000FFFF },
		},
		func = function(inputs)
			local unstack_high_outputs = unstack_high.component({
				both_halves = inputs.r3_3,
			})
			local r4_3 = unstack_high_outputs.low_half
			local r4_4 = unstack_high_outputs.high_half
			local control = spaghetti.lshiftk(inputs.r3_2:bor(2), 17):bor(0x10010000):band(0x10030000)
			control = spaghetti.select(inputs.r4_0:bor(1):bxor(inputs.base):band(0x00FC0000):zeroable(), 0x10020000, control)
			control = spaghetti.select(inputs.r4_0:band(0x03000000):zeroable(), control, 0x10020000)
			return {
				r4_3 = r4_3:bor(control),
				r4_4 = r4_4,
			}
		end,
		fuzz_inputs = function()
			local r3_3 = merge32(math.random(0x0000, 0xFFFF), bitx.bor(math.random(0x0000, 0xFFFF)))
			if bitx.band(r3_3, 0x3FFFFFFF) == 0 then
				r3_3 = bitx.bor(r3_3, 0x20000000)
			end
			return {
				r4_0 = bitx.bor(math.random(0x00000000, 0x00FFFFFF), bitx.lshift(math.random(0, 2), 24), 0x10000000),
				r3_2 = bitx.bor(math.random(0, 1), bitx.lshift(math.random(0, 1), 3), 0x10000000),
				r3_3 = r3_3,
				base = bitx.bor(bitx.lshift(math.random(0x00000000, 0x003FFFFF), 2), 0x10000000),
			}
		end,
		fuzz_outputs = function(inputs)
			local r4_3, r4_4 = split32(inputs.r3_3)
			if bitx.band(inputs.r4_0, 0x03000000) ~= 0 and bitx.band(bitx.bxor(inputs.r4_0, inputs.base), 0x00FC0000) == 0 then
				r4_3 = bitx.bor(r4_3, 0x10000)
				if bitx.band(inputs.r3_2, 1) ~= 0 then
					r4_3 = bitx.bor(r4_3, 0x20000)
				end
			else
				r4_3 = bitx.bor(r4_3, 0x20000)
			end
			return {
				r4_3 = bitx.bor(0x10000000, r4_3),
				r4_4 = bitx.bor(0x10000000, r4_4),
			}
		end,
	}
end)
