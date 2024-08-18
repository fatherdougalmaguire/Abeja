//
//  Z80.swift
//  Abeja
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
    
//    Matt4 has done some excellent research on this. He found that AF and SP are always set to FFFFh after a reset, and all other registers are undefined (different depending on how long the CPU has been powered off, different for different Z80 chips). Of course the PC should be set to 0 after a reset, and so should the IFF1 and IFF2 flags (otherwise strange things could happen). Also since the Z80 is 8080 compatible, interrupt mode is probably 0.
//    Probably the best way to simulate this in an emulator is set PC, IFF1, IFF2, IM to 0 and set all other registers to FFFFh.
    
    struct OpCodes
    {
        var OpcodePattern : String
        var Mnemonic  : String
        var OpcodeSize: Int
        var InstructionSize: Int
        var Cycle : [Int]
        var CFlag : String
        var NFlag : String
        var PVFlag : String
        var HFlag : String
        var ZFlag : String
        var SFlag : String
        var UndocumentedFlag : Bool
        var MnemonicDescription : String
    }
    
    let DefaultOpCode = OpCodes(OpcodePattern: "00:::", Mnemonic: "NOP", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "No operation is performed.")
    
    var OpCodesList = Dictionary<Int, OpCodes>()
    
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
        
        OpCodesList[0x00] = OpCodes(OpcodePattern: "00:::", Mnemonic: "NOP", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "No operation is performed.")
        OpCodesList[0x01] = OpCodes(OpcodePattern: "01:n:n:", Mnemonic: "LD BC,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $nn into BC.")
        OpCodesList[0x02] = OpCodes(OpcodePattern: "02:::", Mnemonic: "LD (BC),A", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores A into the memory location pointed to by BC.")
        OpCodesList[0x03] = OpCodes(OpcodePattern: "03:::", Mnemonic: "INC BC", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Adds one to BC")
        OpCodesList[0x04] = OpCodes(OpcodePattern: "04:::", Mnemonic: "INC B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to B")
        OpCodesList[0x05] = OpCodes(OpcodePattern: "05:::", Mnemonic: "DEC B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from B")
        OpCodesList[0x06] = OpCodes(OpcodePattern: "06:n::", Mnemonic: "LD B,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $n into B.")
        OpCodesList[0x07] = OpCodes(OpcodePattern: "07:::", Mnemonic: "RLCA", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "0", PVFlag: "-", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0x08] = OpCodes(OpcodePattern: "08:::", Mnemonic: "EX AF,AF'", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Exchanges the 16-bit contents of AF and AF'.")
        OpCodesList[0x09] = OpCodes(OpcodePattern: "09:::", Mnemonic: "ADD HL,BC", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of BC is added to HL.")
        OpCodesList[0x10] = OpCodes(OpcodePattern: "10:d::", Mnemonic: "DJNZ D", OpcodeSize: 1, InstructionSize: 2, Cycle: [13,8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The B register is decremented, and if not zero, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.")
        OpCodesList[0x11] = OpCodes(OpcodePattern: "11:n:n:", Mnemonic: "LD DE,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $nn into DE.")
        OpCodesList[0x12] = OpCodes(OpcodePattern: "12:::", Mnemonic: "LD (DE),A", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores A into the memory location pointed to by DE.")
        OpCodesList[0x13] = OpCodes(OpcodePattern: "13:::", Mnemonic: "INC DE", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Adds one to DE")
        OpCodesList[0x14] = OpCodes(OpcodePattern: "14:::", Mnemonic: "INC D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to D")
        OpCodesList[0x15] = OpCodes(OpcodePattern: "15:::", Mnemonic: "DEC D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from D")
        OpCodesList[0x16] = OpCodes(OpcodePattern: "16:::", Mnemonic: "LD D,N", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $n into D")
        OpCodesList[0x17] = OpCodes(OpcodePattern: "17:::", Mnemonic: "RLA", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "0", PVFlag: "-", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0x18] = OpCodes(OpcodePattern: "18:d::", Mnemonic: "JR D", OpcodeSize: 1, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The signed value $d is added to PC. The jump is measured from the start of the instruction opcode.")
        OpCodesList[0x19] = OpCodes(OpcodePattern: "19:::", Mnemonic: "ADD HL,DE", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of DE is added to HL.")
        OpCodesList[0x20] = OpCodes(OpcodePattern: "20:d::", Mnemonic: "JR NZ,D", OpcodeSize: 1, InstructionSize: 2, Cycle: [12,7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.")
        OpCodesList[0x21] = OpCodes(OpcodePattern: "21:n:n:", Mnemonic: "LD HL,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $nn into HL.")
        OpCodesList[0x22] = OpCodes(OpcodePattern: "22:n:n:", Mnemonic: "LD (NN),HL", OpcodeSize: 1, InstructionSize: 3, Cycle: [16], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores HL into the memory location pointed to by $nn.")
        OpCodesList[0x23] = OpCodes(OpcodePattern: "23:::", Mnemonic: "INC HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Adds one to HL")
        OpCodesList[0x24] = OpCodes(OpcodePattern: "24:::", Mnemonic: "INC H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to HL")
        OpCodesList[0x25] = OpCodes(OpcodePattern: "25:::", Mnemonic: "DEC H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from HL")
        OpCodesList[0x26] = OpCodes(OpcodePattern: "26:::", Mnemonic: "LD H,N", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $n into H")
        OpCodesList[0x27] = OpCodes(OpcodePattern: "27:::", Mnemonic: "DAA", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "*", NFlag: "-", PVFlag: "p", HFlag: "*", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adjusts A for BCD addition and subtraction operations.")
        OpCodesList[0x28] = OpCodes(OpcodePattern: "28:d::", Mnemonic: "JR Z,D", OpcodeSize: 1, InstructionSize: 2, Cycle: [12,7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.")
        OpCodesList[0x29] = OpCodes(OpcodePattern: "29:::", Mnemonic: "ADD HL,HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of HL is added to HL.")
        OpCodesList[0x30] = OpCodes(OpcodePattern: "30:d::", Mnemonic: "JR NC,D", OpcodeSize: 1, InstructionSize: 2, Cycle: [12,7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is unset, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.")
        OpCodesList[0x31] = OpCodes(OpcodePattern: "31:n:n:", Mnemonic: "LD SP,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $nn into SP.")
        OpCodesList[0x32] = OpCodes(OpcodePattern: "32:n:n:", Mnemonic: "LD (NN),A", OpcodeSize: 1, InstructionSize: 3, Cycle: [13], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores A into the memory location pointed to by $nn.")
        OpCodesList[0x33] = OpCodes(OpcodePattern: "33:::", Mnemonic: "INC SP", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Adds one to SP")
        OpCodesList[0x34] = OpCodes(OpcodePattern: "34:::", Mnemonic: "INC (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to (HL).")
        OpCodesList[0x35] = OpCodes(OpcodePattern: "35:::", Mnemonic: "DEC (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from (HL).")
        OpCodesList[0x36] = OpCodes(OpcodePattern: "36:n::", Mnemonic: "LD (HL),N", OpcodeSize: 1, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $n into (HL).")
        OpCodesList[0x37] = OpCodes(OpcodePattern: "37:::", Mnemonic: "SCF", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "1", NFlag: "0", PVFlag: "-", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets the carry flag.")
        OpCodesList[0x38] = OpCodes(OpcodePattern: "38:d::", Mnemonic: "JR C,D", OpcodeSize: 1, InstructionSize: 2, Cycle: [12,7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is set, the signed value $d is added to PC. The jump is measured from the start of the instruction opcode.")
        OpCodesList[0x39] = OpCodes(OpcodePattern: "39:::", Mnemonic: "ADD HL,SP", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of SP is added to HL.")
        OpCodesList[0x40] = OpCodes(OpcodePattern: "40:::", Mnemonic: "LD B,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into B")
        OpCodesList[0x41] = OpCodes(OpcodePattern: "41:::", Mnemonic: "LD B,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into B")
        OpCodesList[0x42] = OpCodes(OpcodePattern: "42:::", Mnemonic: "LD B,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into B")
        OpCodesList[0x43] = OpCodes(OpcodePattern: "43:::", Mnemonic: "LD B,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of E are loaded into B")
        OpCodesList[0x44] = OpCodes(OpcodePattern: "44:::", Mnemonic: "LD B,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of H are loaded into B")
        OpCodesList[0x45] = OpCodes(OpcodePattern: "45:::", Mnemonic: "LD B,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of L are loaded into B")
        OpCodesList[0x46] = OpCodes(OpcodePattern: "46:::", Mnemonic: "LD B,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into B")
        OpCodesList[0x47] = OpCodes(OpcodePattern: "47:::", Mnemonic: "LD B,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are loaded into B.")
        OpCodesList[0x48] = OpCodes(OpcodePattern: "48:::", Mnemonic: "LD C,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into C.")
        OpCodesList[0x49] = OpCodes(OpcodePattern: "49:::", Mnemonic: "LD C,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into C.")
        OpCodesList[0x50] = OpCodes(OpcodePattern: "50:::", Mnemonic: "LD D,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into D")
        OpCodesList[0x51] = OpCodes(OpcodePattern: "51:::", Mnemonic: "LD D,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into D")
        OpCodesList[0x52] = OpCodes(OpcodePattern: "52:::", Mnemonic: "LD D,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into D")
        OpCodesList[0x53] = OpCodes(OpcodePattern: "53:::", Mnemonic: "LD D,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of E are loaded into D")
        OpCodesList[0x54] = OpCodes(OpcodePattern: "54:::", Mnemonic: "LD D,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of H are loaded into D")
        OpCodesList[0x55] = OpCodes(OpcodePattern: "55:::", Mnemonic: "LD D,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of L are loaded into D")
        OpCodesList[0x56] = OpCodes(OpcodePattern: "56:::", Mnemonic: "LD D,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into D")
        OpCodesList[0x57] = OpCodes(OpcodePattern: "57:::", Mnemonic: "LD D,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are loaded into D.")
        OpCodesList[0x58] = OpCodes(OpcodePattern: "58:::", Mnemonic: "LD E,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into E.")
        OpCodesList[0x59] = OpCodes(OpcodePattern: "59:::", Mnemonic: "LD E,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into E.")
        OpCodesList[0x60] = OpCodes(OpcodePattern: "60:::", Mnemonic: "LD H,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into H")
        OpCodesList[0x61] = OpCodes(OpcodePattern: "61:::", Mnemonic: "LD H,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into H")
        OpCodesList[0x62] = OpCodes(OpcodePattern: "62:::", Mnemonic: "LD H,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of  D are loaded into H")
        OpCodesList[0x63] = OpCodes(OpcodePattern: "63:::", Mnemonic: "LD H,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of E are loaded into H")
        OpCodesList[0x64] = OpCodes(OpcodePattern: "64:::", Mnemonic: "LD H,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of H are loaded into H")
        OpCodesList[0x65] = OpCodes(OpcodePattern: "65:::", Mnemonic: "LD H,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of L are loaded into H")
        OpCodesList[0x66] = OpCodes(OpcodePattern: "66:::", Mnemonic: "LD H,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into H")
        OpCodesList[0x67] = OpCodes(OpcodePattern: "67:::", Mnemonic: "LD H,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are loaded into H.")
        OpCodesList[0x68] = OpCodes(OpcodePattern: "68:::", Mnemonic: "LD L,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into L.")
        OpCodesList[0x69] = OpCodes(OpcodePattern: "69:::", Mnemonic: "LD L,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into L.")
        OpCodesList[0x70] = OpCodes(OpcodePattern: "70:::", Mnemonic: "LD (HL),B", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into (HL).")
        OpCodesList[0x71] = OpCodes(OpcodePattern: "71:::", Mnemonic: "LD (HL),C", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into (HL).")
        OpCodesList[0x72] = OpCodes(OpcodePattern: "72:::", Mnemonic: "LD (HL),D", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into (HL).")
        OpCodesList[0x73] = OpCodes(OpcodePattern: "73:::", Mnemonic: "LD (HL),E", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of E are loaded into (HL).")
        OpCodesList[0x74] = OpCodes(OpcodePattern: "74:::", Mnemonic: "LD (HL),H", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of H are loaded into (HL).")
        OpCodesList[0x75] = OpCodes(OpcodePattern: "75:::", Mnemonic: "LD (HL),L", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of L are loaded into (HL).")
        OpCodesList[0x76] = OpCodes(OpcodePattern: "76:::", Mnemonic: "HALT", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Suspends CPU operation until an interrupt or reset occurs.")
        OpCodesList[0x77] = OpCodes(OpcodePattern: "77:::", Mnemonic: "LD (HL),A", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are loaded into (HL).")
        OpCodesList[0x78] = OpCodes(OpcodePattern: "78:::", Mnemonic: "LD A,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of B are loaded into A.")
        OpCodesList[0x79] = OpCodes(OpcodePattern: "79:::", Mnemonic: "LD A,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of C are loaded into A.")
        OpCodesList[0x80] = OpCodes(OpcodePattern: "80:::", Mnemonic: "ADD A,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds B to A.")
        OpCodesList[0x81] = OpCodes(OpcodePattern: "81:::", Mnemonic: "ADD A,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds C to A.")
        OpCodesList[0x82] = OpCodes(OpcodePattern: "82:::", Mnemonic: "ADD A,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds D to A.")
        OpCodesList[0x83] = OpCodes(OpcodePattern: "83:::", Mnemonic: "ADD A,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds E to A.")
        OpCodesList[0x84] = OpCodes(OpcodePattern: "84:::", Mnemonic: "ADD A,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds H to A.")
        OpCodesList[0x85] = OpCodes(OpcodePattern: "85:::", Mnemonic: "ADD A,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds L to A.")
        OpCodesList[0x86] = OpCodes(OpcodePattern: "86:::", Mnemonic: "ADD A,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds (HL) to A.")
        OpCodesList[0x87] = OpCodes(OpcodePattern: "87:::", Mnemonic: "ADD A,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds A to A.")
        OpCodesList[0x88] = OpCodes(OpcodePattern: "88:::", Mnemonic: "ADC A,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds B and the carry flag to A.")
        OpCodesList[0x89] = OpCodes(OpcodePattern: "89:::", Mnemonic: "ADC A,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds C and the carry flag to A.")
        OpCodesList[0x90] = OpCodes(OpcodePattern: "90:::", Mnemonic: "SUB B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $r from A.")
        OpCodesList[0x91] = OpCodes(OpcodePattern: "91:::", Mnemonic: "SUB C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $r from A.")
        OpCodesList[0x92] = OpCodes(OpcodePattern: "92:::", Mnemonic: "SUB D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $r from A.")
        OpCodesList[0x93] = OpCodes(OpcodePattern: "93:::", Mnemonic: "SUB E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $r from A.")
        OpCodesList[0x94] = OpCodes(OpcodePattern: "94:::", Mnemonic: "SUB H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $r from A.")
        OpCodesList[0x95] = OpCodes(OpcodePattern: "95:::", Mnemonic: "SUB L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $r from A.")
        OpCodesList[0x96] = OpCodes(OpcodePattern: "96:::", Mnemonic: "SUB (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts (HL) from A.")
        OpCodesList[0x97] = OpCodes(OpcodePattern: "97:::", Mnemonic: "SUB A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts A from A.")
        OpCodesList[0x98] = OpCodes(OpcodePattern: "98:::", Mnemonic: "SBC A,B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts B and the carry flag from A.")
        OpCodesList[0x99] = OpCodes(OpcodePattern: "99:::", Mnemonic: "SBC A,C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts C and the carry flag from A.")
        OpCodesList[0x0A] = OpCodes(OpcodePattern: "0A:::", Mnemonic: "LD A,(BC)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by BC into A.")
        OpCodesList[0x0B] = OpCodes(OpcodePattern: "0B:::", Mnemonic: "DEC BC", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from BC")
        OpCodesList[0x0C] = OpCodes(OpcodePattern: "0C:::", Mnemonic: "INC C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to C.")
        OpCodesList[0x0D] = OpCodes(OpcodePattern: "0D:::", Mnemonic: "DEC C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from C.")
        OpCodesList[0x0E] = OpCodes(OpcodePattern: "0E:n::", Mnemonic: "LD C,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads n into C")
        OpCodesList[0x0F] = OpCodes(OpcodePattern: "0F:::", Mnemonic: "RRCA", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "0", PVFlag: "-", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0x1A] = OpCodes(OpcodePattern: "1A:::", Mnemonic: "LD A,(DE)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by DE into A.")
        OpCodesList[0x1B] = OpCodes(OpcodePattern: "1B:::", Mnemonic: "DEC DE", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from DE")
        OpCodesList[0x1C] = OpCodes(OpcodePattern: "1C:::", Mnemonic: "INC E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to E.")
        OpCodesList[0x1D] = OpCodes(OpcodePattern: "1D:::", Mnemonic: "DEC E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from E.")
        OpCodesList[0x1E] = OpCodes(OpcodePattern: "1E:n::", Mnemonic: "LD E,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads n into E.")
        OpCodesList[0x1F] = OpCodes(OpcodePattern: "1F:::", Mnemonic: "RRA", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "0", PVFlag: "-", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0x2A] = OpCodes(OpcodePattern: "2A:n:n:", Mnemonic: "LD HL,(NN)", OpcodeSize: 1, InstructionSize: 3, Cycle: [16], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into HL.")
        OpCodesList[0x2B] = OpCodes(OpcodePattern: "2B:::", Mnemonic: "DEC HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from HL")
        OpCodesList[0x2C] = OpCodes(OpcodePattern: "2C:::", Mnemonic: "INC L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to L.")
        OpCodesList[0x2D] = OpCodes(OpcodePattern: "2D:::", Mnemonic: "DEC L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from L.")
        OpCodesList[0x2E] = OpCodes(OpcodePattern: "2E:::", Mnemonic: "LD L,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads n into L.")
        OpCodesList[0x2F] = OpCodes(OpcodePattern: "2F:::", Mnemonic: "CPL", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "1", PVFlag: "-", HFlag: "1", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of A are inverted (one's complement).")
        OpCodesList[0x3A] = OpCodes(OpcodePattern: "3A:n:n:", Mnemonic: "LD A,(NN)", OpcodeSize: 1, InstructionSize: 3, Cycle: [13], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into A.")
        OpCodesList[0x3B] = OpCodes(OpcodePattern: "3B:::", Mnemonic: "DEC SP", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from SP")
        OpCodesList[0x3C] = OpCodes(OpcodePattern: "3C:::", Mnemonic: "INC A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to A.")
        OpCodesList[0x3D] = OpCodes(OpcodePattern: "3D:::", Mnemonic: "DEC A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from A.")
        OpCodesList[0x3E] = OpCodes(OpcodePattern: "3E:n::", Mnemonic: "LD A,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads n into A.")
        OpCodesList[0x3F] = OpCodes(OpcodePattern: "3F:::", Mnemonic: "CCF", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "*", NFlag: "0", PVFlag: "-", HFlag: "*", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Inverts the carry flag.")
        OpCodesList[0x4A] = OpCodes(OpcodePattern: "4A:::", Mnemonic: "LD C,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into C.")
        OpCodesList[0x4B] = OpCodes(OpcodePattern: "4B:::", Mnemonic: "LD C,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into C.")
        OpCodesList[0x4C] = OpCodes(OpcodePattern: "4C:::", Mnemonic: "LD C,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into C.")
        OpCodesList[0x4D] = OpCodes(OpcodePattern: "4D:::", Mnemonic: "LD C,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into C.")
        OpCodesList[0x4E] = OpCodes(OpcodePattern: "4E:::", Mnemonic: "LD C,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into C.")
        OpCodesList[0x4F] = OpCodes(OpcodePattern: "4F:::", Mnemonic: "LD C,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into C.")
        OpCodesList[0x5A] = OpCodes(OpcodePattern: "5A:::", Mnemonic: "LD E,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into E")
        OpCodesList[0x5B] = OpCodes(OpcodePattern: "5B:::", Mnemonic: "LD E,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into E")
        OpCodesList[0x5C] = OpCodes(OpcodePattern: "5C:::", Mnemonic: "LD E,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into E")
        OpCodesList[0x5D] = OpCodes(OpcodePattern: "5D:::", Mnemonic: "LD E,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into E")
        OpCodesList[0x5E] = OpCodes(OpcodePattern: "5E:::", Mnemonic: "LD E,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into E")
        OpCodesList[0x5F] = OpCodes(OpcodePattern: "5F:::", Mnemonic: "LD E,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into E")
        OpCodesList[0x6A] = OpCodes(OpcodePattern: "6A:::", Mnemonic: "LD L,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into L")
        OpCodesList[0x6B] = OpCodes(OpcodePattern: "6B:::", Mnemonic: "LD L,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into L")
        OpCodesList[0x6C] = OpCodes(OpcodePattern: "6C:::", Mnemonic: "LD L,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into L")
        OpCodesList[0x6D] = OpCodes(OpcodePattern: "6D:::", Mnemonic: "LD L,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into L")
        OpCodesList[0x6E] = OpCodes(OpcodePattern: "6E:::", Mnemonic: "LD L,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into L")
        OpCodesList[0x6F] = OpCodes(OpcodePattern: "6F:::", Mnemonic: "LD L,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into L")
        OpCodesList[0x7A] = OpCodes(OpcodePattern: "7A:::", Mnemonic: "LD A,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into A")
        OpCodesList[0x7B] = OpCodes(OpcodePattern: "7B:::", Mnemonic: "LD A,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into A")
        OpCodesList[0x7C] = OpCodes(OpcodePattern: "7C:::", Mnemonic: "LD A,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into A")
        OpCodesList[0x7D] = OpCodes(OpcodePattern: "7D:::", Mnemonic: "LD A,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into A")
        OpCodesList[0x7E] = OpCodes(OpcodePattern: "7E:::", Mnemonic: "LD A,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are loaded into A")
        OpCodesList[0x7F] = OpCodes(OpcodePattern: "7F:::", Mnemonic: "LD A,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The contents of D are loaded into A")
        OpCodesList[0x8A] = OpCodes(OpcodePattern: "8A:::", Mnemonic: "ADC A,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds D and the carry flag to A.")
        OpCodesList[0x8B] = OpCodes(OpcodePattern: "8B:::", Mnemonic: "ADC A,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds E and the carry flag to A.")
        OpCodesList[0x8C] = OpCodes(OpcodePattern: "8C:::", Mnemonic: "ADC A,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds H and the carry flag to A.")
        OpCodesList[0x8D] = OpCodes(OpcodePattern: "8D:::", Mnemonic: "ADC A,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds L and the carry flag to A.")
        OpCodesList[0x8E] = OpCodes(OpcodePattern: "8E:::", Mnemonic: "ADC A,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds (HL) and the carry flag to A.")
        OpCodesList[0x8F] = OpCodes(OpcodePattern: "8F:::", Mnemonic: "ADC A,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds A and the carry flag to A.")
        OpCodesList[0x9A] = OpCodes(OpcodePattern: "9A:::", Mnemonic: "SBC A,D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts D and the carry flag from A.")
        OpCodesList[0x9B] = OpCodes(OpcodePattern: "9B:::", Mnemonic: "SBC A,E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts E and the carry flag from A.")
        OpCodesList[0x9C] = OpCodes(OpcodePattern: "9C:::", Mnemonic: "SBC A,H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts H and the carry flag from A.")
        OpCodesList[0x9D] = OpCodes(OpcodePattern: "9D:::", Mnemonic: "SBC A,L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts L and the carry flag from A.")
        OpCodesList[0x9E] = OpCodes(OpcodePattern: "9E:::", Mnemonic: "SBC A,(HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts (HL) and the carry flag from A.")
        OpCodesList[0x9F] = OpCodes(OpcodePattern: "9F:::", Mnemonic: "SBC A,A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts A and the carry flag from A.")
        OpCodesList[0xA0] = OpCodes(OpcodePattern: "A0:::", Mnemonic: "AND B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with B")
        OpCodesList[0xA1] = OpCodes(OpcodePattern: "A1:::", Mnemonic: "AND C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with C")
        OpCodesList[0xA2] = OpCodes(OpcodePattern: "A2:::", Mnemonic: "AND D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with D")
        OpCodesList[0xA3] = OpCodes(OpcodePattern: "A3:::", Mnemonic: "AND E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with E")
        OpCodesList[0xA4] = OpCodes(OpcodePattern: "A4:::", Mnemonic: "AND H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with H")
        OpCodesList[0xA5] = OpCodes(OpcodePattern: "A5:::", Mnemonic: "AND L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with L")
        OpCodesList[0xA6] = OpCodes(OpcodePattern: "A6:::", Mnemonic: "AND (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with (HL).")
        OpCodesList[0xA7] = OpCodes(OpcodePattern: "A7:::", Mnemonic: "AND A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with A.")
        OpCodesList[0xA8] = OpCodes(OpcodePattern: "A8:::", Mnemonic: "XOR B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with B")
        OpCodesList[0xA9] = OpCodes(OpcodePattern: "A9:::", Mnemonic: "XOR C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with C")
        OpCodesList[0xAA] = OpCodes(OpcodePattern: "AA:::", Mnemonic: "XOR D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with D")
        OpCodesList[0xAB] = OpCodes(OpcodePattern: "AB:::", Mnemonic: "XOR E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with E")
        OpCodesList[0xAC] = OpCodes(OpcodePattern: "AC:::", Mnemonic: "XOR H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with H")
        OpCodesList[0xAD] = OpCodes(OpcodePattern: "AD:::", Mnemonic: "XOR L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with L")
        OpCodesList[0xAE] = OpCodes(OpcodePattern: "AE:::", Mnemonic: "XOR (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with (HL).")
        OpCodesList[0xAF] = OpCodes(OpcodePattern: "AF:::", Mnemonic: "XOR A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with A.")
        OpCodesList[0xB0] = OpCodes(OpcodePattern: "B0:::", Mnemonic: "OR B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with B")
        OpCodesList[0xB1] = OpCodes(OpcodePattern: "B1:::", Mnemonic: "OR C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with C")
        OpCodesList[0xB2] = OpCodes(OpcodePattern: "B2:::", Mnemonic: "OR D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with D")
        OpCodesList[0xB3] = OpCodes(OpcodePattern: "B3:::", Mnemonic: "OR E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with E")
        OpCodesList[0xB4] = OpCodes(OpcodePattern: "B4:::", Mnemonic: "OR H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with H")
        OpCodesList[0xB5] = OpCodes(OpcodePattern: "B5:::", Mnemonic: "OR L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with L")
        OpCodesList[0xB6] = OpCodes(OpcodePattern: "B6:::", Mnemonic: "OR (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with (HL).")
        OpCodesList[0xB7] = OpCodes(OpcodePattern: "B7:::", Mnemonic: "OR A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with A.")
        OpCodesList[0xB8] = OpCodes(OpcodePattern: "B8:::", Mnemonic: "CP B", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts B from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xB9] = OpCodes(OpcodePattern: "B9:::", Mnemonic: "CP C", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts C from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xBA] = OpCodes(OpcodePattern: "BA:::", Mnemonic: "CP D", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts D from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xBB] = OpCodes(OpcodePattern: "BB:::", Mnemonic: "CP E", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts E from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xBC] = OpCodes(OpcodePattern: "BC:::", Mnemonic: "CP H", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts H from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xBD] = OpCodes(OpcodePattern: "BD:::", Mnemonic: "CP L", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts L from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xBE] = OpCodes(OpcodePattern: "BE:::", Mnemonic: "CP (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts (HL) from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xBF] = OpCodes(OpcodePattern: "BF:::", Mnemonic: "CP A", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts A from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xC0] = OpCodes(OpcodePattern: "C0:::", Mnemonic: "RET NZ", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is unset, the top stack entry is popped into PC.")
        OpCodesList[0xC1] = OpCodes(OpcodePattern: "C1:::", Mnemonic: "POP BC", OpcodeSize: 1, InstructionSize: 1, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The memory location pointed to by SP is stored into C and SP is incremented. The memory location pointed to by SP is stored into B and SP is incremented again.")
        OpCodesList[0xC2] = OpCodes(OpcodePattern: "C2:n:n:", Mnemonic: "JP NZ,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is unset, $nn is copied to PC.")
        OpCodesList[0xC3] = OpCodes(OpcodePattern: "C3:n:n:", Mnemonic: "JP NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "$nn is copied to PC.")
        OpCodesList[0xC4] = OpCodes(OpcodePattern: "C4:n:n:", Mnemonic: "CALL NZ,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xC5] = OpCodes(OpcodePattern: "C5:::", Mnemonic: "PUSH BC", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "SP is decremented and B is stored into the memory location pointed to by SP. SP is decremented again and C is stored into the memory location pointed to by SP.")
        OpCodesList[0xC6] = OpCodes(OpcodePattern: "C6:n::", Mnemonic: "ADD A,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds $n to A.")
        OpCodesList[0xC7] = OpCodes(OpcodePattern: "C7:::", Mnemonic: "RST 00H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 00H.")
        OpCodesList[0xC8] = OpCodes(OpcodePattern: "C8:::", Mnemonic: "RET Z", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is set, the top stack entry is popped into PC.")
        OpCodesList[0xC9] = OpCodes(OpcodePattern: "C9:::", Mnemonic: "RET", OpcodeSize: 1, InstructionSize: 1, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The top stack entry is popped into PC.")
        OpCodesList[0xCA] = OpCodes(OpcodePattern: "CA:n:n:", Mnemonic: "JP Z,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is set, $nn is copied to PC.")
        OpCodesList[0xCB00] = OpCodes(OpcodePattern: "CB:00::", Mnemonic: "RLC B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB01] = OpCodes(OpcodePattern: "CB:01::", Mnemonic: "RLC C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB02] = OpCodes(OpcodePattern: "CB:02::", Mnemonic: "RLC D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB03] = OpCodes(OpcodePattern: "CB:03::", Mnemonic: "RLC E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB04] = OpCodes(OpcodePattern: "CB:04::", Mnemonic: "RLC H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB05] = OpCodes(OpcodePattern: "CB:05::", Mnemonic: "RLC L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB06] = OpCodes(OpcodePattern: "CB:06::", Mnemonic: "RLC (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB07] = OpCodes(OpcodePattern: "CB:07::", Mnemonic: "RLC A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xCB08] = OpCodes(OpcodePattern: "CB:08::", Mnemonic: "RRC B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB09] = OpCodes(OpcodePattern: "CB:09::", Mnemonic: "RRC C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB0A] = OpCodes(OpcodePattern: "CB:0A::", Mnemonic: "RRC D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB0B] = OpCodes(OpcodePattern: "CB:0B::", Mnemonic: "RRC E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB0C] = OpCodes(OpcodePattern: "CB:0C::", Mnemonic: "RRC H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB0D] = OpCodes(OpcodePattern: "CB:0D::", Mnemonic: "RRC L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB0E] = OpCodes(OpcodePattern: "CB:0E::", Mnemonic: "RRC (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB0F] = OpCodes(OpcodePattern: "CB:0F::", Mnemonic: "RRC A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xCB10] = OpCodes(OpcodePattern: "CB:10::", Mnemonic: "RL B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB11] = OpCodes(OpcodePattern: "CB:11::", Mnemonic: "RL C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB12] = OpCodes(OpcodePattern: "CB:12::", Mnemonic: "RL D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB13] = OpCodes(OpcodePattern: "CB:13::", Mnemonic: "RL E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB14] = OpCodes(OpcodePattern: "CB:14::", Mnemonic: "RL H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB15] = OpCodes(OpcodePattern: "CB:15::", Mnemonic: "RL L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB16] = OpCodes(OpcodePattern: "CB:16::", Mnemonic: "RL (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB17] = OpCodes(OpcodePattern: "CB:17::", Mnemonic: "RL A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xCB18] = OpCodes(OpcodePattern: "CB:18::", Mnemonic: "RR B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB19] = OpCodes(OpcodePattern: "CB:19::", Mnemonic: "RR C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB1A] = OpCodes(OpcodePattern: "CB:1A::", Mnemonic: "RR D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB1B] = OpCodes(OpcodePattern: "CB:1B::", Mnemonic: "RR E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB1C] = OpCodes(OpcodePattern: "CB:1C::", Mnemonic: "RR H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB1D] = OpCodes(OpcodePattern: "CB:1D::", Mnemonic: "RR L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB1E] = OpCodes(OpcodePattern: "CB:1E::", Mnemonic: "RR (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB1F] = OpCodes(OpcodePattern: "CB:1F::", Mnemonic: "RR A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xCB20] = OpCodes(OpcodePattern: "CB:20::", Mnemonic: "SLA B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB21] = OpCodes(OpcodePattern: "CB:21::", Mnemonic: "SLA C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB22] = OpCodes(OpcodePattern: "CB:22::", Mnemonic: "SLA D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB23] = OpCodes(OpcodePattern: "CB:23::", Mnemonic: "SLA E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB24] = OpCodes(OpcodePattern: "CB:24::", Mnemonic: "SLA H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB25] = OpCodes(OpcodePattern: "CB:25::", Mnemonic: "SLA L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB26] = OpCodes(OpcodePattern: "CB:26::", Mnemonic: "SLA (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB27] = OpCodes(OpcodePattern: "CB:27::", Mnemonic: "SLA A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xCB28] = OpCodes(OpcodePattern: "CB:28::", Mnemonic: "SRA B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB29] = OpCodes(OpcodePattern: "CB:29::", Mnemonic: "SRA C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB2A] = OpCodes(OpcodePattern: "CB:2A::", Mnemonic: "SRA D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB2B] = OpCodes(OpcodePattern: "CB:2B::", Mnemonic: "SRA E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB2C] = OpCodes(OpcodePattern: "CB:2C::", Mnemonic: "SRA H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB2D] = OpCodes(OpcodePattern: "CB:2D::", Mnemonic: "SRA L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB2E] = OpCodes(OpcodePattern: "CB:2E::", Mnemonic: "SRA (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB2F] = OpCodes(OpcodePattern: "CB:2F::", Mnemonic: "SRA A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xCB30] = OpCodes(OpcodePattern: "CB:30::", Mnemonic: "SLL B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of B are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB31] = OpCodes(OpcodePattern: "CB:31::", Mnemonic: "SLL C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of C are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB32] = OpCodes(OpcodePattern: "CB:32::", Mnemonic: "SLL D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of D are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB33] = OpCodes(OpcodePattern: "CB:33::", Mnemonic: "SLL E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of E are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB34] = OpCodes(OpcodePattern: "CB:34::", Mnemonic: "SLL H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of H are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB35] = OpCodes(OpcodePattern: "CB:35::", Mnemonic: "SLL L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of L are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB36] = OpCodes(OpcodePattern: "CB:36::", Mnemonic: "SLL (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of (HL) are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB37] = OpCodes(OpcodePattern: "CB:37::", Mnemonic: "SLL A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of A are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xCB38] = OpCodes(OpcodePattern: "CB:38::", Mnemonic: "SRL B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of B are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB39] = OpCodes(OpcodePattern: "CB:39::", Mnemonic: "SRL C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of C are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB3A] = OpCodes(OpcodePattern: "CB:3A::", Mnemonic: "SRL D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of D are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB3B] = OpCodes(OpcodePattern: "CB:3B::", Mnemonic: "SRL E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of E are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB3C] = OpCodes(OpcodePattern: "CB:3C::", Mnemonic: "SRL H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of H are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB3D] = OpCodes(OpcodePattern: "CB:3D::", Mnemonic: "SRL L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of L are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB3E] = OpCodes(OpcodePattern: "CB:3E::", Mnemonic: "SRL (HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of (HL) are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB3F] = OpCodes(OpcodePattern: "CB:3F::", Mnemonic: "SRL A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xCB40] = OpCodes(OpcodePattern: "CB:40::", Mnemonic: "BIT 0,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of B")
        OpCodesList[0xCB41] = OpCodes(OpcodePattern: "CB:41::", Mnemonic: "BIT 0,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of C")
        OpCodesList[0xCB42] = OpCodes(OpcodePattern: "CB:42::", Mnemonic: "BIT 0,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of D")
        OpCodesList[0xCB43] = OpCodes(OpcodePattern: "CB:43::", Mnemonic: "BIT 0,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of E")
        OpCodesList[0xCB44] = OpCodes(OpcodePattern: "CB:44::", Mnemonic: "BIT 0,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of H")
        OpCodesList[0xCB45] = OpCodes(OpcodePattern: "CB:45::", Mnemonic: "BIT 0,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of L")
        OpCodesList[0xCB46] = OpCodes(OpcodePattern: "CB:46::", Mnemonic: "BIT 0,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of (HL).")
        OpCodesList[0xCB47] = OpCodes(OpcodePattern: "CB:47::", Mnemonic: "BIT 0,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of A.")
        OpCodesList[0xCB48] = OpCodes(OpcodePattern: "CB:48::", Mnemonic: "BIT 1,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of B.")
        OpCodesList[0xCB49] = OpCodes(OpcodePattern: "CB:49::", Mnemonic: "BIT 1,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of C")
        OpCodesList[0xCB4A] = OpCodes(OpcodePattern: "CB:4A::", Mnemonic: "BIT 1,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of D")
        OpCodesList[0xCB4B] = OpCodes(OpcodePattern: "CB:4B::", Mnemonic: "BIT 1,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of E")
        OpCodesList[0xCB4C] = OpCodes(OpcodePattern: "CB:4C::", Mnemonic: "BIT 1,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of H")
        OpCodesList[0xCB4D] = OpCodes(OpcodePattern: "CB:4D::", Mnemonic: "BIT 1,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of L")
        OpCodesList[0xCB4E] = OpCodes(OpcodePattern: "CB:4E::", Mnemonic: "BIT 1,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of (HL).")
        OpCodesList[0xCB4F] = OpCodes(OpcodePattern: "CB:4F::", Mnemonic: "BIT 1,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of A")
        OpCodesList[0xCB50] = OpCodes(OpcodePattern: "CB:50::", Mnemonic: "BIT 2,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of B")
        OpCodesList[0xCB51] = OpCodes(OpcodePattern: "CB:51::", Mnemonic: "BIT 2,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of C")
        OpCodesList[0xCB52] = OpCodes(OpcodePattern: "CB:52::", Mnemonic: "BIT 2,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of D")
        OpCodesList[0xCB53] = OpCodes(OpcodePattern: "CB:53::", Mnemonic: "BIT 2,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of E")
        OpCodesList[0xCB54] = OpCodes(OpcodePattern: "CB:54::", Mnemonic: "BIT 2,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of H")
        OpCodesList[0xCB55] = OpCodes(OpcodePattern: "CB:55::", Mnemonic: "BIT 2,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of L")
        OpCodesList[0xCB56] = OpCodes(OpcodePattern: "CB:56::", Mnemonic: "BIT 2,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of (HL).")
        OpCodesList[0xCB57] = OpCodes(OpcodePattern: "CB:57::", Mnemonic: "BIT 2,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of A")
        OpCodesList[0xCB58] = OpCodes(OpcodePattern: "CB:58::", Mnemonic: "BIT 3,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of B")
        OpCodesList[0xCB59] = OpCodes(OpcodePattern: "CB:59::", Mnemonic: "BIT 3,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of C")
        OpCodesList[0xCB5A] = OpCodes(OpcodePattern: "CB:5A::", Mnemonic: "BIT 3,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of D")
        OpCodesList[0xCB5B] = OpCodes(OpcodePattern: "CB:5B::", Mnemonic: "BIT 3,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of E")
        OpCodesList[0xCB5C] = OpCodes(OpcodePattern: "CB:5C::", Mnemonic: "BIT 3,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of H")
        OpCodesList[0xCB5D] = OpCodes(OpcodePattern: "CB:5D::", Mnemonic: "BIT 3,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of L")
        OpCodesList[0xCB5E] = OpCodes(OpcodePattern: "CB:5E::", Mnemonic: "BIT 3,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of (HL).")
        OpCodesList[0xCB5F] = OpCodes(OpcodePattern: "CB:5F::", Mnemonic: "BIT 3,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of A")
        OpCodesList[0xCB60] = OpCodes(OpcodePattern: "CB:60::", Mnemonic: "BIT 4,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of B")
        OpCodesList[0xCB61] = OpCodes(OpcodePattern: "CB:61::", Mnemonic: "BIT 4,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of C")
        OpCodesList[0xCB62] = OpCodes(OpcodePattern: "CB:62::", Mnemonic: "BIT 4,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of D")
        OpCodesList[0xCB63] = OpCodes(OpcodePattern: "CB:63::", Mnemonic: "BIT 4,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of E")
        OpCodesList[0xCB64] = OpCodes(OpcodePattern: "CB:64::", Mnemonic: "BIT 4,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of H")
        OpCodesList[0xCB65] = OpCodes(OpcodePattern: "CB:65::", Mnemonic: "BIT 4,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of L")
        OpCodesList[0xCB66] = OpCodes(OpcodePattern: "CB:66::", Mnemonic: "BIT 4,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of (HL).")
        OpCodesList[0xCB67] = OpCodes(OpcodePattern: "CB:67::", Mnemonic: "BIT 4,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of A")
        OpCodesList[0xCB68] = OpCodes(OpcodePattern: "CB:68::", Mnemonic: "BIT 5,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of B")
        OpCodesList[0xCB69] = OpCodes(OpcodePattern: "CB:69::", Mnemonic: "BIT 5,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of C")
        OpCodesList[0xCB6A] = OpCodes(OpcodePattern: "CB:6A::", Mnemonic: "BIT 5,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of D")
        OpCodesList[0xCB6B] = OpCodes(OpcodePattern: "CB:6B::", Mnemonic: "BIT 5,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of E")
        OpCodesList[0xCB6C] = OpCodes(OpcodePattern: "CB:6C::", Mnemonic: "BIT 5,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of H")
        OpCodesList[0xCB6D] = OpCodes(OpcodePattern: "CB:6D::", Mnemonic: "BIT 5,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of L")
        OpCodesList[0xCB6E] = OpCodes(OpcodePattern: "CB:6E::", Mnemonic: "BIT 5,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of (HL).")
        OpCodesList[0xCB6F] = OpCodes(OpcodePattern: "CB:6F::", Mnemonic: "BIT 5,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of A")
        OpCodesList[0xCB70] = OpCodes(OpcodePattern: "CB:70::", Mnemonic: "BIT 6,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of B")
        OpCodesList[0xCB71] = OpCodes(OpcodePattern: "CB:71::", Mnemonic: "BIT 6,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of C")
        OpCodesList[0xCB72] = OpCodes(OpcodePattern: "CB:72::", Mnemonic: "BIT 6,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of D")
        OpCodesList[0xCB73] = OpCodes(OpcodePattern: "CB:73::", Mnemonic: "BIT 6,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of E")
        OpCodesList[0xCB74] = OpCodes(OpcodePattern: "CB:74::", Mnemonic: "BIT 6,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of H")
        OpCodesList[0xCB75] = OpCodes(OpcodePattern: "CB:75::", Mnemonic: "BIT 6,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of L")
        OpCodesList[0xCB76] = OpCodes(OpcodePattern: "CB:76::", Mnemonic: "BIT 6,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of (HL).")
        OpCodesList[0xCB77] = OpCodes(OpcodePattern: "CB:77::", Mnemonic: "BIT 6,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of A")
        OpCodesList[0xCB78] = OpCodes(OpcodePattern: "CB:78::", Mnemonic: "BIT 7,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of B")
        OpCodesList[0xCB79] = OpCodes(OpcodePattern: "CB:79::", Mnemonic: "BIT 7,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of C")
        OpCodesList[0xCB7A] = OpCodes(OpcodePattern: "CB:7A::", Mnemonic: "BIT 7,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of D")
        OpCodesList[0xCB7B] = OpCodes(OpcodePattern: "CB:7B::", Mnemonic: "BIT 7,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of E")
        OpCodesList[0xCB7C] = OpCodes(OpcodePattern: "CB:7C::", Mnemonic: "BIT 7,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of H")
        OpCodesList[0xCB7D] = OpCodes(OpcodePattern: "CB:7D::", Mnemonic: "BIT 7,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of L")
        OpCodesList[0xCB7E] = OpCodes(OpcodePattern: "CB:7E::", Mnemonic: "BIT 7,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of (HL).")
        OpCodesList[0xCB7F] = OpCodes(OpcodePattern: "CB:7F::", Mnemonic: "BIT 7,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of A")
        OpCodesList[0xCB80] = OpCodes(OpcodePattern: "CB:80::", Mnemonic: "RES 0,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of B.")
        OpCodesList[0xCB81] = OpCodes(OpcodePattern: "CB:81::", Mnemonic: "RES 0,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of C.")
        OpCodesList[0xCB82] = OpCodes(OpcodePattern: "CB:82::", Mnemonic: "RES 0,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of D.")
        OpCodesList[0xCB83] = OpCodes(OpcodePattern: "CB:83::", Mnemonic: "RES 0,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of E.")
        OpCodesList[0xCB84] = OpCodes(OpcodePattern: "CB:84::", Mnemonic: "RES 0,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of H.")
        OpCodesList[0xCB85] = OpCodes(OpcodePattern: "CB:85::", Mnemonic: "RES 0,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of L.")
        OpCodesList[0xCB86] = OpCodes(OpcodePattern: "CB:86::", Mnemonic: "RES 0,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of (HL).")
        OpCodesList[0xCB87] = OpCodes(OpcodePattern: "CB:87::", Mnemonic: "RES 0,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of A.")
        OpCodesList[0xCB88] = OpCodes(OpcodePattern: "CB:88::", Mnemonic: "RES 1,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of B.")
        OpCodesList[0xCB89] = OpCodes(OpcodePattern: "CB:89::", Mnemonic: "RES 1,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of C.")
        OpCodesList[0xCB8A] = OpCodes(OpcodePattern: "CB:8A::", Mnemonic: "RES 1,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of D.")
        OpCodesList[0xCB8B] = OpCodes(OpcodePattern: "CB:8B::", Mnemonic: "RES 1,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of E.")
        OpCodesList[0xCB8C] = OpCodes(OpcodePattern: "CB:8C::", Mnemonic: "RES 1,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of H.")
        OpCodesList[0xCB8D] = OpCodes(OpcodePattern: "CB:8D::", Mnemonic: "RES 1,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of L.")
        OpCodesList[0xCB8E] = OpCodes(OpcodePattern: "CB:8E::", Mnemonic: "RES 1,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of (HL).")
        OpCodesList[0xCB8F] = OpCodes(OpcodePattern: "CB:8F::", Mnemonic: "RES 1,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of A.")
        OpCodesList[0xCB90] = OpCodes(OpcodePattern: "CB:90::", Mnemonic: "RES 2,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of B.")
        OpCodesList[0xCB91] = OpCodes(OpcodePattern: "CB:91::", Mnemonic: "RES 2,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of C.")
        OpCodesList[0xCB92] = OpCodes(OpcodePattern: "CB:92::", Mnemonic: "RES 2,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of D.")
        OpCodesList[0xCB93] = OpCodes(OpcodePattern: "CB:93::", Mnemonic: "RES 2,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of E.")
        OpCodesList[0xCB94] = OpCodes(OpcodePattern: "CB:94::", Mnemonic: "RES 2,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of H.")
        OpCodesList[0xCB95] = OpCodes(OpcodePattern: "CB:95::", Mnemonic: "RES 2,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of L.")
        OpCodesList[0xCB96] = OpCodes(OpcodePattern: "CB:96::", Mnemonic: "RES 2,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of (HL).")
        OpCodesList[0xCB97] = OpCodes(OpcodePattern: "CB:97::", Mnemonic: "RES 2,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of A.")
        OpCodesList[0xCB98] = OpCodes(OpcodePattern: "CB:98::", Mnemonic: "RES 3,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of B.")
        OpCodesList[0xCB99] = OpCodes(OpcodePattern: "CB:99::", Mnemonic: "RES 3,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of C.")
        OpCodesList[0xCB9A] = OpCodes(OpcodePattern: "CB:9A::", Mnemonic: "RES 3,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of D.")
        OpCodesList[0xCB9B] = OpCodes(OpcodePattern: "CB:9B::", Mnemonic: "RES 3,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of E.")
        OpCodesList[0xCB9C] = OpCodes(OpcodePattern: "CB:9C::", Mnemonic: "RES 3,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of H.")
        OpCodesList[0xCB9D] = OpCodes(OpcodePattern: "CB:9D::", Mnemonic: "RES 3,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of L.")
        OpCodesList[0xCB9E] = OpCodes(OpcodePattern: "CB:9E::", Mnemonic: "RES 3,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of (HL).")
        OpCodesList[0xCB9F] = OpCodes(OpcodePattern: "CB:9F::", Mnemonic: "RES 3,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of A.")
        OpCodesList[0xCBA0] = OpCodes(OpcodePattern: "CB:A0::", Mnemonic: "RES 4,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of B.")
        OpCodesList[0xCBA1] = OpCodes(OpcodePattern: "CB:A1::", Mnemonic: "RES 4,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of C.")
        OpCodesList[0xCBA2] = OpCodes(OpcodePattern: "CB:A2::", Mnemonic: "RES 4,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of D.")
        OpCodesList[0xCBA3] = OpCodes(OpcodePattern: "CB:A3::", Mnemonic: "RES 4,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of E.")
        OpCodesList[0xCBA4] = OpCodes(OpcodePattern: "CB:A4::", Mnemonic: "RES 4,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of H.")
        OpCodesList[0xCBA5] = OpCodes(OpcodePattern: "CB:A5::", Mnemonic: "RES 4,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of L.")
        OpCodesList[0xCBA6] = OpCodes(OpcodePattern: "CB:A6::", Mnemonic: "RES 4,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of (HL).")
        OpCodesList[0xCBA7] = OpCodes(OpcodePattern: "CB:A7::", Mnemonic: "RES 4,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of A.")
        OpCodesList[0xCBA8] = OpCodes(OpcodePattern: "CB:A8::", Mnemonic: "RES 5,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of B.")
        OpCodesList[0xCBA9] = OpCodes(OpcodePattern: "CB:A9::", Mnemonic: "RES 5,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of C.")
        OpCodesList[0xCBAA] = OpCodes(OpcodePattern: "CB:AA::", Mnemonic: "RES 5,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of D.")
        OpCodesList[0xCBAB] = OpCodes(OpcodePattern: "CB:AB::", Mnemonic: "RES 5,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of E.")
        OpCodesList[0xCBAC] = OpCodes(OpcodePattern: "CB:AC::", Mnemonic: "RES 5,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of H.")
        OpCodesList[0xCBAD] = OpCodes(OpcodePattern: "CB:AD::", Mnemonic: "RES 5,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of L.")
        OpCodesList[0xCBAE] = OpCodes(OpcodePattern: "CB:AE::", Mnemonic: "RES 5,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of (HL).")
        OpCodesList[0xCBAF] = OpCodes(OpcodePattern: "CB:AF::", Mnemonic: "RES 5,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of A.")
        OpCodesList[0xCBB0] = OpCodes(OpcodePattern: "CB:B0::", Mnemonic: "RES 6,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of B.")
        OpCodesList[0xCBB1] = OpCodes(OpcodePattern: "CB:B1::", Mnemonic: "RES 6,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of C.")
        OpCodesList[0xCBB2] = OpCodes(OpcodePattern: "CB:B2::", Mnemonic: "RES 6,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of D.")
        OpCodesList[0xCBB3] = OpCodes(OpcodePattern: "CB:B3::", Mnemonic: "RES 6,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of E.")
        OpCodesList[0xCBB4] = OpCodes(OpcodePattern: "CB:B4::", Mnemonic: "RES 6,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of H.")
        OpCodesList[0xCBB5] = OpCodes(OpcodePattern: "CB:B5::", Mnemonic: "RES 6,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of L.")
        OpCodesList[0xCBB6] = OpCodes(OpcodePattern: "CB:B6::", Mnemonic: "RES 6,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of (HL).")
        OpCodesList[0xCBB7] = OpCodes(OpcodePattern: "CB:B7::", Mnemonic: "RES 6,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of A.")
        OpCodesList[0xCBB8] = OpCodes(OpcodePattern: "CB:B8::", Mnemonic: "RES 7,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of B.")
        OpCodesList[0xCBB9] = OpCodes(OpcodePattern: "CB:B9::", Mnemonic: "RES 7,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of C.")
        OpCodesList[0xCBBA] = OpCodes(OpcodePattern: "CB:BA::", Mnemonic: "RES 7,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of D.")
        OpCodesList[0xCBBB] = OpCodes(OpcodePattern: "CB:BB::", Mnemonic: "RES 7,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of E.")
        OpCodesList[0xCBBC] = OpCodes(OpcodePattern: "CB:BC::", Mnemonic: "RES 7,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of H.")
        OpCodesList[0xCBBD] = OpCodes(OpcodePattern: "CB:BD::", Mnemonic: "RES 7,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of L.")
        OpCodesList[0xCBBE] = OpCodes(OpcodePattern: "CB:BE::", Mnemonic: "RES 7,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of (HL).")
        OpCodesList[0xCBBF] = OpCodes(OpcodePattern: "CB:BF::", Mnemonic: "RES 7,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of A.")
        OpCodesList[0xCBC0] = OpCodes(OpcodePattern: "CB:C0::", Mnemonic: "SET 0,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of B.")
        OpCodesList[0xCBC1] = OpCodes(OpcodePattern: "CB:C1::", Mnemonic: "SET 0,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of C.")
        OpCodesList[0xCBC2] = OpCodes(OpcodePattern: "CB:C2::", Mnemonic: "SET 0,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of D.")
        OpCodesList[0xCBC3] = OpCodes(OpcodePattern: "CB:C3::", Mnemonic: "SET 0,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of E.")
        OpCodesList[0xCBC4] = OpCodes(OpcodePattern: "CB:C4::", Mnemonic: "SET 0,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of H.")
        OpCodesList[0xCBC5] = OpCodes(OpcodePattern: "CB:C5::", Mnemonic: "SET 0,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of L.")
        OpCodesList[0xCBC6] = OpCodes(OpcodePattern: "CB:C6::", Mnemonic: "SET 0,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of (HL).")
        OpCodesList[0xCBC7] = OpCodes(OpcodePattern: "CB:C7::", Mnemonic: "SET 0,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of A.")
        OpCodesList[0xCBC8] = OpCodes(OpcodePattern: "CB:C8::", Mnemonic: "SET 1,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of B.")
        OpCodesList[0xCBC9] = OpCodes(OpcodePattern: "CB:C9::", Mnemonic: "SET 1,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of C.")
        OpCodesList[0xCBCA] = OpCodes(OpcodePattern: "CB:CA::", Mnemonic: "SET 1,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of D.")
        OpCodesList[0xCBCB] = OpCodes(OpcodePattern: "CB:CB::", Mnemonic: "SET 1,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of E.")
        OpCodesList[0xCBCC] = OpCodes(OpcodePattern: "CB:CC::", Mnemonic: "SET 1,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of H.")
        OpCodesList[0xCBCD] = OpCodes(OpcodePattern: "CB:CD::", Mnemonic: "SET 1,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of L.")
        OpCodesList[0xCBCE] = OpCodes(OpcodePattern: "CB:CE::", Mnemonic: "SET 1,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of (HL).")
        OpCodesList[0xCBCF] = OpCodes(OpcodePattern: "CB:CF::", Mnemonic: "SET 1,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of A.")
        OpCodesList[0xCBD0] = OpCodes(OpcodePattern: "CB:D0::", Mnemonic: "SET 2,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of B.")
        OpCodesList[0xCBD1] = OpCodes(OpcodePattern: "CB:D1::", Mnemonic: "SET 2,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of C.")
        OpCodesList[0xCBD2] = OpCodes(OpcodePattern: "CB:D2::", Mnemonic: "SET 2,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of D.")
        OpCodesList[0xCBD3] = OpCodes(OpcodePattern: "CB:D3::", Mnemonic: "SET 2,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of E.")
        OpCodesList[0xCBD4] = OpCodes(OpcodePattern: "CB:D4::", Mnemonic: "SET 2,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of H.")
        OpCodesList[0xCBD5] = OpCodes(OpcodePattern: "CB:D5::", Mnemonic: "SET 2,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of L.")
        OpCodesList[0xCBD6] = OpCodes(OpcodePattern: "CB:D6::", Mnemonic: "SET 2,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of (HL).")
        OpCodesList[0xCBD7] = OpCodes(OpcodePattern: "CB:D7::", Mnemonic: "SET 2,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of A.")
        OpCodesList[0xCBD8] = OpCodes(OpcodePattern: "CB:D8::", Mnemonic: "SET 3,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of B.")
        OpCodesList[0xCBD9] = OpCodes(OpcodePattern: "CB:D9::", Mnemonic: "SET 3,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of C.")
        OpCodesList[0xCBDA] = OpCodes(OpcodePattern: "CB:DA::", Mnemonic: "SET 3,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of D.")
        OpCodesList[0xCBDB] = OpCodes(OpcodePattern: "CB:DB::", Mnemonic: "SET 3,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of E.")
        OpCodesList[0xCBDC] = OpCodes(OpcodePattern: "CB:DC::", Mnemonic: "SET 3,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of H.")
        OpCodesList[0xCBDD] = OpCodes(OpcodePattern: "CB:DD::", Mnemonic: "SET 3,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of L.")
        OpCodesList[0xCBDE] = OpCodes(OpcodePattern: "CB:DE::", Mnemonic: "SET 3,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of (HL).")
        OpCodesList[0xCBDF] = OpCodes(OpcodePattern: "CB:DF::", Mnemonic: "SET 3,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of A.")
        OpCodesList[0xCBE0] = OpCodes(OpcodePattern: "CB:E0::", Mnemonic: "SET 4,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of B.")
        OpCodesList[0xCBE1] = OpCodes(OpcodePattern: "CB:E1::", Mnemonic: "SET 4,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of C.")
        OpCodesList[0xCBE2] = OpCodes(OpcodePattern: "CB:E2::", Mnemonic: "SET 4,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of D.")
        OpCodesList[0xCBE3] = OpCodes(OpcodePattern: "CB:E3::", Mnemonic: "SET 4,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of E.")
        OpCodesList[0xCBE4] = OpCodes(OpcodePattern: "CB:E4::", Mnemonic: "SET 4,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of H.")
        OpCodesList[0xCBE5] = OpCodes(OpcodePattern: "CB:E5::", Mnemonic: "SET 4,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of L.")
        OpCodesList[0xCBE6] = OpCodes(OpcodePattern: "CB:E6::", Mnemonic: "SET 4,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of (HL).")
        OpCodesList[0xCBE7] = OpCodes(OpcodePattern: "CB:E7::", Mnemonic: "SET 4,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of A.")
        OpCodesList[0xCBE8] = OpCodes(OpcodePattern: "CB:E8::", Mnemonic: "SET 5,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of B.")
        OpCodesList[0xCBE9] = OpCodes(OpcodePattern: "CB:E9::", Mnemonic: "SET 5,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of C.")
        OpCodesList[0xCBEA] = OpCodes(OpcodePattern: "CB:EA::", Mnemonic: "SET 5,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of D.")
        OpCodesList[0xCBEB] = OpCodes(OpcodePattern: "CB:EB::", Mnemonic: "SET 5,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of E.")
        OpCodesList[0xCBEC] = OpCodes(OpcodePattern: "CB:EC::", Mnemonic: "SET 5,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of H.")
        OpCodesList[0xCBED] = OpCodes(OpcodePattern: "CB:ED::", Mnemonic: "SET 5,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of L.")
        OpCodesList[0xCBEE] = OpCodes(OpcodePattern: "CB:EE::", Mnemonic: "SET 5,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of (HL).")
        OpCodesList[0xCBEF] = OpCodes(OpcodePattern: "CB:EF::", Mnemonic: "SET 5,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of A.")
        OpCodesList[0xCBF0] = OpCodes(OpcodePattern: "CB:F0::", Mnemonic: "SET 6,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of B.")
        OpCodesList[0xCBF1] = OpCodes(OpcodePattern: "CB:F1::", Mnemonic: "SET 6,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of C.")
        OpCodesList[0xCBF2] = OpCodes(OpcodePattern: "CB:F2::", Mnemonic: "SET 6,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of D.")
        OpCodesList[0xCBF3] = OpCodes(OpcodePattern: "CB:F3::", Mnemonic: "SET 6,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of E.")
        OpCodesList[0xCBF4] = OpCodes(OpcodePattern: "CB:F4::", Mnemonic: "SET 6,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of H.")
        OpCodesList[0xCBF5] = OpCodes(OpcodePattern: "CB:F5::", Mnemonic: "SET 6,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of L.")
        OpCodesList[0xCBF6] = OpCodes(OpcodePattern: "CB:F6::", Mnemonic: "SET 6,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of (HL).")
        OpCodesList[0xCBF7] = OpCodes(OpcodePattern: "CB:F7::", Mnemonic: "SET 6,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6of A.")
        OpCodesList[0xCBF8] = OpCodes(OpcodePattern: "CB:F8::", Mnemonic: "SET 7,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of B.")
        OpCodesList[0xCBF9] = OpCodes(OpcodePattern: "CB:F9::", Mnemonic: "SET 7,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of C.")
        OpCodesList[0xCBFA] = OpCodes(OpcodePattern: "CB:FA::", Mnemonic: "SET 7,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of D.")
        OpCodesList[0xCBFB] = OpCodes(OpcodePattern: "CB:FB::", Mnemonic: "SET 7,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of E.")
        OpCodesList[0xCBFC] = OpCodes(OpcodePattern: "CB:FC::", Mnemonic: "SET 7,H", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of H.")
        OpCodesList[0xCBFD] = OpCodes(OpcodePattern: "CB:FD::", Mnemonic: "SET 7,L", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of L.")
        OpCodesList[0xCBFE] = OpCodes(OpcodePattern: "CB:FE::", Mnemonic: "SET 7,(HL)", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of (HL).")
        OpCodesList[0xCBFF] = OpCodes(OpcodePattern: "CB:FF::", Mnemonic: "SET 7,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of A.")
        OpCodesList[0xCC] = OpCodes(OpcodePattern: "CC:n:n:", Mnemonic: "CALL Z,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the zero flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xCD] = OpCodes(OpcodePattern: "CD:n:n:", Mnemonic: "CALL NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xCE] = OpCodes(OpcodePattern: "CE:n::", Mnemonic: "ADC A,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds $n and the carry flag to A.")
        OpCodesList[0xCF] = OpCodes(OpcodePattern: "CF:::", Mnemonic: "RST 08H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 8.")
        OpCodesList[0xD0] = OpCodes(OpcodePattern: "D0:::", Mnemonic: "RET NC", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is unset, the top stack entry is popped into PC.")
        OpCodesList[0xD1] = OpCodes(OpcodePattern: "D1:::", Mnemonic: "POP DE", OpcodeSize: 1, InstructionSize: 1, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The memory location pointed to by SP is stored into E and SP is incremented. The memory location pointed to by SP is stored into D and SP is incremented again.")
        OpCodesList[0xD2] = OpCodes(OpcodePattern: "D2:n:n:", Mnemonic: "JP NC,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is unset, $nn is copied to PC.")
        OpCodesList[0xD3] = OpCodes(OpcodePattern: "D3:n::", Mnemonic: "OUT (N),A", OpcodeSize: 1, InstructionSize: 2, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of A is written to port $n.")
        OpCodesList[0xD4] = OpCodes(OpcodePattern: "D4:n:n:", Mnemonic: "CALL NC,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xD5] = OpCodes(OpcodePattern: "D5:::", Mnemonic: "PUSH DE", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "SP is decremented and D is stored into the memory location pointed to by SP. SP is decremented again and E is stored into the memory location pointed to by SP.")
        OpCodesList[0xD6] = OpCodes(OpcodePattern: "D6:n::", Mnemonic: "SUB N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $n from A.")
        OpCodesList[0xD7] = OpCodes(OpcodePattern: "D7:::", Mnemonic: "RST 10H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 10H.")
        OpCodesList[0xD8] = OpCodes(OpcodePattern: "D8:::", Mnemonic: "RET C", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is set, the top stack entry is popped into PC.")
        OpCodesList[0xD9] = OpCodes(OpcodePattern: "D9:::", Mnemonic: "EXX", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Exchanges the 16-bit contents of BC, DE, and HL with BC', DE', and HL'.")
        OpCodesList[0xDA] = OpCodes(OpcodePattern: "DA:n:n:", Mnemonic: "JP C,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is set, $nn is copied to PC.")
        OpCodesList[0xDB] = OpCodes(OpcodePattern: "DB:n::", Mnemonic: "IN A,(N)", OpcodeSize: 1, InstructionSize: 2, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "A byte from port $n is written to A.")
        OpCodesList[0xDC] = OpCodes(OpcodePattern: "DC:n:n:", Mnemonic: "CALL C,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the carry flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xDD04] = OpCodes(OpcodePattern: "DD:04::", Mnemonic: "INC B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to B")
        OpCodesList[0xDD05] = OpCodes(OpcodePattern: "DD:05::", Mnemonic: "DEC B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from B")
        OpCodesList[0xDD06] = OpCodes(OpcodePattern: "DD:06:n:", Mnemonic: "LD B,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads $n into B")
        OpCodesList[0xDD09] = OpCodes(OpcodePattern: "DD:09::", Mnemonic: "ADD IX,BC", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of BC is added to IX.")
        OpCodesList[0xDD0C] = OpCodes(OpcodePattern: "DD:0C::", Mnemonic: "INC C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to C")
        OpCodesList[0xDD0D] = OpCodes(OpcodePattern: "DD:0D::", Mnemonic: "DEC C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from C")
        OpCodesList[0xDD0E] = OpCodes(OpcodePattern: "DD:0E:n:", Mnemonic: "LD C,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into C")
        OpCodesList[0xDD14] = OpCodes(OpcodePattern: "DD:14::", Mnemonic: "INC D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to D")
        OpCodesList[0xDD15] = OpCodes(OpcodePattern: "DD:15::", Mnemonic: "DEC D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from D")
        OpCodesList[0xDD16] = OpCodes(OpcodePattern: "DD:16:n:", Mnemonic: "LD D,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads $n into D")
        OpCodesList[0xDD19] = OpCodes(OpcodePattern: "DD:19::", Mnemonic: "ADD IX,DE", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of DE is added to IX.")
        OpCodesList[0xDD1C] = OpCodes(OpcodePattern: "DD:1C::", Mnemonic: "INC E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to E.")
        OpCodesList[0xDD1D] = OpCodes(OpcodePattern: "DD:1D::", Mnemonic: "DEC E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from E")
        OpCodesList[0xDD1E] = OpCodes(OpcodePattern: "DD:1E:n:", Mnemonic: "LD E,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into E")
        OpCodesList[0xDD21] = OpCodes(OpcodePattern: "DD:21:n:n", Mnemonic: "LD IX,NN", OpcodeSize: 2, InstructionSize: 4, Cycle: [14], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $nn into register IX.")
        OpCodesList[0xDD22] = OpCodes(OpcodePattern: "DD:22:n:n", Mnemonic: "LD (NN),IX", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores IX into the memory location pointed to by $nn.")
        OpCodesList[0xDD23] = OpCodes(OpcodePattern: "DD:23::", Mnemonic: "INC IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Adds one to IX.")
        OpCodesList[0xDD24] = OpCodes(OpcodePattern: "DD:24::", Mnemonic: "INC IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to IXH")
        OpCodesList[0xDD25] = OpCodes(OpcodePattern: "DD:25::", Mnemonic: "DEC IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from IXH")
        OpCodesList[0xDD26] = OpCodes(OpcodePattern: "DD:26:n:", Mnemonic: "LD IHX,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads $n into IXH")
        OpCodesList[0xDD29] = OpCodes(OpcodePattern: "DD:29::", Mnemonic: "ADD IX,IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of IX is added to IX.")
        OpCodesList[0xDD2A] = OpCodes(OpcodePattern: "DD:2A:n:n", Mnemonic: "LD IX,(NN)", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into IX.")
        OpCodesList[0xDD2B] = OpCodes(OpcodePattern: "DD:2B::", Mnemonic: "DEC IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from IX.")
        OpCodesList[0xDD2C] = OpCodes(OpcodePattern: "DD:2C::", Mnemonic: "INC IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to IXL.")
        OpCodesList[0xDD2D] = OpCodes(OpcodePattern: "DD:2D::", Mnemonic: "DEC IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from IXL.")
        OpCodesList[0xDD2E] = OpCodes(OpcodePattern: "DD:2E:n:", Mnemonic: "LD IXL,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into IXL.")
        OpCodesList[0xDD34] = OpCodes(OpcodePattern: "DD:34:d:", Mnemonic: "INC (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [23], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD35] = OpCodes(OpcodePattern: "DD:35:d:", Mnemonic: "DEC (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [23], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD36] = OpCodes(OpcodePattern: "DD:36:d:n", Mnemonic: "LD (IX+D),N", OpcodeSize: 2, InstructionSize: 4, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores $n to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD39] = OpCodes(OpcodePattern: "DD:39::", Mnemonic: "ADD IX,SP", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of SP is added to IX.")
        OpCodesList[0xDD3C] = OpCodes(OpcodePattern: "DD:3C::", Mnemonic: "INC A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to A.")
        OpCodesList[0xDD3D] = OpCodes(OpcodePattern: "DD:3D::", Mnemonic: "DEC A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from A.")
        OpCodesList[0xDD3E] = OpCodes(OpcodePattern: "DD:3E:N:", Mnemonic: "LD A,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into A.")
        OpCodesList[0xDD40] = OpCodes(OpcodePattern: "DD:40::", Mnemonic: "LD B,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into B")
        OpCodesList[0xDD41] = OpCodes(OpcodePattern: "DD:41::", Mnemonic: "LD B,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into B")
        OpCodesList[0xDD42] = OpCodes(OpcodePattern: "DD:42::", Mnemonic: "LD B,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into B")
        OpCodesList[0xDD43] = OpCodes(OpcodePattern: "DD:43::", Mnemonic: "LD B,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into B")
        OpCodesList[0xDD44] = OpCodes(OpcodePattern: "DD:44::", Mnemonic: "LD B,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into B")
        OpCodesList[0xDD45] = OpCodes(OpcodePattern: "DD:45::", Mnemonic: "LD B,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXL are loaded into B")
        OpCodesList[0xDD46] = OpCodes(OpcodePattern: "DD:46:d:", Mnemonic: "LD B,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus $d into B")
        OpCodesList[0xDD47] = OpCodes(OpcodePattern: "DD:47::", Mnemonic: "LD B,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into B")
        OpCodesList[0xDD48] = OpCodes(OpcodePattern: "DD:48::", Mnemonic: "LD C,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into C")
        OpCodesList[0xDD49] = OpCodes(OpcodePattern: "DD:49::", Mnemonic: "LD C,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into C")
        OpCodesList[0xDD4A] = OpCodes(OpcodePattern: "DD:4A::", Mnemonic: "LD C,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into C")
        OpCodesList[0xDD4B] = OpCodes(OpcodePattern: "DD:4B::", Mnemonic: "LD C,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into C")
        OpCodesList[0xDD4C] = OpCodes(OpcodePattern: "DD:4C::", Mnemonic: "LD C,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into C")
        OpCodesList[0xDD4D] = OpCodes(OpcodePattern: "DD:4D::", Mnemonic: "LD C,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXL are loaded into C")
        OpCodesList[0xDD4E] = OpCodes(OpcodePattern: "DD:4E:d:", Mnemonic: "LD C,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus d into C.")
        OpCodesList[0xDD4F] = OpCodes(OpcodePattern: "DD:4F::", Mnemonic: "LD C,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into C.")
        OpCodesList[0xDD50] = OpCodes(OpcodePattern: "DD:50::", Mnemonic: "LD D,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into D")
        OpCodesList[0xDD51] = OpCodes(OpcodePattern: "DD:51::", Mnemonic: "LD D,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into D")
        OpCodesList[0xDD52] = OpCodes(OpcodePattern: "DD:52::", Mnemonic: "LD D,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into D")
        OpCodesList[0xDD53] = OpCodes(OpcodePattern: "DD:53::", Mnemonic: "LD D,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into D")
        OpCodesList[0xDD54] = OpCodes(OpcodePattern: "DD:54::", Mnemonic: "LD D,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into D")
        OpCodesList[0xDD55] = OpCodes(OpcodePattern: "DD:55::", Mnemonic: "LD D,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXL are loaded into D")
        OpCodesList[0xDD56] = OpCodes(OpcodePattern: "DD:56:d:", Mnemonic: "LD D,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus $d into D")
        OpCodesList[0xDD57] = OpCodes(OpcodePattern: "DD:57::", Mnemonic: "LD D,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into D")
        OpCodesList[0xDD58] = OpCodes(OpcodePattern: "DD:58::", Mnemonic: "LD E,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into E")
        OpCodesList[0xDD59] = OpCodes(OpcodePattern: "DD:59::", Mnemonic: "LD E,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into E")
        OpCodesList[0xDD5A] = OpCodes(OpcodePattern: "DD:5A::", Mnemonic: "LD E,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into E")
        OpCodesList[0xDD5B] = OpCodes(OpcodePattern: "DD:5B::", Mnemonic: "LD E,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into E")
        OpCodesList[0xDD5C] = OpCodes(OpcodePattern: "DD:5C::", Mnemonic: "LD E,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into E")
        OpCodesList[0xDD5D] = OpCodes(OpcodePattern: "DD:5D::", Mnemonic: "LD E,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXL are loaded into E")
        OpCodesList[0xDD5E] = OpCodes(OpcodePattern: "DD:5E:d:", Mnemonic: "LD E,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus $d into E")
        OpCodesList[0xDD5F] = OpCodes(OpcodePattern: "DD:5F::", Mnemonic: "LD E,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into E.")
        OpCodesList[0xDD60] = OpCodes(OpcodePattern: "DD:60::", Mnemonic: "LD IXH,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into IXH")
        OpCodesList[0xDD61] = OpCodes(OpcodePattern: "DD:61::", Mnemonic: "LD IXH,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into IXH")
        OpCodesList[0xDD62] = OpCodes(OpcodePattern: "DD:62::", Mnemonic: "LD IXH,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into IXH")
        OpCodesList[0xDD63] = OpCodes(OpcodePattern: "DD:63::", Mnemonic: "LD IXH,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into IXH")
        OpCodesList[0xDD64] = OpCodes(OpcodePattern: "DD:64::", Mnemonic: "LD IXH,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into IXH")
        OpCodesList[0xDD65] = OpCodes(OpcodePattern: "DD:65::", Mnemonic: "LD IXH,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into IXH")
        OpCodesList[0xDD66] = OpCodes(OpcodePattern: "DD:66:d:", Mnemonic: "LD H,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus $d into H")
        OpCodesList[0xDD67] = OpCodes(OpcodePattern: "DD:67::", Mnemonic: "LD IXH,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into IXH.")
        OpCodesList[0xDD68] = OpCodes(OpcodePattern: "DD:68::", Mnemonic: "LD IXL,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into IXL.")
        OpCodesList[0xDD69] = OpCodes(OpcodePattern: "DD:69::", Mnemonic: "LD IXL,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into IXL.")
        OpCodesList[0xDD6A] = OpCodes(OpcodePattern: "DD:6A::", Mnemonic: "LD IXL,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into IXL.")
        OpCodesList[0xDD6B] = OpCodes(OpcodePattern: "DD:6B::", Mnemonic: "LD IXL,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into IXL.")
        OpCodesList[0xDD6C] = OpCodes(OpcodePattern: "DD:6C::", Mnemonic: "LD IXL,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into IXL.")
        OpCodesList[0xDD6D] = OpCodes(OpcodePattern: "DD:6D::", Mnemonic: "LD IXL,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXL are loaded into IXL.")
        OpCodesList[0xDD6E] = OpCodes(OpcodePattern: "DD:6E::", Mnemonic: "LD L,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus d into L.")
        OpCodesList[0xDD6F] = OpCodes(OpcodePattern: "DD:6F::", Mnemonic: "LD IXL,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into IXL.")
        OpCodesList[0xDD70] = OpCodes(OpcodePattern: "DD:70:d:", Mnemonic: "LD (IX+D),B", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores B to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD71] = OpCodes(OpcodePattern: "DD:71:d:", Mnemonic: "LD (IX+D),C", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores C to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD72] = OpCodes(OpcodePattern: "DD:72:d:", Mnemonic: "LD (IX+D),D", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores D to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD73] = OpCodes(OpcodePattern: "DD:73:d:", Mnemonic: "LD (IX+D),E", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores E to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD74] = OpCodes(OpcodePattern: "DD:74:d:", Mnemonic: "LD (IX+D),H", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores H to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD75] = OpCodes(OpcodePattern: "DD:75:d:", Mnemonic: "LD (IX+D),L", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores L to the memory location pointed to by IX plus $d.")
        OpCodesList[0xDD77] = OpCodes(OpcodePattern: "DD:77:d:", Mnemonic: "LD (IX+D),A", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores A to the memory location pointed to by IX plus d.")
        OpCodesList[0xDD78] = OpCodes(OpcodePattern: "DD:78::", Mnemonic: "LD A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into A.")
        OpCodesList[0xDD79] = OpCodes(OpcodePattern: "DD:79::", Mnemonic: "LD A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into A.")
        OpCodesList[0xDD7A] = OpCodes(OpcodePattern: "DD:7A::", Mnemonic: "LD A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into A.")
        OpCodesList[0xDD7B] = OpCodes(OpcodePattern: "DD:7B::", Mnemonic: "LD A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into A.")
        OpCodesList[0xDD7C] = OpCodes(OpcodePattern: "DD:7C::", Mnemonic: "LD A,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXH are loaded into A.")
        OpCodesList[0xDD7D] = OpCodes(OpcodePattern: "DD:7D::", Mnemonic: "LD A,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IXL are loaded into A.")
        OpCodesList[0xDD7E] = OpCodes(OpcodePattern: "DD:7E:d:", Mnemonic: "LD A,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IX plus d into A.")
        OpCodesList[0xDD7F] = OpCodes(OpcodePattern: "DD:7F::", Mnemonic: "LD A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into A.")
        OpCodesList[0xDD80] = OpCodes(OpcodePattern: "DD:80::", Mnemonic: "ADD A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds B to A.")
        OpCodesList[0xDD81] = OpCodes(OpcodePattern: "DD:81::", Mnemonic: "ADD A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds C to A.")
        OpCodesList[0xDD82] = OpCodes(OpcodePattern: "DD:82::", Mnemonic: "ADD A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds D to A.")
        OpCodesList[0xDD83] = OpCodes(OpcodePattern: "DD:83::", Mnemonic: "ADD A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds E to A.")
        OpCodesList[0xDD84] = OpCodes(OpcodePattern: "DD:84::", Mnemonic: "ADD A,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IXH to A.")
        OpCodesList[0xDD85] = OpCodes(OpcodePattern: "DD:85::", Mnemonic: "ADD A,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IXL to A.")
        OpCodesList[0xDD86] = OpCodes(OpcodePattern: "DD:86:d:", Mnemonic: "ADD A,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds the value pointed to by IX plus $d to A.")
        OpCodesList[0xDD87] = OpCodes(OpcodePattern: "DD:87::", Mnemonic: "ADD A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds A to A.")
        OpCodesList[0xDD88] = OpCodes(OpcodePattern: "DD:88::", Mnemonic: "ADC A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds B and the carry flag to A.")
        OpCodesList[0xDD89] = OpCodes(OpcodePattern: "DD:89::", Mnemonic: "ADC A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds C and the carry flag to A.")
        OpCodesList[0xDD8A] = OpCodes(OpcodePattern: "DD:8A::", Mnemonic: "ADC A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds D and the carry flag to A.")
        OpCodesList[0xDD8B] = OpCodes(OpcodePattern: "DD:8B::", Mnemonic: "ADC A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds E and the carry flag to A.")
        OpCodesList[0xDD8C] = OpCodes(OpcodePattern: "DD:8C::", Mnemonic: "ADC A,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IXH and the carry flag to A.")
        OpCodesList[0xDD8D] = OpCodes(OpcodePattern: "DD:8D::", Mnemonic: "ADC A,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IXL and the carry flag to A.")
        OpCodesList[0xDD8E] = OpCodes(OpcodePattern: "DD:8E:d:", Mnemonic: "ADC A,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds the value pointed to by IX plus $d and the carry flag to A.")
        OpCodesList[0xDD8F] = OpCodes(OpcodePattern: "DD:8F::", Mnemonic: "ADC A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds A and the carry flag to A.")
        OpCodesList[0xDD90] = OpCodes(OpcodePattern: "DD:90::", Mnemonic: "SUB B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B from A.")
        OpCodesList[0xDD91] = OpCodes(OpcodePattern: "DD:91::", Mnemonic: "SUB C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts C from A.")
        OpCodesList[0xDD92] = OpCodes(OpcodePattern: "DD:92::", Mnemonic: "SUB D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts D from A.")
        OpCodesList[0xDD93] = OpCodes(OpcodePattern: "DD:93::", Mnemonic: "SUB E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts E from A.")
        OpCodesList[0xDD94] = OpCodes(OpcodePattern: "DD:94::", Mnemonic: "SUB IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IXH from A.")
        OpCodesList[0xDD95] = OpCodes(OpcodePattern: "DD:95::", Mnemonic: "SUB IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IXL from A.")
        OpCodesList[0xDD96] = OpCodes(OpcodePattern: "DD:96:d:", Mnemonic: "SUB (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts the value pointed to by IX plus $d from A.")
        OpCodesList[0xDD97] = OpCodes(OpcodePattern: "DD:97::", Mnemonic: "SUB A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts A from A.")
        OpCodesList[0xDD98] = OpCodes(OpcodePattern: "DD:98::", Mnemonic: "SBC A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B and the carry flag from A.")
        OpCodesList[0xDD99] = OpCodes(OpcodePattern: "DD:99::", Mnemonic: "SBC A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts C and the carry flag from A.")
        OpCodesList[0xDD9A] = OpCodes(OpcodePattern: "DD:9A::", Mnemonic: "SBC A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts D and the carry flag from A.")
        OpCodesList[0xDD9B] = OpCodes(OpcodePattern: "DD:9B::", Mnemonic: "SBC A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts E and the carry flag from A.")
        OpCodesList[0xDD9C] = OpCodes(OpcodePattern: "DD:9C::", Mnemonic: "SBC A,IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IXH and the carry flag from A.")
        OpCodesList[0xDD9D] = OpCodes(OpcodePattern: "DD:9D::", Mnemonic: "SBC A,IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IXL and the carry flag from A.")
        OpCodesList[0xDD9E] = OpCodes(OpcodePattern: "DD:9E:d:", Mnemonic: "SBC A,(IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts the value pointed to by IX plus $d and the carry flag from A.")
        OpCodesList[0xDD9F] = OpCodes(OpcodePattern: "DD:9F::", Mnemonic: "SBC A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts A and the carry flag from A.")
        OpCodesList[0xDDA0] = OpCodes(OpcodePattern: "DD:A0::", Mnemonic: "AND B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with B")
        OpCodesList[0xDDA1] = OpCodes(OpcodePattern: "DD:A1::", Mnemonic: "AND C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with C")
        OpCodesList[0xDDA2] = OpCodes(OpcodePattern: "DD:A2::", Mnemonic: "AND D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with D")
        OpCodesList[0xDDA3] = OpCodes(OpcodePattern: "DD:A3::", Mnemonic: "AND E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with E")
        OpCodesList[0xDDA4] = OpCodes(OpcodePattern: "DD:A4::", Mnemonic: "AND IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with IXH")
        OpCodesList[0xDDA5] = OpCodes(OpcodePattern: "DD:A5::", Mnemonic: "AND IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with IXL")
        OpCodesList[0xDDA6] = OpCodes(OpcodePattern: "DD:A6:d:", Mnemonic: "AND (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with the value pointed to by IX plus $d.")
        OpCodesList[0xDDA7] = OpCodes(OpcodePattern: "DD:A7::", Mnemonic: "AND A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with A.")
        OpCodesList[0xDDA8] = OpCodes(OpcodePattern: "DD:A8::", Mnemonic: "XOR B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with B")
        OpCodesList[0xDDA9] = OpCodes(OpcodePattern: "DD:A9::", Mnemonic: "XOR C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with C")
        OpCodesList[0xDDAA] = OpCodes(OpcodePattern: "DD:AA::", Mnemonic: "XOR D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with D")
        OpCodesList[0xDDAB] = OpCodes(OpcodePattern: "DD:AB::", Mnemonic: "XOR E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with E")
        OpCodesList[0xDDAC] = OpCodes(OpcodePattern: "DD:AC::", Mnemonic: "XOR IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with IXH")
        OpCodesList[0xDDAD] = OpCodes(OpcodePattern: "DD:AD::", Mnemonic: "XOR IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with IXL")
        OpCodesList[0xDDAE] = OpCodes(OpcodePattern: "DD:AE:d:", Mnemonic: "XOR (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with the value pointed to by IX plus $d.")
        OpCodesList[0xDDAF] = OpCodes(OpcodePattern: "DD:AF::", Mnemonic: "XOR A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with A.")
        OpCodesList[0xDDB0] = OpCodes(OpcodePattern: "DD:B0::", Mnemonic: "OR B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with B")
        OpCodesList[0xDDB1] = OpCodes(OpcodePattern: "DD:B1::", Mnemonic: "OR C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with C")
        OpCodesList[0xDDB2] = OpCodes(OpcodePattern: "DD:B2::", Mnemonic: "OR D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with D")
        OpCodesList[0xDDB3] = OpCodes(OpcodePattern: "DD:B3::", Mnemonic: "OR E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with E")
        OpCodesList[0xDDB4] = OpCodes(OpcodePattern: "DD:B4::", Mnemonic: "OR IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with IXH")
        OpCodesList[0xDDB5] = OpCodes(OpcodePattern: "DD:B5::", Mnemonic: "OR IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with IXL")
        OpCodesList[0xDDB6] = OpCodes(OpcodePattern: "DD:B6:d:", Mnemonic: "OR (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with the value pointed to by IX plus $d.")
        OpCodesList[0xDDB7] = OpCodes(OpcodePattern: "DD:B7::", Mnemonic: "OR A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with A.")
        OpCodesList[0xDDB8] = OpCodes(OpcodePattern: "DD:B8::", Mnemonic: "CP B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDB9] = OpCodes(OpcodePattern: "DD:B9::", Mnemonic: "CP C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts C from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDBA] = OpCodes(OpcodePattern: "DD:BA::", Mnemonic: "CP D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts D from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDBB] = OpCodes(OpcodePattern: "DD:BB::", Mnemonic: "CP E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts E from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDBC] = OpCodes(OpcodePattern: "DD:BC::", Mnemonic: "CP IXH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IXH from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDBD] = OpCodes(OpcodePattern: "DD:BD::", Mnemonic: "CP IXL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IXL from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDBE] = OpCodes(OpcodePattern: "DD:BE:d:", Mnemonic: "CP (IX+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts the value pointed to by IX plus $d from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDBF] = OpCodes(OpcodePattern: "DD:BF::", Mnemonic: "CP A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts A from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xDDCB0000] = OpCodes(OpcodePattern: "DD:CB:d:00", Mnemonic: "RLC (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in B.")
        OpCodesList[0xDDCB0001] = OpCodes(OpcodePattern: "DD:CB:d:01", Mnemonic: "RLC (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in C")
        OpCodesList[0xDDCB0002] = OpCodes(OpcodePattern: "DD:CB:d:02", Mnemonic: "RLC (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in C")
        OpCodesList[0xDDCB0003] = OpCodes(OpcodePattern: "DD:CB:d:03", Mnemonic: "RLC (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in E.")
        OpCodesList[0xDDCB0004] = OpCodes(OpcodePattern: "DD:CB:d:04", Mnemonic: "RLC (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in H")
        OpCodesList[0xDDCB0005] = OpCodes(OpcodePattern: "DD:CB:d:05", Mnemonic: "RLC (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in L")
        OpCodesList[0xDDCB0006] = OpCodes(OpcodePattern: "DD:CB:d:06", Mnemonic: "RLC (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xDDCB0007] = OpCodes(OpcodePattern: "DD:CB:d:07", Mnemonic: "RLC (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in A.")
        OpCodesList[0xDDCB0008] = OpCodes(OpcodePattern: "DD:CB:d:08", Mnemonic: "RRC (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in B")
        OpCodesList[0xDDCB0009] = OpCodes(OpcodePattern: "DD:CB:d:09", Mnemonic: "RRC (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in C.")
        OpCodesList[0xDDCB000A] = OpCodes(OpcodePattern: "DD:CB:d:0A", Mnemonic: "RRC (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in D")
        OpCodesList[0xDDCB000B] = OpCodes(OpcodePattern: "DD:CB:d:0B", Mnemonic: "RRC (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in E.")
        OpCodesList[0xDDCB000C] = OpCodes(OpcodePattern: "DD:CB:d:0C", Mnemonic: "RRC (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in H")
        OpCodesList[0xDDCB000D] = OpCodes(OpcodePattern: "DD:CB:d:0D", Mnemonic: "RRC (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in L")
        OpCodesList[0xDDCB000E] = OpCodes(OpcodePattern: "DD:CB:d:0E", Mnemonic: "RRC (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xDDCB000F] = OpCodes(OpcodePattern: "DD:CB:d:0F", Mnemonic: "RRC (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in A.")
        OpCodesList[0xDDCB0010] = OpCodes(OpcodePattern: "DD:CB:d:10", Mnemonic: "RL (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in B")
        OpCodesList[0xDDCB0011] = OpCodes(OpcodePattern: "DD:CB:d:11", Mnemonic: "RL (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in C")
        OpCodesList[0xDDCB0012] = OpCodes(OpcodePattern: "DD:CB:d:12", Mnemonic: "RL (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in D")
        OpCodesList[0xDDCB0013] = OpCodes(OpcodePattern: "DD:CB:d:13", Mnemonic: "RL (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in E")
        OpCodesList[0xDDCB0014] = OpCodes(OpcodePattern: "DD:CB:d:14", Mnemonic: "RL (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in H")
        OpCodesList[0xDDCB0015] = OpCodes(OpcodePattern: "DD:CB:d:15", Mnemonic: "RL (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in L")
        OpCodesList[0xDDCB0016] = OpCodes(OpcodePattern: "DD:CB:d:16", Mnemonic: "RL (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xDDCB0017] = OpCodes(OpcodePattern: "DD:CB:d:17", Mnemonic: "RL (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in A.")
        OpCodesList[0xDDCB0018] = OpCodes(OpcodePattern: "DD:CB:d:18", Mnemonic: "RR (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored inB")
        OpCodesList[0xDDCB0019] = OpCodes(OpcodePattern: "DD:CB:d:19", Mnemonic: "RR (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in C")
        OpCodesList[0xDDCB001A] = OpCodes(OpcodePattern: "DD:CB:d:1A", Mnemonic: "RR (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in D")
        OpCodesList[0xDDCB001B] = OpCodes(OpcodePattern: "DD:CB:d:1B", Mnemonic: "RR (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in E")
        OpCodesList[0xDDCB001C] = OpCodes(OpcodePattern: "DD:CB:d:1C", Mnemonic: "RR (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in H")
        OpCodesList[0xDDCB001D] = OpCodes(OpcodePattern: "DD:CB:d:1D", Mnemonic: "RR (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in L")
        OpCodesList[0xDDCB001E] = OpCodes(OpcodePattern: "DD:CB:d:1E", Mnemonic: "RR (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xDDCB001F] = OpCodes(OpcodePattern: "DD:CB:d:1F", Mnemonic: "RR (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in A.")
        OpCodesList[0xDDCB0020] = OpCodes(OpcodePattern: "DD:CB:d:20", Mnemonic: "SLA (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in B")
        OpCodesList[0xDDCB0021] = OpCodes(OpcodePattern: "DD:CB:d:21", Mnemonic: "SLA (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in C")
        OpCodesList[0xDDCB0022] = OpCodes(OpcodePattern: "DD:CB:d:22", Mnemonic: "SLA (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in D")
        OpCodesList[0xDDCB0023] = OpCodes(OpcodePattern: "DD:CB:d:23", Mnemonic: "SLA (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in E")
        OpCodesList[0xDDCB0024] = OpCodes(OpcodePattern: "DD:CB:d:24", Mnemonic: "SLA (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in H")
        OpCodesList[0xDDCB0025] = OpCodes(OpcodePattern: "DD:CB:d:25", Mnemonic: "SLA (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in L")
        OpCodesList[0xDDCB0026] = OpCodes(OpcodePattern: "DD:CB:d:26", Mnemonic: "SLA (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xDDCB0027] = OpCodes(OpcodePattern: "DD:CB:d:27", Mnemonic: "SLA (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in A.")
        OpCodesList[0xDDCB0028] = OpCodes(OpcodePattern: "DD:CB:d:28", Mnemonic: "SRA (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in B")
        OpCodesList[0xDDCB0029] = OpCodes(OpcodePattern: "DD:CB:d:29", Mnemonic: "SRA (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in C")
        OpCodesList[0xDDCB002A] = OpCodes(OpcodePattern: "DD:CB:d:2A", Mnemonic: "SRA (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in D")
        OpCodesList[0xDDCB002B] = OpCodes(OpcodePattern: "DD:CB:d:2B", Mnemonic: "SRA (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in E")
        OpCodesList[0xDDCB002C] = OpCodes(OpcodePattern: "DD:CB:d:2C", Mnemonic: "SRA (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in H")
        OpCodesList[0xDDCB002D] = OpCodes(OpcodePattern: "DD:CB:d:2D", Mnemonic: "SRA (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in L")
        OpCodesList[0xDDCB002E] = OpCodes(OpcodePattern: "DD:CB:d:2E", Mnemonic: "SRA (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xDDCB002F] = OpCodes(OpcodePattern: "DD:CB:d:2F", Mnemonic: "SRA (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in A.")
        OpCodesList[0xDDCB0030] = OpCodes(OpcodePattern: "DD:CB:d:30", Mnemonic: "SLL (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in B")
        OpCodesList[0xDDCB0031] = OpCodes(OpcodePattern: "DD:CB:d:31", Mnemonic: "SLL (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in C")
        OpCodesList[0xDDCB0032] = OpCodes(OpcodePattern: "DD:CB:d:32", Mnemonic: "SLL (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in D")
        OpCodesList[0xDDCB0033] = OpCodes(OpcodePattern: "DD:CB:d:33", Mnemonic: "SLL (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in E")
        OpCodesList[0xDDCB0034] = OpCodes(OpcodePattern: "DD:CB:d:34", Mnemonic: "SLL (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in H")
        OpCodesList[0xDDCB0035] = OpCodes(OpcodePattern: "DD:CB:d:35", Mnemonic: "SLL (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in L")
        OpCodesList[0xDDCB0036] = OpCodes(OpcodePattern: "DD:CB:d:36", Mnemonic: "SLL (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xDDCB0037] = OpCodes(OpcodePattern: "DD:CB:d:37", Mnemonic: "SLL (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in A.")
        OpCodesList[0xDDCB0038] = OpCodes(OpcodePattern: "DD:CB:d:38", Mnemonic: "SRL (IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in B")
        OpCodesList[0xDDCB0039] = OpCodes(OpcodePattern: "DD:CB:d:39", Mnemonic: "SRL (IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in C")
        OpCodesList[0xDDCB003A] = OpCodes(OpcodePattern: "DD:CB:d:3A", Mnemonic: "SRL (IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in D")
        OpCodesList[0xDDCB003B] = OpCodes(OpcodePattern: "DD:CB:d:3B", Mnemonic: "SRL (IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in E")
        OpCodesList[0xDDCB003C] = OpCodes(OpcodePattern: "DD:CB:d:3C", Mnemonic: "SRL (IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in H")
        OpCodesList[0xDDCB003D] = OpCodes(OpcodePattern: "DD:CB:d:3D", Mnemonic: "SRL (IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in L")
        OpCodesList[0xDDCB003E] = OpCodes(OpcodePattern: "DD:CB:d:3E", Mnemonic: "SRL (IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IX plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xDDCB003F] = OpCodes(OpcodePattern: "DD:CB:d:3F", Mnemonic: "SRL (IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IX plus dare shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in A.")
        OpCodesList[0xDDCB0040] = OpCodes(OpcodePattern: "DD:CB:d:40", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0041] = OpCodes(OpcodePattern: "DD:CB:d:41", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0042] = OpCodes(OpcodePattern: "DD:CB:d:42", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0043] = OpCodes(OpcodePattern: "DD:CB:d:43", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0044] = OpCodes(OpcodePattern: "DD:CB:d:44", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0045] = OpCodes(OpcodePattern: "DD:CB:d:45", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0046] = OpCodes(OpcodePattern: "DD:CB:d:46", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0047] = OpCodes(OpcodePattern: "DD:CB:d:47", Mnemonic: "BIT 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0048] = OpCodes(OpcodePattern: "DD:CB:d:48", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0049] = OpCodes(OpcodePattern: "DD:CB:d:49", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB004A] = OpCodes(OpcodePattern: "DD:CB:d:4A", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB004B] = OpCodes(OpcodePattern: "DD:CB:d:4B", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB004C] = OpCodes(OpcodePattern: "DD:CB:d:4C", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB004D] = OpCodes(OpcodePattern: "DD:CB:d:4D", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB004E] = OpCodes(OpcodePattern: "DD:CB:d:4E", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB004F] = OpCodes(OpcodePattern: "DD:CB:d:4F", Mnemonic: "BIT 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0050] = OpCodes(OpcodePattern: "DD:CB:d:50", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0051] = OpCodes(OpcodePattern: "DD:CB:d:51", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0052] = OpCodes(OpcodePattern: "DD:CB:d:52", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0053] = OpCodes(OpcodePattern: "DD:CB:d:53", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0054] = OpCodes(OpcodePattern: "DD:CB:d:54", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0055] = OpCodes(OpcodePattern: "DD:CB:d:55", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0056] = OpCodes(OpcodePattern: "DD:CB:d:56", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0057] = OpCodes(OpcodePattern: "DD:CB:d:57", Mnemonic: "BIT 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0058] = OpCodes(OpcodePattern: "DD:CB:d:58", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0059] = OpCodes(OpcodePattern: "DD:CB:d:59", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB005A] = OpCodes(OpcodePattern: "DD:CB:d:5A", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB005B] = OpCodes(OpcodePattern: "DD:CB:d:5B", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB005C] = OpCodes(OpcodePattern: "DD:CB:d:5C", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB005D] = OpCodes(OpcodePattern: "DD:CB:d:5D", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB005E] = OpCodes(OpcodePattern: "DD:CB:d:5E", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB005F] = OpCodes(OpcodePattern: "DD:CB:d:5F", Mnemonic: "BIT 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0060] = OpCodes(OpcodePattern: "DD:CB:d:60", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0061] = OpCodes(OpcodePattern: "DD:CB:d:61", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0062] = OpCodes(OpcodePattern: "DD:CB:d:62", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0063] = OpCodes(OpcodePattern: "DD:CB:d:63", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0064] = OpCodes(OpcodePattern: "DD:CB:d:64", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0065] = OpCodes(OpcodePattern: "DD:CB:d:65", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0066] = OpCodes(OpcodePattern: "DD:CB:d:66", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0067] = OpCodes(OpcodePattern: "DD:CB:d:67", Mnemonic: "BIT 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0068] = OpCodes(OpcodePattern: "DD:CB:d:68", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0069] = OpCodes(OpcodePattern: "DD:CB:d:69", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB006A] = OpCodes(OpcodePattern: "DD:CB:d:6A", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB006B] = OpCodes(OpcodePattern: "DD:CB:d:6B", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB006C] = OpCodes(OpcodePattern: "DD:CB:d:6C", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB006D] = OpCodes(OpcodePattern: "DD:CB:d:6D", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB006E] = OpCodes(OpcodePattern: "DD:CB:d:6E", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB006F] = OpCodes(OpcodePattern: "DD:CB:d:6F", Mnemonic: "BIT 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0070] = OpCodes(OpcodePattern: "DD:CB:d:70", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0071] = OpCodes(OpcodePattern: "DD:CB:d:71", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0072] = OpCodes(OpcodePattern: "DD:CB:d:72", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0073] = OpCodes(OpcodePattern: "DD:CB:d:73", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0074] = OpCodes(OpcodePattern: "DD:CB:d:74", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0075] = OpCodes(OpcodePattern: "DD:CB:d:75", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0076] = OpCodes(OpcodePattern: "DD:CB:d:76", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0077] = OpCodes(OpcodePattern: "DD:CB:d:77", Mnemonic: "BIT 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0078] = OpCodes(OpcodePattern: "DD:CB:d:78", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0079] = OpCodes(OpcodePattern: "DD:CB:d:79", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB007A] = OpCodes(OpcodePattern: "DD:CB:d:7A", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB007B] = OpCodes(OpcodePattern: "DD:CB:d:7B", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB007C] = OpCodes(OpcodePattern: "DD:CB:d:7C", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB007D] = OpCodes(OpcodePattern: "DD:CB:d:7D", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB007E] = OpCodes(OpcodePattern: "DD:CB:d:7E", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB007F] = OpCodes(OpcodePattern: "DD:CB:d:7F", Mnemonic: "BIT 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0080] = OpCodes(OpcodePattern: "DD:CB:d:80", Mnemonic: "RES 0,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0081] = OpCodes(OpcodePattern: "DD:CB:d:81", Mnemonic: "RES 0,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0082] = OpCodes(OpcodePattern: "DD:CB:d:82", Mnemonic: "RES 0,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0083] = OpCodes(OpcodePattern: "DD:CB:d:83", Mnemonic: "RES 0,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0084] = OpCodes(OpcodePattern: "DD:CB:d:84", Mnemonic: "RES 0,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0085] = OpCodes(OpcodePattern: "DD:CB:d:85", Mnemonic: "RES 0,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0086] = OpCodes(OpcodePattern: "DD:CB:d:86", Mnemonic: "RES 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0087] = OpCodes(OpcodePattern: "DD:CB:d:87", Mnemonic: "RES 0,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB0088] = OpCodes(OpcodePattern: "DD:CB:d:88", Mnemonic: "RES 1,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB0089] = OpCodes(OpcodePattern: "DD:CB:d:89", Mnemonic: "RES 1,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB008A] = OpCodes(OpcodePattern: "DD:CB:d:8A", Mnemonic: "RES 1,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB008B] = OpCodes(OpcodePattern: "DD:CB:d:8B", Mnemonic: "RES 1,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB008C] = OpCodes(OpcodePattern: "DD:CB:d:8C", Mnemonic: "RES 1,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB008D] = OpCodes(OpcodePattern: "DD:CB:d:8D", Mnemonic: "RES 1,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB008E] = OpCodes(OpcodePattern: "DD:CB:d:8E", Mnemonic: "RES 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB008F] = OpCodes(OpcodePattern: "DD:CB:d:8F", Mnemonic: "RES 1,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB0090] = OpCodes(OpcodePattern: "DD:CB:d:90", Mnemonic: "RES 2,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0091] = OpCodes(OpcodePattern: "DD:CB:d:91", Mnemonic: "RES 2,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0092] = OpCodes(OpcodePattern: "DD:CB:d:92", Mnemonic: "RES 2,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0093] = OpCodes(OpcodePattern: "DD:CB:d:93", Mnemonic: "RES 2,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0094] = OpCodes(OpcodePattern: "DD:CB:d:94", Mnemonic: "RES 2,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0095] = OpCodes(OpcodePattern: "DD:CB:d:95", Mnemonic: "RES 2,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0096] = OpCodes(OpcodePattern: "DD:CB:d:96", Mnemonic: "RES 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB0097] = OpCodes(OpcodePattern: "DD:CB:d:97", Mnemonic: "RES 2,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB0098] = OpCodes(OpcodePattern: "DD:CB:d:98", Mnemonic: "RES 3,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB0099] = OpCodes(OpcodePattern: "DD:CB:d:99", Mnemonic: "RES 3,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB009A] = OpCodes(OpcodePattern: "DD:CB:d:9A", Mnemonic: "RES 3,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB009B] = OpCodes(OpcodePattern: "DD:CB:d:9B", Mnemonic: "RES 3,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB009C] = OpCodes(OpcodePattern: "DD:CB:d:9C", Mnemonic: "RES 3,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB009D] = OpCodes(OpcodePattern: "DD:CB:d:9D", Mnemonic: "RES 3,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B.")
        OpCodesList[0xDDCB009E] = OpCodes(OpcodePattern: "DD:CB:d:9E", Mnemonic: "RES 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB009F] = OpCodes(OpcodePattern: "DD:CB:d:9F", Mnemonic: "RES 3,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB00A0] = OpCodes(OpcodePattern: "DD:CB:d:A0", Mnemonic: "RES 4,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A1] = OpCodes(OpcodePattern: "DD:CB:d:A1", Mnemonic: "RES 4,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A2] = OpCodes(OpcodePattern: "DD:CB:d:A2", Mnemonic: "RES 4,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A3] = OpCodes(OpcodePattern: "DD:CB:d:A3", Mnemonic: "RES 4,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A4] = OpCodes(OpcodePattern: "DD:CB:d:A4", Mnemonic: "RES 4,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A5] = OpCodes(OpcodePattern: "DD:CB:d:A5", Mnemonic: "RES 4,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A6] = OpCodes(OpcodePattern: "DD:CB:d:A6", Mnemonic: "RES 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00A7] = OpCodes(OpcodePattern: "DD:CB:d:A7", Mnemonic: "RES 4,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB00A8] = OpCodes(OpcodePattern: "DD:CB:d:A8", Mnemonic: "RES 5,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00A9] = OpCodes(OpcodePattern: "DD:CB:d:A9", Mnemonic: "RES 5,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00AA] = OpCodes(OpcodePattern: "DD:CB:d:AA", Mnemonic: "RES 5,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00AB] = OpCodes(OpcodePattern: "DD:CB:d:AB", Mnemonic: "RES 5,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00AC] = OpCodes(OpcodePattern: "DD:CB:d:AC", Mnemonic: "RES 5,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00AD] = OpCodes(OpcodePattern: "DD:CB:d:AD", Mnemonic: "RES 5,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00AE] = OpCodes(OpcodePattern: "DD:CB:d:AE", Mnemonic: "RES 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00AF] = OpCodes(OpcodePattern: "DD:CB:d:AF", Mnemonic: "RES 5,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB00B0] = OpCodes(OpcodePattern: "DD:CB:d:B0", Mnemonic: "RES 6,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B1] = OpCodes(OpcodePattern: "DD:CB:d:B1", Mnemonic: "RES 6,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B2] = OpCodes(OpcodePattern: "DD:CB:d:B2", Mnemonic: "RES 6,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B3] = OpCodes(OpcodePattern: "DD:CB:d:B3", Mnemonic: "RES 6,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B4] = OpCodes(OpcodePattern: "DD:CB:d:B4", Mnemonic: "RES 6,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B5] = OpCodes(OpcodePattern: "DD:CB:d:B5", Mnemonic: "RES 6,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B6] = OpCodes(OpcodePattern: "DD:CB:d:B6", Mnemonic: "RES 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00B7] = OpCodes(OpcodePattern: "DD:CB:d:B7", Mnemonic: "RES 6,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB00B8] = OpCodes(OpcodePattern: "DD:CB:d:B8", Mnemonic: "RES 7,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00B9] = OpCodes(OpcodePattern: "DD:CB:d:B9", Mnemonic: "RES 7,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00BA] = OpCodes(OpcodePattern: "DD:CB:d:BA", Mnemonic: "RES 7,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00BB] = OpCodes(OpcodePattern: "DD:CB:d:BB", Mnemonic: "RES 7,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00BC] = OpCodes(OpcodePattern: "DD:CB:d:BC", Mnemonic: "RES 7,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00BD] = OpCodes(OpcodePattern: "DD:CB:d:BD", Mnemonic: "RES 7,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00BE] = OpCodes(OpcodePattern: "DD:CB:d:BE", Mnemonic: "RES 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00BF] = OpCodes(OpcodePattern: "DD:CB:d:BF", Mnemonic: "RES 7,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IX plus d. The result is then stored in A.")
        OpCodesList[0xDDCB00C0] = OpCodes(OpcodePattern: "DD:CB:d:C0", Mnemonic: "SET 0,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00C1] = OpCodes(OpcodePattern: "DD:CB:d:C1", Mnemonic: "SET 0,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00C2] = OpCodes(OpcodePattern: "DD:CB:d:C2", Mnemonic: "SET 0,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00C3] = OpCodes(OpcodePattern: "DD:CB:d:C3", Mnemonic: "SET 0,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00C4] = OpCodes(OpcodePattern: "DD:CB:d:C4", Mnemonic: "SET 0,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00C5] = OpCodes(OpcodePattern: "DD:CB:d:C5", Mnemonic: "SET 0,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00C6] = OpCodes(OpcodePattern: "DD:CB:d:C6", Mnemonic: "SET 0,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00C7] = OpCodes(OpcodePattern: "DD:CB:d:C7", Mnemonic: "SET 0,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00C8] = OpCodes(OpcodePattern: "DD:CB:d:C8", Mnemonic: "SET 1,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00C9] = OpCodes(OpcodePattern: "DD:CB:d:C9", Mnemonic: "SET 1,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00CA] = OpCodes(OpcodePattern: "DD:CB:d:CA", Mnemonic: "SET 1,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00CB] = OpCodes(OpcodePattern: "DD:CB:d:CB", Mnemonic: "SET 1,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00CC] = OpCodes(OpcodePattern: "DD:CB:d:CC", Mnemonic: "SET 1,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00CD] = OpCodes(OpcodePattern: "DD:CB:d:CD", Mnemonic: "SET 1,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00CE] = OpCodes(OpcodePattern: "DD:CB:d:CE", Mnemonic: "SET 1,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00CF] = OpCodes(OpcodePattern: "DD:CB:d:CF", Mnemonic: "SET 1,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00D0] = OpCodes(OpcodePattern: "DD:CB:d:D0", Mnemonic: "SET 2,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00D1] = OpCodes(OpcodePattern: "DD:CB:d:D1", Mnemonic: "SET 2,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00D2] = OpCodes(OpcodePattern: "DD:CB:d:D2", Mnemonic: "SET 2,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00D3] = OpCodes(OpcodePattern: "DD:CB:d:D3", Mnemonic: "SET 2,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00D4] = OpCodes(OpcodePattern: "DD:CB:d:D4", Mnemonic: "SET 2,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00D5] = OpCodes(OpcodePattern: "DD:CB:d:D5", Mnemonic: "SET 2,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00D6] = OpCodes(OpcodePattern: "DD:CB:d:D6", Mnemonic: "SET 2,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00D7] = OpCodes(OpcodePattern: "DD:CB:d:D7", Mnemonic: "SET 2,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00D8] = OpCodes(OpcodePattern: "DD:CB:d:D8", Mnemonic: "SET 3,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00D9] = OpCodes(OpcodePattern: "DD:CB:d:D9", Mnemonic: "SET 3,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00DA] = OpCodes(OpcodePattern: "DD:CB:d:DA", Mnemonic: "SET 3,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00DB] = OpCodes(OpcodePattern: "DD:CB:d:DB", Mnemonic: "SET 3,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00DC] = OpCodes(OpcodePattern: "DD:CB:d:DC", Mnemonic: "SET 3,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00DD] = OpCodes(OpcodePattern: "DD:CB:d:DD", Mnemonic: "SET 3,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00DE] = OpCodes(OpcodePattern: "DD:CB:d:DE", Mnemonic: "SET 3,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00DF] = OpCodes(OpcodePattern: "DD:CB:d:DF", Mnemonic: "SET 3,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00E0] = OpCodes(OpcodePattern: "DD:CB:d:E0", Mnemonic: "SET 4,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00E1] = OpCodes(OpcodePattern: "DD:CB:d:E1", Mnemonic: "SET 4,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00E2] = OpCodes(OpcodePattern: "DD:CB:d:E2", Mnemonic: "SET 4,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00E3] = OpCodes(OpcodePattern: "DD:CB:d:E3", Mnemonic: "SET 4,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00E4] = OpCodes(OpcodePattern: "DD:CB:d:E4", Mnemonic: "SET 4,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00E5] = OpCodes(OpcodePattern: "DD:CB:d:E5", Mnemonic: "SET 4,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00E6] = OpCodes(OpcodePattern: "DD:CB:d:E6", Mnemonic: "SET 4,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00E7] = OpCodes(OpcodePattern: "DD:CB:d:E7", Mnemonic: "SET 4,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00E8] = OpCodes(OpcodePattern: "DD:CB:d:E8", Mnemonic: "SET 5,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00E9] = OpCodes(OpcodePattern: "DD:CB:d:E9", Mnemonic: "SET 5,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00EA] = OpCodes(OpcodePattern: "DD:CB:d:EA", Mnemonic: "SET 5,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00EB] = OpCodes(OpcodePattern: "DD:CB:d:EB", Mnemonic: "SET 5,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00EC] = OpCodes(OpcodePattern: "DD:CB:d:EC", Mnemonic: "SET 5,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00ED] = OpCodes(OpcodePattern: "DD:CB:d:ED", Mnemonic: "SET 5,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00EE] = OpCodes(OpcodePattern: "DD:CB:d:EE", Mnemonic: "SET 5,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00EF] = OpCodes(OpcodePattern: "DD:CB:d:EF", Mnemonic: "SET 5,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00F0] = OpCodes(OpcodePattern: "DD:CB:d:F0", Mnemonic: "SET 6,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00F1] = OpCodes(OpcodePattern: "DD:CB:d:F1", Mnemonic: "SET 6,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00F2] = OpCodes(OpcodePattern: "DD:CB:d:F2", Mnemonic: "SET 6,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00F3] = OpCodes(OpcodePattern: "DD:CB:d:F3", Mnemonic: "SET 6,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00F4] = OpCodes(OpcodePattern: "DD:CB:d:F4", Mnemonic: "SET 6,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00F5] = OpCodes(OpcodePattern: "DD:CB:d:F5", Mnemonic: "SET 6,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00F6] = OpCodes(OpcodePattern: "DD:CB:d:F6", Mnemonic: "SET 6,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00F7] = OpCodes(OpcodePattern: "DD:CB:d:F7", Mnemonic: "SET 6,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDCB00F8] = OpCodes(OpcodePattern: "DD:CB:d:F8", Mnemonic: "SET 7,(IX+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in B")
        OpCodesList[0xDDCB00F9] = OpCodes(OpcodePattern: "DD:CB:d:F9", Mnemonic: "SET 7,(IX+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in C")
        OpCodesList[0xDDCB00FA] = OpCodes(OpcodePattern: "DD:CB:d:FA", Mnemonic: "SET 7,(IX+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in D")
        OpCodesList[0xDDCB00FB] = OpCodes(OpcodePattern: "DD:CB:d:FB", Mnemonic: "SET 7,(IX+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in E")
        OpCodesList[0xDDCB00FC] = OpCodes(OpcodePattern: "DD:CB:d:FC", Mnemonic: "SET 7,(IX+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in H")
        OpCodesList[0xDDCB00FD] = OpCodes(OpcodePattern: "DD:CB:d:FD", Mnemonic: "SET 7,(IX+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d. The result is then stored in L")
        OpCodesList[0xDDCB00FE] = OpCodes(OpcodePattern: "DD:CB:d:FE", Mnemonic: "SET 7,(IX+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus $d.")
        OpCodesList[0xDDCB00FF] = OpCodes(OpcodePattern: "DD:CB:d:FF", Mnemonic: "SET 7,(IX+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IX plus d. The result is then stored in A")
        OpCodesList[0xDDE1] = OpCodes(OpcodePattern: "DD:E1::", Mnemonic: "POP IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [14], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The memory location pointed to by SP is stored into IXL and SP is incremented. The memory location pointed to by SP is stored into IXH and SP is incremented again.")
        OpCodesList[0xDDE3] = OpCodes(OpcodePattern: "DD:E3::", Mnemonic: "EX (SP),IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Exchanges (SP) with IXL, and (SP+1) with IXH.")
        OpCodesList[0xDDE5] = OpCodes(OpcodePattern: "DD:E5::", Mnemonic: "PUSH IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "SP is decremented and IXH is stored into the memory location pointed to by SP. SP is decremented again and IXL is stored into the memory location pointed to by SP.")
        OpCodesList[0xDDE9] = OpCodes(OpcodePattern: "DD:E9::", Mnemonic: "JP (IX)", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value of IX into PC.")
        OpCodesList[0xDDF9] = OpCodes(OpcodePattern: "DD:F9::", Mnemonic: "LD SP,IX", OpcodeSize: 2, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value of IX into SP.")
        OpCodesList[0xDE] = OpCodes(OpcodePattern: "DE:n::", Mnemonic: "SBC A,N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $n and the carry flag from A.")
        OpCodesList[0xDF] = OpCodes(OpcodePattern: "DF:::", Mnemonic: "RST 18H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 18h")
        OpCodesList[0xE0] = OpCodes(OpcodePattern: "E0:::", Mnemonic: "RET PO", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the parity/overflow flag is unset, the top stack entry is popped into PC.")
        OpCodesList[0xE1] = OpCodes(OpcodePattern: "E1:::", Mnemonic: "POP HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The memory location pointed to by SP is stored into L and SP is incremented. The memory location pointed to by SP is stored into H and SP is incremented again.")
        OpCodesList[0xE2] = OpCodes(OpcodePattern: "E2:n:n:", Mnemonic: "JP PO,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the parity/overflow flag is unset, $nn is copied to PC.")
        OpCodesList[0xE3] = OpCodes(OpcodePattern: "E3:::", Mnemonic: "EX (SP),HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Exchanges (SP) with L, and (SP+1) with H.")
        OpCodesList[0xE4] = OpCodes(OpcodePattern: "E4:n:n:", Mnemonic: "CALL PO,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the parity/overflow flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xE5] = OpCodes(OpcodePattern: "E5:::", Mnemonic: "PUSH HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "SP is decremented and H is stored into the memory location pointed to by SP. SP is decremented again and L is stored into the memory location pointed to by SP.")
        OpCodesList[0xE6] = OpCodes(OpcodePattern: "E6:n::", Mnemonic: "AND N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with $n.")
        OpCodesList[0xE7] = OpCodes(OpcodePattern: "E7:::", Mnemonic: "RST 20H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 20H")
        OpCodesList[0xE8] = OpCodes(OpcodePattern: "E8:::", Mnemonic: "RET PE", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the parity/overflow flag is set, the top stack entry is popped into PC.")
        OpCodesList[0xE9] = OpCodes(OpcodePattern: "E9:::", Mnemonic: "JP (HL)", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value of HL into PC.")
        OpCodesList[0xEA] = OpCodes(OpcodePattern: "EA:n:n:", Mnemonic: "JP PE,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the parity/overflow flag is set, $nn is copied to PC.")
        OpCodesList[0xEB] = OpCodes(OpcodePattern: "EB:::", Mnemonic: "EX DE,HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Exchanges the 16-bit contents of DE and HL.")
        OpCodesList[0xEC] = OpCodes(OpcodePattern: "EC:n:n:", Mnemonic: "CALL PE,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the parity/overflow flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xED40] = OpCodes(OpcodePattern: "ED:40::", Mnemonic: "IN B,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to B")
        OpCodesList[0xED41] = OpCodes(OpcodePattern: "ED:41::", Mnemonic: "OUT (C),B", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of B is written to port C.")
        OpCodesList[0xED42] = OpCodes(OpcodePattern: "ED:42::", Mnemonic: "SBC HL,BC", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts BC and the carry flag from HL.")
        OpCodesList[0xED43] = OpCodes(OpcodePattern: "ED:43:n:n", Mnemonic: "LD (NN),BC", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores BC into the memory location pointed to by $nn.")
        OpCodesList[0xED44] = OpCodes(OpcodePattern: "ED:44::", Mnemonic: "NEG", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of A are negated (two's complement). Operation is the same as subtracting A from zero.")
        OpCodesList[0xED45] = OpCodes(OpcodePattern: "ED:45::", Mnemonic: "RETN", OpcodeSize: 2, InstructionSize: 2, Cycle: [14], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Used at the end of a non-maskable interrupt service routine (located at 0066h) to pop the top stack entry into PC. The value of IFF2 is copied to IFF1 so that maskable interrupts are allowed to continue as before. NMIs are not enabled on the TI.")
        OpCodesList[0xED46] = OpCodes(OpcodePattern: "ED:46::", Mnemonic: "IM 0", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets interrupt mode 0.")
        OpCodesList[0xED47] = OpCodes(OpcodePattern: "ED:47::", Mnemonic: "LD I,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [9], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores the value of A into register I.")
        OpCodesList[0xED48] = OpCodes(OpcodePattern: "ED:48::", Mnemonic: "IN C,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "v", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to C.")
        OpCodesList[0xED49] = OpCodes(OpcodePattern: "ED:49::", Mnemonic: "OUT (C),C", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of C is written to port C.")
        OpCodesList[0xED4A] = OpCodes(OpcodePattern: "ED:4A::", Mnemonic: "ADC HL,BC", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds BC and the carry flag to HL.")
        OpCodesList[0xED4B] = OpCodes(OpcodePattern: "ED:4B:n:n", Mnemonic: "LD BC,(NN)", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into BC.")
        OpCodesList[0xED4D] = OpCodes(OpcodePattern: "ED:4D::", Mnemonic: "RETI", OpcodeSize: 2, InstructionSize: 2, Cycle: [14], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Used at the end of a maskable interrupt service routine. The top stack entry is popped into PC, and signals an I/O device that the interrupt has finished, allowing nested interrupts (not a consideration on the TI).")
        OpCodesList[0xED4F] = OpCodes(OpcodePattern: "ED:4F::", Mnemonic: "LD R,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [9], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores the value of A into register R.")
        OpCodesList[0xED50] = OpCodes(OpcodePattern: "ED:50::", Mnemonic: "IN D,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to D")
        OpCodesList[0xED51] = OpCodes(OpcodePattern: "ED:51::", Mnemonic: "OUT (C),D", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of D is written to port C.")
        OpCodesList[0xED52] = OpCodes(OpcodePattern: "ED:52::", Mnemonic: "SBC HL,DE", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts DE and the carry flag from HL.")
        OpCodesList[0xED53] = OpCodes(OpcodePattern: "ED:53:n:n", Mnemonic: "LD (NN),DE", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores DE into the memory location pointed to by $nn.")
        OpCodesList[0xED56] = OpCodes(OpcodePattern: "ED:56::", Mnemonic: "IM 1", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets interrupt mode 1.")
        OpCodesList[0xED57] = OpCodes(OpcodePattern: "ED:57::", Mnemonic: "LD A,I", OpcodeSize: 2, InstructionSize: 2, Cycle: [9], CFlag: "-", NFlag: "0", PVFlag: "*", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Stores the value of register I into A.")
        OpCodesList[0xED58] = OpCodes(OpcodePattern: "ED:58::", Mnemonic: "IN E,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "v", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to E.")
        OpCodesList[0xED59] = OpCodes(OpcodePattern: "ED:59::", Mnemonic: "OUT (C),E", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of E is written to port C.")
        OpCodesList[0xED5A] = OpCodes(OpcodePattern: "ED:5A::", Mnemonic: "ADC HL,DE", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds DE and the carry flag to HL.")
        OpCodesList[0xED5B] = OpCodes(OpcodePattern: "ED:5B:n:n", Mnemonic: "LD DE,(NN)", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into DE.")
        OpCodesList[0xED5E] = OpCodes(OpcodePattern: "ED:5E::", Mnemonic: "IM 2", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets interrupt mode 2.")
        OpCodesList[0xED5F] = OpCodes(OpcodePattern: "ED:5F::", Mnemonic: "LD A,R", OpcodeSize: 2, InstructionSize: 2, Cycle: [9], CFlag: "-", NFlag: "0", PVFlag: "*", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Stores the value of register R into A.")
        OpCodesList[0xED60] = OpCodes(OpcodePattern: "ED:60::", Mnemonic: "IN H,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to H")
        OpCodesList[0xED61] = OpCodes(OpcodePattern: "ED:61::", Mnemonic: "OUT (C),H", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of H is written to port C.")
        OpCodesList[0xED62] = OpCodes(OpcodePattern: "ED:62::", Mnemonic: "SBC HL,HL", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts HL and the carry flag from HL.")
        OpCodesList[0xED63] = OpCodes(OpcodePattern: "ED:63:n:n", Mnemonic: "LD (NN),HL", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Stores HL into the memory location pointed to by $nn.")
        OpCodesList[0xED67] = OpCodes(OpcodePattern: "ED:67::", Mnemonic: "RRD", OpcodeSize: 2, InstructionSize: 2, Cycle: [18], CFlag: "-", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the low-order nibble of (HL) are copied to the low-order nibble of A. The previous contents are copied to the high-order nibble of (HL). The previous contents are copied to the low-order nibble of (HL).")
        OpCodesList[0xED68] = OpCodes(OpcodePattern: "ED:68::", Mnemonic: "IN L,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "v", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to L.")
        OpCodesList[0xED69] = OpCodes(OpcodePattern: "ED:69::", Mnemonic: "OUT (C),L", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of L is written to port C.")
        OpCodesList[0xED6A] = OpCodes(OpcodePattern: "ED:6A::", Mnemonic: "ADC HL,HL", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds HL and the carry flag to HL.")
        OpCodesList[0xED6B] = OpCodes(OpcodePattern: "ED:6B:n:n", Mnemonic: "LD HL,(NN)", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads the value pointed to by $nn into HL.")
        OpCodesList[0xED6F] = OpCodes(OpcodePattern: "ED:6F::", Mnemonic: "RLD", OpcodeSize: 2, InstructionSize: 2, Cycle: [18], CFlag: "-", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the low-order nibble of (HL) are copied to the high-order nibble of (HL). The previous contents are copied to the low-order nibble of A. The previous contents are copied to the low-order nibble of (HL).")
        OpCodesList[0xED70] = OpCodes(OpcodePattern: "ED:70::", Mnemonic: "IN (C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Inputs a byte from port C and affects flags only.")
        OpCodesList[0xED71] = OpCodes(OpcodePattern: "ED:71::", Mnemonic: "OUT (C),0", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Outputs a zero (on NMOS Z80s) or 255 (on CMOS Z80s) to port C.")
        OpCodesList[0xED72] = OpCodes(OpcodePattern: "ED:72::", Mnemonic: "SBC HL,SP", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts SP and the carry flag from HL.")
        OpCodesList[0xED73] = OpCodes(OpcodePattern: "ED:73:n:n", Mnemonic: "LD (NN),SP", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores SP into the memory location pointed to by $nn.")
        OpCodesList[0xED78] = OpCodes(OpcodePattern: "ED:78::", Mnemonic: "IN A,(C)", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "0", PVFlag: "v", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to A.")
        OpCodesList[0xED79] = OpCodes(OpcodePattern: "ED:79::", Mnemonic: "OUT (C),A", OpcodeSize: 2, InstructionSize: 2, Cycle: [12], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of A is written to port C.")
        OpCodesList[0xED7A] = OpCodes(OpcodePattern: "ED:7A::", Mnemonic: "ADC HL,SP", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds SP and the carry flag to HL.")
        OpCodesList[0xED7B] = OpCodes(OpcodePattern: "ED:7B:n:n", Mnemonic: "LD SP,(NN)", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into SP.")
        OpCodesList[0xEDA0] = OpCodes(OpcodePattern: "ED:A0::", Mnemonic: "LDI", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "0", PVFlag: "*", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL and DE are incremented and BC is decremented. p/v is reset if BC becomes zero and set otherwise.")
        OpCodesList[0xEDA1] = OpCodes(OpcodePattern: "ED:A1::", Mnemonic: "CPI", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "1", PVFlag: "*", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Compares the value of the memory location pointed to by HL with A. Then HL is incremented and BC is decremented. p/v is reset if BC becomes zero and set otherwise.")
        OpCodesList[0xEDA2] = OpCodes(OpcodePattern: "ED:A2::", Mnemonic: "INI", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "*", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to the memory location pointed to by HL. Then HL is incremented and B is decremented.")
        OpCodesList[0xEDA3] = OpCodes(OpcodePattern: "ED:A3::", Mnemonic: "OUTI", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "*", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is incremented.")
        OpCodesList[0xEDA8] = OpCodes(OpcodePattern: "ED:A8::", Mnemonic: "LDD", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "0", PVFlag: "*", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL, DE, and BC are decremented. p/v is reset if BC becomes zero and set otherwise.")
        OpCodesList[0xEDA9] = OpCodes(OpcodePattern: "ED:A9::", Mnemonic: "CPD", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "1", PVFlag: "*", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Compares the value of the memory location pointed to by HL with A. Then HL and BC are decremented. p/v is reset if BC becomes zero and set otherwise.")
        OpCodesList[0xEDAA] = OpCodes(OpcodePattern: "ED:AA::", Mnemonic: "IND", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "*", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to the memory location pointed to by HL. Then HL and B are decremented.")
        OpCodesList[0xEDAB] = OpCodes(OpcodePattern: "ED:AB::", Mnemonic: "OUTD", OpcodeSize: 2, InstructionSize: 2, Cycle: [16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "*", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is decremented.")
        OpCodesList[0xEDB0] = OpCodes(OpcodePattern: "ED:B0::", Mnemonic: "LDIR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "0", PVFlag: "0", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL and DE are incremented and BC is decremented. If BC is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDB1] = OpCodes(OpcodePattern: "ED:B1::", Mnemonic: "CPIR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "1", PVFlag: "*", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Compares the value of the memory location pointed to by HL with A. Then HL is incremented and BC is decremented. If BC is not zero and z is not set, this operation is repeated. p/v is reset if BC becomes zero and set otherwise, acting as an indicator that HL reached a memory location whose value equalled A before the counter went to zero. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDB2] = OpCodes(OpcodePattern: "ED:B2::", Mnemonic: "INIR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "1", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to the memory location pointed to by HL. Then HL is incremented and B is decremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDB3] = OpCodes(OpcodePattern: "ED:B3::", Mnemonic: "OTIR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "1", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is incremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDB8] = OpCodes(OpcodePattern: "ED:B8::", Mnemonic: "LDDR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "0", PVFlag: "0", HFlag: "0", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Transfers a byte of data from the memory location pointed to by HL to the memory location pointed to by DE. Then HL, DE, and BC are decremented. If BC is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDB9] = OpCodes(OpcodePattern: "ED:B9::", Mnemonic: "CPDR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "1", PVFlag: "*", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Compares the value of the memory location pointed to by HL with A. Then HL and BC are decremented. If BC is not zero and z is not set, this operation is repeated. p/v is reset if BC becomes zero and set otherwise, acting as an indicator that HL reached a memory location whose value equalled A before the counter went to zero. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDBA] = OpCodes(OpcodePattern: "ED:BA::", Mnemonic: "INDR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "1", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "A byte from port C is written to the memory location pointed to by HL. Then HL and B are decremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEDBB] = OpCodes(OpcodePattern: "ED:BB::", Mnemonic: "OTDR", OpcodeSize: 2, InstructionSize: 2, Cycle: [21,16], CFlag: "-", NFlag: "1", PVFlag: " ", HFlag: " ", ZFlag: "1", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "B is decremented. A byte from the memory location pointed to by HL is written to port C. Then HL is decremented. If B is not zero, this operation is repeated. Interrupts can trigger while this instruction is processing.")
        OpCodesList[0xEE] = OpCodes(OpcodePattern: "EE:n::", Mnemonic: "XOR N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with $n.")
        OpCodesList[0xEF] = OpCodes(OpcodePattern: "EF:::", Mnemonic: "RST 28H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 28h")
        OpCodesList[0xF0] = OpCodes(OpcodePattern: "F0:::", Mnemonic: "RET P", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the sign flag is unset, the top stack entry is popped into PC.")
        OpCodesList[0xF1] = OpCodes(OpcodePattern: "F1:::", Mnemonic: "POP AF", OpcodeSize: 1, InstructionSize: 1, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The memory location pointed to by SP is stored into F and SP is incremented. The memory location pointed to by SP is stored into A and SP is incremented again.")
        OpCodesList[0xF2] = OpCodes(OpcodePattern: "F2:n:n:", Mnemonic: "JP P,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the sign flag is unset, $nn is copied to PC.")
        OpCodesList[0xF3] = OpCodes(OpcodePattern: "F3:::", Mnemonic: "DI", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets both interrupt flip-flops, thus preventing maskable interrupts from triggering.")
        OpCodesList[0xF4] = OpCodes(OpcodePattern: "F4:n:n:", Mnemonic: "CALL P,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the sign flag is unset, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xF5] = OpCodes(OpcodePattern: "F5:::", Mnemonic: "PUSH AF", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "SP is decremented and A is stored into the memory location pointed to by SP. SP is decremented again and F is stored into the memory location pointed to by SP.")
        OpCodesList[0xF6] = OpCodes(OpcodePattern: "F6:n::", Mnemonic: "OR N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with $n.")
        OpCodesList[0xF7] = OpCodes(OpcodePattern: "F7:::", Mnemonic: "RST 30H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 30H")
        OpCodesList[0xF8] = OpCodes(OpcodePattern: "F8:::", Mnemonic: "RET M", OpcodeSize: 1, InstructionSize: 1, Cycle: [11,5], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the sign flag is set, the top stack entry is popped into PC.")
        OpCodesList[0xF9] = OpCodes(OpcodePattern: "F9:::", Mnemonic: "LD SP,HL", OpcodeSize: 1, InstructionSize: 1, Cycle: [6], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value of HL into SP.")
        OpCodesList[0xFA] = OpCodes(OpcodePattern: "FA:n:n:", Mnemonic: "JP M,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the sign flag is set, $nn is copied to PC.")
        OpCodesList[0xFB] = OpCodes(OpcodePattern: "FB:::", Mnemonic: "EI", OpcodeSize: 1, InstructionSize: 1, Cycle: [4], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets both interrupt flip-flops, thus allowing maskable interrupts to occur. An interrupt will not occur until after the immediately following instruction.")
        OpCodesList[0xFC] = OpCodes(OpcodePattern: "FC:n:n:", Mnemonic: "CALL M,NN", OpcodeSize: 1, InstructionSize: 3, Cycle: [17,10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "If the sign flag is set, the current PC value plus three is pushed onto the stack, then is loaded with $nn.")
        OpCodesList[0xFD04] = OpCodes(OpcodePattern: "FD:04::", Mnemonic: "INC B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to B")
        OpCodesList[0xFD05] = OpCodes(OpcodePattern: "FD:05::", Mnemonic: "DEC B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from $r.")
        OpCodesList[0xFD06] = OpCodes(OpcodePattern: "FD:06:n:", Mnemonic: "LD B,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads $n into B")
        OpCodesList[0xFD09] = OpCodes(OpcodePattern: "FD:09::", Mnemonic: "ADD IY,BC", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of BC is added to IY.")
        OpCodesList[0xFD0C] = OpCodes(OpcodePattern: "FD:0C::", Mnemonic: "INC C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to C.")
        OpCodesList[0xFD0D] = OpCodes(OpcodePattern: "FD:0D::", Mnemonic: "DEC C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from C.")
        OpCodesList[0xFD0E] = OpCodes(OpcodePattern: "FD:0E:n:", Mnemonic: "LD C,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into C.")
        OpCodesList[0xFD14] = OpCodes(OpcodePattern: "FD:14::", Mnemonic: "INC D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to D")
        OpCodesList[0xFD15] = OpCodes(OpcodePattern: "FD:15::", Mnemonic: "DEC D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from $r.")
        OpCodesList[0xFD16] = OpCodes(OpcodePattern: "FD:16:n:", Mnemonic: "LD D,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads $n into D")
        OpCodesList[0xFD19] = OpCodes(OpcodePattern: "FD:19::", Mnemonic: "ADD IY,DE", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of DE is added to IY.")
        OpCodesList[0xFD1C] = OpCodes(OpcodePattern: "FD:1C::", Mnemonic: "INC E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to E.")
        OpCodesList[0xFD1D] = OpCodes(OpcodePattern: "FD:1D::", Mnemonic: "DEC E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from E.")
        OpCodesList[0xFD1E] = OpCodes(OpcodePattern: "FD:1E:n:", Mnemonic: "LD E,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into E.")
        OpCodesList[0xFD21] = OpCodes(OpcodePattern: "FD:21:n:n", Mnemonic: "LD IY,NN", OpcodeSize: 2, InstructionSize: 4, Cycle: [14], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads $nn into register IY.")
        OpCodesList[0xFD22] = OpCodes(OpcodePattern: "FD:22:n:n", Mnemonic: "LD (NN),IY", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores IY into the memory location pointed to by $nn.")
        OpCodesList[0xFD23] = OpCodes(OpcodePattern: "FD:23::", Mnemonic: "INC IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Adds one to IY.")
        OpCodesList[0xFD24] = OpCodes(OpcodePattern: "FD:24::", Mnemonic: "INC IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to IY.")
        OpCodesList[0xFD25] = OpCodes(OpcodePattern: "FD:25::", Mnemonic: "DEC IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from $r.")
        OpCodesList[0xFD26] = OpCodes(OpcodePattern: "FD:26:n:", Mnemonic: "LD IYH,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads $n into IYH")
        OpCodesList[0xFD29] = OpCodes(OpcodePattern: "FD:29::", Mnemonic: "ADD IY,IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of IY is added to IY.")
        OpCodesList[0xFD2A] = OpCodes(OpcodePattern: "FD:2A:n:n", Mnemonic: "LD IY,(NN)", OpcodeSize: 2, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by $nn into IY.")
        OpCodesList[0xFD2B] = OpCodes(OpcodePattern: "FD:2B::", Mnemonic: "DEC IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from IY.")
        OpCodesList[0xFD2C] = OpCodes(OpcodePattern: "FD:2C::", Mnemonic: "INC IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to IYL.")
        OpCodesList[0xFD2D] = OpCodes(OpcodePattern: "FD:2D::", Mnemonic: "DEC IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from IYL.")
        OpCodesList[0xFD2E] = OpCodes(OpcodePattern: "FD:2E:n:", Mnemonic: "LD IYL,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into IYL.")
        OpCodesList[0xFD34] = OpCodes(OpcodePattern: "FD:34:d:", Mnemonic: "INC (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [23], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds one to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD35] = OpCodes(OpcodePattern: "FD:35:d:", Mnemonic: "DEC (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [23], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts one from the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD36] = OpCodes(OpcodePattern: "FD:36:d:n", Mnemonic: "LD (IY+D),N", OpcodeSize: 2, InstructionSize: 4, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores $n to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD39] = OpCodes(OpcodePattern: "FD:39::", Mnemonic: "ADD IY,SP", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "+", NFlag: "+", PVFlag: "-", HFlag: "+", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The value of SP is added to IY.")
        OpCodesList[0xFD3C] = OpCodes(OpcodePattern: "FD:3C::", Mnemonic: "INC A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds one to A.")
        OpCodesList[0xFD3D] = OpCodes(OpcodePattern: "FD:3D::", Mnemonic: "DEC A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts one from A.")
        OpCodesList[0xFD3E] = OpCodes(OpcodePattern: "FD:3E:n:", Mnemonic: "LD A,N", OpcodeSize: 2, InstructionSize: 3, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Loads n into A.")
        OpCodesList[0xFD40] = OpCodes(OpcodePattern: "FD:40::", Mnemonic: "LD B,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into B")
        OpCodesList[0xFD41] = OpCodes(OpcodePattern: "FD:41::", Mnemonic: "LD B,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into B")
        OpCodesList[0xFD42] = OpCodes(OpcodePattern: "FD:42::", Mnemonic: "LD B,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into B")
        OpCodesList[0xFD43] = OpCodes(OpcodePattern: "FD:43::", Mnemonic: "LD B,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into B")
        OpCodesList[0xFD44] = OpCodes(OpcodePattern: "FD:44::", Mnemonic: "LD B,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into B")
        OpCodesList[0xFD45] = OpCodes(OpcodePattern: "FD:45::", Mnemonic: "LD B,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into B")
        OpCodesList[0xFD46] = OpCodes(OpcodePattern: "FD:46:d:", Mnemonic: "LD B,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus $d into B")
        OpCodesList[0xFD47] = OpCodes(OpcodePattern: "FD:47::", Mnemonic: "LD B,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into B.")
        OpCodesList[0xFD48] = OpCodes(OpcodePattern: "FD:48::", Mnemonic: "LD C,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into C.")
        OpCodesList[0xFD49] = OpCodes(OpcodePattern: "FD:49::", Mnemonic: "LD C,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into C.")
        OpCodesList[0xFD4A] = OpCodes(OpcodePattern: "FD:4A::", Mnemonic: "LD C,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into C.")
        OpCodesList[0xFD4B] = OpCodes(OpcodePattern: "FD:4B::", Mnemonic: "LD C,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into C.")
        OpCodesList[0xFD4C] = OpCodes(OpcodePattern: "FD:4C::", Mnemonic: "LD C,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into C.")
        OpCodesList[0xFD4D] = OpCodes(OpcodePattern: "FD:4D::", Mnemonic: "LD C,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into C.")
        OpCodesList[0xFD4E] = OpCodes(OpcodePattern: "FD:4E:d:", Mnemonic: "LD C,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus d into C.")
        OpCodesList[0xFD4F] = OpCodes(OpcodePattern: "FD:4F::", Mnemonic: "LD C,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into C.")
        OpCodesList[0xFD50] = OpCodes(OpcodePattern: "FD:50::", Mnemonic: "LD D,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into D")
        OpCodesList[0xFD51] = OpCodes(OpcodePattern: "FD:51::", Mnemonic: "LD D,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into D")
        OpCodesList[0xFD52] = OpCodes(OpcodePattern: "FD:52::", Mnemonic: "LD D,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into D")
        OpCodesList[0xFD53] = OpCodes(OpcodePattern: "FD:53::", Mnemonic: "LD D,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into D")
        OpCodesList[0xFD54] = OpCodes(OpcodePattern: "FD:54::", Mnemonic: "LD D,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into D")
        OpCodesList[0xFD55] = OpCodes(OpcodePattern: "FD:55::", Mnemonic: "LD D,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into D")
        OpCodesList[0xFD56] = OpCodes(OpcodePattern: "FD:56:d:", Mnemonic: "LD D,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus $d into D")
        OpCodesList[0xFD57] = OpCodes(OpcodePattern: "FD:57::", Mnemonic: "LD D,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into D.")
        OpCodesList[0xFD58] = OpCodes(OpcodePattern: "FD:58::", Mnemonic: "LD E,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into E.")
        OpCodesList[0xFD59] = OpCodes(OpcodePattern: "FD:59::", Mnemonic: "LD E,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into E.")
        OpCodesList[0xFD5A] = OpCodes(OpcodePattern: "FD:5A::", Mnemonic: "LD E,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into E.")
        OpCodesList[0xFD5B] = OpCodes(OpcodePattern: "FD:5B::", Mnemonic: "LD E,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into E.")
        OpCodesList[0xFD5C] = OpCodes(OpcodePattern: "FD:5C::", Mnemonic: "LD E,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into E.")
        OpCodesList[0xFD5D] = OpCodes(OpcodePattern: "FD:5D::", Mnemonic: "LD E,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into E.")
        OpCodesList[0xFD5E] = OpCodes(OpcodePattern: "FD:5E:d:", Mnemonic: "LD E,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus d into E.")
        OpCodesList[0xFD5F] = OpCodes(OpcodePattern: "FD:5F::", Mnemonic: "LD E,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into E.")
        OpCodesList[0xFD60] = OpCodes(OpcodePattern: "FD:60::", Mnemonic: "LD IYH,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into IYH")
        OpCodesList[0xFD61] = OpCodes(OpcodePattern: "FD:61::", Mnemonic: "LD IYH,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into IYH")
        OpCodesList[0xFD62] = OpCodes(OpcodePattern: "FD:62::", Mnemonic: "LD IYH,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into IYH")
        OpCodesList[0xFD63] = OpCodes(OpcodePattern: "FD:63::", Mnemonic: "LD IYH,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into IYH")
        OpCodesList[0xFD64] = OpCodes(OpcodePattern: "FD:64::", Mnemonic: "LD IYH,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into IYH")
        OpCodesList[0xFD65] = OpCodes(OpcodePattern: "FD:65::", Mnemonic: "LD IYH,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into IYH")
        OpCodesList[0xFD66] = OpCodes(OpcodePattern: "FD:66:d:", Mnemonic: "LD H,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus $d into H")
        OpCodesList[0xFD67] = OpCodes(OpcodePattern: "FD:67::", Mnemonic: "LD IYH,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into IYH.")
        OpCodesList[0xFD68] = OpCodes(OpcodePattern: "FD:68::", Mnemonic: "LD IYL,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into IYL.")
        OpCodesList[0xFD69] = OpCodes(OpcodePattern: "FD:69::", Mnemonic: "LD IYL,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into IYL.")
        OpCodesList[0xFD6A] = OpCodes(OpcodePattern: "FD:6A::", Mnemonic: "LD IYL,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into IYL.")
        OpCodesList[0xFD6B] = OpCodes(OpcodePattern: "FD:6B::", Mnemonic: "LD IYL,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into IYL.")
        OpCodesList[0xFD6C] = OpCodes(OpcodePattern: "FD:6C::", Mnemonic: "LD IYL,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into IYL.")
        OpCodesList[0xFD6D] = OpCodes(OpcodePattern: "FD:6D::", Mnemonic: "LD IYL,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into IYL.")
        OpCodesList[0xFD6E] = OpCodes(OpcodePattern: "FD:6E:d:", Mnemonic: "LD L,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus d into L.")
        OpCodesList[0xFD6F] = OpCodes(OpcodePattern: "FD:6F::", Mnemonic: "LD IYL,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into IYL.")
        OpCodesList[0xFD70] = OpCodes(OpcodePattern: "FD:70:d:", Mnemonic: "LD (IY+D),B", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores B to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD71] = OpCodes(OpcodePattern: "FD:71:d:", Mnemonic: "LD (IY+D),C", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores C to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD72] = OpCodes(OpcodePattern: "FD:72:d:", Mnemonic: "LD (IY+D),D", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores D to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD73] = OpCodes(OpcodePattern: "FD:73:d:", Mnemonic: "LD (IY+D),E", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores E to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD74] = OpCodes(OpcodePattern: "FD:74:d:", Mnemonic: "LD (IY+D),H", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores H to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD75] = OpCodes(OpcodePattern: "FD:75:d:", Mnemonic: "LD (IY+D),L", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores L to the memory location pointed to by IY plus $d.")
        OpCodesList[0xFD77] = OpCodes(OpcodePattern: "FD:77:d:", Mnemonic: "LD (IY+D),A", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Stores A to the memory location pointed to by IY plus d.")
        OpCodesList[0xFD78] = OpCodes(OpcodePattern: "FD:78::", Mnemonic: "LD A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of B are loaded into A.")
        OpCodesList[0xFD79] = OpCodes(OpcodePattern: "FD:79::", Mnemonic: "LD A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of C are loaded into A.")
        OpCodesList[0xFD7A] = OpCodes(OpcodePattern: "FD:7A::", Mnemonic: "LD A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of D are loaded into A.")
        OpCodesList[0xFD7B] = OpCodes(OpcodePattern: "FD:7B::", Mnemonic: "LD A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of E are loaded into A.")
        OpCodesList[0xFD7C] = OpCodes(OpcodePattern: "FD:7C::", Mnemonic: "LD A,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYH are loaded into A.")
        OpCodesList[0xFD7D] = OpCodes(OpcodePattern: "FD:7D::", Mnemonic: "LD A,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of IYL are loaded into A.")
        OpCodesList[0xFD7E] = OpCodes(OpcodePattern: "FD:7E:d:", Mnemonic: "LD A,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value pointed to by IY plus d into A.")
        OpCodesList[0xFD7F] = OpCodes(OpcodePattern: "FD:7F::", Mnemonic: "LD A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "The contents of A are loaded into A.")
        OpCodesList[0xFD80] = OpCodes(OpcodePattern: "FD:80::", Mnemonic: "ADD A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds B to A.")
        OpCodesList[0xFD81] = OpCodes(OpcodePattern: "FD:81::", Mnemonic: "ADD A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds C to A.")
        OpCodesList[0xFD82] = OpCodes(OpcodePattern: "FD:82::", Mnemonic: "ADD A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds D to A.")
        OpCodesList[0xFD83] = OpCodes(OpcodePattern: "FD:83::", Mnemonic: "ADD A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds E to A.")
        OpCodesList[0xFD84] = OpCodes(OpcodePattern: "FD:84::", Mnemonic: "ADD A,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IYH to A.")
        OpCodesList[0xFD85] = OpCodes(OpcodePattern: "FD:85::", Mnemonic: "ADD A,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IYL to A.")
        OpCodesList[0xFD86] = OpCodes(OpcodePattern: "FD:86:d:", Mnemonic: "ADD A,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds the value pointed to by IY plus $d to A.")
        OpCodesList[0xFD87] = OpCodes(OpcodePattern: "FD:87::", Mnemonic: "ADD A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds A to A.")
        OpCodesList[0xFD88] = OpCodes(OpcodePattern: "FD:88::", Mnemonic: "ADC A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds B and the carry flag to A.")
        OpCodesList[0xFD89] = OpCodes(OpcodePattern: "FD:89::", Mnemonic: "ADC A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds C and the carry flag to A.")
        OpCodesList[0xFD8A] = OpCodes(OpcodePattern: "FD:8A::", Mnemonic: "ADC A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds D and the carry flag to A.")
        OpCodesList[0xFD8B] = OpCodes(OpcodePattern: "FD:8B::", Mnemonic: "ADC A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds E and the carry flag to A.")
        OpCodesList[0xFD8C] = OpCodes(OpcodePattern: "FD:8C::", Mnemonic: "ADC A,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IYH and the carry flag to A.")
        OpCodesList[0xFD8D] = OpCodes(OpcodePattern: "FD:8D::", Mnemonic: "ADC A,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds IYL and the carry flag to A.")
        OpCodesList[0xFD8E] = OpCodes(OpcodePattern: "FD:8E:d:", Mnemonic: "ADC A,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Adds the value pointed to by IY plus $d and the carry flag to A.")
        OpCodesList[0xFD8F] = OpCodes(OpcodePattern: "FD:8F::", Mnemonic: "ADC A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Adds A and the carry flag to A.")
        OpCodesList[0xFD90] = OpCodes(OpcodePattern: "FD:90::", Mnemonic: "SUB B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B from A.")
        OpCodesList[0xFD91] = OpCodes(OpcodePattern: "FD:91::", Mnemonic: "SUB C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B from A.")
        OpCodesList[0xFD92] = OpCodes(OpcodePattern: "FD:92::", Mnemonic: "SUB D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts D from A.")
        OpCodesList[0xFD93] = OpCodes(OpcodePattern: "FD:93::", Mnemonic: "SUB E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts E from A.")
        OpCodesList[0xFD94] = OpCodes(OpcodePattern: "FD:94::", Mnemonic: "SUB IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IYH from A.")
        OpCodesList[0xFD95] = OpCodes(OpcodePattern: "FD:95::", Mnemonic: "SUB IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "SubtractsIYLfrom A.")
        OpCodesList[0xFD96] = OpCodes(OpcodePattern: "FD:96:d:", Mnemonic: "SUB (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts the value pointed to by IY plus $d from A.")
        OpCodesList[0xFD97] = OpCodes(OpcodePattern: "FD:97::", Mnemonic: "SUB A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts A from A.")
        OpCodesList[0xFD98] = OpCodes(OpcodePattern: "FD:98::", Mnemonic: "SBC A,B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B and the carry flag from A.")
        OpCodesList[0xFD99] = OpCodes(OpcodePattern: "FD:99::", Mnemonic: "SBC A,C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts C and the carry flag from A.")
        OpCodesList[0xFD9A] = OpCodes(OpcodePattern: "FD:9A::", Mnemonic: "SBC A,D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts D and the carry flag from A.")
        OpCodesList[0xFD9B] = OpCodes(OpcodePattern: "FD:9B::", Mnemonic: "SBC A,E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts E and the carry flag from A.")
        OpCodesList[0xFD9C] = OpCodes(OpcodePattern: "FD:9C::", Mnemonic: "SBC A,IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IYH and the carry flag from A.")
        OpCodesList[0xFD9D] = OpCodes(OpcodePattern: "FD:9D::", Mnemonic: "SBC A,IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IYL and the carry flag from A.")
        OpCodesList[0xFD9E] = OpCodes(OpcodePattern: "FD:9E:d:", Mnemonic: "SBC A,(IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts the value pointed to by IY plus $d and the carry flag from A.")
        OpCodesList[0xFD9F] = OpCodes(OpcodePattern: "FD:9F::", Mnemonic: "SBC A,A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts A and the carry flag from A.")
        OpCodesList[0xFDA0] = OpCodes(OpcodePattern: "FD:A0::", Mnemonic: "AND B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with B")
        OpCodesList[0xFDA1] = OpCodes(OpcodePattern: "FD:A1::", Mnemonic: "AND C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with C")
        OpCodesList[0xFDA2] = OpCodes(OpcodePattern: "FD:A2::", Mnemonic: "AND D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with D")
        OpCodesList[0xFDA3] = OpCodes(OpcodePattern: "FD:A3::", Mnemonic: "AND E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with E")
        OpCodesList[0xFDA4] = OpCodes(OpcodePattern: "FD:A4::", Mnemonic: "AND IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with IYH")
        OpCodesList[0xFDA5] = OpCodes(OpcodePattern: "FD:A5::", Mnemonic: "AND IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with IYL")
        OpCodesList[0xFDA6] = OpCodes(OpcodePattern: "FD:A6:d:", Mnemonic: "AND (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise AND on A with the value pointed to by IY plus $d.")
        OpCodesList[0xFDA7] = OpCodes(OpcodePattern: "FD:A7::", Mnemonic: "AND A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "1", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise AND on A with A.")
        OpCodesList[0xFDA8] = OpCodes(OpcodePattern: "FD:A8::", Mnemonic: "XOR B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with B")
        OpCodesList[0xFDA9] = OpCodes(OpcodePattern: "FD:A9::", Mnemonic: "XOR C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with C")
        OpCodesList[0xFDAA] = OpCodes(OpcodePattern: "FD:AA::", Mnemonic: "XOR D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with D")
        OpCodesList[0xFDAB] = OpCodes(OpcodePattern: "FD:AB::", Mnemonic: "XOR E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with E")
        OpCodesList[0xFDAC] = OpCodes(OpcodePattern: "FD:AC::", Mnemonic: "XOR IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with IYH")
        OpCodesList[0xFDAD] = OpCodes(OpcodePattern: "FD:AD::", Mnemonic: "XOR IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with IYL")
        OpCodesList[0xFDAE] = OpCodes(OpcodePattern: "FD:AE:d:", Mnemonic: "XOR (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise XOR on A with the value pointed to by IY plus $d.")
        OpCodesList[0xFDAF] = OpCodes(OpcodePattern: "FD:AF::", Mnemonic: "XOR A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise XOR on A with A.")
        OpCodesList[0xFDB0] = OpCodes(OpcodePattern: "FD:B0::", Mnemonic: "OR B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with B")
        OpCodesList[0xFDB1] = OpCodes(OpcodePattern: "FD:B1::", Mnemonic: "OR C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with C")
        OpCodesList[0xFDB2] = OpCodes(OpcodePattern: "FD:B2::", Mnemonic: "OR D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with D")
        OpCodesList[0xFDB3] = OpCodes(OpcodePattern: "FD:B3::", Mnemonic: "OR E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with E")
        OpCodesList[0xFDB4] = OpCodes(OpcodePattern: "FD:B4::", Mnemonic: "OR IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with IYH")
        OpCodesList[0xFDB5] = OpCodes(OpcodePattern: "FD:B5::", Mnemonic: "OR IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with IYL")
        OpCodesList[0xFDB6] = OpCodes(OpcodePattern: "FD:B6:d:", Mnemonic: "OR (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Bitwise OR on A with the value pointed to by IY plus $d.")
        OpCodesList[0xFDB7] = OpCodes(OpcodePattern: "FD:B7::", Mnemonic: "OR A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "0", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Bitwise OR on A with A.")
        OpCodesList[0xFDB8] = OpCodes(OpcodePattern: "FD:B8::", Mnemonic: "CP B", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts B from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDB9] = OpCodes(OpcodePattern: "FD:B9::", Mnemonic: "CP C", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts C from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDBA] = OpCodes(OpcodePattern: "FD:BA::", Mnemonic: "CP D", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts D from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDBB] = OpCodes(OpcodePattern: "FD:BB::", Mnemonic: "CP E", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts E from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDBC] = OpCodes(OpcodePattern: "FD:BC::", Mnemonic: "CP IYH", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IYH from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDBD] = OpCodes(OpcodePattern: "FD:BD::", Mnemonic: "CP IYL", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts IYL from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDBE] = OpCodes(OpcodePattern: "FD:BE:d:", Mnemonic: "CP (IY+D)", OpcodeSize: 2, InstructionSize: 3, Cycle: [19], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts the value pointed to by IY plus $d from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDBF] = OpCodes(OpcodePattern: "FD:BF::", Mnemonic: "CP A", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "Subtracts A from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFDCB0000] = OpCodes(OpcodePattern: "FD:CB:d:00", Mnemonic: "RLC (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in B")
        OpCodesList[0xFDCB0001] = OpCodes(OpcodePattern: "FD:CB:d:01", Mnemonic: "RLC (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in C")
        OpCodesList[0xFDCB0002] = OpCodes(OpcodePattern: "FD:CB:d:02", Mnemonic: "RLC (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in D")
        OpCodesList[0xFDCB0003] = OpCodes(OpcodePattern: "FD:CB:d:03", Mnemonic: "RLC (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in E")
        OpCodesList[0xFDCB0004] = OpCodes(OpcodePattern: "FD:CB:d:04", Mnemonic: "RLC (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in H")
        OpCodesList[0xFDCB0005] = OpCodes(OpcodePattern: "FD:CB:d:05", Mnemonic: "RLC (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in L")
        OpCodesList[0xFDCB0006] = OpCodes(OpcodePattern: "FD:CB:d:06", Mnemonic: "RLC (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0.")
        OpCodesList[0xFDCB0007] = OpCodes(OpcodePattern: "FD:CB:d:07", Mnemonic: "RLC (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and bit 0. The result is then stored in A")
        OpCodesList[0xFDCB0008] = OpCodes(OpcodePattern: "FD:CB:d:08", Mnemonic: "RRC (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in B")
        OpCodesList[0xFDCB0009] = OpCodes(OpcodePattern: "FD:CB:d:09", Mnemonic: "RRC (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in C")
        OpCodesList[0xFDCB000A] = OpCodes(OpcodePattern: "FD:CB:d:0A", Mnemonic: "RRC (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored inD")
        OpCodesList[0xFDCB000B] = OpCodes(OpcodePattern: "FD:CB:d:0B", Mnemonic: "RRC (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in E")
        OpCodesList[0xFDCB000C] = OpCodes(OpcodePattern: "FD:CB:d:0C", Mnemonic: "RRC (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in H")
        OpCodesList[0xFDCB000D] = OpCodes(OpcodePattern: "FD:CB:d:0D", Mnemonic: "RRC (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in L")
        OpCodesList[0xFDCB000E] = OpCodes(OpcodePattern: "FD:CB:d:0E", Mnemonic: "RRC (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7.")
        OpCodesList[0xFDCB000F] = OpCodes(OpcodePattern: "FD:CB:d:0F", Mnemonic: "RRC (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus dare rotated right one bit position. The contents of bit 0 are copied to the carry flag and bit 7. The result is then stored in A.")
        OpCodesList[0xFDCB0010] = OpCodes(OpcodePattern: "FD:CB:d:10", Mnemonic: "RL (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in B")
        OpCodesList[0xFDCB0011] = OpCodes(OpcodePattern: "FD:CB:d:11", Mnemonic: "RL (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in C")
        OpCodesList[0xFDCB0012] = OpCodes(OpcodePattern: "FD:CB:d:12", Mnemonic: "RL (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in D")
        OpCodesList[0xFDCB0013] = OpCodes(OpcodePattern: "FD:CB:d:13", Mnemonic: "RL (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in E")
        OpCodesList[0xFDCB0014] = OpCodes(OpcodePattern: "FD:CB:d:14", Mnemonic: "RL (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in H")
        OpCodesList[0xFDCB0015] = OpCodes(OpcodePattern: "FD:CB:d:15", Mnemonic: "RL (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in L")
        OpCodesList[0xFDCB0016] = OpCodes(OpcodePattern: "FD:CB:d:16", Mnemonic: "RL (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0.")
        OpCodesList[0xFDCB0017] = OpCodes(OpcodePattern: "FD:CB:d:17", Mnemonic: "RL (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus dare rotated left one bit position. The contents of bit 7 are copied to the carry flag and the previous contents of the carry flag are copied to bit 0. The result is then stored in A.")
        OpCodesList[0xFDCB0018] = OpCodes(OpcodePattern: "FD:CB:d:18", Mnemonic: "RR (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in B")
        OpCodesList[0xFDCB0019] = OpCodes(OpcodePattern: "FD:CB:d:19", Mnemonic: "RR (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in C")
        OpCodesList[0xFDCB001A] = OpCodes(OpcodePattern: "FD:CB:d:1A", Mnemonic: "RR (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in D")
        OpCodesList[0xFDCB001B] = OpCodes(OpcodePattern: "FD:CB:d:1B", Mnemonic: "RR (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in E")
        OpCodesList[0xFDCB001C] = OpCodes(OpcodePattern: "FD:CB:d:1C", Mnemonic: "RR (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in H")
        OpCodesList[0xFDCB001D] = OpCodes(OpcodePattern: "FD:CB:d:1D", Mnemonic: "RR (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in L")
        OpCodesList[0xFDCB001E] = OpCodes(OpcodePattern: "FD:CB:d:1E", Mnemonic: "RR (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7.")
        OpCodesList[0xFDCB001F] = OpCodes(OpcodePattern: "FD:CB:d:1F", Mnemonic: "RR (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus dare rotated right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of the carry flag are copied to bit 7. The result is then stored in A.")
        OpCodesList[0xFDCB0020] = OpCodes(OpcodePattern: "FD:CB:d:20", Mnemonic: "SLA (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in B")
        OpCodesList[0xFDCB0021] = OpCodes(OpcodePattern: "FD:CB:d:21", Mnemonic: "SLA (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in C")
        OpCodesList[0xFDCB0022] = OpCodes(OpcodePattern: "FD:CB:d:22", Mnemonic: "SLA (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in D")
        OpCodesList[0xFDCB0023] = OpCodes(OpcodePattern: "FD:CB:d:23", Mnemonic: "SLA (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in E")
        OpCodesList[0xFDCB0024] = OpCodes(OpcodePattern: "FD:CB:d:24", Mnemonic: "SLA (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in H.")
        OpCodesList[0xFDCB0025] = OpCodes(OpcodePattern: "FD:CB:d:25", Mnemonic: "SLA (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in L")
        OpCodesList[0xFDCB0026] = OpCodes(OpcodePattern: "FD:CB:d:26", Mnemonic: "SLA (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0.")
        OpCodesList[0xFDCB0027] = OpCodes(OpcodePattern: "FD:CB:d:27", Mnemonic: "SLA (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus dare shifted left one bit position. The contents of bit 7 are copied to the carry flag and a zero is put into bit 0. The result is then stored in A")
        OpCodesList[0xFDCB0028] = OpCodes(OpcodePattern: "FD:CB:d:28", Mnemonic: "SRA (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in B")
        OpCodesList[0xFDCB0029] = OpCodes(OpcodePattern: "FD:CB:d:29", Mnemonic: "SRA (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in C")
        OpCodesList[0xFDCB002A] = OpCodes(OpcodePattern: "FD:CB:d:2A", Mnemonic: "SRA (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in D")
        OpCodesList[0xFDCB002B] = OpCodes(OpcodePattern: "FD:CB:d:2B", Mnemonic: "SRA (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in E")
        OpCodesList[0xFDCB002C] = OpCodes(OpcodePattern: "FD:CB:d:2C", Mnemonic: "SRA (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in H")
        OpCodesList[0xFDCB002D] = OpCodes(OpcodePattern: "FD:CB:d:2D", Mnemonic: "SRA (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in L")
        OpCodesList[0xFDCB002E] = OpCodes(OpcodePattern: "FD:CB:d:2E", Mnemonic: "SRA (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged.")
        OpCodesList[0xFDCB002F] = OpCodes(OpcodePattern: "FD:CB:d:2F", Mnemonic: "SRA (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus dare shifted right one bit position. The contents of bit 0 are copied to the carry flag and the previous contents of bit 7 are unchanged. The result is then stored in A.")
        OpCodesList[0xFDCB0030] = OpCodes(OpcodePattern: "FD:CB:d:30", Mnemonic: "SLL (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in B")
        OpCodesList[0xFDCB0031] = OpCodes(OpcodePattern: "FD:CB:d:31", Mnemonic: "SLL (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in C")
        OpCodesList[0xFDCB0032] = OpCodes(OpcodePattern: "FD:CB:d:32", Mnemonic: "SLL (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in D")
        OpCodesList[0xFDCB0033] = OpCodes(OpcodePattern: "FD:CB:d:33", Mnemonic: "SLL (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in E")
        OpCodesList[0xFDCB0034] = OpCodes(OpcodePattern: "FD:CB:d:34", Mnemonic: "SLL (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in H")
        OpCodesList[0xFDCB0035] = OpCodes(OpcodePattern: "FD:CB:d:35", Mnemonic: "SLL (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in L")
        OpCodesList[0xFDCB0036] = OpCodes(OpcodePattern: "FD:CB:d:36", Mnemonic: "SLL (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0.")
        OpCodesList[0xFDCB0037] = OpCodes(OpcodePattern: "FD:CB:d:37", Mnemonic: "SLL (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus d are shifted left one bit position. The contents of bit 7 are put into the carry flag and a one is put into bit 0. The result is then stored in A.")
        OpCodesList[0xFDCB0038] = OpCodes(OpcodePattern: "FD:CB:d:38", Mnemonic: "SRL (IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in B")
        OpCodesList[0xFDCB0039] = OpCodes(OpcodePattern: "FD:CB:d:39", Mnemonic: "SRL (IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in C")
        OpCodesList[0xFDCB003A] = OpCodes(OpcodePattern: "FD:CB:d:3A", Mnemonic: "SRL (IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in D")
        OpCodesList[0xFDCB003B] = OpCodes(OpcodePattern: "FD:CB:d:3B", Mnemonic: "SRL (IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in E")
        OpCodesList[0xFDCB003C] = OpCodes(OpcodePattern: "FD:CB:d:3C", Mnemonic: "SRL (IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in H")
        OpCodesList[0xFDCB003D] = OpCodes(OpcodePattern: "FD:CB:d:3D", Mnemonic: "SRL (IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in L")
        OpCodesList[0xFDCB003E] = OpCodes(OpcodePattern: "FD:CB:d:3E", Mnemonic: "SRL (IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "The contents of the memory location pointed to by IY plus $d are shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7.")
        OpCodesList[0xFDCB003F] = OpCodes(OpcodePattern: "FD:CB:d:3F", Mnemonic: "SRL (IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "+", NFlag: "0", PVFlag: "p", HFlag: "0", ZFlag: "+", SFlag: "+", UndocumentedFlag: true , MnemonicDescription: "The contents of the memory location pointed to by IY plus dare shifted right one bit position. The contents of bit 0 are copied to the carry flag and a zero is put into bit 7. The result is then stored in A.")
        OpCodesList[0xFDCB0040] = OpCodes(OpcodePattern: "FD:CB:d:40", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0041] = OpCodes(OpcodePattern: "FD:CB:d:41", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0042] = OpCodes(OpcodePattern: "FD:CB:d:42", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0043] = OpCodes(OpcodePattern: "FD:CB:d:43", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0044] = OpCodes(OpcodePattern: "FD:CB:d:44", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0045] = OpCodes(OpcodePattern: "FD:CB:d:45", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0046] = OpCodes(OpcodePattern: "FD:CB:d:46", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0047] = OpCodes(OpcodePattern: "FD:CB:d:47", Mnemonic: "BIT 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0048] = OpCodes(OpcodePattern: "FD:CB:d:48", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0049] = OpCodes(OpcodePattern: "FD:CB:d:49", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB004A] = OpCodes(OpcodePattern: "FD:CB:d:4A", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB004B] = OpCodes(OpcodePattern: "FD:CB:d:4B", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB004C] = OpCodes(OpcodePattern: "FD:CB:d:4C", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB004D] = OpCodes(OpcodePattern: "FD:CB:d:4D", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB004E] = OpCodes(OpcodePattern: "FD:CB:d:4E", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB004F] = OpCodes(OpcodePattern: "FD:CB:d:4F", Mnemonic: "BIT 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0050] = OpCodes(OpcodePattern: "FD:CB:d:50", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0051] = OpCodes(OpcodePattern: "FD:CB:d:51", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0052] = OpCodes(OpcodePattern: "FD:CB:d:52", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0053] = OpCodes(OpcodePattern: "FD:CB:d:53", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0054] = OpCodes(OpcodePattern: "FD:CB:d:54", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0055] = OpCodes(OpcodePattern: "FD:CB:d:55", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0056] = OpCodes(OpcodePattern: "FD:CB:d:56", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0057] = OpCodes(OpcodePattern: "FD:CB:d:57", Mnemonic: "BIT 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0058] = OpCodes(OpcodePattern: "FD:CB:d:58", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0059] = OpCodes(OpcodePattern: "FD:CB:d:59", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB005A] = OpCodes(OpcodePattern: "FD:CB:d:5A", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB005B] = OpCodes(OpcodePattern: "FD:CB:d:5B", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB005C] = OpCodes(OpcodePattern: "FD:CB:d:5C", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB005D] = OpCodes(OpcodePattern: "FD:CB:d:5D", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB005E] = OpCodes(OpcodePattern: "FD:CB:d:5E", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB005F] = OpCodes(OpcodePattern: "FD:CB:d:5F", Mnemonic: "BIT 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0060] = OpCodes(OpcodePattern: "FD:CB:d:60", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0061] = OpCodes(OpcodePattern: "FD:CB:d:61", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0062] = OpCodes(OpcodePattern: "FD:CB:d:62", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0063] = OpCodes(OpcodePattern: "FD:CB:d:63", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0064] = OpCodes(OpcodePattern: "FD:CB:d:64", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0065] = OpCodes(OpcodePattern: "FD:CB:d:65", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0066] = OpCodes(OpcodePattern: "FD:CB:d:66", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0067] = OpCodes(OpcodePattern: "FD:CB:d:67", Mnemonic: "BIT 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0068] = OpCodes(OpcodePattern: "FD:CB:d:68", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0069] = OpCodes(OpcodePattern: "FD:CB:d:69", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB006A] = OpCodes(OpcodePattern: "FD:CB:d:6A", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB006B] = OpCodes(OpcodePattern: "FD:CB:d:6B", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB006C] = OpCodes(OpcodePattern: "FD:CB:d:6C", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB006D] = OpCodes(OpcodePattern: "FD:CB:d:6D", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB006E] = OpCodes(OpcodePattern: "FD:CB:d:6E", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB006F] = OpCodes(OpcodePattern: "FD:CB:d:6F", Mnemonic: "BIT 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0070] = OpCodes(OpcodePattern: "FD:CB:d:70", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0071] = OpCodes(OpcodePattern: "FD:CB:d:71", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0072] = OpCodes(OpcodePattern: "FD:CB:d:72", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0073] = OpCodes(OpcodePattern: "FD:CB:d:73", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0074] = OpCodes(OpcodePattern: "FD:CB:d:74", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0075] = OpCodes(OpcodePattern: "FD:CB:d:75", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0076] = OpCodes(OpcodePattern: "FD:CB:d:76", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0077] = OpCodes(OpcodePattern: "FD:CB:d:77", Mnemonic: "BIT 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0078] = OpCodes(OpcodePattern: "FD:CB:d:78", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0079] = OpCodes(OpcodePattern: "FD:CB:d:79", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB007A] = OpCodes(OpcodePattern: "FD:CB:d:7A", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB007B] = OpCodes(OpcodePattern: "FD:CB:d:7B", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB007C] = OpCodes(OpcodePattern: "FD:CB:d:7C", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB007D] = OpCodes(OpcodePattern: "FD:CB:d:7D", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB007E] = OpCodes(OpcodePattern: "FD:CB:d:7E", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: false , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB007F] = OpCodes(OpcodePattern: "FD:CB:d:7F", Mnemonic: "BIT 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [20], CFlag: "-", NFlag: "0", PVFlag: " ", HFlag: "1", ZFlag: "+", SFlag: " ", UndocumentedFlag: true , MnemonicDescription: "Tests bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0080] = OpCodes(OpcodePattern: "FD:CB:d:80", Mnemonic: "RES 0,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB0081] = OpCodes(OpcodePattern: "FD:CB:d:81", Mnemonic: "RES 0,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB0082] = OpCodes(OpcodePattern: "FD:CB:d:82", Mnemonic: "RES 0,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB0083] = OpCodes(OpcodePattern: "FD:CB:d:83", Mnemonic: "RES 0,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB0084] = OpCodes(OpcodePattern: "FD:CB:d:84", Mnemonic: "RES 0,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB0085] = OpCodes(OpcodePattern: "FD:CB:d:85", Mnemonic: "RES 0,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB0086] = OpCodes(OpcodePattern: "FD:CB:d:86", Mnemonic: "RES 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0087] = OpCodes(OpcodePattern: "FD:CB:d:87", Mnemonic: "RES 0,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 0 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB0088] = OpCodes(OpcodePattern: "FD:CB:d:88", Mnemonic: "RES 1,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB0089] = OpCodes(OpcodePattern: "FD:CB:d:89", Mnemonic: "RES 1,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB008A] = OpCodes(OpcodePattern: "FD:CB:d:8A", Mnemonic: "RES 1,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB008B] = OpCodes(OpcodePattern: "FD:CB:d:8B", Mnemonic: "RES 1,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB008C] = OpCodes(OpcodePattern: "FD:CB:d:8C", Mnemonic: "RES 1,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB008D] = OpCodes(OpcodePattern: "FD:CB:d:8D", Mnemonic: "RES 1,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB008E] = OpCodes(OpcodePattern: "FD:CB:d:8E", Mnemonic: "RES 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB008F] = OpCodes(OpcodePattern: "FD:CB:d:8F", Mnemonic: "RES 1,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 1 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB0090] = OpCodes(OpcodePattern: "FD:CB:d:90", Mnemonic: "RES 2,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB0091] = OpCodes(OpcodePattern: "FD:CB:d:91", Mnemonic: "RES 2,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB0092] = OpCodes(OpcodePattern: "FD:CB:d:92", Mnemonic: "RES 2,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB0093] = OpCodes(OpcodePattern: "FD:CB:d:93", Mnemonic: "RES 2,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB0094] = OpCodes(OpcodePattern: "FD:CB:d:94", Mnemonic: "RES 2,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB0095] = OpCodes(OpcodePattern: "FD:CB:d:95", Mnemonic: "RES 2,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB0096] = OpCodes(OpcodePattern: "FD:CB:d:96", Mnemonic: "RES 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB0097] = OpCodes(OpcodePattern: "FD:CB:d:97", Mnemonic: "RES 2,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 2 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB0098] = OpCodes(OpcodePattern: "FD:CB:d:98", Mnemonic: "RES 3,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB0099] = OpCodes(OpcodePattern: "FD:CB:d:99", Mnemonic: "RES 3,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB009A] = OpCodes(OpcodePattern: "FD:CB:d:9A", Mnemonic: "RES 3,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB009B] = OpCodes(OpcodePattern: "FD:CB:d:9B", Mnemonic: "RES 3,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB009C] = OpCodes(OpcodePattern: "FD:CB:d:9C", Mnemonic: "RES 3,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB009D] = OpCodes(OpcodePattern: "FD:CB:d:9D", Mnemonic: "RES 3,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB009E] = OpCodes(OpcodePattern: "FD:CB:d:9E", Mnemonic: "RES 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 3 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB009F] = OpCodes(OpcodePattern: "FD:CB:d:9F", Mnemonic: "RES 3,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00A0] = OpCodes(OpcodePattern: "FD:CB:d:A0", Mnemonic: "RES 4,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00A1] = OpCodes(OpcodePattern: "FD:CB:d:A1", Mnemonic: "RES 4,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00A2] = OpCodes(OpcodePattern: "FD:CB:d:A2", Mnemonic: "RES 4,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00A3] = OpCodes(OpcodePattern: "FD:CB:d:A3", Mnemonic: "RES 4,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00A4] = OpCodes(OpcodePattern: "FD:CB:d:A4", Mnemonic: "RES 4,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00A5] = OpCodes(OpcodePattern: "FD:CB:d:A5", Mnemonic: "RES 4,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00A6] = OpCodes(OpcodePattern: "FD:CB:d:A6", Mnemonic: "RES 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00A7] = OpCodes(OpcodePattern: "FD:CB:d:A7", Mnemonic: "RES 4,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 4 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00A8] = OpCodes(OpcodePattern: "FD:CB:d:A8", Mnemonic: "RES 5,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00A9] = OpCodes(OpcodePattern: "FD:CB:d:A9", Mnemonic: "RES 5,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00AA] = OpCodes(OpcodePattern: "FD:CB:d:AA", Mnemonic: "RES 5,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00AB] = OpCodes(OpcodePattern: "FD:CB:d:AB", Mnemonic: "RES 5,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00AC] = OpCodes(OpcodePattern: "FD:CB:d:AC", Mnemonic: "RES 5,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00AD] = OpCodes(OpcodePattern: "FD:CB:d:AD", Mnemonic: "RES 5,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00AE] = OpCodes(OpcodePattern: "FD:CB:d:AE", Mnemonic: "RES 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00AF] = OpCodes(OpcodePattern: "FD:CB:d:AF", Mnemonic: "RES 5,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 5 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00B0] = OpCodes(OpcodePattern: "FD:CB:d:B0", Mnemonic: "RES 6,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00B1] = OpCodes(OpcodePattern: "FD:CB:d:B1", Mnemonic: "RES 6,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00B2] = OpCodes(OpcodePattern: "FD:CB:d:B2", Mnemonic: "RES 6,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00B3] = OpCodes(OpcodePattern: "FD:CB:d:B3", Mnemonic: "RES 6,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00B4] = OpCodes(OpcodePattern: "FD:CB:d:B4", Mnemonic: "RES 6,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00B5] = OpCodes(OpcodePattern: "FD:CB:d:B5", Mnemonic: "RES 6,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00B6] = OpCodes(OpcodePattern: "FD:CB:d:B6", Mnemonic: "RES 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00B7] = OpCodes(OpcodePattern: "FD:CB:d:B7", Mnemonic: "RES 6,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 6 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00B8] = OpCodes(OpcodePattern: "FD:CB:d:B8", Mnemonic: "RES 7,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00B9] = OpCodes(OpcodePattern: "FD:CB:d:B9", Mnemonic: "RES 7,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00BA] = OpCodes(OpcodePattern: "FD:CB:d:BA", Mnemonic: "RES 7,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00BB] = OpCodes(OpcodePattern: "FD:CB:d:BB", Mnemonic: "RES 7,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00BC] = OpCodes(OpcodePattern: "FD:CB:d:BC", Mnemonic: "RES 7,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00BD] = OpCodes(OpcodePattern: "FD:CB:d:BD", Mnemonic: "RES 7,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00BE] = OpCodes(OpcodePattern: "FD:CB:d:BE", Mnemonic: "RES 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00BF] = OpCodes(OpcodePattern: "FD:CB:d:BF", Mnemonic: "RES 7,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Resets bit 7 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00C0] = OpCodes(OpcodePattern: "FD:CB:d:C0", Mnemonic: "SET 0,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00C1] = OpCodes(OpcodePattern: "FD:CB:d:C1", Mnemonic: "SET 0,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00C2] = OpCodes(OpcodePattern: "FD:CB:d:C2", Mnemonic: "SET 0,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00C3] = OpCodes(OpcodePattern: "FD:CB:d:C3", Mnemonic: "SET 0,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00C4] = OpCodes(OpcodePattern: "FD:CB:d:C4", Mnemonic: "SET 0,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00C5] = OpCodes(OpcodePattern: "FD:CB:d:C5", Mnemonic: "SET 0,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00C6] = OpCodes(OpcodePattern: "FD:CB:d:C6", Mnemonic: "SET 0,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00C7] = OpCodes(OpcodePattern: "FD:CB:d:C7", Mnemonic: "SET 0,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 0 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00C8] = OpCodes(OpcodePattern: "FD:CB:d:C8", Mnemonic: "SET 1,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00C9] = OpCodes(OpcodePattern: "FD:CB:d:C9", Mnemonic: "SET 1,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00CA] = OpCodes(OpcodePattern: "FD:CB:d:CA", Mnemonic: "SET 1,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00CB] = OpCodes(OpcodePattern: "FD:CB:d:CB", Mnemonic: "SET 1,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00CC] = OpCodes(OpcodePattern: "FD:CB:d:CC", Mnemonic: "SET 1,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00CD] = OpCodes(OpcodePattern: "FD:CB:d:CD", Mnemonic: "SET 1,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00CE] = OpCodes(OpcodePattern: "FD:CB:d:CE", Mnemonic: "SET 1,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00CF] = OpCodes(OpcodePattern: "FD:CB:d:CF", Mnemonic: "SET 1,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 1 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00D0] = OpCodes(OpcodePattern: "FD:CB:d:D0", Mnemonic: "SET 2,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00D1] = OpCodes(OpcodePattern: "FD:CB:d:D1", Mnemonic: "SET 2,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00D2] = OpCodes(OpcodePattern: "FD:CB:d:D2", Mnemonic: "SET 2,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00D3] = OpCodes(OpcodePattern: "FD:CB:d:D3", Mnemonic: "SET 2,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00D4] = OpCodes(OpcodePattern: "FD:CB:d:D4", Mnemonic: "SET 2,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00D5] = OpCodes(OpcodePattern: "FD:CB:d:D5", Mnemonic: "SET 2,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00D6] = OpCodes(OpcodePattern: "FD:CB:d:D6", Mnemonic: "SET 2,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00D7] = OpCodes(OpcodePattern: "FD:CB:d:D7", Mnemonic: "SET 2,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 2 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00D8] = OpCodes(OpcodePattern: "FD:CB:d:D8", Mnemonic: "SET 3,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in B")
        OpCodesList[0xFDCB00D9] = OpCodes(OpcodePattern: "FD:CB:d:D9", Mnemonic: "SET 3,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in C")
        OpCodesList[0xFDCB00DA] = OpCodes(OpcodePattern: "FD:CB:d:DA", Mnemonic: "SET 3,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in D")
        OpCodesList[0xFDCB00DB] = OpCodes(OpcodePattern: "FD:CB:d:DB", Mnemonic: "SET 3,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in E")
        OpCodesList[0xFDCB00DC] = OpCodes(OpcodePattern: "FD:CB:d:DC", Mnemonic: "SET 3,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in H")
        OpCodesList[0xFDCB00DD] = OpCodes(OpcodePattern: "FD:CB:d:DD", Mnemonic: "SET 3,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in L")
        OpCodesList[0xFDCB00DE] = OpCodes(OpcodePattern: "FD:CB:d:DE", Mnemonic: "SET 3,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d.")
        OpCodesList[0xFDCB00DF] = OpCodes(OpcodePattern: "FD:CB:d:DF", Mnemonic: "SET 3,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 3 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00E0] = OpCodes(OpcodePattern: "FD:CB:d:E0", Mnemonic: "SET 4,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00E1] = OpCodes(OpcodePattern: "FD:CB:d:E1", Mnemonic: "SET 4,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00E2] = OpCodes(OpcodePattern: "FD:CB:d:E2", Mnemonic: "SET 4,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00E3] = OpCodes(OpcodePattern: "FD:CB:d:E3", Mnemonic: "SET 4,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00E4] = OpCodes(OpcodePattern: "FD:CB:d:E4", Mnemonic: "SET 4,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00E5] = OpCodes(OpcodePattern: "FD:CB:d:E5", Mnemonic: "SET 4,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00E6] = OpCodes(OpcodePattern: "FD:CB:d:E6", Mnemonic: "SET 4,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00E7] = OpCodes(OpcodePattern: "FD:CB:d:E7", Mnemonic: "SET 4,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 4 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00E8] = OpCodes(OpcodePattern: "FD:CB:d:E8", Mnemonic: "SET 5,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in B")
        OpCodesList[0xFDCB00E9] = OpCodes(OpcodePattern: "FD:CB:d:E9", Mnemonic: "SET 5,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in C")
        OpCodesList[0xFDCB00EA] = OpCodes(OpcodePattern: "FD:CB:d:EA", Mnemonic: "SET 5,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in D")
        OpCodesList[0xFDCB00EB] = OpCodes(OpcodePattern: "FD:CB:d:EB", Mnemonic: "SET 5,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in E")
        OpCodesList[0xFDCB00EC] = OpCodes(OpcodePattern: "FD:CB:d:EC", Mnemonic: "SET 5,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in H")
        OpCodesList[0xFDCB00ED] = OpCodes(OpcodePattern: "FD:CB:d:ED", Mnemonic: "SET 5,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in L")
        OpCodesList[0xFDCB00EE] = OpCodes(OpcodePattern: "FD:CB:d:EE", Mnemonic: "SET 5,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d.")
        OpCodesList[0xFDCB00EF] = OpCodes(OpcodePattern: "FD:CB:d:EF", Mnemonic: "SET 5,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 5 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00F0] = OpCodes(OpcodePattern: "FD:CB:d:F0", Mnemonic: "SET 6,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in B")
        OpCodesList[0xFDCB00F1] = OpCodes(OpcodePattern: "FD:CB:d:F1", Mnemonic: "SET 6,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in C")
        OpCodesList[0xFDCB00F2] = OpCodes(OpcodePattern: "FD:CB:d:F2", Mnemonic: "SET 6,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in D")
        OpCodesList[0xFDCB00F3] = OpCodes(OpcodePattern: "FD:CB:d:F3", Mnemonic: "SET 6,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in E")
        OpCodesList[0xFDCB00F4] = OpCodes(OpcodePattern: "FD:CB:d:F4", Mnemonic: "SET 6,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in H")
        OpCodesList[0xFDCB00F5] = OpCodes(OpcodePattern: "FD:CB:d:F5", Mnemonic: "SET 6,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d. The result is then stored in L")
        OpCodesList[0xFDCB00F6] = OpCodes(OpcodePattern: "FD:CB:d:F6", Mnemonic: "SET 6,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus $d.")
        OpCodesList[0xFDCB00F7] = OpCodes(OpcodePattern: "FD:CB:d:F7", Mnemonic: "SET 6,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 6 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDCB00F8] = OpCodes(OpcodePattern: "FD:CB:d:F8", Mnemonic: "SET 7,(IY+D),B", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in B")
        OpCodesList[0xFDCB00F9] = OpCodes(OpcodePattern: "FD:CB:d:F9", Mnemonic: "SET 7,(IY+D),C", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in C.")
        OpCodesList[0xFDCB00FA] = OpCodes(OpcodePattern: "FD:CB:d:FA", Mnemonic: "SET 7,(IY+D),D", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in D")
        OpCodesList[0xFDCB00FB] = OpCodes(OpcodePattern: "FD:CB:d:FB", Mnemonic: "SET 7,(IY+D),E", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in E")
        OpCodesList[0xFDCB00FC] = OpCodes(OpcodePattern: "FD:CB:d:FC", Mnemonic: "SET 7,(IY+D),H", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in H")
        OpCodesList[0xFDCB00FD] = OpCodes(OpcodePattern: "FD:CB:d:FD", Mnemonic: "SET 7,(IY+D),L", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in L")
        OpCodesList[0xFDCB00FE] = OpCodes(OpcodePattern: "FD:CB:d:FE", Mnemonic: "SET 7,(IY+D)", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d.")
        OpCodesList[0xFDCB00FF] = OpCodes(OpcodePattern: "FD:CB:d:FF", Mnemonic: "SET 7,(IY+D),A", OpcodeSize: 4, InstructionSize: 4, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: true , MnemonicDescription: "Sets bit 7 of the memory location pointed to by IY plus d. The result is then stored in A.")
        OpCodesList[0xFDE1] = OpCodes(OpcodePattern: "FD:E1::", Mnemonic: "POP IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [14], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The memory location pointed to by SP is stored into IYL and SP is incremented. The memory location pointed to by SP is stored into IYH and SP is incremented again.")
        OpCodesList[0xFDE3] = OpCodes(OpcodePattern: "FD:E3::", Mnemonic: "EX (SP),IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [23], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Exchanges (SP) with IYL, and (SP+1) with IYH.")
        OpCodesList[0xFDE5] = OpCodes(OpcodePattern: "FD:E5::", Mnemonic: "PUSH IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [15], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "SP is decremented and IYH is stored into the memory location pointed to by SP. SP is decremented again and IYL is stored into the memory location pointed to by SP.")
        OpCodesList[0xFDE9] = OpCodes(OpcodePattern: "FD:E9::", Mnemonic: "JP (IY)", OpcodeSize: 2, InstructionSize: 2, Cycle: [8], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value of IY into PC.")
        OpCodesList[0xFDF9] = OpCodes(OpcodePattern: "FD:F9::", Mnemonic: "LD SP,IY", OpcodeSize: 2, InstructionSize: 2, Cycle: [10], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "Loads the value of IY into SP.")
        OpCodesList[0xFE] = OpCodes(OpcodePattern: "FE:n::", Mnemonic: "CP N", OpcodeSize: 1, InstructionSize: 2, Cycle: [7], CFlag: "+", NFlag: "+", PVFlag: "v", HFlag: "+", ZFlag: "+", SFlag: "+", UndocumentedFlag: false , MnemonicDescription: "Subtracts $n from A and affects flags according to the result. A is not modified.")
        OpCodesList[0xFF] = OpCodes(OpcodePattern: "FF:::", Mnemonic: "RST 38H", OpcodeSize: 1, InstructionSize: 1, Cycle: [11], CFlag: "-", NFlag: "-", PVFlag: "-", HFlag: "-", ZFlag: "-", SFlag: "-", UndocumentedFlag: false , MnemonicDescription: "The current PC value plus one is pushed onto the stack, then is loaded with 38h")
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
            print("DJNZ nn")
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
            print("JR nn")
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
            print("JR NZ,nn")
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
            print("JR Z,nn")
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
            print("JR NC,nn")
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
            print("JR C,nn")
        case 0x39:
            print("ADD HL,SP")
        case 0x3A:
            print("LD A,(nn)")
        case 0x3B:
            print("DEC SP")
        case 0x3C:
            print("INC A")
        case 0x3D:
            print("DEC A")
        case 0x3E:
            print("LD A,nn")
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
            print("JP NZ,nn")
        case 0xC3:
            print("JP nn")
        case 0xC4:
            print("CALL NZ,nn")
        case 0xC5:
            print("PUSH BC")
        case 0xC6:
            print("ADD A,nn")
        case 0xC7:
            print("RST 00")
        case 0xC8:
            print("RET Z")
        case 0xC9:
            print("RET")
        case 0xCA:
            print("JP Z,nn")
        case 0xCB:
            switch SecondByte
            {
            case 0x00 :
                print("RLC B")
            case 0x01 :
                print("RLC C")
            case 0x02 :
                print("RLC D")
            case 0x03 :
                print("RLC E")
            case 0x04 :
                print("RLC H")
            case 0x05 :
                print("RLC L")
            case 0x06 :
                print("RLC (HL)")
            case 0x07 :
                print("RLC A")
            case 0x08 :
                print("RRC B")
            case 0x09 :
                print("RRC C")
            case 0x0A :
                print("RRC D")
            case 0x0B :
                print("RRC E")
            case 0x0E :
                print("RRC (HL)")
            case 0x0F :
                print("RRC A")
            case 0x10 :
                print("RL B")
            case 0x11 :
                print("RL C")
            case 0x12 :
                print("RL D")
            case 0x13 :
                print("RL E")
            case 0x14 :
                print("RL H")
            case 0x15 :
                print("RL L")
            case 0x16 :
                print("RL (HL)")
            case 0x17 :
                print("RL A")
            case 0x18 :
                print("RR B")
            case 0x19 :
                print("RR C")
            case 0x1A :
                print("RR D")
            case 0x1B :
                print("RR E")
            case 0x1C  :
                print("RR H")
            case 0x1D :
                print("RR L")
            case 0x1E :
                print("RR (HL)")
            case 0x1F :
                print("RR A")
            case 0x20 :
                print("SLA B")
            case 0x21 :
                print("SLA C")
            case 0x22 :
                print("SLA D")
            case 0x23 :
                print("SLA E")
            case 0x24 :
                print("SLA H")
            case 0x25 :
                print("SLA L")
            case 0x26  :
                print("SLA (HL)")
            case 0x27 :
                print("SLA A")
            case 0x28 :
                print("SRA B")
            case 0x29 :
                print("SRA C")
            case 0x2A :
                print("SRA D")
            case 0x2B :
                print("SRA E")
            case 0x2C :
                print("SRA H")
            case 0x2D :
                print("SRA L")
            case 0x2E :
                print("SRA (HL)")
            case 0x2F :
                print("SRA A")
            case 0x30 :
                print("SLS B")
            case 0x31 :
                print("SLS C")
            case 0x32 :
                print("SLS D")
            case 0x33 :
                print("SLS E")
            case 0x34 :
                print("SLS H")
            case 0x35 :
                print("SLS L")
            case 0x36 :
                print("SLS (HL)")
            case 0x37 :
                print("SLS A")
            case 0x38 :
                print("SRL B")
            case 0x39 :
                print("SRL C")
            case 0x3A :
                print("SRL D")
            case 0x3B :
                print("SRL E")
            case 0x3C :
                print("SRL H")
            case 0x3D :
                print("SRL L")
            case 0x3E :
                print("SRL (HL)")
            case 0x3F :
                print("SRL A")
            case 0x40 :
                print("BIT 0,B")
            case 0x41 :
                print("BIT 0,C")
            case 0x42 :
                print("BIT 0,D")
            case 0x43 :
                print("BIT 0,E")
            case 0x44 :
                print("BIT 0,H")
            case 0x45 :
                print("BIT 0,L")
            case 0x46 :
                print("BIT 0,(HL)")
            case 0x47 :
                print("BIT 0,A")
            case 0x48 :
                print("BIT 1,B")
            case 0x49 :
                print( "BIT 1,C")
            case 0x4A :
                print("BIT 1,D")
            case 0x4B :
                print("BIT 1,E")
            case 0x4C :
                print("BIT 1,H")
            case 0x4D :
                print("BIT 1,L")
            case 0x4E :
                print("BIT 1,(HL)")
            case 0x4F :
                print("BIT 1,A")
            case 0x50 :
                print("BIT 2,B")
            case 0x51 :
                print("BIT 2,C")
            case 0x52 :
                print("BIT 2,D")
            case 0x53 :
                print("BIT 2,E")
            case 0x54 :
                print("BIT 2,H")
            case 0x55 :
                print("BIT 2,L")
            case 0x56 :
                print("BIT 2,(HL)")
            case 0x57 :
                print("BIT 2,A")
            case 0x58 :
                print("BIT 3,B")
            case 0x59 :
                print("BIT 3,C")
            case 0x5A :
                print("BIT 3,D")
            case 0x5B :
                print("BIT 3,E")
            case 0x5C :
                print("BIT 3,H")
            case 0x5D :
                print("BIT 3,L")
            case 0x5E :
                print("BIT 3,(HL)")
            case 0x5F :
                print("BIT 3,A")
            case 0x60 :
                print("BIT 4,B")
            case 0x61 :
                print("BIT 4,C")
            case 0x62 :
                print("BIT 4,D")
            case 0x63 :
                print("BIT 4,E")
            case 0x64 :
                print("BIT 4,H")
            case 0x65 :
                print("BIT 4,L")
            case 0x66 :
                print("BIT 4,(HL)")
            case 0x67 :
                print("BIT 4,A")
            case 0x68 :
                print("BIT 5,B")
            case 0x69 :
                print("BIT 5,C")
            case 0x6A :
                print("BIT 5,D")
            case 0x6B :
                print("BIT 5,")
            case 0x6C :
                print("BIT 5,H")
            case 0x6D :
                print("BIT 5,L")
            case 0x6E :
                print("BIT 5,(HL)")
            case 0x6F :
                print("BIT 5,A")
            case 0x70 :
                print("BIT 6,B")
            case 0x71 :
                print("BIT 6,C")
            case 0x72 :
                print("BIT 6,D")
            case 0x73 :
                print("BIT 6,E")
            case 0x74 :
                print("BIT 6,H")
            case 0x75 :
                print("BIT 6,L")
            case 0x76 :
                print("BIT 6,(HL)")
            case 0x77 :
                print("BIT 6,A")
            case 0x78 :
                print("BIT 7,B")
            case 0x79 :
                print("BIT 7,C")
            case 0x7A :
                print("BIT 7,D")
            case 0x7B :
                print("BIT 7,E")
            case 0x7C :
                print("BIT 7,H")
            case 0x7D :
                print("BIT 7,L")
            case 0x7E :
                print("BIT 7,(HL)")
            case 0x7F :
                print("BIT 7,A")
            case 0x80 :
                print("RES 0,B")
            case 0x81 :
                print("RES 0,C")
            case 0x82 :
                print("RES 0,D")
            case 0x83 :
                print("RES 0,E")
            case 0x84 :
                print("RES 0,H")
            case 0x85 :
                print("RES 0,L")
            case 0x86 :
                print("RES 0,(HL)")
            case 0x87 :
                print("RES 0,A")
            case 0x88 :
                print("RES 1,B")
            case 0x89 :
                print("RES 1,C")
            case 0x8A :
                print("RES 1,D")
            case 0x8B :
                print("RES 1,E")
            case 0x8C :
                print("RES 1,H")
            case 0x8D :
                print("RES 1,L")
            case 0x8E :
                print("RES 1,(HL)")
            case 0x8F :
                print("RES 1,A")
            case 0x90 :
                print("RES 2,B")
            case 0x91 :
                print("RES 2,C")
            case 0x92 :
                print("RES 2,D")
            case 0x93 :
                print("RES 2,E")
            case 0x94 :
                print("RES 2,H")
            case  0x95 :
                print("RES 2,L")
            case 0x96 :
                print("RES 2,(HL)")
            case 0x97 :
                print("RES 2,A")
            case 0x98 :
                print("RES 3,B")
            case 0x99 :
                print("RES 3,C")
            case 0x9A  :
                print("RES 3,D")
            case 0x9B :
                print("RES 3,E")
            case 0x9C :
                print("RES 3,H")
            case 0x9D :
                print("RES 3,L")
            case 0x9E :
                print("RES 3,(HL)")
            case 0x9F :
                print("RES 3,A")
            case 0xA0 :
                print("RES 4,B")
            case 0xA1 :
                print("RES 4,C")
            case 0xA2 :
                print("RES 4,D")
            case 0xA3 :
                print("RES 4,")
            case 0xA4 :
                print("RES 4,H")
            case 0xA5 :
                print("RES 4,L")
            case 0xA6 :
                print("RES 4,(HL)")
            case 0xA7 :
                print("RES 4,A")
            case 0xA8 :
                print("RES 5,B")
            case 0xA9 :
                print("RES 5,C")
            case 0xAA :
                print("RES 5,D")
            case 0xAB :
                print("RES 5,E")
            case 0xAC  :
                print("RES 5,H")
            case 0xAD :
                print("RES 5,L")
            case 0xAE :
                print("RES 5,(HL)")
            case 0xAF :
                print("RES 5,A")
            case 0xB0 :
                print("RES 6,B")
            case 0xB1 :
                print("RES 6,C")
            case 0xB2 :
                print("RES 6,D")
            case 0xB3 :
                print("RES 6,E")
            case 0xB4 :
                print("RES 6,H")
            case 0xB5 :
                print("RES 6,L")
            case 0xB6 :
                print("RES 6,(HL)")
            case 0xB7 :
                print("RES 6,A")
            case 0xB8 :
                print("RES 7,B")
            case 0xB9 :
                print("RES 7,C")
            case 0xBA :
                print("RES 7,D")
            case 0xBB :
                print("RES 7,E")
            case 0xBC :
                print("RES 7,H")
            case 0xBD :
                print("RES 7,L")
            case
                0xBE :
                print("RES 7,(HL)")
            case 0xBF :
                print("RES 7,A")
            case 0xC0 :
                print("SET 0,B")
            case 0xC1 :
                print("SET 0,C")
            case 0xC2 :
                print("SET 0,D")
            case 0xC3 :
                print("SET 0,E")
            case 0xC4 :
                print("SET 0,H")
            case 0xC5 :
                print("SET 0,L")
            case 0xC6 :
                print("SET 0,(HL)")
            case 0xC7 :
                print("SET 0,A")
            case 0xC8 :
                print("SET 1,B")
            case 0xC9 :
                print("SET 1,C")
            case 0xCA  :
                print("SET 1,D")
            case 0xCB :
                print("SET 1,E")
            case 0xCC :
                print("SET 1,H")
            case 0xCD :
                print("SET 1,L")
            case 0xCE :
                print("SET 1,(HL)")
            case 0xCF :
                print("SET 1,A")
            case 0xD0 :
                print("SET 2,B")
            case 0xD1 :
                print("SET 2,C")
            case 0xD2 :
                print("SET 2,D")
            case 0xD3 :
                print("SET 2,E")
            case 0xD4 :
                print("SET 2,H")
            case 0xD5 :
                print("SET 2,L")
            case 0xD6 :
                print("SET 2,(HL)")
            case 0xD7 :
                print("SET 2,A")
            case 0xD8 :
                print("SET 3,B")
            case 0xD9 :
                print("SET 3,C")
            case 0xDA :
                print("SET 3,D")
            case 0xDB :
                print("SET 3,E")
            case 0xDC :
                print("SET 3,H")
            case 0xDD :
                print("SET 3,L")
            case 0xDE :
                print("SET 3,(HL)")
            case 0xDF :
                print("SET 3,A")
            case 0xE0 :
                print("SET 4,B")
            case 0xE1 :
                print("SET 4,C")
            case 0xE2 :
                print("SET 4,D")
            case 0xE3 :
                print("SET 4,E")
            case 0xE4 :
                print("SET 4,H")
            case 0xE5 :
                print( "SET 4,L")
            case 0xE6 :
                print("SET 4,(HL)")
            case 0xE7 :
                print("SET 4,A")
            case 0xE8 :
                print("SET 5,B")
            case 0xE9 :
                print("SET 5,C")
            case 0xEA :
                print("SET 5,D")
            case 0xEB :
                print("SET 5,E")
            case 0xEC :
                print("SET 5,H")
            case 0xED :
                print("SET 5,L")
            case 0xEE :
                print("SET 5,(HL)")
            case 0xEF :
                print("SET 5,A")
            case 0xF0 :
                print("SET 6,B")
            case 0xF1 :
                print("SET 6,C")
            case 0xF2 :
                print("SET 6,D")
            case 0xF3 :
                print("SET 6,E")
            case 0xF4 :
                print( "SET 6,H")
            case 0xF5 :
                print("SET 6,L")
            case 0xF6 :
                print("SET 6,(HL)")
            case 0xF7 :
                print("SET 6,A")
            case 0xF8 :
                print("SET 7,B")
            case 0xF9 :
                print("SET 7,C")
            case 0xFA :
                print("SET 7,D")
            case 0xFB :
                print("SET 7,E")
            case 0xFC :
                print("SET 7,H")
            case 0xFD :
                print("SET 7,L")
            case 0xFE :
                print("SET 7,(HL)")
            case 0xFF :
                print("SET 7,A")
            default :
                print("Unimplemented opcode",FirstByte,SecondByte)
            }
        case 0xCC:
            print("CALL Z,nn")
        case 0xCD:
            print("CALL nn")
        case 0xCE:
            print("ADC A,nn")
        case 0xCF:
            print("RST 08")
        case 0xD0:
            print("RET NC")
        case 0xD1:
            print("POP DE")
        case 0xD2:
            print("JP NC,nn")
        case 0xD3:
            print("OUT (nn),A")
        case 0xD4:
            print("CALL NC,nn")
        case 0xD5:
            print("PUSH DE")
        case 0xD6:
            print("SUB A,nn")
        case 0xD7:
            print("RST 10")
        case 0xD8:
            print("RET C")
        case 0xD9:
            print("EXX")
        case 0xDA:
            print("JP C,nn")
        case 0xDB:
            print("IN A,(nn)")
        case 0xDC:
            print("CALL C,nn")
        case 0xDD:
            switch SecondByte
            {
            case 0x09:
                print("ADD IX,BC")
            case 0x19 :
                print("ADD IX,DE")
            case 0x21 :
                print("LD IX,nn")
            case 0x22  :
                print("LD (nn),IX")
            case 0x23 :
                print("INC IX")
            case 0x24 :
                print("INC IXH")
            case 0x25 :
                print("DEC IXH")
            case 0x26 :
                print("LD IXH,nn")
            case 0x29 :
                print("ADD IX,IX")
            case 0x2A :
                print("LD IX,(nn)")
            case 0x2B :
                print("INC IXL")
            case 0x2D :
                print("DEC IXL")
            case 0x2E :
                print("LD IXL,nn")
            case 0x34 :
                print("INC (IX+nn)")
            case 0x35 :
                print("DEC (IX+nn)")
            case 0x39 :
                print("ADD IX,SP")
            case 0x44 :
                print("LD B,IXH")
            case 0x45 :
                print("LD B,IXL")
            case 0x46 :
                print("LD B,(IX+nn)")
            case 0x4C : print("LD C,IXH")
            case 0x4D :
                print("LD C,IXL")
            case 0x4E :
                print("LD C,(IX+nn)")
            case 0x54 :
                print("LD D,IXL")
            case 0x5E :
                print("LD E,(IX+nn)")
            case 0x60 :
                print("LD IXH,B")
            case 0x61 :
                print("LD IXH,C")
            case 0x62 :
                print("LD IXH,D")
            case 0x63 :
                print("LD IXH,E")
            case 0x64 :
                print("LD IXH,IXH")
            case 0x65 :
                print("LD IXH,IXL")
            case 0x66 :
                print("LD H,(IX+nn)")
            case 0x67 :
                print("LD IXH,A")
            case 0x68 :
                print("LD IXL,B")
            case 0x69 :
                print("LD IXL,C")
            case 0x6A :
                print("LD IXL,D")
            case 0x6B :
                print("LD IXL,E")
            case 0x6C :
                print("LD IXL,IXH")
            case 0x6D :
                print("LD IXL,IXL")
            case 0x6E :
                print("LD L,(IX+nn)")
            case 0x6F :
                print("LD IXL,A")
            case 0x70 :
                print("LD (IX+nn),B")
            case 0x71 :
                print("LD (IX+nn),C")
            case 0x72 :
                print("LD (IX+nn),D")
            case 0x73 :
                print("LD (IX+nn),E")
            case 0x74 :
                print("LD (IX+nn),H")
            case 0x75 :
                print("LD (IX+nn),L")
            case 0x77 :
                print("LD (IX+nn),A")
            case 0x7C :
                print("LD A,IXH")
            case 0x7D :
                print("LD A,IXL")
            case 0x7E :
                print("LD A,(IX+nn)")
            case 0x84 :
                print("ADD A,IXH")
            case 0x85 :
                print("ADD A,IXL")
            case 0x86 :
                print("ADD A,(IX+nn)")
            case 0x8C :
                print("ADC A,IXH")
            case 0x8D :
                print("ADC A,IXL")
            case 0x8E :
                print("ADC A,(IX+nn)")
            case 0x94 :
                print("SUB A,IXH")
            case 0x95 :
                print("SUB A,IXL")
            case 0x96 :
                print("SUB A,(IX+nn)")
            case 0x9C :
                print("SBC A,IXH")
            case 0x9D :
                print("SBC A,IXL")
            case 0x9E :
                print("SBC A,(IX+nn)")
            case 0xA4 :
                print("AND IXH")
            case 0xA5 :
                print("AND IXL")
            case 0xA6 :
                print("AND (IX+nn)")
            case 0xAC :
                print("XOR IXH")
            case 0xAD :
                print("XOR IXL")
            case 0xAE :
                print("XOR (IX+nn)")
            case 0xB4 :
                print("OR IXH")
            case 0xB5 :
                print("OR IXL")
            case 0xB6 :
                print("OR (IX+nn)")
            case 0xBC :
                print("CP IXH")
            case 0xBD :
                print("CP IXL")
            case 0xBE :
                print("CP (IX+nn)")
            case 0xE1 :
                print("POP IX")
            case 0xE :
                print("EX (SP),IX")
            case 0xE5 :
                print("PUSH IX")
            case 0xE9 :
                print("JP (IX)")
            default :
                print("Unimplemented opcode",FirstByte,SecondByte)
            }
        case 0xDE:
            print("SBC A,nn")
        case 0xDF:
            print("RST 18")
        case 0xE0:
            print("RET PO")
        case 0xE1:
            print("POP HL")
        case 0xE2:
            print("JP PO,nn")
        case 0xE3:
            print("EX (SP),HL")
        case 0xE4:
            print("CALL PO,nn")
        case 0xE5:
            print("PUSH HL")
        case 0xE6:
            print("AND nn")
        case 0xE7:
            print("RST 20")
        case 0xE8:
            print("RET PE")
        case 0xE9:
            print("JP (HL)")
        case 0xEA:
            print("JP PE,nn")
        case 0xEB:
            print("EX DE,HL")
        case 0xEC:
            print("CALL P,nn")
        case 0xED:
            switch SecondByte
            {
            case 0x40 :
                print("IN B,(C)")
            case 0x41 :
                print("OUT (C),B")
            case 0x42 :
                print("SBC HL,BC")
            case 0x43 :
                print("LD (nn),BC")
            case 0x44 :
                print("NEG")
            case 0x45 :
                print("RETN")
            case 0x46 :
                print("IM 0")
            case 0x47 :
                print("LD I,A")
            case 0x48 :
                print("IN C,(C)")
            case 0x49 :
                print("OUT (C),C")
            case 0x4A :
                print("ADC HL,BC")
            case 0x4B :
                print("LD BC,(nn)")
            case 0x4D :
                print("RETI")
            case 0x4F :
                print("LD R,A")
            case 0x50 :
                print("IN D,(C)")
            case 0x51 :
                print("OUT (C),D")
            case 0x52 :
                print("SBC HL,DE")
            case 0x53 :
                print("LD (nn),DE")
            case 0x56 :
                print("IM 1")
            case 0x57 :
                print("LD A,I")
            case 0x58 :
                print("IN E,(C)")
            case 0x59 :
                print("OUT (C),E")
            case 0x5A :
                print("ADC HL,DE")
            case 0x5B :
                print("LD DE,(nn)")
            case 0x5E :
                print("IM 2")
            case 0x5F :
                print("LD A,R")
            case 0x60 :
                print("IN H,(C)")
            case 0x61 :
                print("OUT (C),H")
            case 0x62 :
                print("SBC HL,HL")
            case 0x63 :
                print("LD (nn),HL")
            case 0x67 :
                print("RRD")
            case 0x68 :
                print("IN L,(C)")
            case 0x69 :
                print("OUT (C),L")
            case 0x6A :
                print("ADC HL,HL")
            case 0x6B :
                print("LD HL,(nn)")
            case 0x6F :
                print("RLD")
            case 0x70 :
                print("IN F,(C)")
            case 0x71 :
                print("OUT (C),F")
            case 0x72 :
                print("SBC HL,SP")
            case 0x73 :
                print("LD (nn),SP")
            case 0x78 :
                print("IN A,(C)")
            case 0x79 :
                print("OUT (C),A")
            case 0x7A :
                print("ADC HL,SP")
            case 0x7B :
                print("LD SP,(nn)")
            case 0xA0 :
                print("LDI")
            case 0xA1 :
                print("CPI")
            case 0xA2 :
                print("INI")
            case 0xA3 :
                print("OTI")
            case 0xA8 :
                print("LDD")
            case 0xA9 :
                print("CPD")
            case 0xAA :
                print("IND")
            case 0xAB :
                print("OTD")
            case 0xB0 :
                print("LDIR")
            case 0xB1 :
                print("CPIR")
            case 0xB2 :
                print("INIR")
            case 0xB3 :
                print("OTIR")
            case 0xB8 :
                print("LDDR")
            case 0xB9 :
                print("CPDR")
            case 0xBA :
                print("INDR")
            case 0xBB :
                print("OTDR")
            default :
                print("Unimplemented opcode",FirstByte,SecondByte)
            }
        case 0xEE:
            print("XOR nn")
        case 0xEF:
            print("RST 28")
        case 0xF0:
            print("RET P")
        case 0xF1:
            print("POP AF")
        case 0xF2:
            print("JP P,nn")
        case 0xF3:
            print("DI")
        case 0xF4:
            print("CALL P,nn")
        case 0xF5:
            print("PUSH AF")
        case 0xF6:
            print("OR nn")
        case 0xF7:
            print("RST 30")
        case 0xF8:
            print("RET M")
        case 0xF9:
            print("LD SP,HL")
        case 0xFA:
            print("JP M,nn")
        case 0xFB:
            print("EI")
        case 0xFC:
            print("CALL M,nn")
        case 0xFD:
            switch SecondByte
            {
            case 0x09 :
                print("ADD IY,BC")
            case 0x19 :
                print("ADD IY,DE")
            case 0x21 :
                print("LD IY,nn")
            case 0x22 :
                print("LD (nn),IY")
            case 0x23 :
                print("INC IY")
            case 0x24 :
                print("INC IYH")
            case 0x25 :
                print("DEC IYH")
            case 0x26 :
                print("LD IYH,nn")
            case 0x29 :
                print("ADD IY,IY")
            case 0x2A :
                print("LD IY,(nn)")
            case 0x2B :
                print("DEC IY")
            case 0x2C :
                print("INC IYL")
            case 0x2D :
                print("DEC IYL")
            case 0x2E :
                print("LD IYL,nn")
            case 0x34 :
                print("INC (IY+nn)")
            case 0x35 :
                print("DEC (IY+nn)")
            case 0x39 :
                print("ADD IY,SP")
            case 0x44 :
                print("LD B,IYH")
            case 0x45 :
                print("LD B,IYL")
            case 0x46 :
                print("LD B,(IY+nn)")
            case 0x4C :
                print("LD C,IYH")
            case 0x4D :
                print("LD C,IYL")
            case 0x4E :
                print("LD C,(IY+nn)")
            case 0x54 :
                print("LD D,IYH")
            case 0x55 :
                print("LD D,IYL")
            case 0x5E :
                print("LD E,(IY+nn)")
            case 0x60 :
                print("LD IYH,B")
            case 0x61 :
                print("LD IYH,C")
            case 0x62 :
                print("LD IYH,D")
            case 0x63 :
                print("LD IYH,E")
            case 0x64 :
                print("LD IYH,IYH")
            case 0x65 :
                print("LD IYH,IYL")
            case 0x66 :
                print("LD H,(IY+nn)")
            case 0x67 :
                print("LD IYH,A")
            case 0x68 :
                print("LD IYL,B")
            case 0x69 :
                print("LD IYL,C")
            case 0x6A :
                print("LD IYL,D")
            case 0x6B :
                print("LD IYL,E")
            case 0x6C :
                print("LD IYL,IYH")
            case 0x6D :
                print("LD IYL,IYL")
            case 0x6E :
                print("LD L,(IY+nn)")
            case 0x6F :
                print("LD IYL,A")
            case 0x70 :
                print("LD (IY+nn),B")
            case 0x71 :
                print("LD (IY+nn),C")
            case 0x72 :
                print("LD (IY+nn),D")
            case 0x73 :
                print("LD (IY+nn),E")
            case 0x74 :
                print("LD (IY+nn),H")
            case 0x75 :
                print("LD (IY+nn),L")
            case 0x77 :
                print("LD (IY+nn),A")
            case 0x7C :
                print("LD A,IYH")
            case 0x7D :
                print("LD A,IYL")
            case 0x7E :
                print("LD A,(IY+nn)")
            case 0x84 :
                print("ADD A,IYH")
            case 0x85 :
                print("ADD A,IYL")
            case 0x86 :
                print("ADD A,(IY+nn)")
            case 0x8C :
                print("ADC A,IYH")
            case 0x8D :
                print("ADC A,IYL")
            case 0x8E :
                print("ADC A,(IY+nn)")
            case 0x94 :
                print("SUB A,IYH")
            case 0x95 :
                print("SUB A,IYL")
            case 0x96 :
                print("SUB A,(IY+nn)")
            case 0x9C :
                print("SBC A,IYH")
            case 0x9D :
                print("SBC A,IYL")
            case 0x9E :
                print("SBC A,(IY+nn)")
            case 0xA4 :
                print("AND IYH")
            case 0xA5 :
                print("AND IYL")
            case 0xA6 :
                print("AND (IY+nn)")
            case 0xAC :
                print("XOR IYH")
            case 0xAD :
                print("XOR IYL")
            case 0xAE :
                print("XOR (IY+nn)")
            case 0xB4 :
                print("OR IYH")
            case 0xB5 :
                print("OR IYL")
            case 0xB6 :
                print("OR (IY+nn)")
            case 0xBC :
                print("CP IYH")
            case 0xBD :
                print("CP IYL")
            case 0xBE :
                print("CP (IY+nn)")
            case 0xE1 :
                print("POP IY")
            case 0xE3 :
                print("EX (SP),IY")
            case 0xE5 :
                print("PUSH IY")
            case 0xE9 :
                print("JP (IY)")
            default :
                print("Unimplemented opcode",FirstByte,SecondByte)
            }
        case 0xFE:
            print("CP nn")
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
    
    func UnWrapOpCode ( ThisOpCodeIndex : Int ) -> OpCodes
    
    {
        let MyOpCode = OpCodesList[ThisOpCodeIndex]
        
        if let MyOpCode
        {
            return MyOpCode
        }
        else
        {
            return DefaultOpCode
        }
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
        var MyDictionaryIndex : Int
        
        var MyOpCode : OpCodes // = (PrimaryOpCode: 0x00,SecondaryOpCode: 0x00 , Assembler: "NOP", MCycle: 1, TState : [4], InstructionLength : 1)
        
        if InstructionNumber == 1
            
        {
            BaseMemPointer = MemPointer
        }
        
        for MyIndex in 1..<InstructionNumber
        {
            TargetInstructionLength = TargetInstructionLength+UnWrapOpCode(ThisOpCodeIndex : Int(MyMMU.ReadAddress( MemPointer : BaseMemPointer + UInt16(TargetInstructionLength),ThisMemory : ThisMemory))).InstructionSize
        }
        
        TargetAddress = BaseMemPointer+UInt16(TargetInstructionLength)
        
        FirstByte = MyMMU.ReadAddress( MemPointer : TargetAddress,ThisMemory : ThisMemory)
        SecondByte = MyMMU.ReadAddress( MemPointer : TargetAddress+1,ThisMemory : ThisMemory)
        ThirdByte = MyMMU.ReadAddress( MemPointer : TargetAddress+2,ThisMemory : ThisMemory)
        FourthByte = MyMMU.ReadAddress( MemPointer : TargetAddress+3,ThisMemory : ThisMemory)
        
        switch Int(FirstByte)
        {
        case 0xFD, 0xED, 0xDD, 0xCB :
            MyDictionaryIndex = Int(FirstByte)*0x100+Int(SecondByte)
        default:
            MyDictionaryIndex = Int(FirstByte)
        }
        
        MyOpCode = UnWrapOpCode(ThisOpCodeIndex : MyDictionaryIndex)
        
        switch MyOpCode.InstructionSize
        {
        case 1 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + "          " + MyOpCode.Mnemonic
        case 2 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + " " + String(format: "%02X",SecondByte) + "       " + MyOpCode.Mnemonic.replacingOccurrences(of: "n", with: String(format:"%02X",SecondByte))
        case 3 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + " " + String(format: "%02X",SecondByte) + " " + String(format: "%02X",ThirdByte) + "    " + MyOpCode.Mnemonic.replacingOccurrences(of: "nn", with: String(format:"%04X",Int(ThirdByte)*0x100+Int(SecondByte)))
        case 4 : FormattedString = String(format: "%04X",TargetAddress)+": " + String(format: "%02X",FirstByte) + " " + String(format: "%02X",SecondByte) + " " + String(format: "%02X",ThirdByte) + "    " + String(format: "%02X",FourthByte) + "    " + MyOpCode.Mnemonic.replacingOccurrences(of: "nn", with: String(format:"%04X",Int(ThirdByte)*0x100+Int(SecondByte)))
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
