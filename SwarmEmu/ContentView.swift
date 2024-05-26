//
//  ContentView.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

import SwiftUI

struct ContentView: View {
    
    @StateObject var ThisMicrobee = Microbee()
    @State var sideBarVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    var body: some View {
        
        NavigationSplitView(columnVisibility: $sideBarVisibility)
        {
            VStack() {
                List() {
                    Section {
                        ForEach(0...15, id: \.self)
                        {
                            MyIndex in Text(ThisMicrobee.MyZ80.DumpRam(MemPointer: UInt16(ThisMicrobee.CPURegisters.PC/16*16)+UInt16(MyIndex*16),ThisMemory : ThisMicrobee.AllTheRam)).monospaced().foregroundColor(.orange)
                        } // End ForEach
                    }
                header: {
                    Text("Memory")
                }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(width:600)
                List() {
                    Section {
                        Text("PC : "+ThisMicrobee.MyZ80.FormatRegister2(ThisMicrobee.CPURegisters.PC)+"        SP : "+ThisMicrobee.MyZ80.FormatRegister2(ThisMicrobee.CPURegisters.SP)).monospaced().foregroundColor(.orange)
                        Text("IX : "+ThisMicrobee.MyZ80.FormatRegister2(ThisMicrobee.CPURegisters.IX)+"        IY : "+ThisMicrobee.MyZ80.FormatRegister2(ThisMicrobee.CPURegisters.IY)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("16 bit registers")
                }
                    Section {
                        Text("A  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.A)+"        F  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.F)).monospaced().foregroundColor(.orange)
                        Text("B  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.B)+"        C  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.C)).monospaced().foregroundColor(.orange)
                        Text("H  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.H)+"        L  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.L)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("8 bit registers")
                }
                    Section {
                        Text("A' : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.AltA)+"        F' : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.AltF)).monospaced().foregroundColor(.orange)
                        Text("B' : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.AltB)+"        C' : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.AltC)).monospaced().foregroundColor(.orange)
                        Text("H' : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.AltH)+"        L' : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.AltL)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("Alternate 8 bit registers")
                }
                    Section {
                        Text("I  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.I)+"        R  : "+ThisMicrobee.MyZ80.FormatRegister(ThisMicrobee.CPURegisters.R)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("Interrupt registers")
                }
                    Section {
                        Text("S Z H P N C                          S'Z'H'P'N'C'").monospaced().foregroundColor(.orange)
                        Text(ThisMicrobee.MyZ80.FormatRegister3(ThisMicrobee.CPURegisters.F)+"                         "+ThisMicrobee.MyZ80.FormatRegister3(ThisMicrobee.CPURegisters.AltF)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("Flags")
                }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }  detail: {
            EmulatorView()
        }
        .environmentObject(ThisMicrobee)
        
    }
    
    struct EmulatorView: View {
        
        @EnvironmentObject var ThisMicrobee : Microbee
        
        @State var zoomfactor: Float = 1.5
        @State var Interlace: Float = 0
        @State var buttonpress: Int = 0
        
        var body: some View {
            VStack
            {
                VStack
                {
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
                    
                    TimelineView(.animation)
                    { context in
                        Rectangle()
                            .frame(width: CGFloat(ThisMicrobee.MyCRTC.canvasx), height: CGFloat(ThisMicrobee.MyCRTC.canvasy))
                            .colorEffect(ShaderLibrary.newpcg(.floatArray(ThisMicrobee.MyCRTC.screenram),.floatArray(ThisMicrobee.MyCRTC.pcgram),.float(ThisMicrobee.MyCRTC.xcursor),.float(ThisMicrobee.MyCRTC.ycursor),.float(ThisMicrobee.MyCRTC.ypixels),.float(ThisMicrobee.MyCRTC.xcolumns),.float(ThisMicrobee.MyCRTC.charoffset),.float(ThisMicrobee.MyCRTC.tick),.float(ThisMicrobee.MyCRTC.cursortype),.float(ThisMicrobee.MyCRTC.cursorstart),.float(ThisMicrobee.MyCRTC.cursorend),.float(1)))
                            .scaleEffect(x: 1*CGFloat(zoomfactor), y:1.333*CGFloat(zoomfactor))
                            .colorEffect(ShaderLibrary.interlace(.float(Interlace)))
                            .frame(width: CGFloat(ThisMicrobee.MyCRTC.canvasx*zoomfactor), height: CGFloat(ThisMicrobee.MyCRTC.canvasy*1.333*zoomfactor))
                            .onChange(of: context.date) { ThisMicrobee.MyCRTC.updatetick() }
                    }
                }
                
                HStack {
                    Button("Start/Stop CPU")
                    {
                        
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    .tint(.orange)
                    Button("Step CPU")
                    {
                        buttonpress = buttonpress+1
                    }
                    .onChange(of:buttonpress) {
                        ThisMicrobee.ExecuteInstruction(JumpValue : 1)
                        //ThisMicrobee.MyCRTC.printline(String(ThisMicrobee.CPURegisters.PC,radix:16,uppercase: true)+"\n")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    Button("Reset CPU")
                    {
                        
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    .tint(.orange)
                }
            }  .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white)
        }
    }
}


#Preview {
    ContentView()
}
