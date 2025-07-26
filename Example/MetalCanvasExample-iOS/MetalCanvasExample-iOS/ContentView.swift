import SwiftUI
import MetalCanvas

struct ContentView: View {
    @State private var selectedExample = ShaderExamples.solidRed
    @State private var fragmentShader: String? = ShaderExamples.solidRed.source
    
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
                }
                
                // Metal canvas view
                MetalCanvasView(fragmentShader: $fragmentShader)
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