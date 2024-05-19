//
//  Z80.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024.
//

import Foundation
import SwiftUI

class Z80 : ObservableObject {
    
    struct registers
    {
        var A : UInt8  // Accumulator
        var F : UInt8  // Flags
        var B : UInt8  // Accumulator
        var C : UInt8  // Flags
        var H : UInt8  // Accumulator
        var L : UInt8  // Flags
        var AltA : UInt8  // Accumulator
        var AltF : UInt8  // Flags
        var AltB : UInt8  // Accumulator
        var AltC : UInt8  // Flags
        var AltH : UInt8  // Accumulator
        var AltL : UInt8  // Flags
        var I : UInt8  // Interrupt Vector
        var R : UInt8  // Memory Refresh
        var IX : UInt16 // Index Register
        var IY : UInt16 // Index Register
        var SP : UInt16  // Stack Pointer
        var PC : UInt16  // Program Counter
        
        init() {
            self.A = 0
            self.F = 0
            self.B = 0
            self.C = 0
            self.H = 0
            self.L = 0
            self.AltA = 0
            self.AltF = 0
            self.AltB = 0
            self.AltC = 0
            self.AltH = 0
            self.AltL = 0
            self.I = 0
            self.R = 0
            self.IX = 0
            self.IY = 0
            self.SP = 0
            self.PC = 0x3700
        }
    }
    
    @Published var CPURegisters = registers()

    var CPURunning : Bool
    var CPUStep : Bool
    var CPUPost : Bool
    
    var MyCRTC = CRTC()
    var MyPIO = PIO()

    var Bank1Ram = MMU(Label: MMU.MemoryBlocks.Bank1Ram,Active:true,ShaderRam:false,IsRom:false,MemoryStart:0x0000,MemoryEnd:0x3FFF)
    var Bank2Ram = MMU(Label: MMU.MemoryBlocks.Bank2Ram,Active:true,ShaderRam:false,IsRom:false,MemoryStart:0x4000,MemoryEnd:0x7FFF)
    var BasicRom = MMU(Label: MMU.MemoryBlocks.BasicRom,Active:true,ShaderRam:false,IsRom:true,MemoryStart:0x8000,MemoryEnd:0xBFFF)
    var Pak0Rom = MMU(Label: MMU.MemoryBlocks.Pak0Rom,Active:true,ShaderRam:false,IsRom:false,MemoryStart:0xC000,MemoryEnd:0xDFFF)
    var NetRom = MMU(Label: MMU.MemoryBlocks.NetRom,Active:true,ShaderRam:false,IsRom:true,MemoryStart:0xE000,MemoryEnd:0xEFFF)
    var ScreenRam = MMU(Label: MMU.MemoryBlocks.ScreenRam    ,Active:true,ShaderRam:true,IsRom:false,MemoryStart:0xF000,MemoryEnd:0xF7FF)
    var CharRom = MMU(Label: MMU.MemoryBlocks.CharRom,Active:true,ShaderRam:true,IsRom:true,MemoryStart:0xF000,MemoryEnd:0xFFFF)
    var PCGRam = MMU(Label: MMU.MemoryBlocks.PCGRam,Active:true,ShaderRam:true,IsRom:false,MemoryStart:0xF800,MemoryEnd:0xFFFF)
    
    var MemoryBus : [MMU] = []
 
    init() 
    
    {
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.Bank1Ram,Active:true,ShaderRam:false,IsRom:false,MemoryStart:0x0000,MemoryEnd:0x3FFF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.Bank2Ram,Active:true,ShaderRam:false,IsRom:false,MemoryStart:0x4000,MemoryEnd:0x7FFF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.BasicRom,Active:true,ShaderRam:false,IsRom:true, MemoryStart:0x8000,MemoryEnd:0xBFFF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.Pak0Rom,Active:true,ShaderRam:false,IsRom:false,MemoryStart:0xC000,MemoryEnd:0xDFFF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.NetRom,Active:true,ShaderRam:false,IsRom:true,MemoryStart:0xE000,MemoryEnd:0xEFFF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.ScreenRam,Active:true,ShaderRam:true,IsRom:false,MemoryStart:0xF000,MemoryEnd:0xF7FF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.CharRom,Active:true,ShaderRam:true,IsRom:true,MemoryStart:0xF000,MemoryEnd:0xFFFF))
        MemoryBus.append(MMU(Label: MMU.MemoryBlocks.PCGRam,Active:true,ShaderRam:true,IsRom:false,MemoryStart:0xF800,MemoryEnd:0xFFFF))
        
        self.CPURunning = false
        self.CPUStep  = false
        self.CPUPost = false
        
        print(MemoryBus[2])

        bob(2,"basic_5.22e", "rom")
        bob(6,"charrom", "bin")
        
//        MemoryBus[2].LoadRom(FileName: "basic_5.22e", FileExtension: "rom")
//        MemoryBus[6].LoadRom(FileName: "charrom", FileExtension: "bin")
        
        BasicRom.LoadROM(FileName: "basic_5.22e", FileExtension: "rom")
        CharRom.LoadROM(FileName: "charrom", FileExtension: "bin")
    }
    
    func bob (_ index : Int, _ FileName: String, _ FileExtension: String)
    {
        MemoryBus[index].LoadROM(FileName : FileName, FileExtension:FileExtension)
    }
    
    func StepInstruction()
    {
        CPURegisters.PC = CPURegisters.PC+1
        if CPURegisters.PC == 0xFFFF
        {
            CPURegisters.PC = 0
        }
    }
    
    func FormatRegister( _ MyValue : UInt8) -> String {
        
        var FormattedString : String = String(MyValue,radix:2)
        
        while FormattedString.count < 8
        {
          FormattedString = FormattedString+"0"
        }
        
        return "  "+String(format: "%02X",MyValue)+"            "+FormattedString
    }
    
    func FormatRegister2( _ MyValue : UInt16) -> String {
        
        var FormattedString : String = String(MyValue,radix:2)
        
        while FormattedString.count < 16
        {
          FormattedString = FormattedString+"0"
        }
        
        return String(format: "%04X",MyValue)+"    "+FormattedString
    }
    
    func FormatRegister3( _ MyValue : UInt8) -> String {
        
        var FormattedString : String = ""
        
        for index in 0...7
        {
            if (index == 2) || (index == 4)
            {
            }
            else
            {
                if MyValue & ( 1 << index ) > 0
                {
                    FormattedString = FormattedString + "1 "
                }
                else
                {
                    FormattedString = FormattedString + "0 "
                }
            }
        }
    
        return FormattedString
    }
    
    func DumpRam(_ MyValue : Int) -> String {
        
        var FormattedString : String = String(format: "%04X",MyValue)+": "
        
        for index in MyValue..<MyValue+32
        {
            FormattedString = FormattedString+String(format: "%02X",BasicRom.ReadAddress(MemPointer : index)) + " "
        }
        
        FormattedString = FormattedString + "   "
       
        for index in MyValue..<MyValue+32
        {
            switch BasicRom.ReadAddress(MemPointer : index) {
            
            case 0...31 :
                FormattedString = FormattedString+" "
            case 128...255 :
                FormattedString = FormattedString+"."
            default :
                FormattedString = FormattedString+String(UnicodeScalar(BasicRom.ReadAddress(MemPointer : index)))
            }
        }
        return FormattedString
    }
}
