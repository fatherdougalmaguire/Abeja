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
            for myrow in 0...ThisCRTC.canvasy-1 {
                for mycol in 0...ThisCRTC.canvasx-1 {
                    if ThisCRTC.screenbitmap[myrow*ThisCRTC.maxcanvasx+mycol]
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
        .frame(width: CGFloat(ThisCRTC.canvasx)*CGFloat(ThisCRTC.xzoom), height: CGFloat(ThisCRTC.canvasy)*CGFloat(ThisCRTC.yzoom))
        VStack
        {
            Button("Print MicroWorld Basic startup message")
            {
                if eightycolumn
                {
                    ThisCRTC.ClearScreen()
                    ThisCRTC.printstring("Microbee  56k  CP/M",0,1)
                    ThisCRTC.printstring("Vers 2.20 [ZCPR II]",0,2)
                    ThisCRTC.printstring("A>",0,4)
                    ThisCRTC.updatebuffer()
                }
                else
                {
                    ThisCRTC.ClearScreen()
                    ThisCRTC.printstring("Applied Technology MicroBee Colour Basic. Ver 5.22e",0,0)
                    ThisCRTC.printstring("Copyright MS 1983 for MicroWorld Australia",0,2)
                    ThisCRTC.printstring(">_",0,4)
                    ThisCRTC.updatebuffer()
                }
            }
            Toggle("Zoom screen", isOn: $doublesize)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .onChange(of: doublesize)
                {
                    if doublesize
                    {
                        ThisCRTC.xzoom = 2
                        ThisCRTC.yzoom = 4
                        ThisCRTC.updatebuffer()
                    }
                    else
                    {
                        ThisCRTC.xzoom = 1
                        ThisCRTC.yzoom = 2
                        ThisCRTC.updatebuffer()
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
                        ThisCRTC.xcolumns = 80
                        ThisCRTC.yrows = 24
                        ThisCRTC.charoffset = 2048
                        ThisCRTC.canvasx = 640
                        ThisCRTC.canvasy = 264
                        ThisCRTC.ClearScreen()
                        ThisCRTC.printstring("SwarmEmu To-do list",0,0)
                        ThisCRTC.printstring("* Emulate Z80",0,1)
                        ThisCRTC.printstring("* Emulate CRTC",0,2)
                        ThisCRTC.printstring("* Emulate Keyboard",0,3)
                        ThisCRTC.printstring("* Emulate Sound",0,4)
                        ThisCRTC.printstring("* Load Basic",0,5)
                        ThisCRTC.printstring("* Run Games",0,6)
                        ThisCRTC.updatebuffer()
                    }
                    else
                    {
                        ThisCRTC.xpixels = 8
                        ThisCRTC.ypixels = 16
                        ThisCRTC.charoffset = 0
                        ThisCRTC.canvasx = 512
                        ThisCRTC.canvasy = 256
                        ThisCRTC.xcolumns = 64
                        ThisCRTC.yrows = 16
                        ThisCRTC.ClearScreen()
                        ThisCRTC.printstring("SwarmEmu To-do list",0,0)
                        ThisCRTC.printstring("* Emulate Z80",0,1)
                        ThisCRTC.printstring("* Emulate CRTC",0,2)
                        ThisCRTC.printstring("* Emulate Keyboard",0,3)
                        ThisCRTC.printstring("* Emulate Sound",0,4)
                        ThisCRTC.printstring("* Load Basic",0,5)
                        ThisCRTC.printstring("* Run Games",0,6)
                        ThisCRTC.updatebuffer()
                    }
                }
            TextField("Enter text to be displayed here and then press Enter", text: $textInput,
                      onCommit:
                        {
                            ThisCRTC.ClearScreen()
                            ThisCRTC.printstring(textInput,0,0)
                            ThisCRTC.updatebuffer()
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
