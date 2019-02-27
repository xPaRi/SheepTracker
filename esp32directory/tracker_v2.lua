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

function DisableUnnecessaryMessage()
    uart.write(uart.UART1, "$PUBX,40,GSA,0,0,0,0,0,0*4E\n")
    uart.write(uart.UART1, "$PUBX,40,GSV,0,0,0,0,0,0*59\n")
    uart.write(uart.UART1, "$PUBX,40,RMC,0,0,0,0,0,0*47\n")
    uart.write(uart.UART1, "$PUBX,40,VTG,0,0,0,0,0,0*5E\n")
    uart.write(uart.UART1, "$PUBX,40,GLL,0,0,0,0,0,0*5C\n")
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

-- Inicializace displeje
-- Dosazitelne souradnice displeje jsou: [32;1] - [95;23]
gdisplay.attach(gdisplay.SSD1306_128_32, gdisplay.LANDSCAPE_FLIP, true, 0x3C)
gdisplay.on()
gdisplay.setfont(gdisplay.FONT_LCD)

-- Inicializace seriove linky
uart.pins()
uart.attach(uart.UART1, 9600, 8, uart.PARNONE, uart.STOP1)

-- GPS
local lastLat = nil   -- posledni zemepisna delka
local lastLon = nil   -- posledni zemepisna sirka
local kLat = 1 -- koeficient prepoctu zmeny zemepisne delky (0.00001) na metry
local kLon = 1 -- koeficient prepoctu zmeny zemepisne sirky (0.00001) na metry
local distSum = 0     -- soucet vsech vzdalenosti

DisableUnnecessaryMessage() --vypneme zpravy, ktere nepotrebujeme

-- V cyklu cteme zpravu z GPS
while true do
    
    local msg = uart.read(uart.UART1, "*l", 5000)
    
    if (msg ~= nil and msg:len() > 0) then
        print(msg)
        
        local data = Split(msg, ",")

        if (data[1] == "$GPGGA") then -- souradnice
            local gga = GetGPGGA(data)

            if (gga.Fix> 0) then
                local dLat = math.abs((lastLat or gga.Lat) - gga.Lat) * kLat
                local dLon = math.abs((lastLon or gga.Lon) - gga.Lon) * kLon
            
                local dist = math.sqrt(dLat^2 + dLon^2)                
                distSum = distSum + dist
            
                lastLat = gga.Lat
                lastLon = gga.Lon      

                gdisplay.clear()

                gdisplay.write(32, 1, gga.Prec.." ("..gga.Sat..")") --4.6 (3)

                gdisplay.write(32, 9, tostring(dist))
                gdisplay.write(32,17, tostring(distSum))


                --gdisplay.write(32, 9, tostring(gga.Lat)) --492111621.0
                --gdisplay.write(32,17, tostring(gga.Lon)) --175101021.0
            else
                gdisplay.write(32, 1, gga.Prec.." ("..gga.Sat..")") --4.6 (3)

                gdisplay.write(32, 9, "Fix")
                gdisplay.write(32,17, "not valid")

            end
        
            print(gga.Prec.." ("..gga.Sat..")", gga.Lat, gga.Lon)
        end
    end
end
--
