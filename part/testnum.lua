--$GPGLL,4921.11621,N,01751.01021,E,184216.00,A,A*6A 


function GetLat(str)
    deg = tonumber(str:sub(1,2)) * 100000
    min = tonumber(str:sub(3,10)) / 6 * 10000
    
    return deg + min
end

function GetLon(str)
    deg = tonumber(str:sub(1,3)) * 100000
    min = tonumber(str:sub(4,11)) / 6 * 10000

    return deg + min
end


lat = GetLat("4922.11621") --> 49.36860 (49.3686035)
lon = GetLon("01751.01021") --> 17.85017 (17.850170166667)

print(string.format("%0f", lat))
print(string.format("%0f", lon))
