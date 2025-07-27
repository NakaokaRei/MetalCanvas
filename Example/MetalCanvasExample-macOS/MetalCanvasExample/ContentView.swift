import MetalCanvas
import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
    var metalCanvas: MetalCanvas?
    
    func loadTextureIfNeeded(for shaderName: String) {
        guard shaderName == "Texture Demo",
              let canvas = metalCanvas else { return }
        
        Task {
            if let bundlePath = Bundle.main.path(forResource: "Metal_icon", ofType: "png") {
                do {
                    let texture = try await canvas.textureManager.loadTexture(
                        from: URL(fileURLWithPath: bundlePath),
                        key: "metalIcon"
                    )
                    canvas.setTexture(texture, for: "metalIcon")
                    print("Successfully loaded Metal_icon.png from bundle")
                } catch {
                    print("Error loading texture: \(error)")
                }
            } else {
                print("Metal_icon.png not found in bundle")
            }
        }
    }
}

struct ContentView: View {
    @State private var fragmentShader: String? = ShaderExamples.solidRed.source
    @State private var selectedExample = ShaderExamples.solidRed
    @State private var editableShaderCode: String = ShaderExamples.solidRed.source
    @State private var shaderError: String?
    @State private var showCode = true
    @StateObject private var viewModel = ContentViewModel()

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
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Button(action: {
                        viewModel.metalCanvas?.toggle()
                    }) {
                        Image(
                            systemName: viewModel.metalCanvas?.isTimerPaused == true
                                ? "play.fill" : "pause.fill"
                        )
                    }
                    .help(viewModel.metalCanvas?.isTimerPaused == true ? "Play" : "Pause")

                    Button(action: {
                        viewModel.metalCanvas?.reset()
                    }) {
                        Image(systemName: "backward.fill")
                    }
                    .help("Reset timer")

                    Button(action: { showCode.toggle() }) {
                        Image(
                            systemName:
                                "chevron.left.forwardslash.chevron.right"
                        )
                        .foregroundColor(showCode ? .accentColor : .primary)
                    }
                    .help(showCode ? "Hide shader code" : "Show shader code")

                    Button(action: {
                        // Reset to original
                        editableShaderCode = selectedExample.source
                        fragmentShader = selectedExample.source
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                    }
                    .help("Reset to original")
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))

                // Canvas with code editor
                if showCode {
                    HSplitView {
                        MetalCanvasView(
                            fragmentShader: $fragmentShader,
                            onShaderError: { error in
                                shaderError = error.localizedDescription
                            },
                            onCanvasCreated: { canvas in
                                viewModel.metalCanvas = canvas
                                viewModel.loadTextureIfNeeded(for: selectedExample.name)
                            }
                        )

                        ShaderEditorView(
                            code: $editableShaderCode,
                            shaderError: $shaderError,
                            onUpdate: { newCode in
                                fragmentShader = newCode
                                shaderError = nil
                            }
                        )
                        .frame(minWidth: 300)
                    }
                } else {
                    MetalCanvasView(
                        fragmentShader: $fragmentShader,
                        onShaderError: { error in
                            shaderError = error.localizedDescription
                        },
                        onCanvasCreated: { canvas in
                            viewModel.metalCanvas = canvas
                            viewModel.loadTextureIfNeeded(for: selectedExample.name)
                        }
                    )
                }
            }
        }
        .onChange(of: selectedExample) { oldValue, newValue in
            fragmentShader = newValue.source
            editableShaderCode = newValue.source
            viewModel.loadTextureIfNeeded(for: newValue.name)
        }
    }
}

struct ShaderListView: View {
    @Binding var selectedShader: ShaderExample

    var body: some View {
        List(ShaderExamples.all, id: \.id, selection: $selectedShader) {
            shader in
            HStack {
                Image(systemName: shader.icon)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(shader.name)
                        .font(.system(size: 16, weight: .semibold))
                    Text(shader.description)
                        .font(.system(size: 13))
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
                .font(.system(size: 18, design: .monospaced))
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
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: 60, alignment: .leading)
                .background(Color.red.opacity(0.1))
            }

            TextEditor(text: $code)
                .font(.system(size: 18, design: .monospaced))
                .onChange(of: code) { oldValue, newValue in
                    // Delay to avoid too frequent updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if code == newValue {  // Check if still the same after delay
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
