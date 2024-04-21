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
        .windowResizability(.contentSize)
        .commands
        {
            AboutPanelCommand(
                            title: "About SwarmEmu",
                            applicationName: "SwarmEmu",
                            credits: "\nSwarmEmu is a SwiftUI/Swift emulator compatible with tape based models of the Microbee computer\n\nBased on Nanowasp ( http://www.nanowasp.org ) \nCopyright (c) 2007, 2011 David G. Churchill\n\nThe MicroWorld Basic V5.22e ROM and the MicroBee Font ROM are used in this emulator with kind permission from Ewan J. Wordsworth of Microbee Technology\n\nHello to Jason Isaacs"
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
                Divider()
                Link("Microbee Technologies Forum", destination: URL(string: "https://microbeetechnology.com.au/forum/")!)
                Link("Hello to Jason Isaacs", destination: URL(string: "https://www.kermodeandmayo.com")!)
            }
        }
    }
}

struct ExampleView: View {
     var body: some View {
        Text("some text")
    }
}
