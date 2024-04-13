//
//  ContentView.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

import SwiftUI

struct ContentView: View {
    
    @StateObject var ThisCRTC = CRTC()
    @State private var textInput : String = ""
    
    let zoom : Int = 2
    
    var body: some View {
        Canvas { context, size in
            for myrow in 0...255 {
                for mycol in 0...511 {
                    if ThisCRTC.screenbitmap[myrow*512+mycol]
                    {
                        context.fill(Path(CGRect(x:mycol*zoom,y:myrow*zoom, width: 1*zoom, height: 1*zoom)), with: .color(Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0)))
                    }
                    else
                    {
                        context.fill(Path(CGRect(x:mycol*zoom,y:myrow*zoom, width: 1*zoom, height: 1*zoom)), with: .color(Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1.0)))
                    }
                }
            }
        }
        .frame(width: 1024, height: 512)
        VStack
        {
            Button("Print MicroWorld Basic startup message")
            {
                ThisCRTC.ClearScreen()
                ThisCRTC.printstring("Applied Technology MicroBee Colour Basic. Ver 5.22e",0,0)
                ThisCRTC.printstring("Copyright MS 1983 for MicroWorld Australia",0,2)
                ThisCRTC.printstring(">",0,4)
            }
            TextField("Enter text here and press Enter", text: $textInput,
                      onCommit:
                        {
                            ThisCRTC.ClearScreen()
                            ThisCRTC.printstring(textInput,0,0)
                            
                        }
            )
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
