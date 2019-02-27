-- Zaokrouhleni
function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- Init and clear display
function clr()
	gdisplay.attach(gdisplay.SSD1306_128_64, gdisplay.LANDSCAPE_FLIP, false, 0x3C)
	gdisplay.on()
	gdisplay.clear()
end

-- Wait for GPS fix...
function fnv()
	gdisplay.rect(1,48,127,63,gdisplay.WHITE,gdisplay.WHITE)
	gdisplay.setfont(gdisplay.FONT_DEFAULT)
	gdisplay.write({3,50}, "Wait for GPS fix...",gdisplay.BLACK)
end

-- zobrazi stav baterie
function bat()
	BAT_MIN = 3.1
	BAT_MAX = 4.2
	BAT_DELTA = BAT_MAX - BAT_MIN
	BAT_K = BAT_DELTA / 100

	-- Setup device attached to ADC1 on GPIO32
	channel = adc.attach(adc.ADC1, pio.GPIO32)

	-- Read
	k = 0.003070715

	raw, millivolts = channel:read()
	volts = millivolts * k
	percent = (volts - BAT_MIN) / BAT_K

	gdisplay.rect({1,48},127,16,gdisplay.BLACK, gdisplay.BLACK)
	gdisplay.line({1,48},{127,48},gdisplay.WHITE)
	gdisplay.setfont(gdisplay.FONT_DEFAULT)
	gdisplay.write({1,50}, round(volts,2).."v")
	gdisplay.write({80,50}, round(percent,0).."%")
end

-- zobrazi vzdalenost v metrech (max 99999)
function dist(distance)
	gdisplay.rect({1,22},127,23,gdisplay.BLACK, gdisplay.BLACK)
	gdisplay.setfont(gdisplay.FONT_7SEG)
	gdisplay.write({10,22}, round(distance,0))
	gdisplay.setfont(gdisplay.FONT_DEFAULT)
	gdisplay.write({100,35}, "m")
end

-- zobrazi stav satelitu
function sat(precision, sat)
	gdisplay.setfont(gdisplay.FONT_DEFAULT)
	gdisplay.write({1,1}, round(precision,3).."m")
	gdisplay.write({100,1}, round(sat,0))
	gdisplay.line({1,15},{127,15},gdisplay.WHITE)
end

clr()
--fnv()
sat(1.123456, 16)
bat()
dist(12345)