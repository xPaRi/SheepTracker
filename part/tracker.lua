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

-- Vraci objekt informace $GPGSV (satelity)
function GetGPGSV(data)
    return {SatNum=tonumber(data[2]) or 0, SatInView=tonumber(data[4]) or 0}
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
local satNum = nil    -- pocet analyzovanych satelitu
local satTotal = nil  -- pocet satelitu na obloze
local horDil = nil    -- horizontalni presnost

local lastLat = nil   -- posledni zemepisna delka
local lastLon = nil   -- posledni zemepisna sirka
local dataGPGSV = nil -- posledni zprava o satelitech
local dataGPGGA = nil -- posledni zprava o souradnicich

local showPrec = false -- indikuje, zda se bude zobrazovat presnost nebo pocet satelitu

DisableUnnecessaryMessage()

while true do
    
    
    -- Cteme zpravu z GPS
    local msg = uart.read(uart.UART1, "*l", 5000)
    
    if (msg ~= nil and msg:len() > 0) then
        print(msg)
        
        local amsg=Split(msg, ",")

        if (amsg[1] == "$GPGSV") then
            dataGPGSV = GetGPGSV(amsg)
        elseif (amsg[1] == "$GPGGA") then
            dataGPGGA = GetGPGGA(amsg)
        elseif (amsg[1] == "$GPGLL") then -- indikuje posledni zpravu, takze neco zobrazime
            gdisplay.clear()

            showPrec = not showPrec

            if (dataGPGSV ~= nil and not showPrec) then
                gdisplay.write(32,1, "SAT: "..dataGPGSV.SatNum.."/"..dataGPGSV.SatInView)
            end
            
            if (dataGPGGA ~= nil) then
                if (showPrec) then
                    gdisplay.write(32,1, "PRE: "..dataGPGGA.Prec)
                end

                gdisplay.write(32,9, tostring(dataGPGGA.Lat)) --4921.11621N
                gdisplay.write(32,17, tostring(dataGPGGA.Lon)) --1751.01021E
            end

            print()
        end
    end
end
