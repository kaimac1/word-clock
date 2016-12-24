TIME_SERVER = 'time.windows.com'

--------------------------
-- Time synchronisation --
--------------------------

h = 0
m = 0
h_old = 0
m_old = 0

hr = 0

function is_dst(tm)
    -- April - September: DST
    -- November - February: no DST
    if tm['mon'] > 3 and tm['mon'] < 10 then
        return true
    elseif tm['mon'] < 3 or tm['mon'] > 10 then
        return false
    end

    -- March: DST after 01:00 on last Sunday (ls)
    -- October: DST until 01:00 on last Sunday
    ls = 30 - ((tm['wday'] - tm['day'] + 1) % 7)
    if tm['day'] > ls or (tm['day'] == ls and tm['hour'] > 0) then
        return (tm['mon'] == 3)
    else
        return (tm['mon'] == 10)
    end

end

function time_update()
    -- Get time and date, perform DST correction
    tm = rtctime.epoch2cal(rtctime.get())
    if is_dst(tm) then
        tm['hour'] = (tm['hour'] + 1) % 24
    end
    
    print('Time:', string.format("%02d:%02d:%02d", tm['hour'], tm['min'], tm['sec']))

    -- Compute indices into 'phrases' and 'hours' arrays
    h = tm['hour']
    secs = tm['min'] * 60 + tm['sec']
    m = (secs + 150)/300
    if m > 6 then
        h = (h + 1)
    end
    h = h % 12
    m = m % 12

    -- Update the display if we need to
    if h ~= h_old or m ~= m_old then
        print('Updating')
        h_old = h
        m_old = m
    
        local words = {}
        for _,v in ipairs(phrases[m+1]) do
            table.insert(words, v)
        end
        table.insert(words, hours[h+1])
        display_update(words)    
    end
end

function time_sync()
    sntp.sync(TIME_SERVER, time_sync_ok, time_sync_fail)
end

function time_sync_ok(sec, usec, server)
    print('SNTP sync OK', sec)
    time_update()
    tmr.alarm(2, 10000, tmr.ALARM_AUTO, time_update)
    tmr.alarm(0, 60000, tmr.ALARM_SINGLE, time_sync)
end

function time_sync_fail(error)
    print('SNTP sync failed:', error)
    -- Try again after 5 seconds
    tmr.alarm(0, 5000, tmr.ALARM_SINGLE, time_sync)
end    


----------
-- WiFi --
----------

function wifi_ready(T)
    print('WiFi connected')
    tmr.alarm(0, 5000, tmr.ALARM_SINGLE, time_sync)
end

function wifi_disconnected(T)
    print('Disconnected ('..T.reason..')')
end


function enduser_success()
    print("enduser_setup: success")
end

function enduser_failed(err_num, err_string)
    print("enduser_setup: Err #" .. err_num .. ": " .. err_string)
end

function button_pressed(level)
    print("button pressed")
    wifi.sta.disconnect()
    enduser_setup.start(enduser_success, enduser_failed)
end


-----------
-- Setup --
-----------

print('init')

-- LEDs
ws2812.init()
fb = ws2812.newBuffer(110, 3)
fb2 = ws2812.newBuffer(110, 3)
buf_old = ws2812.newBuffer(110, 3)
buf_new = ws2812.newBuffer(110, 3)
buf_old:fill(0, 0, 0)
ws2812.write(fb)

tmr.alarm(3, 500, tmr.ALARM_AUTO, update_brightness)
    
-- "FLASH" button
gpio.mode(3, gpio.INT)
gpio.trig(3, "down", button_pressed)

-- WiFi events & force connect
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_ready)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnected)
wifi.sta.disconnect()
wifi.sta.connect()
