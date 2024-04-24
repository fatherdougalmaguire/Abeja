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
        VStack
        {
            //Spacer()
            Canvas { context, size in
                print("display buffer")
                print(Date().timeIntervalSince1970)
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
                print(Date().timeIntervalSince1970)
            }
            .frame(width: CGFloat(ThisCRTC.canvasx*ThisCRTC.xzoom), height: CGFloat(ThisCRTC.canvasy*ThisCRTC.yzoom))
            Spacer()
            Toggle("Zoom screen", isOn: $doublesize)
                .toggleStyle(SwitchToggleStyle(tint: Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0)))
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
                .toggleStyle(SwitchToggleStyle(tint: Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0)))
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
                    ThisCRTC.printline("SwarmEmu To-do list\n\n")
                    ThisCRTC.printline("* Emulate Z80\n")
                    ThisCRTC.printline("* Emulate CRTC\n")
                    ThisCRTC.printline("* Emulate Keyboard\n")
                    ThisCRTC.printline("* Emulate Sound\n")
                    ThisCRTC.printline("* Load Basic\n")
                    ThisCRTC.printline("* Run Games\n\n")
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
                    ThisCRTC.printline("SwarmEmu To-do list\n\n")
                    ThisCRTC.printline("* Emulate Z80\n")
                    ThisCRTC.printline("* Emulate CRTC\n")
                    ThisCRTC.printline("* Emulate Keyboard\n")
                    ThisCRTC.printline("* Emulate Sound\n")
                    ThisCRTC.printline("* Load Basic\n")
                    ThisCRTC.printline("* Run Games\n\n")
                    ThisCRTC.updatebuffer()
                }
            }
            TextField("Enter text to be displaye here and press Enter", text: $textInput,
                      onCommit:
                        {
                ThisCRTC.printline(textInput+"\n")
                ThisCRTC.updatebuffer()
            }
            )
            .background(Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0))
            .textFieldStyle(.plain)
            .cornerRadius(10)
            .frame(width: 300, height: 50)
            .multilineTextAlignment(.center)
            Spacer()
            Button("Clear Screen")
            {
                ThisCRTC.ClearScreen()
                ThisCRTC.updatebuffer()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0))
            Spacer()
            Button("Print boot message")
            {
                if eightycolumn
                {
                    ThisCRTC.ClearScreen()
                    ThisCRTC.printline("Microbee  56k  CP/M\n")
                    ThisCRTC.printline("Vers 2.20 [ZCPR II]\n\n")
                    ThisCRTC.printline("A>")
                    ThisCRTC.updatebuffer()
                }
                else
                {
                    ThisCRTC.ClearScreen()
                    ThisCRTC.printline("Applied Technology MicroBee Colour Basic. Ver 5.22e\n\n")
                    ThisCRTC.printline("Copyright MS 1983 for MicroWorld Australia\n\n")
                    ThisCRTC.printline(">_")
                    ThisCRTC.updatebuffer()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.sRGB, red: 1, green: 0.749, blue: 0, opacity: 1.0))
            Spacer()
        }
        .background(Color.white)
        //.frame(maxWidth: .infinity, maxHeight: .infinity )
        //.frame(maxWidth: .infinity, alignment: .leading)
        //.scaledToFit()
    }
}

#Preview {
    ContentView()
}
