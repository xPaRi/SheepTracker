----------------------------------------------
-- Utility pro Sheep Tracker
----------------------------------------------

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

-- Zaokrouhleni
function Round(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    
	return math.floor(num * mult + 0.5) / mult
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
    if (data[7] == "0" or data[3] == nil or data[5] == nil) then
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