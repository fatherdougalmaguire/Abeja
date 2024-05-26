//
//  EmulatorCore.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024.
//

import Foundation
import SwiftUI

class MMU : ObservableObject {
    
    enum MemoryBlocks  
    {
        case Bank1Ram
        case Bank2Ram
        case BasicRom
        case Pak0Rom
        case NetRom
        case ScreenRam
        case CharRom
        case PCGRam
    }
    
    struct MemoryBlock 
    {
        var MemoryStart : Int
        var MemoryEnd : Int
        var AddressSpace : Array<UInt8>
        
        init ( MemoryStart : Int,  MemoryEnd : Int )
        {
            self.MemoryStart = MemoryStart
            self.MemoryEnd = MemoryEnd
            self.AddressSpace = Array<UInt8>(repeating: 0,count:MemoryEnd-MemoryStart+1)
        }
    }

    func LoadROM ( FileName : String,  FileExtension : String, MemPointer : UInt16, ThisMemory : inout MemoryBlock)
    
    {
        var LoadCounter : Int = Int(MemPointer)
        
        if let urlPath = Bundle.main.url(forResource: FileName, withExtension: FileExtension )
        {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    ThisMemory.AddressSpace[LoadCounter] = UInt8(MyIndex)
                    LoadCounter = LoadCounter + 1
                }
            }
            catch
            {
                print("Problem loading Rom file")
            }
        }
        else
        {
            print("Can't find Rom file")
        }
    }
    
    func ReadAddress (  MemPointer : UInt16, ThisMemory : MemoryBlock ) -> UInt8
    {
        return ThisMemory.AddressSpace[Int(MemPointer)]
    }
    
    func WriteAddress (  MemPointer : UInt16, DataValue : UInt8, ThisMemory : inout MemoryBlock )
    {
        if MemPointer >= 0xF000
        {
            
        }
        ThisMemory.AddressSpace[Int(MemPointer)] = DataValue
    }
    
}


