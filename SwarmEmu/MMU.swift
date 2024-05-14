//
//  EmulatorCore.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024.
//

import Foundation
import SwiftUI

class MMU : ObservableObject {
    
    struct MMUblock
    {
        var memoryactive : Bool
        var memorystart : Int
        var memoryend : Int
        var AddressSpace : Array<UInt8>
        var FloatAddressSpace : Array<Float>
        
        init( _ memoryactive: Bool, _ memorystart: Int, _ memoryend: Int, _ AddressSpace: Array<UInt8>, _ FloatAddressSpace: Array<Float>) {
            self.memoryactive = memoryactive
            self.memorystart = memorystart
            self.memoryend = memoryend
            self.AddressSpace = AddressSpace
            self.FloatAddressSpace = FloatAddressSpace
        }
    }
    
    @Published var memory = MMUblock(true,0,0,[0],[0])
    
    init (_ tmemoryactive : Bool = true, _ tmemorystart : Int, _ tmemoryend : Int, _ filename : String, _ fileext : String)
    
    {
        var LoadCounter : Int = 0
        
        self.memory.memoryactive = tmemoryactive
        self.memory.memorystart = tmemorystart
        self.memory.memoryend = tmemoryend
        self.memory.AddressSpace = Array<UInt8>(repeating: 0,count:tmemoryend-tmemorystart+1)
        if let urlPath = Bundle.main.url(forResource: filename, withExtension: fileext )
        {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    self.memory.AddressSpace[LoadCounter] = MyIndex
                    LoadCounter = LoadCounter + 1
                }
            }
            catch
            {
                print("Problem with basic rom")
            }
        }
        else
        {
            print("Can't find basic rom")
        }
    }
    
}


