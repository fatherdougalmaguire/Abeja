//
//  ContentView.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

import SwiftUI

struct ContentView: View {
    
    @StateObject var ThisCRTC1 = CRTC()
    @StateObject var ThisZ80 = Z80()
    
    @State private var zoomfactor: Float = 1.5
    @State private var Interlace: Float = 0
    @State private var buttonpress: Int = 0
    
    var body: some View {
        
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
            
            TimelineView(.animation) { context in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: CGFloat(ThisCRTC1.canvasx), height: CGFloat(ThisCRTC1.canvasy))
                    .colorEffect(ShaderLibrary.newpcg(.floatArray(ThisCRTC1.screenram),.floatArray(ThisCRTC1.pcgram),.float(ThisCRTC1.xcursor),.float(ThisCRTC1.ycursor),.float(ThisCRTC1.ypixels),.float(ThisCRTC1.xcolumns),.float(ThisCRTC1.charoffset),.float(ThisCRTC1.tick),.float(ThisCRTC1.cursortype),.float(ThisCRTC1.cursorstart),.float(ThisCRTC1.cursorend),.float(1)))
                    .scaleEffect(x: 1*CGFloat(zoomfactor), y:1.333*CGFloat(zoomfactor))
                    .colorEffect(ShaderLibrary.interlace(.float(Interlace)))
                    .frame(width: CGFloat(ThisCRTC1.canvasx*zoomfactor), height: CGFloat(ThisCRTC1.canvasy*1.333*zoomfactor))
                    .onChange(of: context.date) { ThisCRTC1.updatetick() }
            }
            HStack() {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    List() {
                        Section {
                            ForEach(0...32, id: \.self)
                            {
                                MyIndex in Text(ThisZ80.DumpRam(Int(ThisZ80.CPURegisters.PC/32*32)+Int(MyIndex*32))).monospaced().foregroundColor(.orange)
                            } // End ForEach
                        }
                        header: {
                            Text("Memory")
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                List() {
                    Section {
                        Text("PC : "+ThisZ80.FormatRegister2(ThisZ80.CPURegisters.PC)+"        SP : "+ThisZ80.FormatRegister2(ThisZ80.CPURegisters.SP)).monospaced().foregroundColor(.orange)
                        Text("IX : "+ThisZ80.FormatRegister2(ThisZ80.CPURegisters.IX)+"        IY : "+ThisZ80.FormatRegister2(ThisZ80.CPURegisters.IY)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("16 bit registers")
                }
                    Section {
                        Text("A  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.A)+"        F  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.F)).monospaced().foregroundColor(.orange)
                        Text("B  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.B)+"        C  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.C)).monospaced().foregroundColor(.orange)
                        Text("H  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.H)+"        L  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.L)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("8 bit registers")
                }
                    Section {
                        Text("A' : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.AltA)+"        F' : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.AltF)).monospaced().foregroundColor(.orange)
                        Text("B' : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.AltB)+"        C' : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.AltC)).monospaced().foregroundColor(.orange)
                        Text("H' : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.AltH)+"        L' : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.AltL)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("Alternate 8 bit registers")
                }
                    Section {
                        Text("I  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.I)+"        R  : "+ThisZ80.FormatRegister(ThisZ80.CPURegisters.R)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("Interrupt registers")
                }
                    Section {
                        Text("S Z H P N C                          S'Z'H'P'N'C'").monospaced().foregroundColor(.orange)
                        Text(ThisZ80.FormatRegister3(ThisZ80.CPURegisters.F)+"                         "+ThisZ80.FormatRegister3(ThisZ80.CPURegisters.AltF)).monospaced().foregroundColor(.orange)
                    }
                header: {
                    Text("Flags")
                }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        HStack {
            Button("Start/Stop CPU")
            {
                
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
            Button("Step CPU")
            {
                buttonpress = buttonpress+1
            }
            .onChange(of:buttonpress) {
                ThisZ80.StepInstruction()
            }
            .buttonStyle(.borderedProminent)
            Button("Reset CPU")
            {
  
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
        }.padding(15)
    }
}

#Preview {
    ContentView()
}
