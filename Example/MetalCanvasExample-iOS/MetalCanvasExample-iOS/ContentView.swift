import SwiftUI
import MetalCanvas

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
    @State private var selectedExample = ShaderExamples.solidRed
    @State private var fragmentShader: String? = ShaderExamples.solidRed.source
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Shader picker
                Picker("Shader", selection: $selectedExample) {
                    ForEach(ShaderExamples.all, id: \.id) { shader in
                        Text(shader.name)
                            .tag(shader)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedExample) { oldValue, newValue in
                    fragmentShader = newValue.source
                    viewModel.loadTextureIfNeeded(for: newValue.name)
                }
                
                // Timer controls
                HStack {
                    Button(action: {
                        viewModel.metalCanvas?.toggle()
                    }) {
                        Image(systemName: viewModel.metalCanvas?.isTimerPaused == true ? "play.fill" : "pause.fill")
                            .font(.title2)
                    }
                    .padding()
                    
                    Button(action: {
                        viewModel.metalCanvas?.reset()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text(selectedExample.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing)
                }
                .background(Color(UIColor.systemGray6))
                
                // Metal canvas view
                MetalCanvasView(fragmentShader: $fragmentShader,
                              onCanvasCreated: { canvas in
                                  viewModel.metalCanvas = canvas
                                  viewModel.loadTextureIfNeeded(for: selectedExample.name)
                              })
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarTitle("MetalCanvas iOS", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}
