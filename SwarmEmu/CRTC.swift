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
    
    var xpixels : Int = 8
    var ypixels : Float = 16
    
    var xcolumns : Float = 64
    var yrows : Float = 16
    
    var maxcanvasx : Int = 640
    var maxcanvasy : Int = 264
    
    var canvasx : Float = 512
    var canvasy : Float = 256
    
    //var bitmapsize : Int = 168960
    
    var charoffset : Float = 0
    
    var xcursor : Float = 1
    var ycursor : Float = 1
    
    var tick : Float = 0
    
    @Published var cursortype : Float = 2 // 0 = No blinking, 1 = No Cursor, 2 = normal flash, 3 = flash flash
    
    var cursorstart :  Float = 15
    var cursorend : Float = 15
    
    //@Published var screenbitmap = Array<Bool>(repeating: false,count:168960)
    //@Published var screenbitmap = Array(repeating: Array(repeating: false, count: 80*8),count:11*24)
    
    func updatetick ()
    {
        var ticklimit : Float
        
        tick = tick+1
        if cursortype == 2
        {
          ticklimit = 40
        }
        else
        {
          ticklimit = 20
        }
        if tick > ticklimit
        {
          tick = 0
        }
        
    }
    
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
    
    init ( startupmessage : String = "")
    
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
        
        printline(startupmessage)
//        printline("Applied Technology MicroBee Colour Basic. Ver 5.22e\n\n")
//        printline("Copyright MS 1983 for MicroWorld Australia\n\n")
//        printline(">")
    }

    func printstring( _ message : String, _ xpos : Int, _ ypos : Int )
    
    {
        var xposition : Int = 0
        
        for ascii in message
        {
          if xpos+xposition < 64
            {
              screenram[ypos*Int(xcolumns)+xpos+xposition] = Float(ascii.asciiValue ?? 0)
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
                  screenram[Int(ycursor-1)*Int(xcolumns)+Int(xcursor)-1] = Float(ascii.asciiValue ?? 0)
                  //print(xpos,ypos,ypos*xcolumns+xpos+xposition,ascii.asciiValue,ascii)
                  xcursor = xcursor+1
              }
            }
          if xcursor > xcolumns
            {
             xcursor = 1
             ycursor = ycursor+1
            }
          if ycursor > yrows
            {
              ycursor = yrows
              for index in 0..<(Int(yrows)-1)*Int(xcolumns)
              {
               screenram[index] = screenram[index+Int(xcolumns)]
              }
              for index in (Int(yrows)-1)*Int(xcolumns)..<Int(yrows)*Int(xcolumns)
              {
               screenram[index] = 32
              }
            }
        }
    }
}
