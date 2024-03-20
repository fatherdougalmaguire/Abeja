//
//  ContentView.swift
//  SwarmEmu
//
//  Created by Antonio Sanchez-Rivas on 20/3/2024.
//

import SwiftUI

struct ContentView: View {
    
    @State var imagename : String = "basic"
    
    var body: some View {
        Text("These are just screenshots")
        VStack {
            Image(imagename)
                .resizable()
                .scaledToFit()
                .frame(width: 700, height: 700)
            HStack {
                Button("Basic", action:
                        {
                    imagename = "basic"
                }
                )
                .buttonStyle(.borderedProminent)
            }
            Button("Emu Joust", action:
                    {
                imagename = "joust"
            }
            )
            .buttonStyle(.borderedProminent)
            Button("Space Invaders", action:
                    {
                imagename = "space invaders"
            }
            )
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
