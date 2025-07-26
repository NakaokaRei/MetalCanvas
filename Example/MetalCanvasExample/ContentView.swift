import SwiftUI
import MetalCanvas

struct ContentView: View {
    @State private var fragmentShader: String? = ShaderExamples.gradient.source
    @State private var selectedExample = ShaderExamples.gradient
    @State private var isPaused = false
    @State private var showCode = false
    
    var body: some View {
        HSplitView {
            // Shader selection sidebar
            ShaderListView(selectedShader: $selectedExample)
                .frame(minWidth: 200, maxWidth: 300)
            
            // Main content
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text(selectedExample.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { isPaused.toggle() }) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    }
                    .help(isPaused ? "Play" : "Pause")
                    
                    Button(action: { showCode.toggle() }) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                    }
                    .help("Show shader code")
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                // Canvas
                if showCode {
                    HSplitView {
                        MetalCanvasView(fragmentShader: $fragmentShader)
                            .onAppear {
                                fragmentShader = selectedExample.source
                            }
                        
                        ShaderCodeView(shader: selectedExample)
                            .frame(minWidth: 300)
                    }
                } else {
                    MetalCanvasView(fragmentShader: $fragmentShader)
                        .onAppear {
                            fragmentShader = selectedExample.source
                        }
                }
            }
        }
        .onChange(of: selectedExample) { oldValue, newValue in
            fragmentShader = newValue.source
        }
    }
}

struct ShaderListView: View {
    @Binding var selectedShader: ShaderExample
    
    var body: some View {
        List(ShaderExamples.all, id: \.id, selection: $selectedShader) { shader in
            HStack {
                Image(systemName: shader.icon)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(shader.name)
                        .font(.headline)
                    Text(shader.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .tag(shader)
        }
        .listStyle(SidebarListStyle())
    }
}

struct ShaderCodeView: View {
    let shader: ShaderExample
    
    var body: some View {
        ScrollView {
            Text(shader.source)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

#Preview {
    ContentView()
}