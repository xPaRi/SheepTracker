-- cteni 84x vycasovaneho uatu privede esp k restartu
-- testujeme, zda se da cist bez vycasovani

-- Attach an UART device to UART2, 115200 bps, 8N1
uart.attach(uart.UART2, 115200, 8, uart.PARNONE, uart.STOP1)

-- Read line from UART, with a 500 milliseconds timeout
uart.read(uart.UART2, "*el", 24*60*60*1000)

-- nejde to, protoze parametr je povinny a proste by doslo jak jako tak
-- k prekroceni cca 84 vycasovani a k naslednemu restartu