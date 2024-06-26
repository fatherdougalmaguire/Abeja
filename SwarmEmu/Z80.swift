//
//  Z80.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024.
//

import Foundation
import SwiftUI

class Z80 : ObservableObject {
    
    struct Registers
    {
        var A : UInt8  // Accumulator
        var F : UInt8  // Flags
        var B : UInt8  // Accumulator
        var C : UInt8  // Flags
        var D : UInt8  // Accumulator
        var E : UInt8  // Flags
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
            self.D = 0
            self.E = 0
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
            self.PC = 0x0000
        }
    }
    
    struct OpCodes
    {
        var PrimaryOpCode       : UInt8
        var SecondaryOpCode     : UInt8
        var Assembler           : String
        var MCycle              : Int
        var TState              : [Int]
        var InstructionLength   : Int
    }
    
    var OpCodesList = [OpCodes]()
    
    @Published var CPURunning : Bool
    @Published var CPUStep : Bool
    var CPUPost : Bool
    
    var BaseMemPointer : UInt16 = 0
    
    var MyMMU = MMU()
    
    init()
    {
        self.CPURunning = false
        self.CPUStep  = false
        self.CPUPost = false
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x00,SecondaryOpCode: 0x00 , Assembler: "NOP", MCycle: 1, TState : [4], InstructionLength : 1))  //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x01,SecondaryOpCode: 0x00 , Assembler: "LD BC,nn", MCycle: 2, TState : [4,3,3], InstructionLength : 3)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x02,SecondaryOpCode: 0x00 , Assembler: "LD (BC),A", MCycle: 2, TState : [4,3], InstructionLength : 1))  //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x03,SecondaryOpCode: 0x00 , Assembler: "INC BC", MCycle: 1, TState : [6], InstructionLength : 1))  //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x04,SecondaryOpCode: 0x00 , Assembler: "INC B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x05,SecondaryOpCode: 0x00 , Assembler: "DEC B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x06,SecondaryOpCode: 0x00 , Assembler: "LD B,n", MCycle: 2, TState : [4,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x07,SecondaryOpCode: 0x00 , Assembler: "RLCA", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x08,SecondaryOpCode: 0x00 , Assembler: "EX AF,AF’", MCycle: 1, TState : [4], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x09,SecondaryOpCode: 0x00 , Assembler: "ADD HL,BC", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x0A,SecondaryOpCode: 0x00 , Assembler: "LD A,(BC)", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x0B,SecondaryOpCode: 0x00 , Assembler: "DEC BC", MCycle: 1, TState : [6], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x0C,SecondaryOpCode: 0x00 , Assembler: "INC C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x0D,SecondaryOpCode: 0x00 , Assembler: "DEC C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x0E,SecondaryOpCode: 0x00 , Assembler: "LD C,n", MCycle: 2, TState : [4,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x0F,SecondaryOpCode: 0x00 , Assembler: "CA", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x10,SecondaryOpCode: 0x00 , Assembler: "DJNZ NN", MCycle: 1, TState : [13,8], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x11,SecondaryOpCode: 0x00 , Assembler: "LD DE,nn", MCycle: 2, TState : [4,3,3], InstructionLength : 3)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x12,SecondaryOpCode: 0x00 , Assembler: "LD (DE),A", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x13,SecondaryOpCode: 0x00 , Assembler: "INC DE", MCycle: 1, TState : [6], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x14,SecondaryOpCode: 0x00 , Assembler: "INC D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x15,SecondaryOpCode: 0x00 , Assembler: "DEC D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x16,SecondaryOpCode: 0x00 , Assembler: "LD D,n", MCycle: 2, TState : [4,3,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x17,SecondaryOpCode: 0x00 , Assembler: "RLA", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x18,SecondaryOpCode: 0x00 , Assembler: "JR NN", MCycle: 1, TState : [12], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x19,SecondaryOpCode: 0x00 , Assembler: "ADD HL,DE", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x1A,SecondaryOpCode: 0x00 , Assembler: "LD A,(DE)", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x1B,SecondaryOpCode: 0x00 , Assembler: "DEC DE", MCycle: 1, TState : [6], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x1C,SecondaryOpCode: 0x00 , Assembler: "INC E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x1D,SecondaryOpCode: 0x00 , Assembler: "DEC E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x1E,SecondaryOpCode: 0x00 , Assembler: "LD E,n", MCycle: 2, TState : [4,3,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x1F,SecondaryOpCode: 0x00 , Assembler: "RRA", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x20,SecondaryOpCode: 0x00 , Assembler: "JR NZ,NN", MCycle: 1, TState : [12,7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x21,SecondaryOpCode: 0x00 , Assembler: "LD HL,nn", MCycle: 2, TState : [4,3,3], InstructionLength : 3)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x22,SecondaryOpCode: 0x00 , Assembler: "LD (nn),HL", MCycle: 5, TState : [4,3,3,3,3], InstructionLength : 3)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x23,SecondaryOpCode: 0x00 , Assembler: "INC HL", MCycle: 1, TState : [6], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x24,SecondaryOpCode: 0x00 , Assembler: "INC H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x25,SecondaryOpCode: 0x00 , Assembler: "DEC H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x26,SecondaryOpCode: 0x00 , Assembler: "LD H,n", MCycle: 2, TState : [4,3,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x27,SecondaryOpCode: 0x00 , Assembler: "DAA", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x28,SecondaryOpCode: 0x00 , Assembler: "JR Z,NN", MCycle: 1, TState : [12,7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x29,SecondaryOpCode: 0x00 , Assembler: "ADD HL,HL", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x2A,SecondaryOpCode: 0x00 , Assembler: "LD HL,(nn)", MCycle: 5, TState : [4,3,3,3,3], InstructionLength : 3))  //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x2B,SecondaryOpCode: 0x00 , Assembler: "DEC HL", MCycle: 1, TState : [6], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x2C,SecondaryOpCode: 0x00 , Assembler: "INC L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x2D,SecondaryOpCode: 0x00 , Assembler: "DEC L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x2E,SecondaryOpCode: 0x00 , Assembler: "LD L,n", MCycle: 2, TState : [4,3,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x2F,SecondaryOpCode: 0x00 , Assembler: "CPL", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x30,SecondaryOpCode: 0x00 , Assembler: "JR NC,NN", MCycle: 1, TState : [12,7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x31,SecondaryOpCode: 0x00 , Assembler: "LD SP,nn", MCycle: 2, TState : [4,3,3], InstructionLength : 3)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x32,SecondaryOpCode: 0x00 , Assembler: "LD (nn),A", MCycle: 4, TState : [4,3,3,3], InstructionLength : 3)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x33,SecondaryOpCode: 0x00 , Assembler: "INC SP", MCycle: 1, TState : [6], InstructionLength : 1))  //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x34,SecondaryOpCode: 0x00 , Assembler: "INC (HL)", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x35,SecondaryOpCode: 0x00 , Assembler: "DEC (HL)", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x36,SecondaryOpCode: 0x00 , Assembler: "LD (HL),n", MCycle: 3, TState : [4,3,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x37,SecondaryOpCode: 0x00 , Assembler: "SCF", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x38,SecondaryOpCode: 0x00 , Assembler: "JR C,NN", MCycle: 1, TState : [12,7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x39,SecondaryOpCode: 0x00 , Assembler: "ADD HL,SP", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x3A,SecondaryOpCode: 0x00 , Assembler: "LD A,(HHLL)", MCycle: 1, TState : [13], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x3B,SecondaryOpCode: 0x00 , Assembler: "DEC SP", MCycle: 1, TState : [6], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x3C,SecondaryOpCode: 0x00 , Assembler: "INC A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x3D,SecondaryOpCode: 0x00 , Assembler: "DEC A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x3E,SecondaryOpCode: 0x00 , Assembler: "LD A,n", MCycle: 2, TState : [4,3], InstructionLength : 2)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x3F,SecondaryOpCode: 0x00 , Assembler: "CCF", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x40,SecondaryOpCode: 0x00 , Assembler: "LD B,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x41,SecondaryOpCode: 0x00 , Assembler: "LD B,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x42,SecondaryOpCode: 0x00 , Assembler: "LD B,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x43,SecondaryOpCode: 0x00 , Assembler: "LD B,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x44,SecondaryOpCode: 0x00 , Assembler: "LD B,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x45,SecondaryOpCode: 0x00 , Assembler: "LD B,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x46,SecondaryOpCode: 0x00 , Assembler: "LD B,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x47,SecondaryOpCode: 0x00 , Assembler: "LD B,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x48,SecondaryOpCode: 0x00 , Assembler: "LD C,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x49,SecondaryOpCode: 0x00 , Assembler: "LD C,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x4A,SecondaryOpCode: 0x00 , Assembler: "LD C,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x4B,SecondaryOpCode: 0x00 , Assembler: "LD C,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x4C,SecondaryOpCode: 0x00 , Assembler: "LD C,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x4D,SecondaryOpCode: 0x00 , Assembler: "LD C,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x4E,SecondaryOpCode: 0x00 , Assembler: "LD C,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x4F,SecondaryOpCode: 0x00 , Assembler: "LD C,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x50,SecondaryOpCode: 0x00 , Assembler: "LD D,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x51,SecondaryOpCode: 0x00 , Assembler: "LD D,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x52,SecondaryOpCode: 0x00 , Assembler: "LD D,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x53,SecondaryOpCode: 0x00 , Assembler: "LD D,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x54,SecondaryOpCode: 0x00 , Assembler: "LD D,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x55,SecondaryOpCode: 0x00 , Assembler: "LD D,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x56,SecondaryOpCode: 0x00 , Assembler: "LD D,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x57,SecondaryOpCode: 0x00 , Assembler: "LD D,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x58,SecondaryOpCode: 0x00 , Assembler: "LD E,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x59,SecondaryOpCode: 0x00 , Assembler: "LD E,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x5A,SecondaryOpCode: 0x00 , Assembler: "LD E,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x5B,SecondaryOpCode: 0x00 , Assembler: "LD E,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x5C,SecondaryOpCode: 0x00 , Assembler: "LD E,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x5D,SecondaryOpCode: 0x00 , Assembler: "LD E,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x5E,SecondaryOpCode: 0x00 , Assembler: "LD E,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x5F,SecondaryOpCode: 0x00 , Assembler: "LD E,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x60,SecondaryOpCode: 0x00 , Assembler: "LD H,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x61,SecondaryOpCode: 0x00 , Assembler: "LD H,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x62,SecondaryOpCode: 0x00 , Assembler: "LD H,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x63,SecondaryOpCode: 0x00 , Assembler: "LD H,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x64,SecondaryOpCode: 0x00 , Assembler: "LD H,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x65,SecondaryOpCode: 0x00 , Assembler: "LD H,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x66,SecondaryOpCode: 0x00 , Assembler: "LD H,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x67,SecondaryOpCode: 0x00 , Assembler: "LD H,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x68,SecondaryOpCode: 0x00 , Assembler: "LD L,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x69,SecondaryOpCode: 0x00 , Assembler: "LD L,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x6A,SecondaryOpCode: 0x00 , Assembler: "LD L,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x6B,SecondaryOpCode: 0x00 , Assembler: "LD L,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x6C,SecondaryOpCode: 0x00 , Assembler: "LD L,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x6D,SecondaryOpCode: 0x00 , Assembler: "LD L,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x6E,SecondaryOpCode: 0x00 , Assembler: "LD L,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x6F,SecondaryOpCode: 0x00 , Assembler: "LD L,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x70,SecondaryOpCode: 0x00 , Assembler: "LD (HL),B", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x71,SecondaryOpCode: 0x00 , Assembler: "LD (HL),C", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x72,SecondaryOpCode: 0x00 , Assembler: "LD (HL),D", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x73,SecondaryOpCode: 0x00 , Assembler: "LD (HL),E", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x74,SecondaryOpCode: 0x00 , Assembler: "LD (HL),H", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x75,SecondaryOpCode: 0x00 , Assembler: "LD (HL),L", MCycle: 2, TState : [4,3], InstructionLength : 1)) //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x76,SecondaryOpCode: 0x00 , Assembler: "HALT", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x77,SecondaryOpCode: 0x00 , Assembler: "LD (HL),A", MCycle: 2, TState : [4,3], InstructionLength : 1))  //  Y
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x78,SecondaryOpCode: 0x00 , Assembler: "LD A,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x79,SecondaryOpCode: 0x00 , Assembler: "LD A,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x7A,SecondaryOpCode: 0x00 , Assembler: "LD A,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x7B,SecondaryOpCode: 0x00 , Assembler: "LD A,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x7C,SecondaryOpCode: 0x00 , Assembler: "LD A,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x7D,SecondaryOpCode: 0x00 , Assembler: "LD A,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x7E,SecondaryOpCode: 0x00 , Assembler: "LD A,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x7F,SecondaryOpCode: 0x00 , Assembler: "LD A,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x80,SecondaryOpCode: 0x00 , Assembler: "ADD A,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x81,SecondaryOpCode: 0x00 , Assembler: "ADD A,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x82,SecondaryOpCode: 0x00 , Assembler: "ADD A,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x83,SecondaryOpCode: 0x00 , Assembler: "ADD A,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x84,SecondaryOpCode: 0x00 , Assembler: "ADD A,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x85,SecondaryOpCode: 0x00 , Assembler: "ADD A,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x86,SecondaryOpCode: 0x00 , Assembler: "ADD A,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x87,SecondaryOpCode: 0x00 , Assembler: "ADD A,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x88,SecondaryOpCode: 0x00 , Assembler: "ADC A,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x89,SecondaryOpCode: 0x00 , Assembler: "ADC A,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x8A,SecondaryOpCode: 0x00 , Assembler: "ADC A,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x8B,SecondaryOpCode: 0x00 , Assembler: "ADC A,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x8C,SecondaryOpCode: 0x00 , Assembler: "ADC A,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x8D,SecondaryOpCode: 0x00 , Assembler: "ADC A,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x8E,SecondaryOpCode: 0x00 , Assembler: "ADC A,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x8F,SecondaryOpCode: 0x00 , Assembler: "ADC A,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x90,SecondaryOpCode: 0x00 , Assembler: "SUB A,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x91,SecondaryOpCode: 0x00 , Assembler: "SUB A,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x92,SecondaryOpCode: 0x00 , Assembler: "SUB A,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x93,SecondaryOpCode: 0x00 , Assembler: "SUB A,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x94,SecondaryOpCode: 0x00 , Assembler: "SUB A,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x95,SecondaryOpCode: 0x00 , Assembler: "SUB A,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x96,SecondaryOpCode: 0x00 , Assembler: "SUB A,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x97,SecondaryOpCode: 0x00 , Assembler: "SUB A,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x98,SecondaryOpCode: 0x00 , Assembler: "SBC A,B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x99,SecondaryOpCode: 0x00 , Assembler: "SBC A,C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x9A,SecondaryOpCode: 0x00 , Assembler: "SBC A,D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x9B,SecondaryOpCode: 0x00 , Assembler: "SBC A,E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x9C,SecondaryOpCode: 0x00 , Assembler: "SBC A,H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x9D,SecondaryOpCode: 0x00 , Assembler: "SBC A,L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x9E,SecondaryOpCode: 0x00 , Assembler: "SBC A,(HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0x9F,SecondaryOpCode: 0x00 , Assembler: "SBC A,A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA0,SecondaryOpCode: 0x00 , Assembler: "AND B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA1,SecondaryOpCode: 0x00 , Assembler: "AND C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA2,SecondaryOpCode: 0x00 , Assembler: "AND D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA3,SecondaryOpCode: 0x00 , Assembler: "AND E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA4,SecondaryOpCode: 0x00 , Assembler: "AND H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA5,SecondaryOpCode: 0x00 , Assembler: "AND L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA6,SecondaryOpCode: 0x00 , Assembler: "AND (HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA7,SecondaryOpCode: 0x00 , Assembler: "AND A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA8,SecondaryOpCode: 0x00 , Assembler: "XOR B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xA9,SecondaryOpCode: 0x00 , Assembler: "XOR C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xAA,SecondaryOpCode: 0x00 , Assembler: "XOR D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xAB,SecondaryOpCode: 0x00 , Assembler: "XOR E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xAC,SecondaryOpCode: 0x00 , Assembler: "XOR H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xAD,SecondaryOpCode: 0x00 , Assembler: "XOR L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xAE,SecondaryOpCode: 0x00 , Assembler: "XOR (HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xAF,SecondaryOpCode: 0x00 , Assembler: "XOR A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB0,SecondaryOpCode: 0x00 , Assembler: "OR B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB1,SecondaryOpCode: 0x00 , Assembler: "OR C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB2,SecondaryOpCode: 0x00 , Assembler: "OR D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB3,SecondaryOpCode: 0x00 , Assembler: "OR E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB4,SecondaryOpCode: 0x00 , Assembler: "OR H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB5,SecondaryOpCode: 0x00 , Assembler: "OR L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB6,SecondaryOpCode: 0x00 , Assembler: "OR (HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB7,SecondaryOpCode: 0x00 , Assembler: "OR A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB8,SecondaryOpCode: 0x00 , Assembler: "CP B", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xB9,SecondaryOpCode: 0x00 , Assembler: "CP C", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xBA,SecondaryOpCode: 0x00 , Assembler: "CP D", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xBB,SecondaryOpCode: 0x00 , Assembler: "CP E", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xBC,SecondaryOpCode: 0x00 , Assembler: "CP H", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xBD,SecondaryOpCode: 0x00 , Assembler: "CP L", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xBE,SecondaryOpCode: 0x00 , Assembler: "CP (HL)", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xBF,SecondaryOpCode: 0x00 , Assembler: "CP A", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC0,SecondaryOpCode: 0x00 , Assembler: "RET NZ", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC1,SecondaryOpCode: 0x00 , Assembler: "POP BC", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC2,SecondaryOpCode: 0x00 , Assembler: "JP NZ,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC3,SecondaryOpCode: 0x00 , Assembler: "JP HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC4,SecondaryOpCode: 0x00 , Assembler: "CALL NZ,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC5,SecondaryOpCode: 0x00 , Assembler: "PUSH BC", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC6,SecondaryOpCode: 0x00 , Assembler: "ADD A,NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC7,SecondaryOpCode: 0x00 , Assembler: "RST 00", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC8,SecondaryOpCode: 0x00 , Assembler: "RET Z", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xC9,SecondaryOpCode: 0x00 , Assembler: "RET", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCA,SecondaryOpCode: 0x00 , Assembler: "JP Z,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x0 , Assembler: "RLC B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1 , Assembler: "RLC C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2 , Assembler: "RLC D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3 , Assembler: "RLC E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4 , Assembler: "RLC H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5 , Assembler: "RLC L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6 , Assembler: "RLC (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7 , Assembler: "RLC A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8 , Assembler: "RRC B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9 , Assembler: "RRC C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x0A , Assembler: "RRC D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x0B , Assembler: "RRC E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x0E , Assembler: "RRC (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x0F , Assembler: "RRC A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x10 , Assembler: "RL B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x11 , Assembler: "RL C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x12 , Assembler: "RL D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x13 , Assembler: "RL E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x14 , Assembler: "RL H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x15 , Assembler: "RL L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x16 , Assembler: "RL (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x17 , Assembler: "RL A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x18 , Assembler: "RR B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x19 , Assembler: "RR C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1A , Assembler: "RR D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1B , Assembler: "RR E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1C , Assembler: "RR H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1D , Assembler: "RR L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1E , Assembler: "RR (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x1F , Assembler: "RR A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x20 , Assembler: "SLA B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x21 , Assembler: "SLA C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x22 , Assembler: "SLA D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x23 , Assembler: "SLA E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x24 , Assembler: "SLA H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x25 , Assembler: "SLA L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x26 , Assembler: "SLA (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x27 , Assembler: "SLA A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x28 , Assembler: "SRA B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x29 , Assembler: "SRA C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2A , Assembler: "SRA D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2B , Assembler: "SRA E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2C , Assembler: "SRA H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2D , Assembler: "SRA L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2E , Assembler: "SRA (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x2F , Assembler: "SRA A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x30 , Assembler: "SLS B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x31 , Assembler: "SLS C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x32 , Assembler: "SLS D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x33 , Assembler: "SLS E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x34 , Assembler: "SLS H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x35 , Assembler: "SLS L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x36 , Assembler: "SLS (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x37 , Assembler: "SLS A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x38 , Assembler: "SRL B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x39 , Assembler: "SRL C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3A , Assembler: "SRL D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3B , Assembler: "SRL E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3C , Assembler: "SRL H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3D , Assembler: "SRL L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3E , Assembler: "SRL (HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x3F , Assembler: "SRL A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x40 , Assembler: "BIT 0,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x41 , Assembler: "BIT 0,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x42 , Assembler: "BIT 0,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x43 , Assembler: "BIT 0,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x44 , Assembler: "BIT 0,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x45 , Assembler: "BIT 0,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x46 , Assembler: "BIT 0,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x47 , Assembler: "BIT 0,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x48 , Assembler: "BIT 1,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x49 , Assembler: "BIT 1,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4A , Assembler: "BIT 1,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4B , Assembler: "BIT 1,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4C , Assembler: "BIT 1,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4D , Assembler: "BIT 1,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4E , Assembler: "BIT 1,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x4F , Assembler: "BIT 1,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x50 , Assembler: "BIT 2,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x51 , Assembler: "BIT 2,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x52 , Assembler: "BIT 2,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x53 , Assembler: "BIT 2,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x54 , Assembler: "BIT 2,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x55 , Assembler: "BIT 2,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x56 , Assembler: "BIT 2,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x57 , Assembler: "BIT 2,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x58 , Assembler: "BIT 3,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x59 , Assembler: "BIT 3,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5A , Assembler: "BIT 3,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5B , Assembler: "BIT 3,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5C , Assembler: "BIT 3,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5D , Assembler: "BIT 3,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5E , Assembler: "BIT 3,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x5F , Assembler: "BIT 3,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x60 , Assembler: "BIT 4,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x61 , Assembler: "BIT 4,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x62 , Assembler: "BIT 4,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x63 , Assembler: "BIT 4,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x64 , Assembler: "BIT 4,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x65 , Assembler: "BIT 4,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x66 , Assembler: "BIT 4,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x67 , Assembler: "BIT 4,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x68 , Assembler: "BIT 5,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x69 , Assembler: "BIT 5,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6A , Assembler: "BIT 5,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6B , Assembler: "BIT 5,", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6C , Assembler: "BIT 5,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6D , Assembler: "BIT 5,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6E , Assembler: "BIT 5,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x6F , Assembler: "BIT 5,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x70 , Assembler: "BIT 6,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x71 , Assembler: "BIT 6,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x72 , Assembler: "BIT 6,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x73 , Assembler: "BIT 6,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x74 , Assembler: "BIT 6,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x75 , Assembler: "BIT 6,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x76 , Assembler: "BIT 6,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x77 , Assembler: "BIT 6,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x78 , Assembler: "BIT 7,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x79 , Assembler: "BIT 7,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7A , Assembler: "BIT 7,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7B , Assembler: "BIT 7,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7C , Assembler: "BIT 7,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7D , Assembler: "BIT 7,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7E , Assembler: "BIT 7,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x7F , Assembler: "BIT 7,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x80 , Assembler: "RES 0,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x81 , Assembler: "RES 0,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x82 , Assembler: "RES 0,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x83 , Assembler: "RES 0,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x84 , Assembler: "RES 0,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x85 , Assembler: "RES 0,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x86 , Assembler: "RES 0,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x87 , Assembler: "RES 0,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x88 , Assembler: "RES 1,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x89 , Assembler: "RES 1,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8A , Assembler: "RES 1,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8B , Assembler: "RES 1,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8C , Assembler: "RES 1,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8D , Assembler: "RES 1,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8E , Assembler: "RES 1,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x8F , Assembler: "RES 1,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x90 , Assembler: "RES 2,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x91 , Assembler: "RES 2,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x92 , Assembler: "RES 2,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x93 , Assembler: "RES 2,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x94 , Assembler: "RES 2,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x95 , Assembler: "RES 2,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x96 , Assembler: "RES 2,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x97 , Assembler: "RES 2,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x98 , Assembler: "RES 3,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x99 , Assembler: "RES 3,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9A , Assembler: "RES 3,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9B , Assembler: "RES 3,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9C , Assembler: "RES 3,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9D , Assembler: "RES 3,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9E , Assembler: "RES 3,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0x9F , Assembler: "RES 3,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA0 , Assembler: "RES 4,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA1 , Assembler: "RES 4,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA2 , Assembler: "RES 4,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA3 , Assembler: "RES 4,", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA4 , Assembler: "RES 4,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA5 , Assembler: "RES 4,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA6 , Assembler: "RES 4,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA7 , Assembler: "RES 4,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA8 , Assembler: "RES 5,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xA9 , Assembler: "RES 5,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xAA , Assembler: "RES 5,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xAB , Assembler: "RES 5,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xAC , Assembler: "RES 5,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xAD , Assembler: "RES 5,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xAE , Assembler: "RES 5,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xAF , Assembler: "RES 5,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB0 , Assembler: "RES 6,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB1 , Assembler: "RES 6,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB2 , Assembler: "RES 6,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB3 , Assembler: "RES 6,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB4 , Assembler: "RES 6,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB5 , Assembler: "RES 6,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB6 , Assembler: "RES 6,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB7 , Assembler: "RES 6,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB8 , Assembler: "RES 7,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xB9 , Assembler: "RES 7,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xBA , Assembler: "RES 7,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xBB , Assembler: "RES 7,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xBC , Assembler: "RES 7,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xBD , Assembler: "RES 7,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xBE , Assembler: "RES 7,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xBF , Assembler: "RES 7,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC0 , Assembler: "SET 0,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC1 , Assembler: "SET 0,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC2 , Assembler: "SET 0,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC3 , Assembler: "SET 0,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC4 , Assembler: "SET 0,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC5 , Assembler: "SET 0,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC6 , Assembler: "SET 0,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC7 , Assembler: "SET 0,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC8 , Assembler: "SET 1,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xC9 , Assembler: "SET 1,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xCA , Assembler: "SET 1,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xCB , Assembler: "SET 1,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xCC , Assembler: "SET 1,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xCD , Assembler: "SET 1,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xCE , Assembler: "SET 1,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xCF , Assembler: "SET 1,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD0 , Assembler: "SET 2,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD1 , Assembler: "SET 2,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD2 , Assembler: "SET 2,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD3 , Assembler: "SET 2,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD4 , Assembler: "SET 2,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD5 , Assembler: "SET 2,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD6 , Assembler: "SET 2,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD7 , Assembler: "SET 2,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD8 , Assembler: "SET 3,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xD9 , Assembler: "SET 3,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xDA , Assembler: "SET 3,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xDB , Assembler: "SET 3,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xDC , Assembler: "SET 3,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xDD , Assembler: "SET 3,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xDE , Assembler: "SET 3,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xDF , Assembler: "SET 3,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE0 , Assembler: "SET 4,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE1 , Assembler: "SET 4,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE2 , Assembler: "SET 4,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE3 , Assembler: "SET 4,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE4 , Assembler: "SET 4,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE5 , Assembler: "SET 4,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE6 , Assembler: "SET 4,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE7 , Assembler: "SET 4,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE8 , Assembler: "SET 5,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xE9 , Assembler: "SET 5,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xEA , Assembler: "SET 5,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xEB , Assembler: "SET 5,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xEC , Assembler: "SET 5,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xED , Assembler: "SET 5,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xEE , Assembler: "SET 5,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xEF , Assembler: "SET 5,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF0 , Assembler: "SET 6,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF1 , Assembler: "SET 6,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF2 , Assembler: "SET 6,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF3 , Assembler: "SET 6,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF4 , Assembler: "SET 6,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF5 , Assembler: "SET 6,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF6 , Assembler: "SET 6,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF7 , Assembler: "SET 6,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF8 , Assembler: "SET 7,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xF9 , Assembler: "SET 7,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xFA , Assembler: "SET 7,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xFB , Assembler: "SET 7,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xFC , Assembler: "SET 7,H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xFD , Assembler: "SET 7,L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xFE , Assembler: "SET 7,(HL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCB,SecondaryOpCode: 0xFF , Assembler: "SET 7,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCC,SecondaryOpCode: 0x00 , Assembler: "CALL Z,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCD,SecondaryOpCode: 0x00 , Assembler: "CALL HHLL", MCycle: 1, TState : [17], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCE,SecondaryOpCode: 0x00 , Assembler: "ADC A,NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xCF,SecondaryOpCode: 0x00 , Assembler: "RST 08", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD0,SecondaryOpCode: 0x00 , Assembler: "RET NC", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD1,SecondaryOpCode: 0x00 , Assembler: "POP DE", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD2,SecondaryOpCode: 0x00 , Assembler: "JP NC,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD3,SecondaryOpCode: 0x00 , Assembler: "OUT (NN),A", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD4,SecondaryOpCode: 0x00 , Assembler: "CALL NC,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD5,SecondaryOpCode: 0x00 , Assembler: "PUSH DE", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD6,SecondaryOpCode: 0x00 , Assembler: "SUB A,NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD7,SecondaryOpCode: 0x00 , Assembler: "RST 10", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD8,SecondaryOpCode: 0x00 , Assembler: "RET C", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xD9,SecondaryOpCode: 0x00 , Assembler: "EXX", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDA,SecondaryOpCode: 0x00 , Assembler: "JP C,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDB,SecondaryOpCode: 0x00 , Assembler: "IN A,(NN)", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDC,SecondaryOpCode: 0x00 , Assembler: "CALL C,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x9 , Assembler: "ADD IX,BC", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x19 , Assembler: "ADD IX,DE", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x21 , Assembler: "LD IX,HHLL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x22 , Assembler: "LD (HHLL),IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x23 , Assembler: "INC IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x24 , Assembler: "INC IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x25 , Assembler: "DEC IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x26 , Assembler: "LD IXH,NN", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x29 , Assembler: "ADD IX,IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x2A , Assembler: "LD IX,(HHLL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x2B , Assembler: "DEC IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x2C , Assembler: "INC IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x2D , Assembler: "DEC IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x2E , Assembler: "LD IXL,NN", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x34 , Assembler: "INC (IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x35 , Assembler: "DEC (IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x39 , Assembler: "ADD IX,SP", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x44 , Assembler: "LD B,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x45 , Assembler: "LD B,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x46 , Assembler: "LD B,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x4C , Assembler: "LD C,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x4D , Assembler: "LD C,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x4E , Assembler: "LD C,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x54 , Assembler: "LD D,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x55 , Assembler: "LD D,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x5E , Assembler: "LD E,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x60 , Assembler: "LD IXH,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x61 , Assembler: "LD IXH,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x62 , Assembler: "LD IXH,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x63 , Assembler: "LD IXH,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x64 , Assembler: "LD IXH,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x65 , Assembler: "LD IXH,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x66 , Assembler: "LD H,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x67 , Assembler: "LD IXH,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x68 , Assembler: "LD IXL,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x69 , Assembler: "LD IXL,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x6A , Assembler: "LD IXL,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x6B , Assembler: "LD IXL,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x6C , Assembler: "LD IXL,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x6D , Assembler: "LD IXL,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x6E , Assembler: "LD L,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x6F , Assembler: "LD IXL,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x70 , Assembler: "LD (IX+NN),B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x71 , Assembler: "LD (IX+NN),C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x72 , Assembler: "LD (IX+NN),D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x73 , Assembler: "LD (IX+NN),E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x74 , Assembler: "LD (IX+NN),H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x75 , Assembler: "LD (IX+NN),L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x77 , Assembler: "LD (IX+NN),A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x7C , Assembler: "LD A,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x7D , Assembler: "LD A,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x7E , Assembler: "LD A,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x84 , Assembler: "ADD A,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x85 , Assembler: "ADD A,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x86 , Assembler: "ADD A,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x8C , Assembler: "ADC A,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x8D , Assembler: "ADC A,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x8E , Assembler: "ADC A,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x94 , Assembler: "SUB A,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x95 , Assembler: "SUB A,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x96 , Assembler: "SUB A,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x9C , Assembler: "SBC A,IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x9D , Assembler: "SBC A,IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0x9E , Assembler: "SBC A,(IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xA4 , Assembler: "AND IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xA5 , Assembler: "AND IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xA6 , Assembler: "AND (IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xAC , Assembler: "XOR IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xAD , Assembler: "XOR IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xAE , Assembler: "XOR (IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xB4 , Assembler: "OR IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xB5 , Assembler: "OR IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xB6 , Assembler: "OR (IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xBC , Assembler: "CP IXH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xBD , Assembler: "CP IXL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xBE , Assembler: "CP (IX+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xE1 , Assembler: "POP IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xE3 , Assembler: "EX (SP),IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xE5 , Assembler: "PUSH IX", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDD,SecondaryOpCode: 0xE9 , Assembler: "JP (IX)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDE,SecondaryOpCode: 0x00 , Assembler: "SBC A,NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xDF,SecondaryOpCode: 0x00 , Assembler: "RST 18", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE0,SecondaryOpCode: 0x00 , Assembler: "RET PO", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE1,SecondaryOpCode: 0x00 , Assembler: "POP HL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE2,SecondaryOpCode: 0x00 , Assembler: "JP PO,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE3,SecondaryOpCode: 0x00 , Assembler: "EX (SP),HL", MCycle: 1, TState : [19], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE4,SecondaryOpCode: 0x00 , Assembler: "CALL PO,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE5,SecondaryOpCode: 0x00 , Assembler: "PUSH HL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE6,SecondaryOpCode: 0x00 , Assembler: "AND NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE7,SecondaryOpCode: 0x00 , Assembler: "RST 20", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE8,SecondaryOpCode: 0x00 , Assembler: "RET PE", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xE9,SecondaryOpCode: 0x00 , Assembler: "JP (HL)", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xEA,SecondaryOpCode: 0x00 , Assembler: "JP PE,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xEB,SecondaryOpCode: 0x00 , Assembler: "EX DE,HL", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xEC,SecondaryOpCode: 0x00 , Assembler: "CALL P,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x40 , Assembler: "IN B,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x41 , Assembler: "OUT (C),B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x42 , Assembler: "SBC HL,BC", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x43 , Assembler: "LD (HHLL),BC", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x44 , Assembler: "NEG", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x45 , Assembler: "RETN", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x46 , Assembler: "IM 0", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x47 , Assembler: "LD I,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x48 , Assembler: "IN C,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x49 , Assembler: "OUT (C),C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x4A , Assembler: "ADC HL,BC", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x4B , Assembler: "LD BC,(HHLL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x4D , Assembler: "RETI", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x4F , Assembler: "LD R,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x50 , Assembler: "IN D,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x51 , Assembler: "OUT (C),D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x52 , Assembler: "SBC HL,DE", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x53 , Assembler: "LD (HHLL),DE", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x56 , Assembler: "IM 1", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x57 , Assembler: "LD A,I", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x58 , Assembler: "IN E,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x59 , Assembler: "OUT (C),E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x5A , Assembler: "ADC HL,DE", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x5B , Assembler: "LD DE,(HHLL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x5E , Assembler: "IM 2", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x5F , Assembler: "LD A,R", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x60 , Assembler: "IN H,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x61 , Assembler: "OUT (C),H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x62 , Assembler: "SBC HL,HL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x63 , Assembler: "LD (HHLL),HL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x67 , Assembler: "RRD", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x68 , Assembler: "IN L,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x69 , Assembler: "OUT (C),L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x6A , Assembler: "ADC HL,HL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x6B , Assembler: "LD HL,(HHLL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x6F , Assembler: "RLD", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x70 , Assembler: "IN F,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x71 , Assembler: "OUT (C),F", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x72 , Assembler: "SBC HL,SP", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x73 , Assembler: "LD (HHLL),SP", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x78 , Assembler: "IN A,(C)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x79 , Assembler: "OUT (C),A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x7A , Assembler: "ADC HL,SP", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0x7B , Assembler: "LD SP,(HHLL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xA0 , Assembler: "LDI", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xA1 , Assembler: "CPI", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xA2 , Assembler: "INI", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xA3 , Assembler: "OTI", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xA8 , Assembler: "LDD", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xA9 , Assembler: "CPD", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xAA , Assembler: "IND", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xAB , Assembler: "OTD", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xB0 , Assembler: "LDIR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xB1 , Assembler: "CPIR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xB2 , Assembler: "INIR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xB3 , Assembler: "OTIR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xB8 , Assembler: "LDDR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xB9 , Assembler: "CPDR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xBA , Assembler: "INDR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xED,SecondaryOpCode: 0xBB , Assembler: "OTDR", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xEE,SecondaryOpCode: 0x00 , Assembler: "XOR NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xEF,SecondaryOpCode: 0x00 , Assembler: "RST 28", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF0,SecondaryOpCode: 0x00 , Assembler: "RET P", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF1,SecondaryOpCode: 0x00 , Assembler: "POP AF", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF2,SecondaryOpCode: 0x00 , Assembler: "JP P,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF3,SecondaryOpCode: 0x00 , Assembler: "DI", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF4,SecondaryOpCode: 0x00 , Assembler: "CALL P,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF5,SecondaryOpCode: 0x00 , Assembler: "PUSH AF", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF6,SecondaryOpCode: 0x00 , Assembler: "OR NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF7,SecondaryOpCode: 0x00 , Assembler: "RST 30", MCycle: 1, TState : [11], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF8,SecondaryOpCode: 0x00 , Assembler: "RET M", MCycle: 1, TState : [11,15], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xF9,SecondaryOpCode: 0x00 , Assembler: "LD SP,HL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFA,SecondaryOpCode: 0x00 , Assembler: "JP M,HHLL", MCycle: 1, TState : [10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFB,SecondaryOpCode: 0x00 , Assembler: "EI", MCycle: 1, TState : [4], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFC,SecondaryOpCode: 0x00 , Assembler: "CALL M,HHLL", MCycle: 1, TState : [17,10], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x9 , Assembler: "ADD IY,BC", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x19 , Assembler: "ADD IY,DE", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x21 , Assembler: "LD IY,HHLL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x22 , Assembler: "LD (HHLL),IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x23 , Assembler: "INC IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x24 , Assembler: "INC IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x25 , Assembler: "DEC IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x26 , Assembler: "LD IYH,NN", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x29 , Assembler: "ADD IY,IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x2A , Assembler: "LD IY,(HHLL)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x2B , Assembler: "DEC IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x2C , Assembler: "INC IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x2D , Assembler: "DEC IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x2E , Assembler: "LD IYL,NN", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x34 , Assembler: "INC (IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x35 , Assembler: "DEC (IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x39 , Assembler: "ADD IY,SP", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x44 , Assembler: "LD B,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x45 , Assembler: "LD B,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x46 , Assembler: "LD B,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x4C , Assembler: "LD C,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x4D , Assembler: "LD C,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x4E , Assembler: "LD C,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x54 , Assembler: "LD D,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x55 , Assembler: "LD D,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x5E , Assembler: "LD E,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x60 , Assembler: "LD IYH,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x61 , Assembler: "LD IYH,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x62 , Assembler: "LD IYH,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x63 , Assembler: "LD IYH,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x64 , Assembler: "LD IYH,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x65 , Assembler: "LD IYH,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x66 , Assembler: "LD H,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x67 , Assembler: "LD IYH,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x68 , Assembler: "LD IYL,B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x69 , Assembler: "LD IYL,C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x6A , Assembler: "LD IYL,D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x6B , Assembler: "LD IYL,E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x6C , Assembler: "LD IYL,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x6D , Assembler: "LD IYL,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x6E , Assembler: "LD L,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x6F , Assembler: "LD IYL,A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x70 , Assembler: "LD (IY+NN),B", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x71 , Assembler: "LD (IY+NN),C", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x72 , Assembler: "LD (IY+NN),D", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x73 , Assembler: "LD (IY+NN),E", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x74 , Assembler: "LD (IY+NN),H", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x75 , Assembler: "LD (IY+NN),L", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x77 , Assembler: "LD (IY+NN),A", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x7C , Assembler: "LD A,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x7D , Assembler: "LD A,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x7E , Assembler: "LD A,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x84 , Assembler: "ADD A,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x85 , Assembler: "ADD A,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x86 , Assembler: "ADD A,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x8C , Assembler: "ADC A,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x8D , Assembler: "ADC A,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x8E , Assembler: "ADC A,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x94 , Assembler: "SUB A,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x95 , Assembler: "SUB A,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x96 , Assembler: "SUB A,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x9C , Assembler: "SBC A,IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x9D , Assembler: "SBC A,IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0x9E , Assembler: "SBC A,(IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xA4 , Assembler: "AND IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xA5 , Assembler: "AND IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xA6 , Assembler: "AND (IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xAC , Assembler: "XOR IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xAD , Assembler: "XOR IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xAE , Assembler: "XOR (IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xB4 , Assembler: "OR IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xB5 , Assembler: "OR IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xB6 , Assembler: "OR (IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xBC , Assembler: "CP IYH", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xBD , Assembler: "CP IYL", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xBE , Assembler: "CP (IY+NN)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xE1 , Assembler: "POP IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xE3 , Assembler: "EX (SP),IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xE5 , Assembler: "PUSH IY", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFD,SecondaryOpCode: 0xE9 , Assembler: "JP (IY)", MCycle: 1, TState : [0,0], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFE,SecondaryOpCode: 0x00 , Assembler: "CP NN", MCycle: 1, TState : [7], InstructionLength : 1))
        OpCodesList.append(OpCodes(PrimaryOpCode: 0xFF,SecondaryOpCode: 0x00 , Assembler: "RST 38", MCycle: 1, TState : [11], InstructionLength : 1))
    }
    
    func FetchInstruction(TheseRegisters : inout Registers, ThisMemory : inout MMU.MemoryBlock, ThisScreenMemory : inout Array<Float>)
    {
        var FirstByte : UInt8
        var SecondByte : UInt8
        var ThirdByte : UInt8
        var FourthByte : UInt8
        
        var MemoryAddress : Int
        
        FirstByte = MyMMU.ReadAddress(MemPointer: TheseRegisters.PC, ThisMemory: ThisMemory)
        SecondByte = MyMMU.ReadAddress(MemPointer: TheseRegisters.PC+1, ThisMemory: ThisMemory)
        ThirdByte = MyMMU.ReadAddress(MemPointer: TheseRegisters.PC+2, ThisMemory: ThisMemory)
        FourthByte = MyMMU.ReadAddress(MemPointer: TheseRegisters.PC+3, ThisMemory: ThisMemory)
        
        switch FirstByte {
        case 0x00:
            print("NOP")
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x01:
            print("LD BC,nn")
            TheseRegisters.B = ThirdByte
            TheseRegisters.C = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x02:
            print("LD (BC),A")
            MemoryAddress = Int(TheseRegisters.B)*0x100+Int(TheseRegisters.C)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.A
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.A)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x03:
            print("INC BC")
            if TheseRegisters.C == 0xFF
            {
                TheseRegisters.C = 0
                TheseRegisters.B = TheseRegisters.B + 1
            }
            else
            {
                TheseRegisters.C = TheseRegisters.C + 1
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x04:
            print("INC B")
        case 0x05:
            print("DEC B")
        case 0x06:
            print("LD B,n")
            TheseRegisters.B = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x07:
            print("RLCA")
        case 0x08:
            print("EX AF,AF’")
            (TheseRegisters.A,TheseRegisters.AltA) = (TheseRegisters.AltA,TheseRegisters.A)
            (TheseRegisters.F,TheseRegisters.AltF) = (TheseRegisters.AltF,TheseRegisters.F)
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x09:
            print("ADD HL,BC")
        case 0x0A:
            print("LD A,(BC)")
            MemoryAddress = Int(TheseRegisters.B)*0x100+Int(TheseRegisters.C)
            TheseRegisters.A = ThisMemory.AddressSpace[MemoryAddress]
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x0B:
            print("DEC BC")
        case 0x0C:
            print("INC C")
        case 0x0D:
            print("DEC C")
        case 0x0E:
            print("LD C,n")
            TheseRegisters.C = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x0F:
            print("CA")
        case 0x10:
            print("DJNZ NN")
        case 0x11:
            print("LD DE,nn")
            TheseRegisters.D = ThirdByte
            TheseRegisters.E = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x12:
            print("LD (DE),A")
            MemoryAddress = Int(TheseRegisters.D)*0x100+Int(TheseRegisters.E)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.A
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.A)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x13:
            print("INC DE")
            if TheseRegisters.E == 0xFF
            {
                TheseRegisters.E = 0
                TheseRegisters.D = TheseRegisters.D + 1
            }
            else
            {
                TheseRegisters.E = TheseRegisters.E + 1
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x14:
            print("INC D")
        case 0x15:
            print("DEC D")
        case 0x16:
            print("LD D,n")
            TheseRegisters.D = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x17:
            print("RLA")
        case 0x18:
            print("JR NN")
        case 0x19:
            print("ADD HL,DE")
        case 0x1A:
            print("LD A,(DE)")
            MemoryAddress = Int(TheseRegisters.D)*0x100+Int(TheseRegisters.E)
            TheseRegisters.A = ThisMemory.AddressSpace[MemoryAddress]
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x1B:
            print("DEC DE")
        case 0x1C:
            print("INC E")
        case 0x1D:
            print("DEC E")
        case 0x1E:
            print("LD E,n")
            TheseRegisters.E = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x1F:
            print("RRA")
        case 0x20:
            print("JR NZ,NN")
        case 0x21:
            print("LD HL,nn")
            TheseRegisters.H = ThirdByte
            TheseRegisters.L = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x22:
            print("LD (nn),HL")
            MemoryAddress = Int(ThirdByte)*0x100+Int(SecondByte)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.L
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.L)
            }
            MemoryAddress = MemoryAddress + 1
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.H
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.H)
            }
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x23:
            print("INC HL")
            if TheseRegisters.L == 0xFF
            {
                TheseRegisters.L = 0
                TheseRegisters.H = TheseRegisters.H + 1
            }
            else
            {
                TheseRegisters.L = TheseRegisters.L + 1
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x24:
            print("INC H")
        case 0x25:
            print("DEC H")
        case 0x26:
            print("LD H,n")
            TheseRegisters.H = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x27:
            print("DAA")
        case 0x28:
            print("JR Z,NN")
        case 0x29:
            print("ADD HL,HL")
        case 0x2A:
            print("LD HL,(nn)")
            MemoryAddress = Int(ThirdByte)*0x100+Int(SecondByte)
            TheseRegisters.L = ThisMemory.AddressSpace[MemoryAddress]
            TheseRegisters.H = ThisMemory.AddressSpace[MemoryAddress+1]
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x2B:
            print("DEC HL")
        case 0x2C:
            print("INC L")
        case 0x2D:
            print("DEC L")
        case 0x2E:
            print("LD L,n")
            TheseRegisters.L = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x2F:
            print("CPL")
        case 0x30:
            print("JR NC,NN")
        case 0x31:
            print("LD SP,nn")
            TheseRegisters.SP = UInt16(ThirdByte)*0x100 + UInt16(SecondByte)
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x32:
            print("LD (nn),A")
            MemoryAddress = Int(ThirdByte)*0x100+Int(SecondByte)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.A
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.A)
            }
            TheseRegisters.PC = TheseRegisters.PC+3
        case 0x33:
            print("INC SP")
            TheseRegisters.SP = TheseRegisters.SP + 1
            TheseRegisters.PC = TheseRegisters.PC + 1
        case 0x34:
            print("INC (HL)")
        case 0x35:
            print("DEC (HL)")
        case 0x36:
            print("LD (HL),n")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  SecondByte
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(SecondByte)
            }
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x37:
            print("SCF")
        case 0x38:
            print("JR C,NN")
        case 0x39:
            print("ADD HL,SP")
        case 0x3A:
            print("LD A,(HHLL)")
        case 0x3B:
            print("DEC SP")
        case 0x3C:
            print("INC A")
        case 0x3D:
            print("DEC A")
        case 0x3E:
            print("LD A,NN")
            TheseRegisters.A = SecondByte
            TheseRegisters.PC = TheseRegisters.PC+2
        case 0x3F:
            print("CCF")
        case 0x40:
            print("LD B,B")
        case 0x41:
            print("LD B,C")
        case 0x42:
            print("LD B,D")
        case 0x43:
            print("LD B,E")
        case 0x44:
            print("LD B,H")
        case 0x45:
            print("LD B,L")
        case 0x46:
            print("LD B,(HL)")
        case 0x47:
            print("LD B,A")
        case 0x48:
            print("LD C,B")
        case 0x49:
            print("LD C,C")
        case 0x4A:
            print("LD C,D")
        case 0x4B:
            print("LD C,E")
        case 0x4C:
            print("LD C,H")
        case 0x4D:
            print("LD C,L")
        case 0x4E:
            print("LD C,(HL)")
        case 0x4F:
            print("LD C,A")
        case 0x50:
            print("LD D,B")
        case 0x51:
            print("LD D,C")
        case 0x52:
            print("LD D,D")
        case 0x53:
            print("LD D,E")
        case 0x54:
            print("LD D,H")
        case 0x55:
            print("LD D,L")
        case 0x56:
            print("LD D,(HL)")
        case 0x57:
            print("LD D,A")
        case 0x58:
            print("LD E,B")
        case 0x59:
            print("LD E,C")
        case 0x5A:
            print("LD E,D")
        case 0x5B:
            print("LD E,E")
        case 0x5C:
            print("LD E,H")
        case 0x5D:
            print("LD E,L")
        case 0x5E:
            print("LD E,(HL)")
        case 0x5F:
            print("LD E,A")
        case 0x60:
            print("LD H,B")
        case 0x61:
            print("LD H,C")
        case 0x62:
            print("LD H,D")
        case 0x63:
            print("LD H,E")
        case 0x64:
            print("LD H,H")
        case 0x65:
            print("LD H,L")
        case 0x66:
            print("LD H,(HL)")
        case 0x67:
            print("LD H,A")
        case 0x68:
            print("LD L,B")
        case 0x69:
            print("LD L,C")
        case 0x6A:
            print("LD L,D")
        case 0x6B:
            print("LD L,E")
        case 0x6C:
            print("LD L,H")
        case 0x6D:
            print("LD L,L")
        case 0x6E:
            print("LD L,(HL)")
        case 0x6F:
            print("LD L,A")
        case 0x70:
            print("LD (HL),B")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.B
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.B)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x71:
            print("LD (HL),C")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.C
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.C)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x72:
            print("LD (HL),D")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.D
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.D)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x73:
            print("LD (HL),E")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.E
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.E)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x74:
            print("LD (HL),H")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.H
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.H)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x75:
            print("LD (HL),L")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.L
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.L)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x76:
            print("HALT")
        case 0x77:
            print("LD (HL),A")
            MemoryAddress = Int(TheseRegisters.H)*0x100+Int(TheseRegisters.L)
            ThisMemory.AddressSpace[MemoryAddress] =  TheseRegisters.A
            if (MemoryAddress >= 0xF000) && (MemoryAddress <= 0xF7FF)
            {
                ThisScreenMemory[MemoryAddress-0xF000] =  Float(TheseRegisters.A)
            }
            TheseRegisters.PC = TheseRegisters.PC+1
        case 0x78:
            print("LD A,B")
        case 0x79:
            print("LD A,C")
        case 0x7A:
            print("LD A,D")
        case 0x7B:
            print("LD A,E")
        case 0x7C:
            print("LD A,H")
        case 0x7D:
            print("LD A,L")
        case 0x7E:
            print("LD A,(HL)")
        case 0x7F:
            print("LD A,A")
        case 0x80:
            print("ADD A,B")
        case 0x81:
            print("ADD A,C")
        case 0x82:
            print("ADD A,D")
        case 0x83:
            print("ADD A,E")
        case 0x84:
            print("ADD A,H")
        case 0x85:
            print("ADD A,L")
        case 0x86:
            print("ADD A,(HL)")
        case 0x87:
            print("ADD A,A")
        case 0x88:
            print("ADC A,B")
        case 0x89:
            print("ADC A,C")
        case 0x8A:
            print("ADC A,D")
        case 0x8B:
            print("ADC A,E")
        case 0x8C:
            print("ADC A,H")
        case 0x8D:
            print("ADC A,L")
        case 0x8E:
            print("ADC A,(HL)")
        case 0x8F:
            print("ADC A,A")
        case 0x90:
            print("SUB A,B")
        case 0x91:
            print("SUB A,C")
        case 0x92:
            print("SUB A,D")
        case 0x93:
            print("SUB A,E")
        case 0x94:
            print("SUB A,H")
        case 0x95:
            print("SUB A,L")
        case 0x96:
            print("SUB A,(HL)")
        case 0x97:
            print("SUB A,A")
        case 0x98:
            print("SBC A,B")
        case 0x99:
            print("SBC A,C")
        case 0x9A:
            print("SBC A,D")
        case 0x9B:
            print("SBC A,E")
        case 0x9C:
            print("SBC A,H")
        case 0x9D:
            print("SBC A,L")
        case 0x9E:
            print("SBC A,(HL)")
        case 0x9F:
            print("SBC A,A")
        case 0xA0:
            print("AND B")
        case 0xA1:
            print("AND C")
        case 0xA2:
            print("AND D")
        case 0xA3:
            print("AND E")
        case 0xA4:
            print("AND H")
        case 0xA5:
            print("AND L")
        case 0xA6:
            print("AND (HL)")
        case 0xA7:
            print("AND A")
        case 0xA8:
            print("XOR B")
        case 0xA9:
            print("XOR C")
        case 0xAA:
            print("XOR D")
        case 0xAB:
            print("XOR E")
        case 0xAC:
            print("XOR H")
        case 0xAD:
            print("XOR L")
        case 0xAE:
            print("XOR (HL)")
        case 0xAF:
            print("XOR A")
        case 0xB0:
            print("OR B")
        case 0xB1:
            print("OR C")
        case 0xB2:
            print("OR D")
        case 0xB3:
            print("OR E")
        case 0xB4:
            print("OR H")
        case 0xB5:
            print("OR L")
        case 0xB6:
            print("OR (HL)")
        case 0xB7:
            print("OR A")
        case 0xB8:
            print("CP B")
        case 0xB9:
            print("CP C")
        case 0xBA:
            print("CP D")
        case 0xBB:
            print("CP E")
        case 0xBC:
            print("CP H")
        case 0xBD:
            print("CP L")
        case 0xBE:
            print("CP (HL)")
        case 0xBF:
            print("CP A")
        case 0xC0:
            print("RET NZ")
        case 0xC1:
            print("POP BC")
        case 0xC2:
            print("JP NZ,HHLL")
        case 0xC3:
            print("JP HHLL")
        case 0xC4:
            print("CALL NZ,HHLL")
        case 0xC5:
            print("PUSH BC")
        case 0xC6:
            print("ADD A,NN")
        case 0xC7:
            print("RST 00")
        case 0xC8:
            print("RET Z")
        case 0xC9:
            print("RET")
        case 0xCA:
            print("JP Z,HHLL")
        case 0xCB:
            print("CB not handled yet")
            //        case 0xCB:    print("RLC B")
            //        case 0xCB:    print("RLC C")
            //        case 0xCB:    print("RLC D")
            //        case 0xCB:    print("RLC E")
            //        case 0xCB:    print("RLC H")
            //        case 0xCB:    print("RLC L")
            //        case 0xCB:    print("RLC (HL)")
            //        case 0xCB:    print("RLC A")
            //        case 0xCB:    print("RRC B")
            //        case 0xCB:    print("RRC C")
            //        case 0xCB:    print("RRC D")
            //        case 0xCB:    print("RRC E")
            //        case 0xCB:    print("RRC (HL)")
            //        case 0xCB:    print("RRC A")
            //        case 0xCB:    print("RL B")
            //        case 0xCB:    print("RL C")
            //        case 0xCB:    print("RL D")
            //        case 0xCB:    print("RL E")
            //        case 0xCB:    print("RL H")
            //        case 0xCB:    print("RL L")
            //        case 0xCB:    print("RL (HL)")
            //        case 0xCB:    print("RL A")
            //        case 0xCB:    print("RR B")
            //        case 0xCB:    print("RR C")
            //        case 0xCB:    print("RR D")
            //        case 0xCB:    print("RR E")
            //        case 0xCB:    print("RR H")
            //        case 0xCB:    print("RR L")
            //        case 0xCB:    print("RR (HL)")
            //        case 0xCB:    print("RR A")
            //        case 0xCB:    print("SLA B")
            //        case 0xCB:    print("SLA C")
            //        case 0xCB:    print("SLA D")
            //        case 0xCB:    print("SLA E")
            //        case 0xCB:    print("SLA H")
            //        case 0xCB:    print("SLA L")
            //        case 0xCB:    print("SLA (HL)")
            //        case 0xCB:    print("SLA A")
            //        case 0xCB:    print("SRA B")
            //        case 0xCB:    print("SRA C")
            //        case 0xCB:    print("SRA D")
            //        case 0xCB:    print("SRA E")
            //        case 0xCB:    print("SRA H")
            //        case 0xCB:    print("SRA L")
            //        case 0xCB:    print("SRA (HL)")
            //        case 0xCB:    print("SRA A")
            //        case 0xCB:    print("SLS B")
            //        case 0xCB:    print("SLS C")
            //        case 0xCB:    print("SLS D")
            //        case 0xCB:    print("SLS E")
            //        case 0xCB:    print("SLS H")
            //        case 0xCB:    print("SLS L")
            //        case 0xCB:    print("SLS (HL)")
            //        case 0xCB:    print("SLS A")
            //        case 0xCB:    print("SRL B")
            //        case 0xCB:    print("SRL C")
            //        case 0xCB:    print("SRL D")
            //        case 0xCB:    print("SRL E")
            //        case 0xCB:    print("SRL H")
            //        case 0xCB:    print("SRL L")
            //        case 0xCB:    print("SRL (HL)")
            //        case 0xCB:    print("SRL A")
            //        case 0xCB:    print("BIT 0,B")
            //        case 0xCB:    print("BIT 0,C")
            //        case 0xCB:    print("BIT 0,D")
            //        case 0xCB:    print("BIT 0,E")
            //        case 0xCB:    print("BIT 0,H")
            //        case 0xCB:    print("BIT 0,L")
            //        case 0xCB:    print("BIT 0,(HL)")
            //        case 0xCB:    print("BIT 0,A")
            //        case 0xCB:    print("BIT 1,B")
            //        case 0xCB:    print("BIT 1,C")
            //        case 0xCB:    print("BIT 1,D")
            //        case 0xCB:    print("BIT 1,E")
            //        case 0xCB:    print("BIT 1,H")
            //        case 0xCB:    print("BIT 1,L")
            //        case 0xCB:    print("BIT 1,(HL)")
            //        case 0xCB:    print("BIT 1,A")
            //        case 0xCB:    print("BIT 2,B")
            //        case 0xCB:    print("BIT 2,C")
            //        case 0xCB:    print("BIT 2,D")
            //        case 0xCB:    print("BIT 2,E")
            //        case 0xCB:    print("BIT 2,H")
            //        case 0xCB:    print("BIT 2,L")
            //        case 0xCB:    print("BIT 2,(HL)")
            //        case 0xCB:    print("BIT 2,A")
            //        case 0xCB:    print("BIT 3,B")
            //        case 0xCB:    print("BIT 3,C")
            //        case 0xCB:    print("BIT 3,D")
            //        case 0xCB:    print("BIT 3,E")
            //        case 0xCB:    print("BIT 3,H")
            //        case 0xCB:    print("BIT 3,L")
            //        case 0xCB:    print("BIT 3,(HL)")
            //        case 0xCB:    print("BIT 3,A")
            //        case 0xCB:    print("BIT 4,B")
            //        case 0xCB:    print("BIT 4,C")
            //        case 0xCB:    print("BIT 4,D")
            //        case 0xCB:    print("BIT 4,E")
            //        case 0xCB:    print("BIT 4,H")
            //        case 0xCB:    print("BIT 4,L")
            //        case 0xCB:    print("BIT 4,(HL)")
            //        case 0xCB:    print("BIT 4,A")
            //        case 0xCB:    print("BIT 5,B")
            //        case 0xCB:    print("BIT 5,C")
            //        case 0xCB:    print("BIT 5,D")
            //        case 0xCB:    print("BIT 5,")
            //        case 0xCB:    print("BIT 5,H")
            //        case 0xCB:    print("BIT 5,L")
            //        case 0xCB:    print("BIT 5,(HL)")
            //        case 0xCB:    print("BIT 5,A")
            //        case 0xCB:    print("BIT 6,B")
            //        case 0xCB:    print("BIT 6,C")
            //        case 0xCB:    print("BIT 6,D")
            //        case 0xCB:    print("BIT 6,E")
            //        case 0xCB:    print("BIT 6,H")
            //        case 0xCB:    print("BIT 6,L")
            //        case 0xCB:    print("BIT 6,(HL)")
            //        case 0xCB:    print("BIT 6,A")
            //        case 0xCB:    print("BIT 7,B")
            //        case 0xCB:    print("BIT 7,C")
            //        case 0xCB:    print("BIT 7,D")
            //        case 0xCB:    print("BIT 7,E")
            //        case 0xCB:    print("BIT 7,H")
            //        case 0xCB:    print("BIT 7,L")
            //        case 0xCB:    print("BIT 7,(HL)")
            //        case 0xCB:    print("BIT 7,A")
            //        case 0xCB:    print("RES 0,B")
            //        case 0xCB:    print("RES 0,C")
            //        case 0xCB:    print("RES 0,D")
            //        case 0xCB:    print("RES 0,E")
            //        case 0xCB:    print("RES 0,H")
            //        case 0xCB:    print("RES 0,L")
            //        case 0xCB:    print("RES 0,(HL)")
            //        case 0xCB:    print("RES 0,A")
            //        case 0xCB:    print("RES 1,B")
            //        case 0xCB:    print("RES 1,C")
            //        case 0xCB:    print("RES 1,D")
            //        case 0xCB:    print("RES 1,E")
            //        case 0xCB:    print("RES 1,H")
            //        case 0xCB:    print("RES 1,L")
            //        case 0xCB:    print("RES 1,(HL)")
            //        case 0xCB:    print("RES 1,A")
            //        case 0xCB:    print("RES 2,B")
            //        case 0xCB:    print("RES 2,C")
            //        case 0xCB:    print("RES 2,D")
            //        case 0xCB:    print("RES 2,E")
            //        case 0xCB:    print("RES 2,H")
            //        case 0xCB:    print("RES 2,L")
            //        case 0xCB:    print("RES 2,(HL)")
            //        case 0xCB:    print("RES 2,A")
            //        case 0xCB:    print("RES 3,B")
            //        case 0xCB:    print("RES 3,C")
            //        case 0xCB:    print("RES 3,D")
            //        case 0xCB:    print("RES 3,E")
            //        case 0xCB:    print("RES 3,H")
            //        case 0xCB:    print("RES 3,L")
            //        case 0xCB:    print("RES 3,(HL)")
            //        case 0xCB:    print("RES 3,A")
            //        case 0xCB:    print("RES 4,B")
            //        case 0xCB:    print("RES 4,C")
            //        case 0xCB:    print("RES 4,D")
            //        case 0xCB:    print("RES 4,")
            //        case 0xCB:    print("RES 4,H")
            //        case 0xCB:    print("RES 4,L")
            //        case 0xCB:    print("RES 4,(HL)")
            //        case 0xCB:    print("RES 4,A")
            //        case 0xCB:    print("RES 5,B")
            //        case 0xCB:    print("RES 5,C")
            //        case 0xCB:    print("RES 5,D")
            //        case 0xCB:    print("RES 5,E")
            //        case 0xCB:    print("RES 5,H")
            //        case 0xCB:    print("RES 5,L")
            //        case 0xCB:    print("RES 5,(HL)")
            //        case 0xCB:    print("RES 5,A")
            //        case 0xCB:    print("RES 6,B")
            //        case 0xCB:    print("RES 6,C")
            //        case 0xCB:    print("RES 6,D")
            //        case 0xCB:    print("RES 6,E")
            //        case 0xCB:    print("RES 6,H")
            //        case 0xCB:    print("RES 6,L")
            //        case 0xCB:    print("RES 6,(HL)")
            //        case 0xCB:    print("RES 6,A")
            //        case 0xCB:    print("RES 7,B")
            //        case 0xCB:    print("RES 7,C")
            //        case 0xCB:    print("RES 7,D")
            //        case 0xCB:    print("RES 7,E")
            //        case 0xCB:    print("RES 7,H")
            //        case 0xCB:    print("RES 7,L")
            //        case 0xCB:    print("RES 7,(HL)")
            //        case 0xCB:    print("RES 7,A")
            //        case 0xCB:    print("SET 0,B")
            //        case 0xCB:    print("SET 0,C")
            //        case 0xCB:    print("SET 0,D")
            //        case 0xCB:    print("SET 0,E")
            //        case 0xCB:    print("SET 0,H")
            //        case 0xCB:    print("SET 0,L")
            //        case 0xCB:    print("SET 0,(HL)")
            //        case 0xCB:    print("SET 0,A")
            //        case 0xCB:    print("SET 1,B")
            //        case 0xCB:    print("SET 1,C")
            //        case 0xCB:    print("SET 1,D")
            //        case 0xCB:    print("SET 1,E")
            //        case 0xCB:    print("SET 1,H")
            //        case 0xCB:    print("SET 1,L")
            //        case 0xCB:    print("SET 1,(HL)")
            //        case 0xCB:    print("SET 1,A")
            //        case 0xCB:    print("SET 2,B")
            //        case 0xCB:    print("SET 2,C")
            //        case 0xCB:    print("SET 2,D")
            //        case 0xCB:    print("SET 2,E")
            //        case 0xCB:    print("SET 2,H")
            //        case 0xCB:    print("SET 2,L")
            //        case 0xCB:    print("SET 2,(HL)")
            //        case 0xCB:    print("SET 2,A")
            //        case 0xCB:    print("SET 3,B")
            //        case 0xCB:    print("SET 3,C")
            //        case 0xCB:    print("SET 3,D")
            //        case 0xCB:    print("SET 3,E")
            //        case 0xCB:    print("SET 3,H")
            //        case 0xCB:    print("SET 3,L")
            //        case 0xCB:    print("SET 3,(HL)")
            //        case 0xCB:    print("SET 3,A")
            //        case 0xCB:    print("SET 4,B")
            //        case 0xCB:    print("SET 4,C")
            //        case 0xCB:    print("SET 4,D")
            //        case 0xCB:    print("SET 4,E")
            //        case 0xCB:    print("SET 4,H")
            //        case 0xCB:    print("SET 4,L")
            //        case 0xCB:    print("SET 4,(HL)")
            //        case 0xCB:    print("SET 4,A")
            //        case 0xCB:    print("SET 5,B")
            //        case 0xCB:    print("SET 5,C")
            //        case 0xCB:    print("SET 5,D")
            //        case 0xCB:    print("SET 5,E")
            //        case 0xCB:    print("SET 5,H")
            //        case 0xCB:    print("SET 5,L")
            //        case 0xCB:    print("SET 5,(HL)")
            //        case 0xCB:    print("SET 5,A")
            //        case 0xCB:    print("SET 6,B")
            //        case 0xCB:    print("SET 6,C")
            //        case 0xCB:    print("SET 6,D")
            //        case 0xCB:    print("SET 6,E")
            //        case 0xCB:    print("SET 6,H")
            //        case 0xCB:    print("SET 6,L")
            //        case 0xCB:    print("SET 6,(HL)")
            //        case 0xCB:    print("SET 6,A")
            //        case 0xCB:    print("SET 7,B")
            //        case 0xCB:    print("SET 7,C")
            //        case 0xCB:    print("SET 7,D")
            //        case 0xCB:    print("SET 7,E")
            //        case 0xCB:    print("SET 7,H")
            //        case 0xCB:    print("SET 7,L")
            //        case 0xCB:    print("SET 7,(HL)")
            //        case 0xCB:    print("SET 7,A")
        case 0xCC:
            print("CALL Z,HHLL")
        case 0xCD:
            print("CALL HHLL")
        case 0xCE:
            print("ADC A,NN")
        case 0xCF:
            print("RST 08")
        case 0xD0:
            print("RET NC")
        case 0xD1:
            print("POP DE")
        case 0xD2:
            print("JP NC,HHLL")
        case 0xD3:
            print("OUT (NN),A")
        case 0xD4:
            print("CALL NC,HHLL")
        case 0xD5:
            print("PUSH DE")
        case 0xD6:
            print("SUB A,NN")
        case 0xD7:
            print("RST 10")
        case 0xD8:
            print("RET C")
        case 0xD9:
            print("EXX")
        case 0xDA:
            print("JP C,HHLL")
        case 0xDB:
            print("IN A,(NN)")
        case 0xDC:
            print("CALL C,HHLL")
        case 0xDD:
            print("DD not handled yet")
            //        case 0xDD:    print("ADD IX,BC")
            //        case 0xDD:    print("ADD IX,DE")
            //        case 0xDD:    print("LD IX,HHLL")
            //        case 0xDD:    print("LD (HHLL),IX")
            //        case 0xDD:    print("INC IX")
            //        case 0xDD:    print("INC IXH")
            //        case 0xDD:    print("DEC IXH")
            //        case 0xDD:    print("LD IXH,NN")
            //        case 0xDD:    print("ADD IX,IX")
            //        case 0xDD:    print("LD IX,(HHLL)")
            //        case 0xDD:    print("DEC IX")
            //        case 0xDD:    print("INC IXL")
            //        case 0xDD:    print("DEC IXL")
            //        case 0xDD:    print("LD IXL,NN")
            //        case 0xDD:    print("INC (IX+NN)")
            //        case 0xDD:    print("DEC (IX+NN)")
            //        case 0xDD:    print("ADD IX,SP")
            //        case 0xDD:    print("LD B,IXH")
            //        case 0xDD:    print("LD B,IXL")
            //        case 0xDD:    print("LD B,(IX+NN)")
            //        case 0xDD:    print("LD C,IXH")
            //        case 0xDD:    print("LD C,IXL")
            //        case 0xDD:    print("LD C,(IX+NN)")
            //        case 0xDD:    print("LD D,IXH")
            //        case 0xDD:    print("LD D,IXL")
            //        case 0xDD:    print("LD E,(IX+NN)")
            //        case 0xDD:    print("LD IXH,B")
            //        case 0xDD:    print("LD IXH,C")
            //        case 0xDD:    print("LD IXH,D")
            //        case 0xDD:    print("LD IXH,E")
            //        case 0xDD:    print("LD IXH,IXH")
            //        case 0xDD:    print("LD IXH,IXL")
            //        case 0xDD:    print("LD H,(IX+NN)")
            //        case 0xDD:    print("LD IXH,A")
            //        case 0xDD:    print("LD IXL,B")
            //        case 0xDD:    print("LD IXL,C")
            //        case 0xDD:    print("LD IXL,D")
            //        case 0xDD:    print("LD IXL,E")
            //        case 0xDD:    print("LD IXL,IXH")
            //        case 0xDD:    print("LD IXL,IXL")
            //        case 0xDD:    print("LD L,(IX+NN)")
            //        case 0xDD:    print("LD IXL,A")
            //        case 0xDD:    print("LD (IX+NN),B")
            //        case 0xDD:    print("LD (IX+NN),C")
            //        case 0xDD:    print("LD (IX+NN),D")
            //        case 0xDD:    print("LD (IX+NN),E")
            //        case 0xDD:    print("LD (IX+NN),H")
            //        case 0xDD:    print("LD (IX+NN),L")
            //        case 0xDD:    print("LD (IX+NN),A")
            //        case 0xDD:    print("LD A,IXH")
            //        case 0xDD:    print("LD A,IXL")
            //        case 0xDD:    print("LD A,(IX+NN)")
            //        case 0xDD:    print("ADD A,IXH")
            //        case 0xDD:    print("ADD A,IXL")
            //        case 0xDD:    print("ADD A,(IX+NN)")
            //        case 0xDD:    print("ADC A,IXH")
            //        case 0xDD:    print("ADC A,IXL")
            //        case 0xDD:    print("ADC A,(IX+NN)")
            //        case 0xDD:    print("SUB A,IXH")
            //        case 0xDD:    print("SUB A,IXL")
            //        case 0xDD:    print("SUB A,(IX+NN)")
            //        case 0xDD:    print("SBC A,IXH")
            //        case 0xDD:    print("SBC A,IXL")
            //        case 0xDD:    print("SBC A,(IX+NN)")
            //        case 0xDD:    print("AND IXH")
            //        case 0xDD:    print("AND IXL")
            //        case 0xDD:    print("AND (IX+NN)")
            //        case 0xDD:    print("XOR IXH")
            //        case 0xDD:    print("XOR IXL")
            //        case 0xDD:    print("XOR (IX+NN)")
            //        case 0xDD:    print("OR IXH")
            //        case 0xDD:    print("OR IXL")
            //        case 0xDD:    print("OR (IX+NN)")
            //        case 0xDD:    print("CP IXH")
            //        case 0xDD:    print("CP IXL")
            //        case 0xDD:    print("CP (IX+NN)")
            //        case 0xDD:    print("POP IX")
            //        case 0xDD:    print("EX (SP),IX")
            //        case 0xDD:    print("PUSH IX")
            //        case 0xDD:    print("JP (IX)")
        case 0xDE:
            print("SBC A,NN")
        case 0xDF:
            print("RST 18")
        case 0xE0:
            print("RET PO")
        case 0xE1:
            print("POP HL")
        case 0xE2:
            print("JP PO,HHLL")
        case 0xE3:
            print("EX (SP),HL")
        case 0xE4:
            print("CALL PO,HHLL")
        case 0xE5:
            print("PUSH HL")
        case 0xE6:
            print("AND NN")
        case 0xE7:
            print("RST 20")
        case 0xE8:
            print("RET PE")
        case 0xE9:
            print("JP (HL)")
        case 0xEA:
            print("JP PE,HHLL")
        case 0xEB:
            print("EX DE,HL")
        case 0xEC:
            print("CALL P,HHLL")
        case 0xED:
            print("ED not handled yet")
            //        case 0xED:    print("IN B,(C)")
            //        case 0xED:    print("OUT (C),B")
            //        case 0xED:    print("SBC HL,BC")
            //        case 0xED:    print("LD (HHLL),BC")
            //        case 0xED:    print("NEG")
            //        case 0xED:    print("RETN")
            //        case 0xED:    print("IM 0")
            //        case 0xED:    print("LD I,A")
            //        case 0xED:    print("IN C,(C)")
            //        case 0xED:    print("OUT (C),C")
            //        case 0xED:    print("ADC HL,BC")
            //        case 0xED:    print("LD BC,(HHLL)")
            //        case 0xED:    print("RETI")
            //        case 0xED:    print("LD R,A")
            //        case 0xED:    print("IN D,(C)")
            //        case 0xED:    print("OUT (C),D")
            //        case 0xED:    print("SBC HL,DE")
            //        case 0xED:    print("LD (HHLL),DE")
            //        case 0xED:    print("IM 1")
            //        case 0xED:    print("LD A,I")
            //        case 0xED:    print("IN E,(C)")
            //        case 0xED:    print("OUT (C),E")
            //        case 0xED:    print("ADC HL,DE")
            //        case 0xED:    print("LD DE,(HHLL)")
            //        case 0xED:    print("IM 2")
            //        case 0xED:    print("LD A,R")
            //        case 0xED:    print("IN H,(C)")
            //        case 0xED:    print("OUT (C),H")
            //        case 0xED:    print("SBC HL,HL")
            //        case 0xED:    print("LD (HHLL),HL")
            //        case 0xED:    print("RRD")
            //        case 0xED:    print("IN L,(C)")
            //        case 0xED:    print("OUT (C),L")
            //        case 0xED:    print("ADC HL,HL")
            //        case 0xED:    print("LD HL,(HHLL)")
            //        case 0xED:    print("RLD")
            //        case 0xED:    print("IN F,(C)")
            //        case 0xED:    print("OUT (C),F")
            //        case 0xED:    print("SBC HL,SP")
            //        case 0xED:    print("LD (HHLL),SP")
            //        case 0xED:    print("IN A,(C)")
            //        case 0xED:    print("OUT (C),A")
            //        case 0xED:    print("ADC HL,SP")
            //        case 0xED:    print("LD SP,(HHLL)")
            //        case 0xED:    print("LDI")
            //        case 0xED:    print("CPI")
            //        case 0xED:    print("INI")
            //        case 0xED:    print("OTI")
            //        case 0xED:    print("LDD")
            //        case 0xED:    print("CPD")
            //        case 0xED:    print("IND")
            //        case 0xED:    print("OTD")
            //        case 0xED:    print("LDIR")
            //        case 0xED:    print("CPIR")
            //        case 0xED:    print("INIR")
            //        case 0xED:    print("OTIR")
            //        case 0xED:    print("LDDR")
            //        case 0xED:    print("CPDR")
            //        case 0xED:    print("INDR")
            //        case 0xED:    print("OTDR")
        case 0xEE:
            print("XOR NN")
        case 0xEF:
            print("RST 28")
        case 0xF0:
            print("RET P")
        case 0xF1:
            print("POP AF")
        case 0xF2:
            print("JP P,HHLL")
        case 0xF3:
            print("DI")
        case 0xF4:
            print("CALL P,HHLL")
        case 0xF5:
            print("PUSH AF")
        case 0xF6:
            print("OR NN")
        case 0xF7:
            print("RST 30")
        case 0xF8:
            print("RET M")
        case 0xF9:
            print("LD SP,HL")
        case 0xFA:
            print("JP M,HHLL")
        case 0xFB:
            print("EI")
        case 0xFC:
            print("CALL M,HHLL")
        case 0xFD:
            print("FD not handled yet")
            //        case 0xFD:    print("ADD IY,BC")
            //        case 0xFD:    print("ADD IY,DE")
            //        case 0xFD:    print("LD IY,HHLL")
            //        case 0xFD:    print("LD (HHLL),IY")
            //        case 0xFD:    print("INC IY")
            //        case 0xFD:    print("INC IYH")
            //        case 0xFD:    print("DEC IYH")
            //        case 0xFD:    print("LD IYH,NN")
            //        case 0xFD:    print("ADD IY,IY")
            //        case 0xFD:    print("LD IY,(HHLL)")
            //        case 0xFD:    print("DEC IY")
            //        case 0xFD:    print("INC IYL")
            //        case 0xFD:    print("DEC IYL")
            //        case 0xFD:    print("LD IYL,NN")
            //        case 0xFD:    print("INC (IY+NN)")
            //        case 0xFD:    print("DEC (IY+NN)")
            //        case 0xFD:    print("ADD IY,SP")
            //        case 0xFD:    print("LD B,IYH")
            //        case 0xFD:    print("LD B,IYL")
            //        case 0xFD:    print("LD B,(IY+NN)")
            //        case 0xFD:    print("LD C,IYH")
            //        case 0xFD:    print("LD C,IYL")
            //        case 0xFD:    print("LD C,(IY+NN)")
            //        case 0xFD:    print("LD D,IYH")
            //        case 0xFD:    print("LD D,IYL")
            //        case 0xFD:    print("LD E,(IY+NN)")
            //        case 0xFD:    print("LD IYH,B")
            //        case 0xFD:    print("LD IYH,C")
            //        case 0xFD:    print("LD IYH,D")
            //        case 0xFD:    print("LD IYH,E")
            //        case 0xFD:    print("LD IYH,IYH")
            //        case 0xFD:    print("LD IYH,IYL")
            //        case 0xFD:    print("LD H,(IY+NN)")
            //        case 0xFD:    print("LD IYH,A")
            //        case 0xFD:    print("LD IYL,B")
            //        case 0xFD:    print("LD IYL,C")
            //        case 0xFD:    print("LD IYL,D")
            //        case 0xFD:    print("LD IYL,E")
            //        case 0xFD:    print("LD IYL,IYH")
            //        case 0xFD:    print("LD IYL,IYL")
            //        case 0xFD:    print("LD L,(IY+NN)")
            //        case 0xFD:    print("LD IYL,A")
            //        case 0xFD:    print("LD (IY+NN),B")
            //        case 0xFD:    print("LD (IY+NN),C")
            //        case 0xFD:    print("LD (IY+NN),D")
            //        case 0xFD:    print("LD (IY+NN),E")
            //        case 0xFD:    print("LD (IY+NN),H")
            //        case 0xFD:    print("LD (IY+NN),L")
            //        case 0xFD:    print("LD (IY+NN),A")
            //        case 0xFD:    print("LD A,IYH")
            //        case 0xFD:    print("LD A,IYL")
            //        case 0xFD:    print("LD A,(IY+NN)")
            //        case 0xFD:    print("ADD A,IYH")
            //        case 0xFD:    print("ADD A,IYL")
            //        case 0xFD:    print("ADD A,(IY+NN)")
            //        case 0xFD:    print("ADC A,IYH")
            //        case 0xFD:    print("ADC A,IYL")
            //        case 0xFD:    print("ADC A,(IY+NN)")
            //        case 0xFD:    print("SUB A,IYH")
            //        case 0xFD:    print("SUB A,IYL")
            //        case 0xFD:    print("SUB A,(IY+NN)")
            //        case 0xFD:    print("SBC A,IYH")
            //        case 0xFD:    print("SBC A,IYL")
            //        case 0xFD:    print("SBC A,(IY+NN)")
            //        case 0xFD:    print("AND IYH")
            //        case 0xFD:    print("AND IYL")
            //        case 0xFD:    print("AND (IY+NN)")
            //        case 0xFD:    print("XOR IYH")
            //        case 0xFD:    print("XOR IYL")
            //        case 0xFD:    print("XOR (IY+NN)")
            //        case 0xFD:    print("OR IYH")
            //        case 0xFD:    print("OR IYL")
            //        case 0xFD:    print("OR (IY+NN)")
            //        case 0xFD:    print("CP IYH")
            //        case 0xFD:    print("CP IYL")
            //        case 0xFD:    print("CP (IY+NN)")
            //        case 0xFD:    print("POP IY")
            //        case 0xFD:    print("EX (SP),IY")
            //        case 0xFD:    print("PUSH IY")
            //        case 0xFD:    print("JP (IY)")
        case 0xFE:
            print("CP NN")
        case 0xFF:
            print("RST 38")
        default:
            print("Unimplemented opcode",FirstByte)
        }
    }
    
    func DecodeInstruction(TheseRegisters : inout Registers, ThisMemory : inout MMU.MemoryBlock)
    {
    }
    
    func ExecuteInstruction(TheseRegisters : inout Registers, ThisMemory : inout MMU.MemoryBlock, ThisScreenMemory : inout Array<Float>)
    {
        ThisMemory.AddressSpace[Int(TheseRegisters.PC)] = TheseRegisters.A
        ThisScreenMemory[Int(TheseRegisters.PC-0xF000)] = Float(TheseRegisters.A)
    }
    
    func UpdateProgramCounter(TheseRegisters : inout Registers, ThisMemory : inout MMU.MemoryBlock, JumpValue : Int )
    {
        TheseRegisters.PC = TheseRegisters.PC+UInt16(JumpValue)
        if TheseRegisters.PC > 0xFFFF
        {
            TheseRegisters.PC = 0
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
    
    func DumpRam( BaseMemPointer : UInt16, MemPointer : UInt16, ThisMemory : MMU.MemoryBlock ) -> AttributedString {
        
        var FormattedString : String = String(format: "%04X",Int(MemPointer))+": "
        var FormattedAttributedString : AttributedString
        
        for index in Int(MemPointer)...Int(MemPointer)+15
        {
            FormattedString = FormattedString+String(format: "%02X",MyMMU.ReadAddress(MemPointer : UInt16(index),ThisMemory : ThisMemory)) + " "
        }
        
        FormattedString = FormattedString + "  "
        
        for index in Int(MemPointer)...Int(MemPointer)+15
        {
            switch MyMMU.ReadAddress(MemPointer : UInt16(index),ThisMemory : ThisMemory)
            {
            case 0...31 :
                FormattedString = FormattedString + " "
            case 128...255 :
                FormattedString  = FormattedString + "."
            default :
                FormattedString  = FormattedString + String(UnicodeScalar(MyMMU.ReadAddress(MemPointer : UInt16(index),ThisMemory : ThisMemory)))
            }
        }

        FormattedAttributedString = AttributedString(FormattedString)
        
        if (Int(BaseMemPointer) >= Int(MemPointer)) && (Int(BaseMemPointer) <= Int(MemPointer)+15)
        {
            let offset = Int(BaseMemPointer-MemPointer)
            let beginindex = FormattedAttributedString.characters.index(FormattedAttributedString.startIndex, offsetBy: 6+(offset*3))
            let endIndex = FormattedAttributedString.characters.index(FormattedAttributedString.startIndex, offsetBy: 8+(offset*3))
            FormattedAttributedString[beginindex..<endIndex].foregroundColor = .white
            FormattedAttributedString[beginindex..<endIndex].backgroundColor = .orange
        }
        
        return FormattedAttributedString
    }
    
    
    func ShowInstructions (InstructionNumber : Int, MemPointer : UInt16, ThisMemory : MMU.MemoryBlock) -> AttributedString {
        
        var FormattedString : String
        var FormattedAttributedString : AttributedString
        var FirstByte : UInt8
        var SecondByte : UInt8
        var ThirdByte : UInt8
        var FourthByte : UInt8
        var TargetInstructionLength : Int = 0
        var TargetAddress : UInt16
        
        var MyOpCode : OpCodes
        
        if InstructionNumber == 1
            
        {
            BaseMemPointer = MemPointer
        }
        
        for MyIndex in 1..<InstructionNumber
        {
            TargetInstructionLength = TargetInstructionLength+OpCodesList[Int(MyMMU.ReadAddress( MemPointer : BaseMemPointer + UInt16(TargetInstructionLength),ThisMemory : ThisMemory))].InstructionLength
        }
        
        TargetAddress = BaseMemPointer+UInt16(TargetInstructionLength)
        
        FirstByte = MyMMU.ReadAddress( MemPointer : TargetAddress,ThisMemory : ThisMemory)
        SecondByte = MyMMU.ReadAddress( MemPointer : TargetAddress+1,ThisMemory : ThisMemory)
        ThirdByte = MyMMU.ReadAddress( MemPointer : TargetAddress+2,ThisMemory : ThisMemory)
        
        MyOpCode = OpCodesList[Int(FirstByte)]
        
        switch MyOpCode.InstructionLength
        {
        case 1 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + "          " + MyOpCode.Assembler
        case 2 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + " " + String(format: "%02X",SecondByte) + "       " + MyOpCode.Assembler.replacingOccurrences(of: "n", with: String(format:"%02X",SecondByte))
        case 3 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + " " + String(format: "%02X",SecondByte) + " " + String(format: "%02X",ThirdByte) + "    " + MyOpCode.Assembler.replacingOccurrences(of: "nn", with: String(format:"%04X",Int(ThirdByte)*0x100+Int(SecondByte)))
        default : FormattedString = String(format: "%04X",TargetAddress)+": "
        }
        
        FormattedAttributedString = AttributedString(FormattedString)
        
        if (Int(MemPointer) == Int(TargetAddress))
        {
            FormattedAttributedString.foregroundColor = .white
            FormattedAttributedString.backgroundColor = .orange
        }
        
        return FormattedAttributedString
    }
}
