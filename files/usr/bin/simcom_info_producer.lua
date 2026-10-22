#!/usr/bin/env lua

function Trim(s)
	if not s then return "" end
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function DisableATCommandEcho(serial)
	serial:write("ATE0\r\n")
	while true do
		local line = serial:read("*l")
		if not line or line == "OK" or line == "ERROR" then break end
	end
end

function WriteTmp(key, val)
	if not val or val == "" then return end
	local f, _ = io.open("/tmp/modem_" .. key, "w")
	if f then
		f:write(val .. "\n")
		f:close()
	end
end

function GetATI(serial)
	local data = {}

	serial:write("ATI\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" then
			break
		end

		local key, val = line:match("^([^:]+):%s*(.*)$")
		if key and val then
			key = Trim(key):lower()
			val = Trim(val)

			if key == "manufacturer" then
				data.manufacturer = val
			elseif key == "model" then
				data.model = val
			elseif key == "revision" then
				data.revision = val
			elseif key == "imei" then
				data.imei = val
			end
		end
	end

	return data
end

function GetSerialNumber(serial)
	local data = "N/A"

	serial:write("AT+CGSN\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" then
			break
		end

		if line:match("^[0-9]+$") then
			data = line
		end
	end

	return data
end

function GetIMSI(serial)
	local data = "N/A"

	serial:write("AT+CIMI\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" then
			break
		end

		if line:match("^[0-9]+$") then
			data = line
		end
	end

	return data
end

function GetSimState(serial)
	local state = "not inserted"
	serial:write("AT+CPIN?\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		if line:find("+CPIN:") then
			state = "inserted"
		end
	end
	return state
end

function GetPinState(serial)
	local state = "unknown"
	serial:write("AT+CPIN?\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		local val = line:match("^%+CPIN:%s*(.*)$")
		if val then
			state = val
		end
	end
	return state
end

function GetNetState(serial)
	local state = "unknown"
	serial:write("AT+CGREG?\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		local _, stat = line:match("^%+CGREG:%s*(%d+),(%d+)")
		if stat then
			if stat == "1" then
				state = "registered"
			elseif stat == "2" then
				state = "searching"
			elseif stat == "3" then
				state = "denied"
			elseif stat == "5" then
				state = "roaming"
			elseif stat == "0" then
				state = "not registered"
			end
		end
	end
	return state
end

function GetSignal(serial)
	local state = "unknown"
	serial:write("AT+CSQ\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		local rssi = line:match("^%+CSQ:%s*(%d+),")
		if rssi then
			local val = tonumber(rssi)
			if val == 99 or val == 199 or not val then
				state = "unknown"
			elseif val >= 0 and val <= 30 then
				state = tostring(-113 + (2 * val))
			elseif val == 31 then
				state = "-51"
			elseif val == 100 then
				state = "-116"
			elseif val == 101 then
				state = "-115"
			elseif val >= 102 and val <= 191 then
				state = tostring(-116 + (val - 100))
			end
		end
	end

	return state
end

function GetCPSI(serial)
	local data = {
		connection_type = "unknown",
		operator_number = "unknown",
		cell_id         = "unknown",
		rsrp            = "unknown",
		rsrq            = "unknown",
		sinr            = "unknown"
	}

	serial:write("AT+CPSI?\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		local payload = line:match("^%+CPSI:%s*(.*)$")
		if payload then
			if payload:find("^NO SERVICE") then
				data.connection_type = "NO SERVICE"
			else
				local parts = {}
				for part in payload:gmatch("[^,]+") do
					table.insert(parts, Trim(part))
				end

				local mode = parts[1]
				if mode then
					data.connection_type = mode

					if mode == "LTE" and #parts >= 14 then
						data.operator_number = parts[3]
						data.cell_id         = parts[5]
						data.rsrq            = parts[11]
						data.rsrp            = parts[12]
						data.sinr            = parts[14]
					elseif (mode == "GSM" or mode == "WCDMA" or mode == "TDS-CDMA") and #parts >= 5 then
						data.operator_number = parts[3]
						data.cell_id         = parts[5]
					end
				end
				data.operator_number = data.operator_number:gsub("-", "")
			end
		end
	end

	return data
end

function GetConnectionState(serial)
	local state = "disconnected"
	serial:write("AT+CGACT?\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		-- Parse response line: +CGACT: <cid>, <state>
		local _, status = line:match("^%+CGACT:%s*(%d+),(%d+)")
		if status == "1" then
			state = "connected"
		end
	end

	return state
end

function GetOperator(serial)
	local operator = "unknown"

	-- First attempt: Read Service Provider Name directly from SIM
	serial:write("AT+CSPN?\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		local spn = line:match('^+CSPN:%s*"([^"]+)"')
		if spn then
			operator = spn
		end
	end

	if operator == "unknown" then
		serial:write("AT+COPS=3,0\r\n")
		serial:read("*l")

		serial:write("AT+COPS?\r\n")

		while true do
			local line = serial:read("*l")
			if not line then break end

			line = Trim(line)

			if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
				break
			end

			local name = line:match('^+COPS:%s*%d+,%d+,"([^"]+)"')
			if name then
				operator = name
			end
		end
	end

	return operator
end

function GetTemperature(serial)
	local temp = "unknown"
	serial:write("AT+CPMUTEMP\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		local val = line:match("^%+CPMUTEMP:%s*([%d%.%-]+)")
		if val then
			temp = val * 10
		end
	end

	return temp
end

function GetNetworkBytes(iface)
	local function ReadFile(path)
		local f = io.open(path, "r")
		if not f then return "0" end
		local val = f:read("*l") or "0"
		f:close()
		return Trim(val)
	end

	local sent = ReadFile("/sys/class/net/" .. iface .. "/statistics/tx_bytes")
	local received = ReadFile("/sys/class/net/" .. iface .. "/statistics/rx_bytes")

	return sent, received
end

function GetDailyBytes(iface)
	local today = tostring(os.date("%Y-%m-%d"))
	local stats_file = "/etc/modem_daily_stats"

	local cur_sent, cur_received = GetNetworkBytes(iface)
	local cur_tx = tonumber(cur_sent) or 0
	local cur_rx = tonumber(cur_received) or 0

	local stored_date, base_tx, base_rx, acc_tx, acc_rx = "", 0, 0, 0, 0
	local f = io.open(stats_file, "r")
	if f then
		local line = f:read("*l")
		f:close()
		if line then
			stored_date, base_tx, base_rx, acc_tx, acc_rx =
			    line:match("^(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)$")
			base_tx                                       = tonumber(base_tx) or 0
			base_rx                                       = tonumber(base_rx) or 0
			acc_tx                                        = tonumber(acc_tx) or 0
			acc_rx                                        = tonumber(acc_rx) or 0
		end
	end

	if stored_date ~= today or cur_tx < base_tx or cur_rx < base_rx then
		stored_date = today
		base_tx = cur_tx
		base_rx = cur_rx
		acc_tx = 0
		acc_rx = 0

		local wf = io.open(stats_file, "w")
		if wf then
			wf:write(string.format("%s %d %d %d %d\n", today, base_tx, base_rx, acc_tx, acc_rx))
			wf:close()
		end
	end

	local sent_today = tostring((cur_tx - base_tx) + acc_tx)
	local received_today = tostring((cur_rx - base_rx) + acc_rx)

	return sent_today, received_today
end

function GetWeeklyBytes(iface)
	local current_week = tostring(os.date("%Y-%W"))
	local stats_file = "/etc/modem_weekly_stats"

	local cur_sent, cur_received = GetNetworkBytes(iface)
	local cur_tx = tonumber(cur_sent) or 0
	local cur_rx = tonumber(cur_received) or 0

	local stored_week, base_tx, base_rx, acc_tx, acc_rx = "", 0, 0, 0, 0
	local f = io.open(stats_file, "r")
	if f then
		local line = f:read("*l")
		f:close()
		if line then
			stored_week, base_tx, base_rx, acc_tx, acc_rx =
			    line:match("^(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)$")
			base_tx                                       = tonumber(base_tx) or 0
			base_rx                                       = tonumber(base_rx) or 0
			acc_tx                                        = tonumber(acc_tx) or 0
			acc_rx                                        = tonumber(acc_rx) or 0
		end
	end

	if stored_week ~= current_week or cur_tx < base_tx or cur_rx < base_rx then
		stored_week = current_week
		base_tx = cur_tx
		base_rx = cur_rx
		acc_tx = 0
		acc_rx = 0

		local wf = io.open(stats_file, "w")
		if wf then
			wf:write(string.format("%s %d %d %d %d\n", current_week, base_tx, base_rx, acc_tx, acc_rx))
			wf:close()
		end
	end

	local sent_week = tostring((cur_tx - base_tx) + acc_tx)
	local received_week = tostring((cur_rx - base_rx) + acc_rx)

	return sent_week, received_week
end

function GetMonthlyBytes(iface)
	local current_month = tostring(os.date("%Y-%m"))
	local stats_file = "/etc/modem_monthly_stats"

	local cur_sent, cur_received = GetNetworkBytes(iface)
	local cur_tx = tonumber(cur_sent) or 0
	local cur_rx = tonumber(cur_received) or 0

	local stored_month, base_tx, base_rx, acc_tx, acc_rx = "", 0, 0, 0, 0
	local f = io.open(stats_file, "r")
	if f then
		local line = f:read("*l")
		f:close()
		if line then
			stored_month, base_tx, base_rx, acc_tx, acc_rx =
			    line:match("^(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)$")
			base_tx                                        = tonumber(base_tx) or 0
			base_rx                                        = tonumber(base_rx) or 0
			acc_tx                                         = tonumber(acc_tx) or 0
			acc_rx                                         = tonumber(acc_rx) or 0
		end
	end

	if stored_month ~= current_month or cur_tx < base_tx or cur_rx < base_rx then
		stored_month = current_month
		base_tx = cur_tx
		base_rx = cur_rx
		acc_tx = 0
		acc_rx = 0

		local wf = io.open(stats_file, "w")
		if wf then
			wf:write(string.format("%s %d %d %d %d\n", current_month, base_tx, base_rx, acc_tx, acc_rx))
			wf:close()
		end
	end

	local sent_month = tostring((cur_tx - base_tx) + acc_tx)
	local received_month = tostring((cur_rx - base_rx) + acc_rx)

	return sent_month, received_month
end

function GetIP(serial)
	local ip = "unknown"
	serial:write("AT+CGPADDR\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" or line:find("+CME ERROR") then
			break
		end

		-- Parse unquoted (+CGPADDR: 1,10.67.4.37) or quoted (+CGPADDR: 1,"10.67.4.37") formats
		local _, addr = line:match('^+CGPADDR:%s*(%d+),%s*"?([^",%s]+)"?')
		if addr then
			local ipv4 = addr:match("(%d+%.%d+%.%d+%.%d+)")
			if ipv4 and ipv4 ~= "0.0.0.0" then
				ip = ipv4
			end
		end
	end

	return ip
end

function GetCCID(serial)
	local data = "-1"

	serial:write("AT+CICCID\r\n")

	while true do
		local line = serial:read("*l")
		if not line then break end

		line = Trim(line)

		if line == "OK" or line == "ERROR" then
			break
		end

		local ccid = line:match("^%+ICCID:%s*([%d%.%-]+)")
		ccid = Trim(ccid)
		if ccid:match("^[0-9]+$") then
			data = ccid
		end
	end

	return data
end

local serial, err = io.open("/dev/ttyUSB3", "r+")
if not serial then
	print("Failed to open port:", err)
	return
end

serial:setvbuf("no")

DisableATCommandEcho(serial)

Ati = GetATI(serial)
for k, v in pairs(Ati) do
	print(string.format("\t%-15s : %s", k, v))
	WriteTmp(k, v)
end

SerialNum = GetSerialNumber(serial)
WriteTmp("serial", SerialNum)

ImsiNum = GetIMSI(serial)
WriteTmp("imsi", ImsiNum)

PinState = GetPinState(serial)
WriteTmp("pin_state", PinState)

SimState = GetSimState(serial)
WriteTmp("sim_state", SimState)

NetState = GetNetState(serial)
WriteTmp("net_state", NetState)

Signal = GetSignal(serial)
WriteTmp("signal", Signal)

Cpsi = GetCPSI(serial)
for k, v in pairs(Cpsi) do
	print(string.format("\t%-15s : %s", k, v))
	WriteTmp(k, v)
end

ConnState = GetConnectionState(serial)
WriteTmp("connection_state", ConnState)

Operator = GetOperator(serial)
WriteTmp("operator", Operator)

Temperature = GetTemperature(serial)
WriteTmp("temperature", Temperature)

SimComIface = "wwan0"
Sent, Received = GetNetworkBytes(SimComIface)
SentToday, ReceivedToday = GetDailyBytes(SimComIface)
SentCurrentWeek, ReceivedCurrentWeek = GetWeeklyBytes(SimComIface)
SentCurrentMonth, ReceivedCurrentMonth = GetMonthlyBytes(SimComIface)
WriteTmp("sent", Sent)
WriteTmp("received", Received)
WriteTmp("sent_today", SentToday)
WriteTmp("received_today", ReceivedToday)
WriteTmp("sent_current_week", SentCurrentWeek)
WriteTmp("received_current_week", ReceivedCurrentWeek)
WriteTmp("sent_current_month", SentCurrentMonth)
WriteTmp("received_current_month", ReceivedCurrentMonth)

SimComIp = GetIP(serial)
WriteTmp("ip", SimComIp)

ICCID = GetCCID(serial)
WriteTmp("iccid", ICCID)

serial:close()
-- /tmp/modem_num
-- /tmp/modem_index
-- /tmp/modem_descr
-- /tmp/modem_imei -- Done
-- /tmp/modem_model -- Done
-- /tmp/modem_manufacturer -- Done
-- /tmp/modem_revision -- Done
-- /tmp/modem_serial -- Done
-- /tmp/modem_imsi -- Done
-- /tmp/modem_sim_state -- Done
-- /tmp/modem_pin_state -- Done
-- /tmp/modem_net_state -- Done
-- /tmp/modem_signal -- Done
-- /tmp/modem_operator -- Done
-- /tmp/modem_operator_number -- Done
-- /tmp/modem_connection_state -- Done
-- /tmp/modem_connection_type -- Done
-- /tmp/modem_temperature -- Done
-- /tmp/modem_cell_id -- Done
-- /tmp/modem_sinr -- Done
-- /tmp/modem_rsrp -- Done
-- /tmp/modem_rsrq -- Done
-- /tmp/modem_sent -- Done
-- /tmp/modem_received -- Done
-- /tmp/modem_ip -- Done
-- /tmp/modem_sent_today -- Done
-- /tmp/modem_received_today -- Done
-- /tmp/modem_sent_current_week -- Done
-- /tmp/modem_received_current_week -- Done
-- /tmp/modem_sent_current_month -- Done
-- /tmp/modem_received_current_month -- Done
-- /tmp/modem_iccid -- Done
