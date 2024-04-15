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
    
    //@Published var screenbitmap = Array<Bool>(repeating: false,count:131072)
    
    init()
    
    {
        
    }
}
