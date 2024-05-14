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
        
        var A : UInt8 // Accumulator
        var F : UInt8 // Flags
        var B : UInt8 // Accumulator
        var C : UInt8 // Flags
        var H : UInt8 // Accumulator
        var L : UInt8  // Flags
        var AltA : UInt8 // Accumulator
        var AltF : UInt8  // Flags
        var AltB : UInt8 // Accumulator
        var AltC : UInt8 // Flags
        var AltH : UInt8 // Accumulator
        var AltL : UInt8 // Flags
        var I : UInt8 // Interrupt Vector
        var R : UInt8 // Memory Refresh
        var IX : UInt16 // Index Register
        var IY : UInt16 // Index Register
        var SP : UInt16 // Stack Pointer
        var PC : UInt16 // Program Counter
    }
    
    @Published var CPURegisters = registers( A: 0, F :0,B : 0,C : 0,H : 0,L : 0,AltA : 0,AltF : 0,AltB : 0,AltC : 0,AltH : 0,AltL : 0,I : 0,R : 0,IX : 0,IY : 0,SP : 0,PC : 0 )
    
    var CPURunning : Bool = false
    
    func StepInstruction()
    {
        self.CPURegisters.PC = self.CPURegisters.PC+1
        if self.CPURegisters.PC == 0xFFFF
        {
            self.CPURegisters.PC = 0
        }
    }
}
