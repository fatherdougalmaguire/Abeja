//
//  ContentView.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

import SwiftUI

struct ContentView: View {
    
    @StateObject var ThisCRTC1 = CRTC()
    @StateObject var ThisCRTC2 = CRTC()
    @StateObject var BasicRom = MMU(true,0x8000,0xBFFF,"basic_5.22e","rom")
    // The Microbee's 16K of BASIC ROM starts at address 0x8000. Additional ROMs for EDASM, or WordBee were often also installed and these occupied the space from 0xC000 up to 0xF000.
    @StateObject var ThisZ80 = Z80()
    
    @State private var textInput : String = ""
    @State private var doublesize : Bool = false
    @State private var eightycolumn : Bool = false
    @State private var zoomfactor: Float = 1.5
    @State private var county: Int = 1
    @State private var Interlace: Float = 0
    
    
    let timer = Timer.publish(every: 0.01 , on: .main, in: .common).autoconnect()
    
    
    let startDate = Date()
    
    var body: some View {
        VStack
        {
            HStack {
//                Slider(value: $ThisCRTC.cursortype, in: 0...3, step:1)
//                {
//                    Text("Cursor")
//                } minimumValueLabel: {
//                    Text("Solid")//.font(.title2).fontWeight(.thin)
//                } maximumValueLabel: {
//                    Text("Fast")//.font(.title2).fontWeight(.thin)
//                }
//                .frame(width: 200)
//                .tint(.orange)
                Slider(value: $zoomfactor, in: 1...2, step:0.25)
                {
                    Text("Zoom")
                } minimumValueLabel: {
                    Text("1x")//.font(.title2).fontWeight(.thin)
                } maximumValueLabel: {
                    Text("2x")//.font(.title2).fontWeight(.thin)
                }
                .frame(width: 200)
                .tint(.orange)
//                Slider(value: $Interlace, in: 0...1, step:1)
//                {
//                    Text("Interlace")
//                } minimumValueLabel: {
//                    Text("Off")//.font(.title2).fontWeight(.thin)
//                } maximumValueLabel: {
//                    Text("On")//.font(.title2).fontWeight(.thin)
//                }
//                .frame(width: 200)
//                .tint(.orange)
            }
            TimelineView(.animation) { context in
                HStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: CGFloat(ThisCRTC1.canvasx), height: CGFloat(ThisCRTC1.canvasy))
                        .colorEffect(ShaderLibrary.newpcg(.floatArray(ThisCRTC1.screenram),.floatArray(ThisCRTC1.pcgram),.float(ThisCRTC1.xcursor),.float(ThisCRTC1.ycursor),.float(ThisCRTC1.ypixels),.float(ThisCRTC1.xcolumns),.float(ThisCRTC1.charoffset),.float(ThisCRTC1.tick),.float(ThisCRTC1.cursortype),.float(ThisCRTC1.cursorstart),.float(ThisCRTC1.cursorend),.float(1)))
                        .scaleEffect(x: 1*CGFloat(zoomfactor), y:1.333*CGFloat(zoomfactor))
                        .colorEffect(ShaderLibrary.interlace(.float(Interlace)))
                        .frame(width: CGFloat(ThisCRTC1.canvasx*zoomfactor), height: CGFloat(ThisCRTC1.canvasy*1.333*zoomfactor))
                        .onChange(of: context.date) { ThisCRTC1.updatetick() }
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: CGFloat(ThisCRTC2.canvasx), height: CGFloat(ThisCRTC2.canvasy))
                        .colorEffect(ShaderLibrary.newpcg(.floatArray(ThisCRTC2.screenram),.floatArray(ThisCRTC2.pcgram),.float(ThisCRTC2.xcursor),.float(ThisCRTC2.ycursor),.float(ThisCRTC2.ypixels),.float(ThisCRTC2.xcolumns),.float(ThisCRTC2.charoffset),.float(ThisCRTC2.tick),.float(ThisCRTC2.cursortype),.float(ThisCRTC2.cursorstart),.float(ThisCRTC2.cursorend),.float(0)))
                        .scaleEffect(x: 1*CGFloat(zoomfactor), y:1.333*CGFloat(zoomfactor))
                        .colorEffect(ShaderLibrary.interlace(.float(Interlace)))
                        .frame(width: CGFloat(ThisCRTC2.canvasx*zoomfactor), height: CGFloat(ThisCRTC2.canvasy*1.333*zoomfactor))
                        .onChange(of: context.date) { ThisCRTC2.updatetick() }
                }
                }
