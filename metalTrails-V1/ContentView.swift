//
//  ContentView.swift
//  Pipeline
//
//  Created by Raul on 1/19/24.
//

import SwiftUI

struct ContentView: View {
 //   @State private var hideStatusBar = true         // this is how we set the status bar state (iOS ONLY)
    
    
    @State private var renderer: Renderer?
    var body: some View {
        VStack {
            MetalView()
        }
 //       .statusBar(hidden: hideStatusBar)                // hide status bar , turn on only when building on (iOS ONLY)
 //       .persistentSystemOverlays(.hidden)                // hide other overlays (iOS ONLY)
    }
    
}
