function tf(id)
    fontList = 
    { gdisplay.FONT_DEFAULT	
    , gdisplay.FONT_DEJAVU18	
    , gdisplay.FONT_DEJAVU24	
    , gdisplay.FONT_UBUNTU16	
    , gdisplay.FONT_COMIC24	
    , gdisplay.FONT_TOONEY32	
    , gdisplay.FONT_MINYA24	
    , gdisplay.FONT_7SEG	
    , gdisplay.FONT_LCD}

    gdisplay.clear()
    gdisplay.setfont(fontList[id])
    gdisplay.write({1,20}, "SAT 12345")
end