//            Spacer()
//            Toggle("80 column display", isOn: $eightycolumn)
//                .toggleStyle(SwitchToggleStyle(tint: .orange))
//                .onChange(of: eightycolumn)
//            {
//                if eightycolumn
//                {
//                    ThisCRTC.xpixels = 8
//                    ThisCRTC.ypixels = 11
//                    ThisCRTC.xcolumns = 80
//                    ThisCRTC.yrows = 24
//                    ThisCRTC.charoffset = 2048
//                    ThisCRTC.canvasx = 640
//                    ThisCRTC.canvasy = 264
//                    ThisCRTC.cursortype = 0
//                    ThisCRTC.cursorstart = 0
//                    ThisCRTC.cursorend = 10
//                    ThisCRTC.ClearScreen()
//                    ThisCRTC.printline("SwarmEmu To-do list\n\n")
//                    ThisCRTC.printline("* Emulate Z80\n")
//                    ThisCRTC.printline("* Emulate CRTC\n")
//                    ThisCRTC.printline("* Emulate Keyboard\n")
//                    ThisCRTC.printline("* Emulate Sound\n")
//                    ThisCRTC.printline("* Load Basic\n")
//                    ThisCRTC.printline("* Run Games\n\n")
//                    //ThisCRTC.updatebuffer()
//                }
//                else
//                {
//                    ThisCRTC.xpixels = 8
//                    ThisCRTC.ypixels = 16
//                    ThisCRTC.charoffset = 0
//                    ThisCRTC.canvasx = 512
//                    ThisCRTC.canvasy = 256
//                    ThisCRTC.xcolumns = 64
//                    ThisCRTC.yrows = 16
//                    ThisCRTC.cursortype = 2
//                    ThisCRTC.cursorstart = 15
//                    ThisCRTC.cursorend = 15
//                    ThisCRTC.ClearScreen()
//                    ThisCRTC.printline("SwarmEmu To-do list\n\n")
//                    ThisCRTC.printline("* Emulate Z80\n")
//                    ThisCRTC.printline("* Emulate CRTC\n")
//                    ThisCRTC.printline("* Emulate Keyboard\n")
//                    ThisCRTC.printline("* Emulate Sound\n")
//                    ThisCRTC.printline("* Load Basic\n")
//                    ThisCRTC.printline("* Run Games\n\n")
//                    //ThisCRTC.updatebuffer()
//                }
//            }
//            TextField("Enter text to be displaye here and press Enter", text: $textInput,
//                      onCommit:
//                        {
//                ThisCRTC.printline(textInput+"\n")
//                //ThisCRTC.updatebuffer()
//            }
//            )
//            .background(.orange)
//            .textFieldStyle(.plain)
//            .cornerRadius(10)
//            .frame(width: 300, height: 50)
//            .multilineTextAlignment(.center)
//        Spacer()
//            Button("Clear Screen")
//            {
//                ThisCRTC1.ClearScreen()
//                //ThisCRTC.updatebuffer()
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.orange)
//            Spacer()
//            Button("Print boot message")
//            {
//                if eightycolumn
//                {
//                    ThisCRTC.ClearScreen()
//                    ThisCRTC.printline("Microbee  56k  CP/M\n")
//                    ThisCRTC.printline("Vers 2.20 [ZCPR II]\n\n")
//                    ThisCRTC.printline("A>")
//                    // ThisCRTC.updatebuffer()
//                }
//                else
//                {
//                    ThisCRTC.ClearScreen()
//                    ThisCRTC.printline("Applied Technology MicroBee Colour Basic. Ver 5.22e\n\n")
//                    ThisCRTC.printline("Copyright MS 1983 for MicroWorld Australia\n\n")
//                    ThisCRTC.printline(">")
//                    // ThisCRTC.updatebuffer()
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.orange)
//            Spacer()
//            Button("Scrolltastic")
//            {
//                for myindex in 1...1000
//                {
//                    ThisCRTC1.printline("Line "+String(myindex+county)+" : Hello to Jason Isaacs\n")
//                }
//                county = county+1
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.orange)
//            Spacer()
            Button("Start/Stop Z80")
            {
                ThisZ80.CPURunning = !ThisZ80.CPURunning
                ThisCRTC2.ClearScreen()
                ThisCRTC2.printline("A: 00000000    F: 00000000    B: 00000000    C: 00000000\n")
                ThisCRTC2.printline("H: 00000000    L: 00000000    I: 00000000    R: 00000000\n\n")
                ThisCRTC2.printline("IX: 00000000 00000000\n")
                ThisCRTC2.printline("IY: 00000000 00000000\n")
                ThisCRTC2.printline("SP: 00000000 00000000\n")
                ThisCRTC2.printline("PC: 00000000 00000000\n")
            }
            .buttonStyle(.borderedProminent)
//            .tint(.orange)
            .onReceive(timer)
            { timerthingy in
                if ThisZ80.CPURunning 
                {
                    ThisZ80.StepInstruction()
                    ThisCRTC2.printstring(String(ThisZ80.CPURegisters.PC,radix:2),4,6)
                    ThisCRTC2.printstring(String(format: "%0000x", ThisZ80.CPURegisters.PC).uppercased(),23,6)
                }
            }
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
