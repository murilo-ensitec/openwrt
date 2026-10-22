#!/usr/bin/lua
local nixio = require("nixio")
local SamplePeriodMs = 1500

local function GetCpuTimes()
	local f = io.open("/proc/stat", "r")
	if not f then return nil end
	local line = f:read("*l")
	f:close()
	if not line then return nil end

	local user, nice, system, idle, iowait, irq, softirq, steal =
	    line:match("^cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")

	if not user then return nil end

	local total_idle = (tonumber(idle) or 0) + (tonumber(iowait) or 0)
	local total_time = (tonumber(user) or 0) + (tonumber(nice) or 0) +
	    (tonumber(system) or 0) + total_idle +
	    (tonumber(irq) or 0) + (tonumber(softirq) or 0) +
	    (tonumber(steal) or 0)

	return total_time, total_idle
end

local t1, i1 = 0, 0
local oneSecondInMs = 1000
local sPeriod = math.floor(SamplePeriodMs / oneSecondInMs)
local nsPeriod = (SamplePeriodMs % oneSecondInMs) * 1000 * 1000
while true do
	nixio.nanosleep(sPeriod, nsPeriod)

	local t2, i2 = GetCpuTimes()

	if t1 and t2 and (t2 - t1) > 0 then
		local total_diff = t2 - t1
		local idle_diff = i2 - i1
		local usage = math.floor((((total_diff - idle_diff) / total_diff) * 100) + 0.5)

		local wf = io.open("/tmp/cpu_usage", "w")
		if wf then
			wf:write(tostring(usage) .. "\n")
			wf:close()
		end
	end
end
