//
//  Microbee.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 21/5/2024.
//

import Foundation
import SwiftUI

class Microbee : ObservableObject
{
    
    enum MicrobeeModelType
    {
        case m16IC
        case m32IC
        case m32PC
        case m56K
        case mCIAB
        case m128K
        case m256TC
    }
    
    var MicrobeeModel : MicrobeeModelType
    var BatteryBackupOn : Bool
    var ExecCount : Int = 0
    
    var MyCRTC = CRTC()
    var MyPIO = PIO()
    var MyZ80 = Z80()
    var MyKeyboard = Keyboard()
    var MySound = Sound()
    var MyTape = Tape()
    var MyDisk = Disk()
    var MyMMU = MMU()
    
    @Published var AllTheRam = MMU.MemoryBlock(MemoryStart: 0x0000, MemoryEnd: 0xFFFF, FillData: 0x00)
    @Published var CPURegisters = Z80.Registers()
    
    init()
    {
        self.MicrobeeModel = MicrobeeModelType.m32IC
        self.BatteryBackupOn = false
        MyMMU.LoadROM(FileName: "basic_5.22e", FileExtension: "rom",MemPointer : 0x8000, ThisMemory: &AllTheRam)
        MyMMU.LoadROM(FileName: "charrom", FileExtension: "bin", MemPointer : 0xF000, ThisMemory: &AllTheRam)
        MyCRTC.LoadCharRom(MemPointer : 0xF000, MemSize : 0x1000, ThisMemory: AllTheRam)
        self.AllTheRam.AddressSpace[0x0000] = 0x21
        self.AllTheRam.AddressSpace[0x0001] = 0x00
        self.AllTheRam.AddressSpace[0x0002] = 0xF0
        self.AllTheRam.AddressSpace[0x0003] = 0x3E
        self.AllTheRam.AddressSpace[0x0004] = 0x48
        self.AllTheRam.AddressSpace[0x0005] = 0x77
        self.AllTheRam.AddressSpace[0x0006] = 0x23
        self.AllTheRam.AddressSpace[0x0007] = 0x3E
        self.AllTheRam.AddressSpace[0x0008] = 0x45
        self.AllTheRam.AddressSpace[0x0009] = 0x77
        self.AllTheRam.AddressSpace[0x000A] = 0x23
        self.AllTheRam.AddressSpace[0x000B] = 0x3E
        self.AllTheRam.AddressSpace[0x000C] = 0x4C
        self.AllTheRam.AddressSpace[0x000D] = 0x77
        self.AllTheRam.AddressSpace[0x000E] = 0x23
        self.AllTheRam.AddressSpace[0x000F] = 0x3E
        self.AllTheRam.AddressSpace[0x0010] = 0x4C
        self.AllTheRam.AddressSpace[0x0011] = 0x77
        self.AllTheRam.AddressSpace[0x0012] = 0x23
        self.AllTheRam.AddressSpace[0x0013] = 0x3E
        self.AllTheRam.AddressSpace[0x0014] = 0x4F
        self.AllTheRam.AddressSpace[0x0015] = 0x77
        self.AllTheRam.AddressSpace[0x0016] = 0x23
        
        //        0000   21 00 F0               LD   HL,61440
        //        0003   3E 48                  LD   A,72
        //        0005   77                     LD   (HL),A
        //        0006   23                     INC   HL
        //        0007   3E 45                  LD   A,69
        //        0009   77                     LD   (HL),A
        //        000A   23                     INC   HL
        //        000B   3E 4C                  LD   A,76
        //        000D   77                     LD   (HL),A
        //        000E   23                     INC   HL
        //        000F   3E 4C                  LD   A,76
        //        0011   77                     LD   (HL),A
        //        0012   23                     INC   HL
        //        0013   3E 4F                  LD   A,79
        //        0015   77                     LD   (HL),A
        //        0016   23                     INC   HL
    }
    
