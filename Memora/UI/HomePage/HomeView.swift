import SwiftUI

struct HomeView: View {
    @State private var appear = false
    @State private var rotate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Soft background (journal vibe)
                Palette.paper
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    // Title + Date (centered at top)
                    VStack(spacing: 20) {
                        Text("Hi, John!")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145)) // Explicit dark ink color
                            .multilineTextAlignment(.center)

                        Text(formattedToday())
                            .font(.system(size: 32, design: .serif))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

                    // Memory ball — large & rotating slowly
                    Image("memory_ball")
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: min(geo.size.width * 0.7, 600),
                            height: min(geo.size.width * 0.7, 600)
                        ) // square (1:1)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        //.shadow(color: Palette.shadow, radius: 14, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Palette.ink.opacity(0.06), lineWidth: 1)
                        )
                        .rotationEffect(.degrees(rotate ? 360 : 0))
                        .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: rotate)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.15), value: appear)
                        .padding(.top, 90)

                    // Start Recall button
                    NavigationLink {
                        RecallPlaceholderView()
                            .transition(.opacity.animation(.easeInOut(duration: 0.35)))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                            Text("Start Recall")
                        }
                        .font(.system(size: 28, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 40)
                        .background(Color(red: 0.910, green: 0.722, blue: 0.675))
                        //.background(Color.blush)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Palette.shadow, radius: 8, x: 0, y: 6)
                        .accessibilityLabel("Start Recall")
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            appear = true
            rotate = true
        }
        .navigationBarHidden(true)
    }

    // e.g., "November 7th, 2025"
    private func formattedToday(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy"
        let base = df.string(from: date)
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 11, 12, 13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return base.replacingOccurrences(of: " \(day),", with: " \(day)\(suffix),")
    }
}

#Preview {
    NavigationStack { HomeView() }
        .previewInterfaceOrientation(.landscapeLeft) // or .portrait
        .previewLayout(.fixed(width: 1180, height: 820)) // iPad Air 11" points
}
