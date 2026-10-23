#!/usr/bin/lua
local nixio = require("nixio")

local has_ubus, ubus = pcall(require, "ubus")

local INTERFACE_MODEM = "cwan"
local GPIO_SELC       = "610"
local GPIO_RESET      = "609"
local SWAP_LOCK_FILE  = "/tmp/last_sim_swap"
local COOLDOWN_SEC    = 120
local CHECK_INTERVAL  = 30

local FILE_SIM_STATE  = "/tmp/modem_sim_state"
local FILE_CONN_STATE = "/tmp/modem_connection_state"
local FILE_NET_STATE  = "/tmp/modem_net_state"
local FILE_IP         = "/tmp/modem_ip"

local function log_msg(msg)
    os.execute(string.format("logger -t SIM-Watchdog %q", msg))
end

local function read_file(filepath, default)
    local f = io.open(filepath, "r")
    if not f then return default end
    local content = f:read("*l")
    f:close()
    if not content or content == "" then return default end
    return (content:gsub("^%s*(.-)%s*$", "%1"))
end

local function write_file(filepath, value)
    local f = io.open(filepath, "w")
    if not f then return false end
    f:write(tostring(value) .. "\n")
    f:close()
    return true
end

local function check_mwan3_status(iface)
    if not has_ubus then return false end
    local conn = ubus.connect()
    if not conn then return false end

    local status = conn:call("mwan3", "status", {})
    conn:close()

    if status and status.interfaces and status.interfaces[iface] then
        local state = status.interfaces[iface].status or status.interfaces[iface].state
        if state == "online" then
            return true
        end
    end
    return false
end

local function is_modem_healthy()
    if check_mwan3_status(INTERFACE_MODEM) then
        return true, "mwan3 online"
    end

    local sim_state  = read_file(FILE_SIM_STATE, "N/A"):upper()
    local conn_state = read_file(FILE_CONN_STATE, "N/A"):upper()
    local net_state  = read_file(FILE_NET_STATE, "N/A"):upper()
    local ip         = read_file(FILE_IP, "0.0.0.0")

    if sim_state ~= "READY" and sim_state ~= "OK" then
        return false, string.format("SIM state invalid (%s)", sim_state)
    end

    if conn_state == "DISCONNECTED" or conn_state == "N/A" or net_state == "N/A" or ip == "0.0.0.0" then
        return false, string.format("Modem offline (Conn: %s, Net: %s, IP: %s)", conn_state, net_state, ip)
    end

    return true, "Telemetry OK"
end

local function init_gpio(pin, direction)
    local gpio_path = "/sys/class/gpio/gpio" .. pin
    if not nixio.fs.stat(gpio_path) then
        write_file("/sys/class/gpio/export", pin)
        nixio.nanosleep(0, 100000000)
    end
    write_file(gpio_path .. "/direction", direction or "out")
end

local function can_execute_action()
    local now = os.time()
    local last_swap = tonumber(read_file(SWAP_LOCK_FILE, "0")) or 0
    return (now - last_swap) >= COOLDOWN_SEC
end

local function recover_modem(reason)
    log_msg(string.format("Health check failed (%s). Initiating recovery...", reason))

    write_file(SWAP_LOCK_FILE, os.time())

    init_gpio(GPIO_SELC, "out")
    init_gpio(GPIO_RESET, "out")

    local selc_path = "/sys/class/gpio/gpio" .. GPIO_SELC .. "/value"
    local current_slot = tonumber(read_file(selc_path, "0")) or 0
    local new_slot = (current_slot == 0) and 1 or 0

    write_file(selc_path, new_slot)
    log_msg(string.format("Switched SIM slot (GPIO %s) to %d", GPIO_SELC, new_slot))

    os.execute(string.format("ifdown %s 2>/dev/null", INTERFACE_MODEM))

    local reset_path = "/sys/class/gpio/gpio" .. GPIO_RESET .. "/value"
    write_file(reset_path, "1")
    nixio.nanosleep(3, 0)
    write_file(reset_path, "0")

    log_msg("Hardware reset pulse executed. Waiting 15s for SIMCOM boot...")
    nixio.nanosleep(15, 0)

    os.execute(string.format("ifup %s 2>/dev/null", INTERFACE_MODEM))
    log_msg("Interface " .. INTERFACE_MODEM .. " re-enabled.")
end

log_msg(string.format("Watchdog service started. Checking '%s' every %ds.", INTERFACE_MODEM, CHECK_INTERVAL))

while true do
    local healthy, reason = is_modem_healthy()

    if not healthy then
        if can_execute_action() then
            recover_modem(reason)
        end
    end

    nixio.nanosleep(CHECK_INTERVAL, 0)
end
