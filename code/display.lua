---------------
-- Word data --
---------------

-- word = {position, length}
five    = {12, 4}
ten     = {31, 3}
quarter = {23, 7}
twenty  = {17, 6}
half    = {7, 4}
oclock  = {100, 6}
past    = {41, 4}
to      = {40, 2}

hours = {
    {67, 6},
    {34, 3},
    {57, 3},
    {73, 5},
    {45, 4},
    {107, 4},
    {51, 3},
    {78, 5},
    {95, 5},
    {62, 4},
    {86, 3},
    {89, 6}
}

phrases = {
    {oclock},
    {five, past},
    {ten, past},
    {quarter, past},
    {twenty, past},
    {twenty, five, past},
    {half, past},
    {twenty, five, to},
    {twenty, to},
    {quarter, to},
    {ten, to},
    {five, to}
}


-------------
-- Display --
-------------

TIME_STEP = 5 -- ms
BRIGHTNESS = 96

function display_update(words)

    -- Copy buffer to buf_old
    buf_old:mix(256, buf_new)

    -- Fill buf_new
    buf_new:fill(0,0,0)
    for i,v in ipairs(words) do
        for x = v[1], v[1]+v[2]-1 do
            buf_new:set(x, 255, 255, 255)
        end
    end

    tmr.alarm(1, TIME_STEP, tmr.ALARM_AUTO, crossfade)

end

step = 0
function crossfade()

    fb:mix(256 - step, buf_old, step, buf_new)
    update_brightness()

    -- Stop timer at the end
    if step == 256 then
        tmr.unregister(1)
        step = 0
    else
        step = step + 1
    end    
    
end

function update_brightness()

    BRIGHTNESS = 8 + (adc.read(0) - 30) * 56 / 994

    fb2:mix(BRIGHTNESS, fb)
    ws2812.write(fb2)

end
