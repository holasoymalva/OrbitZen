//
//  ContentView.swift
//  OrbitZen Watch App
//
//  Created by malva on 10/12/25.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    // Create the scene once and keep it alive
    @State private var scene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }()
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .focusable()
                .onAppear {
                    // Ensure size is correct when view appears
                    scene.size = geometry.size
                }
                .onTapGesture {
                    scene.handleTap()
                }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
