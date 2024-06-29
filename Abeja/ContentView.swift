//
//  ContentView.swift
//  Abeja
//
//  Created by Antonio Sanchez-Rivas on 14/4/2024
//

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
                            MyIndex in Text(ThisMicrobee.MyZ80.DumpRam(BaseMemPointer : ThisMicrobee.CPURegisters.PC, MemPointer : UInt16(ThisMicrobee.CPURegisters.PC/256*256)+UInt16(MyIndex*16),ThisMemory : ThisMicrobee.AllTheRam)).monospaced().foregroundColor(.orange).truncationMode(.tail).lineLimit(1)
                        } // End ForEach
                    }
                header: {
                    Text("Memory")
                }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(width:625)
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
        
        let ZoomValues = ["Small","Medium","Large"]
        
        @State var zoomfactory: String = "Small"
        @State var zoomfactor: Float = 1.0
        @State var Interlace: Float = 0
        @State var buttonpress: Int = 0
        @State var buttonpress1: Int = 0
        @State private var fullText: String = "21 00 F0 3E 48 77 23 3E 45 77 23 3E 4C 77 23 3E 4C 77 23 3E 4F 77 23"
        @State private var fullText1: String = ""
        
        var body: some View {
            VStack
            {
                Spacer()
                TimelineView(.animation)
                { context in
                    Rectangle()
                        .frame(width: CGFloat(ThisMicrobee.MyCRTC.canvasx), height: CGFloat(ThisMicrobee.MyCRTC.canvasy))
                        .colorEffect(ShaderLibrary.newpcg(.floatArray(ThisMicrobee.MyCRTC.screenram),.floatArray(ThisMicrobee.MyCRTC.pcgram),.float(ThisMicrobee.MyCRTC.xcursor),.float(ThisMicrobee.MyCRTC.ycursor),.float(ThisMicrobee.MyCRTC.ypixels),.float(ThisMicrobee.MyCRTC.xcolumns),.float(ThisMicrobee.MyCRTC.charoffset),.float(ThisMicrobee.MyCRTC.tick),.float(ThisMicrobee.MyCRTC.cursortype),.float(ThisMicrobee.MyCRTC.cursorstart),.float(ThisMicrobee.MyCRTC.cursorend),.float(1)))
                        .scaleEffect(x: 1*CGFloat(zoomfactor), y:1.333*CGFloat(zoomfactor))
                        .colorEffect(ShaderLibrary.interlace(.float(Interlace)))
                        .frame(width: CGFloat(ThisMicrobee.MyCRTC.canvasx*zoomfactor), height: CGFloat(ThisMicrobee.MyCRTC.canvasy*1.333*zoomfactor))
                        .onChange(of: context.date) 
                        {
                            ThisMicrobee.MyCRTC.updatetick()
                            ThisMicrobee.ExecuteInstructionBundle(JumpValue : 1)
                        }
                }
                HStack {
                    VStack { List() {
                        Section {
                            ForEach(1...16, id: \.self)
                            {
                                MyIndex in Text(ThisMicrobee.MyZ80.ShowInstructions(InstructionNumber : MyIndex, MemPointer : ThisMicrobee.CPURegisters.PC,ThisMemory : ThisMicrobee.AllTheRam)).monospaced().foregroundColor(.orange).truncationMode(.tail).lineLimit(1)
                            }
                        }
                    header: {
                        Text("Disassembler")
                    }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                        
                        TextField("PC",text: $fullText1)
                        Button("Go to Address")
                        {
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                        .tint(.orange)
                        Spacer()
                    }
                    VStack {
                        Form {
                            Section { TextEditor(text: $fullText)
                                    .cornerRadius(10.0)
                                    .shadow(radius: 1.0)
                                    .monospaced()
                                    .foregroundColor(.orange)
                                    .frame(minHeight: 500, maxHeight: 500)
                            }
                        header: {
                            Text("Hex Loader")
                        }
                        }
                        Button("Compile")
                        {
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                        .tint(.orange)
                        Spacer()
                    }
                    VStack {
                        Picker("Zoom Factor", selection: $zoomfactory )
                        {
                            ForEach(ZoomValues, id: \.self)
                            {
                                Text(String($0))
                            }
                        }
                        .padding()
                        .tint(.orange)
                        .onChange(of : zoomfactory)
                        {
                            switch zoomfactory
                            {
                            case "Small" : zoomfactor = 1.0
                            case "Medium" : zoomfactor = 1.5
                            case "Large" : zoomfactor = 2.0
                            default:
                                zoomfactor = 1.5
                            }
                        }
                        Button("Start/Stop CPU",systemImage: "playpause")
                        {
                            buttonpress = buttonpress+1
                        }
                        .onChange(of:buttonpress) 
                        {
                            ThisMicrobee.MyZ80.CPURunning = !ThisMicrobee.MyZ80.CPURunning
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        Button("Step CPU",systemImage: "forward.frame")
                        {
                            buttonpress1 = buttonpress1+1
                            ThisMicrobee.MyZ80.CPUStep = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .onChange(of:buttonpress1)
                        {
                            ThisMicrobee.StepInstruction( JumpValue : 1 )
                        }
                        Button("Reset CPU",systemImage: "restart")
                        {
                            ThisMicrobee.ResetCPU()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    Spacer()
                }
            }  .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white)
        }
    }
}


#Preview {
    ContentView()
}
