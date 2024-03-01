// Importing SwiftUI for UI elements and MetalKit for rendering graphics.
import SwiftUI
import MetalKit

// MetalView is a SwiftUI view that integrates Metal for rendering graphics.
struct MetalView: View {
    // SwiftUI's @State property wrapper is used for maintaining state within the view.
    // metalView is an instance of MTKView, which is Metal's view class for rendering graphics.
    @State private var metalView = MTKView()

    // renderer is an optional instance of Renderer, our custom renderer class handling Metal drawing.
    @State private var renderer: Renderer?
    
    // body is a computed property that defines the view's content.
    var body: some View {
        // MetalViewRepresentable is a custom SwiftUI representable for Metal's MTKView.
        MetalViewRepresentable(metalView: $metalView)
            // onAppear is a view modifier that executes a closure when the view appears.
            .onAppear {
                // Setting the clear color of metalView to black.
                // MTLClearColor specifies the color values to use when clearing a drawable.
                metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
                
                // Initializing the renderer with the current metalView instance.
                // This ties the renderer's lifecycle to this MetalView instance.
                renderer = Renderer(metalView: metalView)
            }
    }
}

// A platform-specific typealias to adapt Metal's MTKView to SwiftUI.
// This approach abstracts away the specific view representable needed per platform (macOS or iOS).
#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#endif

// MetalViewRepresentable is a struct that bridges UIKit's UIView or AppKit's NSView to SwiftUI.
struct MetalViewRepresentable: ViewRepresentable {
    // A binding to the MTKView instance from the parent view.
    // The @Binding property wrapper allows this structure to share state with its parent.
    @Binding var metalView: MTKView
    
    
    
    // Platform-specific implementation to create the MTKView for macOS.
    // makeNSView is called by SwiftUI when it needs to create an NSView for macOS.
#if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        // Returning the metalView to be used as the NSView for this representable.
        metalView.preferredFramesPerSecond = 60 // sets framerate for MacOS
        return metalView
    }
    // updateNSView is called by SwiftUI when the NSView needs to update.
    func updateNSView(_ uiView: NSViewType, context: Context) {
        // Currently, the metal view does not need to update any properties dynamically.
        updateMetalView()
    }
#elseif os(iOS)
    // Platform-specific implementation to create the MTKView for iOS.
    // makeUIView is called by SwiftUI when it needs to create an UIView for iOS.
    func makeUIView(context: Context) -> MTKView {
        // Returning the metalView to be used as the UIView for this representable.
        metalView.preferredFramesPerSecond = 120 // sets frame rate for iOS
        return metalView
    }
    
    // updateUIView is called by SwiftUI when the UIView needs to update.
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Currently, the metal view does not need to update any properties dynamically.
        updateMetalView()
    }
#endif
    
    // A function that could be used to update properties of the metalView.
    // This is currently empty, but it provides a placeholder for future updates if needed.
    func updateMetalView() {
    }
}
