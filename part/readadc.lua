channel = adc.attach(adc.ADC1, pio.GPIO32)

raw, mv = channel:read()

print(raw, mv)


-- 1306	1202.0 => 3.691

-- bat http://sa.tipa.eu/datasheet/04250245-datasheet-en.pdf
-- 4.2 V MAX
-- 3.0 V MIN