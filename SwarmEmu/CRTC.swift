//
//  CRTC.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 6/4/2024.
//

import Foundation
import SwiftUI

class CRTC : ObservableObject {
    
    var pcgram = Array<Float>(repeating: 0,count:4096)
    var screenram = Array<Float>(repeating: 32,count:2048)
    
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
    
    var xcursor : Float = 1
    var ycursor : Float = 1
    
    //@Published var screenbitmap = Array<Bool>(repeating: false,count:168960)
    //@Published var screenbitmap = Array(repeating: Array(repeating: false, count: 80*8),count:11*24)
    
    func ClearScreen()
    {
        //for MyIndex in 0..<168960
       // {
       //     screenbitmap[MyIndex] = false
       // }
        for MyIndex in 0..<2048
        {
            screenram[MyIndex] = 32
        }
        
        xcursor = 1
        ycursor = 1
    }
    
   init ()
    
    {
        var pcgindex : Int = 0
    
        if let urlPath = Bundle.main.url(forResource: "charrom", withExtension: "bin") {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    pcgram[pcgindex] = Float(MyIndex)
                    pcgindex = pcgindex + 1
                }
            } catch {
                print("Problem with character rom")
            }
        } else {
            print("Can't find character rom")
        }
        
        ClearScreen()
        printline("SwarmEmu To-do list\n\n")
        printline("* Emulate Z80\n")
        printline("* Emulate CRTC\n")
        printline("* Emulate Keyboard\n")
        printline("* Emulate Sound\n")
        printline("* Load Basic\n")
        printline("* Run Games\n\n")
        //updatebuffer()
    }
    
    func updatebuffer ()
    
    {
//        var startpos : Int
//        var startpos2 : Int
//        
//        var bit7 : Bool
//        var bit6 : Bool
//        var bit5 : Bool
//        var bit4 : Bool
//        var bit3 : Bool
//        var bit2 : Bool
//        var bit1 : Bool
//        var bit0 : Bool
//        
//        var dxpos : Int
//        var dypos : Int
//        
//        print("update buffer")
//        print(Date().timeIntervalSince1970)
//        
//        for BufferIndex in 0..<xcolumns*yrows-1
//                
//        {
//            startpos = Int(screenram[BufferIndex])*16+charoffset
//            //print(BufferIndex,screenram[BufferIndex],UnicodeScalar(screenram[BufferIndex]))
//            dxpos = BufferIndex % xcolumns
//            dypos = BufferIndex / xcolumns
//            for MyIndex in 0..<ypixels
//            {
//                bit7 = ((Int(pcgram[startpos+MyIndex]) & 0b10000000) >> 7) == 1
//                bit6 = ((Int(pcgram[startpos+MyIndex]) & 0b01000000) >> 6) == 1
//                bit5 = ((Int(pcgram[startpos+MyIndex]) & 0b00100000) >> 5) == 1
//                bit4 = ((Int(pcgram[startpos+MyIndex]) & 0b00010000) >> 4) == 1
//                bit3 = ((Int(pcgram[startpos+MyIndex]) & 0b00001000) >> 3) == 1
//                bit2 = ((Int(pcgram[startpos+MyIndex]) & 0b00000100) >> 2) == 1
//                bit1 = ((Int(pcgram[startpos+MyIndex]) & 0b00000010) >> 1) == 1
//                bit0 = ((Int(pcgram[startpos+MyIndex]) & 0b00000001) >> 0) == 1
//                
//                startpos2 = (dypos*maxcanvasx*ypixels)+(MyIndex*maxcanvasx)+(dxpos*8)
//                screenbitmap[startpos2] = bit7
//                screenbitmap[startpos2+1] = bit6
//                screenbitmap[startpos2+2] = bit5
//                screenbitmap[startpos2+3] = bit4
//                screenbitmap[startpos2+4] = bit3
//                screenbitmap[startpos2+5] = bit2
//                screenbitmap[startpos2+6] = bit1
//                screenbitmap[startpos2+7] = bit0
//            }
//        }
//        print(Date().timeIntervalSince1970)

    }

    func printstring( _ message : String, _ xpos : Int, _ ypos : Int )
    
    {
        var xposition : Int = 0
        
        for ascii in message
        {
          if xpos+xposition < 64
            {
              screenram[ypos*xcolumns+xpos+xposition] = Float(ascii.asciiValue ?? 0)
              //print(xpos,ypos,ypos*xcolumns+xpos+xposition,ascii.asciiValue,ascii)
              xposition = xposition+1
            }
        }
    }
    
    func printline( _ message : String )
    
    {
        for ascii in message
        {
          if xcursor <= Float(xcolumns)
            {
              if ascii.asciiValue == 10
              {
               xcursor = Float(xcolumns+1)
              }
              else
              {
                  screenram[Int(ycursor-1)*xcolumns+Int(xcursor)-1] = Float(ascii.asciiValue ?? 0)
                  //print(xpos,ypos,ypos*xcolumns+xpos+xposition,ascii.asciiValue,ascii)
                  xcursor = xcursor+1
              }
            }
          if xcursor > Float(xcolumns)
            {
             xcursor = 1
             ycursor = ycursor+1
            }
          if ycursor > Float(yrows)
            {
              ycursor = Float(yrows)
              for index in 0..<(yrows-1)*xcolumns
              {
               screenram[index] = screenram[index+xcolumns]
              }
              for index in (yrows-1)*xcolumns..<yrows*xcolumns
              {
               screenram[index] = 32
              }
            }
        }
    }
}
