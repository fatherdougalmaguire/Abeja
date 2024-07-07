//
//  buffer.metal
//  shader test
//
//  Created by Antonio Sanchez-Rivas on 3/5/2024.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 newpcg(float2 position, half4 color, device const float *screenram, int screenramsize, device const float *pcgchar, int pcgcharsize, float xcursorpos, float ycursorpos, float ypixels, float xcolumns, float charoffset, float tick, float cursortype, float cursorstart, float cursorend, float screencolor)
{
    half4 thingy;
    half4 drawingcolor;
    int screenpos;
    int pcgpos;
    int xcursor;
    int ycursor;
    
    switch (int(screencolor)) {
      case 0:
            drawingcolor = half4(1.0,0.749,0,1);
        break;
      case 1:
            drawingcolor = half4(0.2,1,0,1);
        break;
      default:
            drawingcolor = half4(1,1,1,1);
    }
//    if (screencolor > 0)
//    {
//        drawingcolor = half4(1.0,0.749,0,1);
//    }
//    else
//    {
//        drawingcolor = half4(0.2,1,0,1);
//    }
        
    ycursor = int(position.y) % int(ypixels); // 16 refers to pixels high - 16 for 64x16 and 11 for 80x24
    xcursor = int(position.x) % 8;  // 8 refers to pixels wide - 8 for 64x16 and 80x25
    
    screenpos = trunc(position.y/ypixels)*int(xcolumns)+trunc(position.x/8.0); // screenram - 16 refers to pixels high - 16 for 64x16 and 11 for 80x24,8 refers to pixels wide - 8 for 64x16 and 80x25, 64 refers to columns of textp[
    pcgpos = int(charoffset)+int(screenram[screenpos])*16+int(ycursor);  // 16 refers to PCG data - 16 for 64x16 and 80x24
    
    int bitmask = (128 >> int(xcursor));
    
    if ((int(pcgchar[pcgpos]) & bitmask)  > 0 )
    {
        thingy = drawingcolor;
    }
    else
    {
        thingy = half4(0.0,0.0,0.0,1.0);
    }
    
    switch (int(cursortype))  {
        case 0: // 0 = No blinking
            if ((int(position.x) >= int((xcursorpos-1)*8)) && (int(position.x) <= int((xcursorpos*8)-1)) && ( int(position.y) >= int(((ycursorpos-1)*ypixels)+cursorstart)) && ( int(position.y) <= int((int(ycursorpos-1)*ypixels)+cursorend)))
            {
                thingy = drawingcolor;
            }
            break;

        case 1: // 1 = No Cursor
            break;
            
        case 2: // 2 = normal flash
            if (( tick > 20 ) && (int(position.x) >= int((xcursorpos-1)*8)) && (int(position.x) <= int((xcursorpos*8)-1)) && ( int(position.y) >= int(((ycursorpos-1)*ypixels)+cursorstart)) && ( int(position.y) <= int((int(ycursorpos-1)*ypixels)+cursorend)))
            {
                thingy = drawingcolor;
            }
            break;
            
        case 3: // 3 = fast flash
            if (( tick > 10 ) && (int(position.x) >= int((xcursorpos-1)*8)) && (int(position.x) <= int((xcursorpos*8)-1)) && ( int(position.y) >= int(((ycursorpos-1)*ypixels)+cursorstart)) && ( int(position.y) <= int((int(ycursorpos-1)*ypixels)+cursorend)))
            {
                thingy = drawingcolor;
            }
            break;
    }
    return thingy;
}

[[ stitchable ]] half4 interlace ( float2 position, half4 color, float interlaceon )
{
    half4 InterlaceColor = half4(0.0, 0.0, 0.0, 1.0);

    // 2 pixels wide, change for more/less
    // or change fragCoord.y to fragCoord.x for vertical lines
    if ((int(position.y) % 2 == 0) && (interlaceon == 1))
    {
        return InterlaceColor;
    }
    else 
    {
        return color;
    }
}
