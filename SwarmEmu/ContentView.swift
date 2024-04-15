//
//  ContentView.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

import SwiftUI

struct ContentView: View {
    
    @StateObject var ThisCRTC = CRTC()
    @StateObject var ThisEmulatorCore = EmulatorCore()
    
    @State private var textInput : String = ""
    @State private var doublesize : Bool = false
    @State private var eightycolumn : Bool = false
    
    var body: some View {
        Canvas { context, size in
            for myrow in 0...255 {
                for mycol in 0...511 {
                    if ThisCRTC.screenbitmap[myrow*512+mycol]
                    {
                        context.fill(Path(CGRect(x:mycol*ThisCRTC.xzoom,y:myrow*ThisCRTC.yzoom, width: 1*ThisCRTC.xzoom, height: 1*ThisCRTC.yzoom)), with: .color(Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0)))
                    }
                    else
                    {
                        context.fill(Path(CGRect(x:mycol*ThisCRTC.xzoom,y:myrow*ThisCRTC.yzoom, width: 1*ThisCRTC.xzoom, height: 1*ThisCRTC.yzoom)), with: .color(Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1.0)))
                    }
                }
            }
        }
        .frame(width: 512*CGFloat(ThisCRTC.xzoom), height: 256*CGFloat(ThisCRTC.yzoom))
        VStack
        {
            Button("Print MicroWorld Basic startup message")
            {
                ThisCRTC.ClearScreen()
                ThisCRTC.printstring("Applied Technology MicroBee Colour Basic. Ver 5.22e",0,0)
                ThisCRTC.printstring("Copyright MS 1983 for MicroWorld Australia",0,2)
                ThisCRTC.printstring(">_",0,4)
            }
            Toggle("Zoom screen", isOn: $doublesize)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .onChange(of: doublesize)
                {
                    if doublesize
                    {
                        ThisCRTC.xzoom = 2
                        ThisCRTC.yzoom = 4
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                    }
                    else
                    {
                        ThisCRTC.xzoom = 1
                        ThisCRTC.yzoom = 2
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                    }
                }
            Toggle("80 column display", isOn: $eightycolumn)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .onChange(of: eightycolumn)
                {
                    if eightycolumn
                    {
                        ThisCRTC.xpixels = 8
                        ThisCRTC.ypixels = 11
                        ThisCRTC.charoffset = 2048
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                    }
                    else
                    {
                        ThisCRTC.xpixels = 8
                        ThisCRTC.ypixels = 16
                        ThisCRTC.charoffset = 0
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                        ThisCRTC.screenbitmap[0] = !ThisCRTC.screenbitmap[0]
                    }
                }
            TextField("Enter text to be displayed here and then press Enter", text: $textInput,
                      onCommit:
                        {
                            ThisCRTC.ClearScreen()
                            ThisCRTC.printstring(textInput,0,0)
                            
                        }
                      )
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
