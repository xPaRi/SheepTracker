require "utils"

-- Inicializace displeje
-- Vykresleni masky masku pro vpisovani hodnot
function InitDisplay()
    -- Inicializace
    gdisplay.attach(gdisplay.SSD1306_128_64, gdisplay.LANDSCAPE_FLIP, false, 0x3C)
	gdisplay.on()
    gdisplay.clear()
    gdisplay.settransp(false) -- co je za tectem bude prepsano

    -- Pozice
    SAT_Y = 48

    -- Maska
    gdisplay.line({1,10}, {127,10}, gdisplay.WHITE)

    gdisplay.setfont(gdisplay.FONT_DEFAULT)
    gdisplay.write({3,35}, "DST")

    gdisplay.line({1,SAT_Y}, {127,SAT_Y}, gdisplay.WHITE)
    gdisplay.setfont(gdisplay.FONT_LCD)
    gdisplay.write({38,SAT_Y+4}, "M")
    gdisplay.write({90,SAT_Y+4}, "SAT")
    --
end

-- Inicializace managementu akumulatoru
-- Definice promennych a konstant pro potrebne prepocty
function InitBatteryMgmt()
    BatChannel = adc.attach(adc.ADC1, pio.GPIO32) -- ADC1 na GPIO32

    BAT_MIN = 3.1
    BAT_MAX = 4.11
    BAT_DELTA = BAT_MAX - BAT_MIN
    BAT_K = BAT_DELTA / 100

    ADC1_K = 0.003070715 -- koeficient prepoctu z mV ADC na volty
    
    BatVolt = 0 -- napeti baterie
    BatPerc = 0 -- napeti baterie v procentech
end

-- Inicializace tlačítka pro nulování
function InitClr()
    ClrPin = pio.GPIO17
    ClrFlag = false -- indikuje stisk mazaciho tlacitka

    pio.pin.setdir(pio.INPUT, ClrPin)
    pio.pin.setpull(pio.PULLUP, ClrPin)
end

-- Inicializace GPS modulu
-- Definice promennych
function InitGps()
    IsShowMsg = false   -- indikuje, zda bude zobrazovana GPS zprava

    SatCount = 0        -- pocet zpracovavanych satelitu
    SatPrecision = nil  -- presnost urceni polohy
    SatFixed = false    -- indikace fixace polohy

    LastLat = nil       -- posledni zemepisna delka
    LastLon = nil       -- posledni zemepisna sirka
    KlatX = 1.1015      -- koeficient prepoctu zmeny zemepisne delky (0.00001) na metry v X
    KlatY = 0.1544      -- koeficient prepoctu zmeny zemepisne delky (0.00001) na metry v Y
    KlonX = -0.0987     -- koeficient prepoctu zmeny zemepisne sirky (0.00001) na metry v X
    KlonY = 0.7041      -- koeficient prepoctu zmeny zemepisne sirky (0.00001) na metry v Y

    Distance = 0        -- urazena vzdalenost

    uart.attach(uart.UART1, 9600, 8, uart.PARNONE, uart.STOP1, 2048)
    DisableUnnecessaryMessage()
end

-- Funkce pro vlakno ctouci jednou za cas napeti v akumulatoru
function BatteryThread()
    while(IsRun) do
        raw, millivolts = BatChannel:read()

        DispMutex:lock()
	    BatVolt = millivolts * ADC1_K
        BatPerc = (BatVolt - BAT_MIN) / BAT_K
        DispMutex:unlock()

        thread.sleep(5)
    end
end

-- Funkce pro vlakno ctouci vstup tlacitka pro nulovani
function ClrThread()
    while(IsRun) do
        local press = pio.pin.getval(ClrPin) == 0

        if (press) then
            DispMutex:lock()
            gdisplay.rect({32, 14},92,33, gdisplay.WHITE, gdisplay.WHITE)
            ClrFlag = true
            DispMutex:unlock()
        elseif(ClrFlag) then
            DispMutex:lock()
            Distance = 0
            ClrFlag = false
            DispMutex:unlock()
        end

        thread.sleepms(50)
    end
end

