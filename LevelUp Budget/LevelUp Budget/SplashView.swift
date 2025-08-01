import SwiftUI

struct SplashView: View {
    @State private var progress: CGFloat = 0
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    let onAnimationComplete: () -> Void
    let animationDuration: TimeInterval = 2.5
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo and app name
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    Text("LevelUp Budget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                }
                
                // Progress bar
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .scaleEffect(x: 1.5, y: 2, anchor: .center)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        print("🎬 Starting splash animation")
        
        // Animate logo
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Animate progress
        withAnimation(.easeInOut(duration: animationDuration)) {
            progress = 1.0
        }
        
        // Transition to login after animation - use a simple timer
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            print("⏰ Animation complete - calling onAnimationComplete callback")
            print("🔍 Progress value: \(progress)")
            print("🔍 Animation duration: \(animationDuration)")
            onAnimationComplete()
        }
    }
}

#Preview {
    SplashView(onAnimationComplete: {})
} 