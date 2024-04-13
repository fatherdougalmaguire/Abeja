//
//  SwarmEmuApp.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

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
                            credits: "\nSwarmEmu is a SwiftUI/Swift emulator compatible with tape based models of the Microbee computer\n\nBased on Nanowasp ( http://www.nanowasp.org ) \nCopyright (c) 2007, 2011 David G. Churchill\n\nHello to Jason Isaacs"
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
