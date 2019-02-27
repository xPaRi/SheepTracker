-- osahani rozliseni
function test1()
	gdisplay.attach(gdisplay.SSD1306_128_64, gdisplay.LANDSCAPE_FLIP, false, 0x3C)

	gdisplay.on()

	gdisplay.clear()
	gdisplay.setfont(gdisplay.FONT_LCD)

	local w, h = gdisplay.getscreensize()

	gdisplay.write(1,20, "res: " .. w .. " x " .. h .. " px")

	gdisplay.putpixel(1,1)
	gdisplay.putpixel(127,1)
	gdisplay.putpixel(127,63)
	gdisplay.putpixel(1,63)

	-- zluta cast (dole smerem k MCU)
	gdisplay.putpixel(1,48)

	print ("res: " .. w .. "x" .. h)
end

-- nastaveni pro pouzit v Sheep trackeru
function Test2()
	gdisplay.attach(gdisplay.SSD1306_128_64, gdisplay.LANDSCAPE_FLIP, false, 0x3C)
 
	gdisplay.on()
         
 	gdisplay.clear()
                 
end

Test2()