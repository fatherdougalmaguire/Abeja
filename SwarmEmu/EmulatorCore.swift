//
//  EmulatorCore.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024.
//

import Foundation
import SwiftUI

class EmulatorCore : ObservableObject {
    
    @Published var AddressSpace = Array<UInt8>(repeating: 0,count:65536)
    
    var LoadCounter : Int = 32768;
        
    // The Microbee's 16K of BASIC ROM starts at address 0x8000. Additional ROMs for EDASM, or WordBee were often also installed and these occupied the space from 0xC000 up to 0xF000.
    init()
    
    {
        if let urlPath = Bundle.main.url(forResource: "basic_5.22e", withExtension: "rom") {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    AddressSpace[LoadCounter] = MyIndex
                    LoadCounter = LoadCounter + 1
                }
            } catch {
                print("Problem with basic rom")
            }
        } else {
            print("Can't find basic rom")
        }
    }
}