    func ExecuteInstructionBundle( JumpValue : Int )
    {
        if (MyZ80.CPURunning) // && (ExecCount < 1)
        {
            let clock = ContinuousClock()
            let result = clock.measure {
                for MyIndex in 1...1000
                {
                    MyZ80.FetchInstruction(TheseRegisters : &CPURegisters,ThisMemory : &AllTheRam, ThisScreenMemory : &MyCRTC.screenram)
                }
            }
            print(result)
            print(result/1000)
            ExecCount = ExecCount + 1
        }
    }
    
    func StepInstruction( JumpValue : Int )
    {
        let clock = ContinuousClock()
        let result = clock.measure {
            MyZ80.FetchInstruction(TheseRegisters : &CPURegisters,ThisMemory : &AllTheRam, ThisScreenMemory : &MyCRTC.screenram)
        }
        print(result)
    }
    
    
    func ResetCPU()
    {
        CPURegisters.A = 0
        CPURegisters.F = 0
        CPURegisters.B = 0
        CPURegisters.C = 0
        CPURegisters.D = 0
        CPURegisters.E = 0
        CPURegisters.H = 0
        CPURegisters.L = 0
        CPURegisters.AltA = 0
        CPURegisters.AltF = 0
        CPURegisters.AltB = 0
        CPURegisters.AltC = 0
        CPURegisters.AltH = 0
        CPURegisters.AltL = 0
        CPURegisters.I = 0
        CPURegisters.R = 0
        CPURegisters.IX = 0
        CPURegisters.IY = 0
        CPURegisters.SP = 0
        CPURegisters.PC = 0x0000
        for MyIndex in 0x000...0xFFFF
        {
            AllTheRam.AddressSpace[MyIndex] = 0x00
        }
        MyMMU.LoadROM(FileName: "basic_5.22e", FileExtension: "rom",MemPointer : 0x8000, ThisMemory: &AllTheRam)
        MyMMU.LoadROM(FileName: "charrom", FileExtension: "bin", MemPointer : 0xF000, ThisMemory: &AllTheRam)
        MyCRTC.LoadCharRom(MemPointer : 0xF000, MemSize : 0x1000, ThisMemory: AllTheRam)
        MyCRTC.ClearScreen()
        self.AllTheRam.AddressSpace[0x0000] = 0x21
        self.AllTheRam.AddressSpace[0x0001] = 0x00
        self.AllTheRam.AddressSpace[0x0002] = 0xF0
        self.AllTheRam.AddressSpace[0x0003] = 0x3E
        self.AllTheRam.AddressSpace[0x0004] = 0x48
        self.AllTheRam.AddressSpace[0x0005] = 0x77
        self.AllTheRam.AddressSpace[0x0006] = 0x23
        self.AllTheRam.AddressSpace[0x0007] = 0x3E
        self.AllTheRam.AddressSpace[0x0008] = 0x45
        self.AllTheRam.AddressSpace[0x0009] = 0x77
        self.AllTheRam.AddressSpace[0x000A] = 0x23
        self.AllTheRam.AddressSpace[0x000B] = 0x3E
        self.AllTheRam.AddressSpace[0x000C] = 0x4C
        self.AllTheRam.AddressSpace[0x000D] = 0x77
        self.AllTheRam.AddressSpace[0x000E] = 0x23
        self.AllTheRam.AddressSpace[0x000F] = 0x3E
        self.AllTheRam.AddressSpace[0x0010] = 0x4C
        self.AllTheRam.AddressSpace[0x0011] = 0x77
        self.AllTheRam.AddressSpace[0x0012] = 0x23
        self.AllTheRam.AddressSpace[0x0013] = 0x3E
        self.AllTheRam.AddressSpace[0x0014] = 0x4F
        self.AllTheRam.AddressSpace[0x0015] = 0x77
        self.AllTheRam.AddressSpace[0x0016] = 0x23
    }
}

