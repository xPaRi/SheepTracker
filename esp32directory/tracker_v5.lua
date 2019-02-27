--[[ 
1. Program cte data z GPS prijimace po seriovem portu
2. Na data ceka 5 sekund
3. Prazdne radky pocitaji, ale nevypisuji
4. GPS prijimac je GPS Modul GY-NEO6MV2
5. Zapojeni
   ESP.TX (gpio 13) -> GPS.RX
   ESP.RX (gpio 12) -> GPS.TX
6. DISPLAY OLED
7. Zapojeni
   ESP.I2C0SCL (gpio 21) -> DISP.D1
   ESP.I2C0SDA (gpio 22) -> DISP.D2

]]

ledPin = pio.GPIO16   -- onboard LED
clrPin = pio.GPIO4    -- pin pro vymazani

-- GPS
lastLat = nil     -- posledni zemepisna delka
lastLon = nil     -- posledni zemepisna sirka
kLatX = 1.1015    -- koeficient prepoctu zmeny zemepisne delky (0.00001) na metry v X
kLatY = 0.1544    -- koeficient prepoctu zmeny zemepisne delky (0.00001) na metry v Y
kLonX = -0.0987   -- koeficient prepoctu zmeny zemepisne sirky (0.00001) na metry v X
kLonY = 0.7041    -- koeficient prepoctu zmeny zemepisne sirky (0.00001) na metry v Y
distSum = 0       -- soucet vsech vzdalenosti

-- Rozsvitime onboard LED
function LedOn()
    pio.pin.setlow(ledPin)
end

-- Zhasneme onboard LED
function LedOff()
    pio.pin.sethigh(ledPin)
end

-- Vypne nepotrebne zpravy posilane modulem GPS
function DisableUnnecessaryMessage()
    local msgTable = 
    {   "$PUBX,40,GLL,0,0,0,0,0,0*5C",
        "$PUBX,40,ZDA,0,0,0,0,0,0*44",
        "$PUBX,40,VTG,0,0,0,0,0,0*5E",
        "$PUBX,40,GSV,0,0,0,0,0,0*59",
        "$PUBX,40,GSA,0,0,0,0,0,0*4E",
        "$PUBX,40,RMC,0,0,0,0,0,0*47",
        "$PUBX,40,GNS,0,0,0,0,0,0*41",
        "$PUBX,40,GRS,0,0,0,0,0,0*5D",
        "$PUBX,40,GST,0,0,0,0,0,0*5B",
        "$PUBX,40,TXT,0,0,0,0,0,0*43"
    }

    tmr.delay(1)

    for key, value in ipairs(msgTable) do
        uart.write(uart.UART1, value.."\r\n")
        tmr.delayms(300)
    end
end


-- Ziskavame Latitude z retezce "4921.11621" => 492111621
function GetLat(str)
    local deg = tonumber(str:sub(1,2)) * 100000
    local min = tonumber(str:sub(3,10)) / 6 * 10000
    
    return deg + min
end

-- Ziskavame Longitude z retezce "01751.01021" => 175101021
function GetLon(str)
    local deg = tonumber(str:sub(1,3)) * 100000
    local min = tonumber(str:sub(4,11)) / 6 * 10000

    return deg + min
end

-- Nastriha retezec podle oddelovace
function Split(s, delimiter)
    result = {};
    
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        if (match=="") then
            table.insert(result, "")
        else
            table.insert(result, match)
        end

    end
    
    return result;
end

-- Vraci objekt informace $GPGGA (souradnice, case, satelity, presnost)
function GetGPGGA(data)
    --$GPGGA, 193433.00 , , , , ,0,00,99.99,,,,,,*69 
    if (data[7] == "0") then
        return 
        {
            Utc=data[2],
            Lat=nil,
            Lon=nil,
            Fix=tonumber(data[7]),
            Sat=tonumber(data[8]),
            Prec=tonumber(data[9])
        }
    else
        return
        {
            Utc=data[2],
            Lat=GetLat(data[3]),
            Lon=GetLon(data[5]),
            Fix=tonumber(data[7]),
            Sat=tonumber(data[8]),
            Prec=tonumber(data[9])
        }
    end
end

-- Nacte data z GPS, zpracuje je a zobrazi
function GPS()
    
    LedOn()
    local msg = uart.read(uart.UART1, "*el", 1000)
    LedOff()
    
    if (msg ~= nil and msg:len() > 35 and msg:sub(1,6)=="$GPGGA" and msg:len() < 90) then
        print(msg)
        
        local gga = GetGPGGA(Split(msg, ","))

        if (gga.Fix> 0) then
            local tempLat = math.abs((lastLat or gga.Lat) - gga.Lat)
            local tempLon = math.abs((lastLon or gga.Lon) - gga.Lon)

            local dLat = (tempLat * kLatX) + (tempLon * kLonX)
            local dLon = (tempLon * kLonY) + (tempLat * kLatY)

            local dist = math.sqrt(math.abs(dLat^2 + dLon^2))
            
            if (dist < 0.5) then
                dist = 0
            end
            
            distSum = distSum + dist
        
            lastLat = gga.Lat
            lastLon = gga.Lon      

            gdisplay.clear()
            gdisplay.write(32, 1, gga.Prec.." ("..gga.Sat..")") --4.6 (3)
            gdisplay.write(32, 9, tostring(dist))
            gdisplay.write(32,17, tostring(math.ceil(distSum)))
            --gdisplay.write(32,17, tostring(distSum))
        else
            gdisplay.clear()
            gdisplay.write(32, 1, gga.Prec.." ("..gga.Sat..")") --4.6 (3)
            gdisplay.write(32, 9, "Fix")
            gdisplay.write(32,17, "not valid")
        end
    end
end

-- Inicializace ovladaciho tlacitka
pio.pin.setdir(pio.INPUT, clrPin)
pio.pin.setpull(pio.PULLUP, clrPin)

-- Inicializace onboard LED
pio.pin.setdir(pio.OUTPUT, ledPin)
LedOff()

-- Inicializace displeje
-- Dosazitelne souradnice displeje jsou: [32;1] - [95;23]
gdisplay.attach(gdisplay.SSD1306_128_32, gdisplay.LANDSCAPE_FLIP, true, 0x3C)
gdisplay.on()
gdisplay.setfont(gdisplay.FONT_LCD)

-- Inicializace seriove linky
uart.attach(uart.UART1, 9600, 8, uart.PARNONE, uart.STOP1, 2048)
DisableUnnecessaryMessage() --vypneme zpravy, ktere nepotrebujeme

-- Zmena rychlosti seriove linky na 19200
-- uart.write(uart.UART1, "$PUBX,41,1,0007,0003,19200,0*25\n")
-- uart.attach(uart.UART1, 19200, 8, uart.PARNONE, uart.STOP1)

-- V cyklu cteme zpravu z GPS
while true do
    local press = pio.pin.getval(clrPin) == 0
    
    if (press) then
        distSum = 0
        lastLat = nil
        lastLon = nil
        
        gdisplay.clear(gdisplay.WHITE)
        uart.consume(uart.UART1)
    else
        GPS()
    end
end
--
