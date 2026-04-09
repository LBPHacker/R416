local spaghetti  = require("spaghetti")
local bitx       = require("spaghetti.bitx")
local testbed    = require("spaghetti.testbed")
local common     = require("r4.common")
local stack_high = require("r4.comp.r3_bus.stack_high").instantiate()

local merge32 = common.merge32

return testbed.module(function(params)
	return {
		tag = "top",
		opt_params = {
			thread_count  = 1,
			temp_initial  = 1,
			temp_final    = 0.5,
			temp_loss     = 1e-6,
			round_length  = 10000,
			seed          = { 0x56789ABC, 0x8765443 },
		},
		stacks        = 1,
		storage_slots = 26,
		work_slots    = 8,
		inputs = {
			{ name = "r4_0", index = 1, keepalive = 0x10000000, payload = 0x03FFFFFF, initial = 0x10000000 },
			{ name = "base", index = 3, keepalive = 0x10000000, payload = 0x00FFFFFC, initial = 0x10000000 },
			{ name = "r4_1", index = 7, keepalive = 0x10000000, payload = 0x07FFFFFF, initial = 0x10000000 },
			{ name = "r4_2", index = 9, keepalive = 0x10000000, payload = 0x0000FFFF, initial = 0x10000000 },
		},
		outputs = {
			{ name = "r3_0", index = 7, keepalive = 0x10000000, payload = 0x000AFFFF },
			{ name = "r3_1", index = 9, keepalive = 0x00000000, payload = 0xFFFFFFFF, never_zero = true },
		},
		func = function(inputs)
			local stack_high_outputs = stack_high.component({
				low_half = inputs.r4_1:band(0x1000FFFF),
				high_half = inputs.r4_2,
			})
			local r3_0 = spaghetti.rshiftk(inputs.r4_0, 2):bor(0x10000000):band(0x1000FFFF)
				:bor(spaghetti.rshiftk(inputs.r4_0, 5):bor(0x10000000):band(0x10080000))
				:bor(spaghetti.rshiftk(inputs.r4_0, 8):bor(0x10000000):band(0x10020000))
			r3_0 = spaghetti.select(inputs.r4_0:bor(1):bxor(inputs.base):band(0x00FC0000):zeroable(), 0x10000000, r3_0)
			r3_0 = spaghetti.select(inputs.r4_0:band(0x03000000):zeroable(), r3_0, 0x10000000)
			return {
				r3_0 = r3_0,
				r3_1 = stack_high_outputs.both_halves,
			}
		end,
		fuzz_inputs = function()
			return {
				r4_0 = bitx.bor(math.random(0x00000000, 0x00FFFFFF), bitx.lshift(math.random(0, 2), 24), 0x10000000),
				r4_1 = bitx.bor(math.random(0x00000000, 0x07FFFFFF), 0x10000000),
				r4_2 = bitx.bor(math.random(0x00000000, 0x0000FFFF), 0x10000000),
				base = bitx.bor(bitx.lshift(math.random(0x00000000, 0x003FFFFF), 2), 0x10000000),
			}
		end,
		fuzz_outputs = function(inputs)
			local r3_0 = 0x10000000
			if bitx.band(inputs.r4_0, 0x03000000) ~= 0 and bitx.band(bitx.bxor(inputs.r4_0, inputs.base), 0x00FC0000) == 0 then
				r3_0 = bitx.bor(
					0x10000000,
					bitx.band(bitx.rshift(inputs.r4_0, 5), 0x80000),
					bitx.band(bitx.rshift(inputs.r4_0, 8), 0x20000),
					bitx.band(bitx.rshift(inputs.r4_0, 2), 0xFFFF)
				)
			end
			local r3_1 = merge32(bitx.band(inputs.r4_1, 0xFFFF), bitx.band(inputs.r4_2, 0xFFFF))
			if bitx.band(r3_1, 0x3FFFFFFF) == 0 then
				r3_1 = bitx.bor(r3_1, 0x20000000)
			end
			return {
				r3_0 = r3_0,
				r3_1 = r3_1,
			}
		end,
	}
end)
