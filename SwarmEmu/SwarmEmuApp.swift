//
//  SwarmEmuApp.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 20/3/2024.
//

import SwiftUI

@main
struct SwarmEmuApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands
        {
            AboutPanelCommand(
                            title: "About SwarmEmu",
                            applicationName: "SwarmEmu",
                            credits: "\nSwarmEmu is a Microbee emulator written in Swift/SwiftUI\n\nIt is a port of Nanowasp ( www.nanowasp.org )\na Javascript emulation of a tape based Microbee written by David G. Churchill\nCopyright (c) 2007, 2011\n\nand hello to Jason Isaacs"
                        )
            CommandMenu("Tape") {
                Button("Nothing to see here folks") {
                }.keyboardShortcut("D")
            }
            CommandMenu("Emulator") {
                Button("Nothing to see here folks") {
                }.keyboardShortcut("I")
            }
            CommandMenu("Super Secret Menu") {
                Button("Nothing to see here folks") {
                }.keyboardShortcut("W")
            }
            CommandGroup(replacing: .help) {
                Link("Microbee Technologies Forum", destination: URL(string: "https://microbeetechnology.com.au/forum/")!)
                Divider()
            }
            CommandGroup(after: .help) {
                Link("Hello to Jason Isaacs", destination: URL(string: "https://www.kermodeandmayo.com")!)
            }
        }
    }
}
