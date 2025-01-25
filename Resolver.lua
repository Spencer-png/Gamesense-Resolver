local json = require("json")
local http = require('gamesense/http')

ui.new_label("CONFIG", "Lua", "\aFF4040FF -------> Resolver Coded by Spencer <------- ")
ui.new_label("CONFIG", "Lua", "\aFF4040FF ------> Full Machine Learning Resolver <------")

client.color_log(0,255,0, "[MLR] Machine Learning Resolver Successfully Loaded!, Coded by Spencer")
client.color_log(255, 0, 0, "[MLR] Dont forgot to start your local http server")

json.encode_number_precision(6)
json.encode_sparse_array(true, 2, 10)

local resolver = {
    history = {},
    player_records = {},
    last_simulation_time = {}
}

local HTTP_HOST = "http://127.0.0.1:8080"

local function http_post(data, callback)
    local success, encoded_data = pcall(json.stringify, data)
    if not success then
        return nil
    end

    http.post(HTTP_HOST, {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = encoded_data
    }, function(success, response)
        if not success or not response.body then
            return
        end

        local success, decoded_response = pcall(json.parse, response.body)
        if success then
            if callback then
                callback(decoded_response)
            end
        else
            print("Failed to parse JSON response:", decoded_response)
        end
    end)
end

local function get_targets()
    return entity.get_players(true)
end

local function get_hitbox_position(player, hitbox)
    local x, y, z = entity.hitbox_position(player, hitbox)
    return x and {x = x, y = y, z = z} or nil
end

function resolver.record_player(player)
    if not entity.is_alive(player) then return end

    local steam_id = entity.get_steam64(player)
    if not steam_id then return end

    if not resolver.player_records[steam_id] then
        resolver.player_records[steam_id] = {
            last_angles = {},
            desync_history = {},
            shot_records = {},
            missed_shots = 0,
            learned_side = nil
        }
    end

    local sim_time = entity.get_prop(player, "m_flSimulationTime")
    local eye_angles = {entity.get_prop(player, "m_angEyeAngles")}

    if sim_time ~= resolver.last_simulation_time[steam_id] then
        table.insert(resolver.player_records[steam_id].last_angles, {
            angles = eye_angles,
            sim_time = sim_time,
            hitbox_pos = get_hitbox_position(player, 0)
        })

        if #resolver.player_records[steam_id].last_angles > 8 then
            table.remove(resolver.player_records[steam_id].last_angles, 1)
        end

        resolver.last_simulation_time[steam_id] = sim_time
    end
end

function resolver.resolve_angles(player)
    local steam_id = entity.get_steam64(player)
    if not steam_id or not resolver.player_records[steam_id] then return end

    local records = resolver.player_records[steam_id]
    if #records.last_angles < 2 then return end

    local angle_delta = records.last_angles[#records.last_angles].angles[2] - records.last_angles[#records.last_angles - 1].angles[2]
    local desync_side = angle_delta > 0 and 1 or -1
    table.insert(records.desync_history, desync_side)

    if #records.desync_history > 5 then
        table.remove(records.desync_history, 1)
    end

    http_post({
        steam_id = tostring(steam_id),
        desync_history = records.desync_history,
        missed_shots = records.missed_shots
    }, function(response)
        if response and response.learned_side then
            records.learned_side = response.learned_side
        end
    end)

    local resolve_angle = records.last_angles[#records.last_angles].angles[2]
    if records.learned_side then
        resolve_angle = resolve_angle + (58 * records.learned_side)
    end

    return resolve_angle
end

function resolver.on_shot_fired(e)
    local target = e.target
    if not target then return end

    local steam_id = entity.get_steam64(target)
    if not steam_id or not resolver.player_records[steam_id] then return end

    table.insert(resolver.player_records[steam_id].shot_records, {
        tick = e.tick,
        predicted_angle = resolver.player_records[steam_id].last_angles[#resolver.player_records[steam_id].last_angles],
        hit = e.hit,
        teleported = e.teleported
    })

    if not e.hit then
        resolver.player_records[steam_id].missed_shots = resolver.player_records[steam_id].missed_shots + 1
    else
        resolver.player_records[steam_id].missed_shots = 0
    end
end

local last_update = globals.realtime()
function resolver.update()
    if globals.realtime() - last_update < 0.1 then return end
    last_update = globals.realtime()

    local targets = get_targets()
    for _, player in ipairs(targets) do
        resolver.record_player(player)
        local resolved_angle = resolver.resolve_angles(player)

        if resolved_angle then
            plist.set(player, "Force body yaw value", resolved_angle)
        end
    end
end

client.set_event_callback("paint", resolver.update)
client.set_event_callback("aim_fire", resolver.on_shot_fired)