-- Funkce pro vlakno ctouci data z Gps
function GpsThread()
    uart.consume(uart.UART1) -- sezereme vse, co je ve fronte

    while(IsRun) do
        -- protoze se po 84x vycasovani vsecko sesype, cekama radeji 24 hodin na dalsi zpravu
        local msg = uart.read(uart.UART1, "*el", 24*60*60*1000)

        if (msg ~= nil and msg:len() > 35 and msg:sub(1,6)=="$GPGGA" and msg:len() < 90) then
            if (IsShowMsg) then
                print(msg)
            end
    
            local gga = GetGPGGA(Split(msg, ","))

            if (gga.Fix > 0) then
                local tempLat = math.abs((LastLat or gga.Lat) - gga.Lat)
                local tempLon = math.abs((LastLon or gga.Lon) - gga.Lon)

                local dLat = (tempLat * KlatX) + (tempLon * KlonX)
                local dLon = (tempLon * KlonY) + (tempLat * KlatY)

                local dist = math.sqrt(math.abs(dLat^2 + dLon^2))
                
                if (dist < 0.5) then
                    dist = 0
                end

                DispMutex:lock()
                Distance = Distance + dist
                SatPrecision = gga.Prec
                SatFixed = true
                SatCount = gga.Sat
                DispMutex:unlock()

                LastLat = gga.Lat
                LastLon = gga.Lon
            else
                DispMutex:lock()

                SatPrecision = nil
                SatFixed = false
                SatCount = nil

                DispMutex:unlock()
            end
        end
    end
end

-- Funkce pro vlakno vykreslujici jednou za cas udaje na display
function DisplayThread()
    local fixFlag = true --zajistuje poblikavani FIX
    local lastDistance = nil --posledni vzdalenost (optimalizace vykreslovani)

    while(IsRun) do
        DispMutex:lock()

        -- baterie
        gdisplay.setfont(gdisplay.FONT_LCD)
        gdisplay.write({ 1,1}, Round(BatVolt,2).."V    ", gdisplay.WHITE, gdisplay.BLACK)
        gdisplay.write({105,1}, math.ceil(BatPerc).."%    ", gdisplay.WHITE, gdisplay.BLACK)
        
        -- vzdalenost
        if (ClrFlag) then
            gdisplay.rect({32, 14},92,33, gdisplay.WHITE, gdisplay.WHITE)
            lastDistance = nil
        elseif (lastDistance ~= Distance) then
            gdisplay.setfont(gdisplay.FONT_7SEG)
            gdisplay.rect({32, 14},92,33, gdisplay.BLACK, gdisplay.BLACK)
            --gdisplay.write({35,22}, "888888", gdisplay.BLACK, gdisplay.BLACK) -- mazani (tento font nepodporuje mazani)
            gdisplay.write({35,22}, ("      "..math.ceil(Distance)):sub(-6), gdisplay.WHITE, gdisplay.BLACK)
            lastDistance = Distance
        end

        -- satelity
        gdisplay.setfont(gdisplay.FONT_LCD)

        if (SatPrecision == nil) then
            gdisplay.write({ 3,SAT_Y+4}, "--.--", gdisplay.WHITE, gdisplay.BLACK)
        elseif (SatPrecision<10) then
            gdisplay.write({ 3,SAT_Y+4}, Round(SatPrecision,2).."  ", gdisplay.WHITE, gdisplay.BLACK)
        else
            gdisplay.write({ 3,SAT_Y+4}, Round(SatPrecision,2).." ", gdisplay.WHITE, gdisplay.BLACK)
        end

        if (SatFixed) then
            gdisplay.rect({50, SAT_Y+3},31,10, gdisplay.BLACK, gdisplay.BLACK)
            fixFlag = true
        else
            if (fixFlag) then
                gdisplay.rect({50, SAT_Y+3},31,10, gdisplay.WHITE, gdisplay.WHITE)
                gdisplay.write({57,SAT_Y+4}, "FIX", gdisplay.BLACK, gdisplay.WHITE)
            else
                gdisplay.rect({50, SAT_Y+3},31,10, gdisplay.WHITE, gdisplay.BLACK)
                gdisplay.write({57,SAT_Y+4}, "FIX", gdisplay.WHITE, gdisplay.BLACK)
            end

            fixFlag = not fixFlag
        end

        if (SatCount == nil) then
            gdisplay.write({113,SAT_Y+4}, "--  ", gdisplay.WHITE, gdisplay.BLACK)
        else
            gdisplay.write({113,SAT_Y+4}, math.ceil(SatCount).."  ", gdisplay.WHITE, gdisplay.BLACK)
        end

        DispMutex:unlock()

        thread.sleepms(250)
    end
end

-- Spusti vsechny potrebne thready
function Start()
    IsRun = true

    thDisplay = thread.start(DisplayThread,8192,20,1,"Display")
    thBattery = thread.start(BatteryThread,8192,20,1,"Battery")
    thGps     = thread.start(GpsThread,8192,20,1,"Gps")
    thClr     = thread.start(ClrThread,8192,20,1,"Clr")

    thread.list()
end

-- Zastavi vsechny procesy
function Stop()
    IsRun = false

    thread.list()
    print("Wait for stop...")
    thread.sleep(3)
    thread.list()
end

DispMutex = thread.createmutex(thread.RecursiveLock)
IsRun = true -- timto se daji stopnout vsechny procesy While

InitDisplay()
InitBatteryMgmt()
InitGps()
InitClr()

------------------------------------------------------------
-- Spustime prislusna vlakna
------------------------------------------------------------
Start()

