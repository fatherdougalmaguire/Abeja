//
//  ContentView.swift
//  SwarmEmu
//
// SwarmEmu Copyright (c) 2024 Tony Sanchez
// Nanowasp Copyright (c) 2007, 2011 David G. Churchill

import SwiftUI

struct ContentView: View {
    
    @State var imagename : String = "OIG3"
    
    var body: some View {
        Text("At some point in the future,  this code will actually do something")
        VStack {
            Image(imagename)
                .resizable()
                .scaledToFit()
                .frame(width: 700, height: 700)
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
