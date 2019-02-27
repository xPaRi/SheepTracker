--[[ 

1. Program cte data z GPS prijimace po seriovem portu
2. Na data ceka 5 sekund
3. Prazdne radky pocitaji, ale nevypisuji
4. GPS prijimac je GPS Modul GY-NEO6MV2
5. Zapojeni
   ESP.TX (gpio 13) -> GPS.RX
   ESP.RX (gpio 12) -> GPS.TX
   
]]


uart.pins()

uart.attach(uart.UART1, 9600, 8, uart.PARNONE, uart.STOP1)

count = 1

uart.write(uart.UART1, "AT")
while true do
    
    local msg = uart.read(uart.UART1, "*l", 5000)
    
    if (msg ~= nil and msg:len() > 0) then
        print("#" .. count .. " " .. msg)
        
        if (msg:sub(1,6) == "$GPGLL") then
            print()
        end
    end
    
    count = count + 1
end