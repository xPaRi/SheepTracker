Wiki
----
https://github.com/whitecatboard/Lua-RTOS-ESP32/wiki

GPS Modul GY-NEO6MV2
https://laskarduino.cz/vstupni-periferie-ostatni/133003-gps-modul-gy-neo6mv2.html?gclid=Cj0KCQiAvebhBRD5ARIsAIQUmnnyWQ9Go68mATNubpKxbcNfmYPXtuhycrhn0mJt7Xp-FpjrS-VW-xwaAoTXEALw_wcB
ublox/u-blox NEO-6M GPS modul s anténou a vestavěnou EEPROM. Tento modul je kompatibilní s APM2 a APM2.5. Na EEPROM lze uložit všechna vaše konfigurační data.

Specifikace:
Napájení: 3.3V / 5V
Vestavěná EEPROM pamět
Keramická anténa, super signál!
LED indikace
Přenosová rychlost: 9600
Rozhraní: RS232 TTL
Rozměry desky: 25mm x 35mm
Rozměry antény: 25mm x 25mm x 8mm
Hmotnost: 19 g
Modul je kompatibilní s APM2 a APM2.5

Součástí dodávky:
1ks GPS Modul GY-NEO6MV2
1ks Anténa.

Zobrazovač
----------
ESP32: 
 SDA (pin 22)
 SCL (pin 21)

DISP viz. obrázek

Screen Size: 64x48 pixels (0.66” Across)
Operating Voltage: 3.3V
Driver IC: SSD1306
Interface: IIC(I2C)
IIC Address: 0x3C (or 0x3D)

Vzorec do Excelu
----------------
https://exceltown.com/navody/postupy-a-spinave-triky/zajimave-kombinace-funkci/vzdalenost-dvou-mist-na-zemi-podle-gps-souradnic/
=ACOS(COS(RADIANS(90-A2))*COS(RADIANS(90-A3))+SIN(RADIANS(90-A2))*SIN(RADIANS(90-A3))*COS(RADIANS(B2-B3)))*6371

- A2 je první zeměpisná šířka, A3 délka druhého místa
- B2 je první zeměpisná délka, B3 délka druhého místa
- 6371 je poloměr země. Pokud jsou místa na jiné planetě, dosaďte příslušnou hodnotu...
- Souřadnice jsou zadané ve stupních, minuty jsou převedeny na desetinná místa stupňů
- Jižní zeměpisná šířka se převádí na záporné hodnoty
- Západní šířka také

https://prevodyonline.eu/cz/souradnice.html
http://www.astromik.org/raspi/50.htm

Vypínání zasílaných zpráv NEO 6M GPS modulu 
-------------------------------------------
(http://www.astromik.org/raspi/50.htm)

Funguje jen do restartu GPS modulu

1. zmena baund rate na 19200 
  $PUBX,41,1,0007,0003,19200,0*25 

2. vypnuti GSV,GLL,VTG,RMC,GSA 
  $PUBX,40,GSV,0,0,0,0,0,0*59 
  $PUBX,40,GLL,0,0,0,0,0,0*5C 
  $PUBX,40,VTG,0,0,0,0,0,0*5E 
  $PUBX,40,RMC,0,0,0,0,0,0*47 
  $PUBX,40,GSA,0,0,0,0,0,0*4E 

3. Zapnuti vysielania GGA a GSV kazdych 5s na UART 
  $PUBX,40,GGA,0,5,0,0,0,0*5F 
  $PUBX,40,GSV,0,5,0,0,0,0*5C 