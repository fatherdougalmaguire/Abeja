//
//  EmulatorCore.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024.
//

import Foundation
import SwiftUI

class MMU : ObservableObject {
    
    enum MemoryBlocks  {
        case Bank1Ram
        case Bank2Ram
        case BasicRom
        case Pak0Rom
        case NetRom
        case ScreenRam
        case CharRom
        case PCGRam
    }
    
    var Label : MemoryBlocks
    var Active : Bool
    var ShaderRam : Bool
    var IsRom : Bool
    var MemoryStart : Int
    var MemoryEnd : Int
    var AddressSpace : Array<UInt8>
    var FloatAddressSpace : Array<Float>
    
    init ( Label : MemoryBlocks, Active : Bool,  ShaderRam : Bool, IsRom : Bool,  MemoryStart : Int,  MemoryEnd : Int )
    
    {
        self.Label = Label
        self.Active = Active
        self.ShaderRam = ShaderRam
        self.IsRom = IsRom
        self.MemoryStart = MemoryStart
        self.MemoryEnd = MemoryEnd
        self.AddressSpace = Array<UInt8>(repeating: 0,count:MemoryEnd-MemoryStart+1)
        self.FloatAddressSpace = Array<Float>(repeating: 0,count:MemoryEnd-MemoryStart+1)
    }
    
    func LoadROM ( FileName : String,  FileExtension : String)
    
    {
        var LoadCounter : Int = 0
        
        if let urlPath = Bundle.main.url(forResource: FileName, withExtension: FileExtension )
        {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    AddressSpace[LoadCounter] = MyIndex
                    FloatAddressSpace[LoadCounter] = Float(MyIndex)
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
    
    func ReadAddress (  MemPointer : Int ) -> UInt8
    {
        return AddressSpace[MemPointer]
    }
    
    func WriteAddress (  MemPointer : Int, DataValue : UInt8 )
    {
        AddressSpace[MemPointer] = DataValue
        FloatAddressSpace[MemPointer] = Float(DataValue)
    }
    
}


