//
//  CRTC.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 6/4/2024.
//

import Foundation
import SwiftUI

class CRTC : ObservableObject {
    
    var pcg = Array<UInt8>(repeating: 0,count:4096)
    var screen = Array<UInt8>(repeating: 32,count:4096)
    
    var xzoom : Int = 1
    var yzoom : Int = 2
    
    @Published var screenbitmap = Array<Bool>(repeating: false,count:131072)
    
    func ClearScreen()
    {
        for MyIndex in 0..<131072
        {
            screenbitmap[MyIndex] = false
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
                    pcg[pcgindex] = MyIndex
                    pcgindex = pcgindex + 1
                }
            } catch {
                print("Problem with character rom")
            }
        } else {
            print("Can't find character rom")
        }
        print(pcg[0])

        ClearScreen()
        printstring("SwarmEmu To-do list",0,0)
        printstring("* Emulate Z80",0,1)
        printstring("* Emulate CRTC",0,2)
        printstring("* Emulate Keyboard",0,3)
        printstring("* Emulate Sound",0,4)
        printstring("* Load Basic",0,5)
        printstring("* Run Games",0,6)
    }
    
    func printchar ( _ charo : Character, _ dxpos : Int, _ dypos : Int )
    
    {
        var startpos : Int
        
        var bit8 : Bool
        var bit7 : Bool
        var bit6 : Bool
        var bit5 : Bool
        var bit4 : Bool
        var bit3 : Bool
        var bit2 : Bool
        var bit1 : Bool
        
        startpos = Int(charo.asciiValue ?? 0)*16
        
        for MyIndex in 0...15
        {
            //print("**",MyIndex)
            bit8 = ((pcg[startpos+MyIndex] & 0b10000000) >> 7) == 1
            bit7 = ((pcg[startpos+MyIndex] & 0b01000000) >> 6) == 1
            bit6 = ((pcg[startpos+MyIndex] & 0b00100000) >> 5) == 1
            bit5 = ((pcg[startpos+MyIndex] & 0b00010000) >> 4) == 1
            bit4 = ((pcg[startpos+MyIndex] & 0b00001000) >> 3) == 1
            bit3 = ((pcg[startpos+MyIndex] & 0b00000100) >> 2) == 1
            bit2 = ((pcg[startpos+MyIndex] & 0b00000010) >> 1) == 1
            bit1 = ((pcg[startpos+MyIndex] & 0b00000001) >> 0) == 1
            
            //let stringy = String(pcg[startpos+MyIndex], radix: 2)
            //let padd = String(repeating: "0",count: (8 - stringy.count))
            //print(padd + stringy)
            
            if bit8 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)] = true
            }
            if bit7 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+1] = true
                // print((ypos+MyIndex)*512+xpos+1)
            }
            if bit6 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+2] = true
                // print((ypos+MyIndex)*512+xpos+2)
            }
            if bit5 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+3] = true
                //print((ypos+MyIndex)*512+xpos+3)
            }
            if bit4 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+4] = true
                // print((ypos+MyIndex)*512+xpos+4)
            }
            if bit3 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+5] = true
                // print((ypos+MyIndex)*512+xpos+5)
            }
            if bit2 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+6] = true
                //print((ypos+MyIndex)*512+xpos+6)
            }
            if bit1 {
                screenbitmap[(dypos*512*16)+(MyIndex*512)+(dxpos*8)+7] = true
                //print((ypos+MyIndex)*512+xpos+7)
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
              printchar(ascii,xpos+xposition,ypos)
              xposition = xposition+1
            }
        }
    }
}
