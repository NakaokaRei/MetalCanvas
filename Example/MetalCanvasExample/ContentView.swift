import SwiftUI
import MetalCanvas

struct ContentView: View {
    @State private var fragmentShader: String? = ShaderExamples.solidRed.source
    @State private var selectedExample = ShaderExamples.solidRed
    @State private var isPaused = false
    @State private var showCode = false
    @State private var editableShaderCode: String = ShaderExamples.solidRed.source
    @State private var isEditing = false
    @State private var shaderError: String?
    
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
                    
                    if showCode {
                        Button(action: { 
                            if isEditing {
                                // When exiting edit mode, ensure the current code is applied
                                fragmentShader = editableShaderCode
                            }
                            isEditing.toggle()
                        }) {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                                .foregroundColor(isEditing ? .green : .primary)
                        }
                        .help(isEditing ? "Apply changes" : "Edit shader")
                        
                        if isEditing {
                            Button(action: {
                                // Reset to original
                                editableShaderCode = selectedExample.source
                                fragmentShader = selectedExample.source
                            }) {
                                Image(systemName: "arrow.uturn.backward.circle")
                            }
                            .help("Reset to original")
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                // Canvas
                if showCode {
                    HSplitView {
                        MetalCanvasView(fragmentShader: $fragmentShader) { error in
                            shaderError = error.localizedDescription
                        }
                        
                        if isEditing {
                            ShaderEditorView(code: $editableShaderCode, 
                                           shaderError: $shaderError,
                                           onUpdate: { newCode in
                                fragmentShader = newCode
                                shaderError = nil
                            })
                            .frame(minWidth: 300)
                        } else {
                            ShaderCodeView(shader: selectedExample)
                                .frame(minWidth: 300)
                        }
                    }
                } else {
                    MetalCanvasView(fragmentShader: $fragmentShader) { error in
                        shaderError = error.localizedDescription
                    }
                }
            }
        }
        .onChange(of: selectedExample) { oldValue, newValue in
            fragmentShader = newValue.source
            editableShaderCode = newValue.source
            isEditing = false
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

struct ShaderEditorView: View {
    @Binding var code: String
    @Binding var shaderError: String?
    let onUpdate: (String) -> Void
    @State private var lastValidCode: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let error = shaderError {
                ScrollView(.horizontal) {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: 60, alignment: .leading)
                .background(Color.red.opacity(0.1))
            }
            
            TextEditor(text: $code)
                .font(.system(.body, design: .monospaced))
                .onChange(of: code) { oldValue, newValue in
                    // Delay to avoid too frequent updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if code == newValue { // Check if still the same after delay
                            validateAndUpdate(newValue)
                        }
                    }
                }
                .onAppear {
                    lastValidCode = code
                    validateAndUpdate(code)
                }
        }
    }
    
    private func validateAndUpdate(_ newCode: String) {
        // Always update to see compilation errors
        onUpdate(newCode)
        lastValidCode = newCode
    }
}

#Preview {
    ContentView()
}