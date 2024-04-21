//
//  CRTC.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 6/4/2024.
//

import Foundation
import SwiftUI

class CRTC : ObservableObject {
    
    var pcgram = Array<UInt8>(repeating: 0,count:4096)
    var screenram = Array<UInt8>(repeating: 32,count:2048)
    
    var xzoom : Int = 1
    var yzoom : Int = 2
    
    var xpixels : Int = 8
    var ypixels : Int = 16
    
    var xcolumns : Int = 64
    var yrows : Int = 16
    
    var maxcanvasx : Int = 640
    var maxcanvasy : Int = 264
    
    var canvasx : Int = 512
    var canvasy : Int = 256
    
    var bitmapsize : Int = 168960
    
    var charoffset : Int = 0
    
    @Published var screenbitmap = Array<Bool>(repeating: false,count:168960)
    //@Published var screenbitmap = Array(repeating: Array(repeating: false, count: 80*8),count:11*24)
    
    func ClearScreen()
    {
        for MyIndex in 0..<168960
        {
            screenbitmap[MyIndex] = false
        }
        for MyIndex in 0..<2048
        {
            screenram[MyIndex] = 32
        }
    }
    
   init ()
    
    {
        var pcgindex : Int = 0
    
        if let urlPath = Bundle.main.url(forResource: "charrom", withExtension: "bin") {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    pcgram[pcgindex] = MyIndex
                    pcgindex = pcgindex + 1
                }
            } catch {
                print("Problem with character rom")
            }
        } else {
            print("Can't find character rom")
        }
        
        ClearScreen()
        printstring("SwarmEmu To-do list",0,0)
        printstring("* Emulate Z80",0,1)
        printstring("* Emulate CRTC",0,2)
        printstring("* Emulate Keyboard",0,3)
        printstring("* Emulate Sound",0,4)
        printstring("* Load Basic",0,5)
        printstring("* Run Games",0,6)
        updatebuffer()
    }
    
    func updatebuffer ()
    
    {
        var startpos : Int
        
        var bit7 : Bool
        var bit6 : Bool
        var bit5 : Bool
        var bit4 : Bool
        var bit3 : Bool
        var bit2 : Bool
        var bit1 : Bool
        var bit0 : Bool
        var dxpos : Int
        var dypos : Int
        
        for BufferIndex in 0..<2048
                
        {
            startpos = Int(screenram[BufferIndex])*16+charoffset
            //print(BufferIndex,screenram[BufferIndex],UnicodeScalar(screenram[BufferIndex]))
            dxpos = BufferIndex % xcolumns
            dypos = BufferIndex / xcolumns
            for MyIndex in 0..<ypixels
            {
                bit7 = ((pcgram[startpos+MyIndex] & 0b10000000) >> 7) == 1
                bit6 = ((pcgram[startpos+MyIndex] & 0b01000000) >> 6) == 1
                bit5 = ((pcgram[startpos+MyIndex] & 0b00100000) >> 5) == 1
                bit4 = ((pcgram[startpos+MyIndex] & 0b00010000) >> 4) == 1
                bit3 = ((pcgram[startpos+MyIndex] & 0b00001000) >> 3) == 1
                bit2 = ((pcgram[startpos+MyIndex] & 0b00000100) >> 2) == 1
                bit1 = ((pcgram[startpos+MyIndex] & 0b00000010) >> 1) == 1
                bit0 = ((pcgram[startpos+MyIndex] & 0b00000001) >> 0) == 1
                
                if bit7 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)] = true
                }
                if bit6 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+1] = true
                }
                if bit5 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+2] = true
                }
                if bit4 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+3] = true
                }
                if bit3 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+4] = true
                }
                if bit2 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+5] = true
                }
                if bit1 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+6] = true
                }
                if bit0 {
                    screenbitmap[(dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)+7] = true
                }
            }
        }

    }

    func printstring( _ message : String, _ xpos : Int, _ ypos : Int )
    
    {
        
        var xposition : Int = 0
        
        for ascii in message
        {
          if xpos+xposition < 64
            {
              screenram[ypos*xcolumns+xpos+xposition] = ascii.asciiValue ?? 0
              //print(xpos,ypos,ypos*xcolumns+xpos+xposition,ascii.asciiValue,ascii)
              xposition = xposition+1
            }
        }
    }
}
