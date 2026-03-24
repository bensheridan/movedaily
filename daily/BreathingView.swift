import SwiftUI
internal import Combine

struct BreathingView: View {
    @State private var isInhaling = false
    @State private var statusText = "Inhale"
    @State private var scale: CGFloat = 0.5
    
    // Timer for breathing cycle (e.g., Box Breathing 4s each)
    let breathingTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 50) {
            Text("Breathing Exercise")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(statusText)
                .font(.title)
                .foregroundColor(.blue)
                .animation(.easeInOut, value: statusText)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.1)
                    .foregroundColor(.blue)
                    .frame(width: 300, height: 300)
                
                Circle()
                    .fill(
                        RadialGradient(colors: [.blue.opacity(0.6), .blue.opacity(0.2)], center: .center, startRadius: 10, endRadius: 150)
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 4), value: scale)
            }
            
            Spacer()
            
            Button("Done") {
                // Return or complete
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 50)
        }
        .padding()
        .onReceive(breathingTimer) { _ in
            toggleBreathing()
        }
        .onAppear {
            toggleBreathing()
        }
    }
    
    private func toggleBreathing() {
        if statusText == "Inhale" {
            statusText = "Hold"
            scale = 1.0
        } else if statusText == "Hold" && scale == 1.0 {
            statusText = "Exhale"
            scale = 0.5
        } else if statusText == "Exhale" {
            statusText = "Hold"
            scale = 0.5
        } else {
            statusText = "Inhale"
            scale = 1.0
        }
    }
}

#Preview {
    BreathingView()
}
