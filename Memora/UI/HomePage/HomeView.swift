import SwiftUI
import Combine // <-- MODIFIED: Need this for .onReceive

// <-- MODIFIED: Create a Hashable enum for our navigation destinations
enum NavigationDestination: Hashable {
    case recall
    case memoryTest
    case memoryGallery
    case caregiverDashboard
}

struct HomeView: View {
    @State private var appear = false
    @State private var rotate = false
    
    // <-- MODIFIED: Add state for our navigation path
    @State private var navigationPath = NavigationPath()

    var body: some View {
        GeometryReader { geo in
            // <-- MODIFIED: Wrap your content in a NavigationStack
            // This allows us to control navigation from code.
            NavigationStack(path: $navigationPath) {
                ZStack {
                    // Soft background (journal vibe)
                    Palette.paper
                        .ignoresSafeArea()

                    ScrollView {
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
                            .padding(.top, 50)

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
                                .padding(.top, 80)

                            // Start Recall button
                            // <-- MODIFIED: Changed to NavigationLink(value:label:)
                            NavigationLink(value: NavigationDestination.recall) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 28))
                                    Text("Start Memory Training")
                                        .font(.system(size: 28))
                                }
                                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
                                .font(.system(size: 30, design: .rounded).weight(.semibold))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 30)
                                .background(Palette.blush)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Palette.shadow, radius: 10, x: 0, y: 6)
                                .accessibilityLabel("Start Recall")
                            }
                            .padding(.top, 10)
                            
                            // Grid layout for menu buttons
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 20) {
                                NavigationLink(value: NavigationDestination.memoryGallery) {
                                    GridMenuButton(icon: "photo.on.rectangle", title: "Memory Gallery", color: Palette.button)
                                }
                                
                                NavigationLink(value: NavigationDestination.memoryTest) {
                                    GridMenuButton(icon: "brain.head.profile", title: "Memory Test", color: Palette.button)
                                }
                                
                                NavigationLink(value: NavigationDestination.caregiverDashboard) {
                                    GridMenuButton(icon: "person.2.fill", title: "Caregiver Dashboard", color: Palette.button2)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 30)
                            .padding(.bottom, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 5)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .startMemoryRecall)) { _ in
                    // When we "hear" the message, add the recall
                    // destination to our navigation path.
                    // This has the same effect as tapping the button.
                    navigationPath.append(NavigationDestination.recall)
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .recall:
                        RecallPlaceholderView()
                    case .memoryTest:
                        MemoryTestView()
                    case .memoryGallery:
                        MemoryGalleryView()
                    case .caregiverDashboard:
                        CaregiverDashboardView()
                    }
                }
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


struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
            
            Text(title)
                .font(.system(size: 24, design: .rounded).weight(.semibold))
                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Palette.shadow, radius: 6, x: 0, y: 4)
    }
}

struct GridMenuButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
            
            Text(title)
                .font(.system(size: 22, design: .rounded).weight(.semibold))
                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Palette.shadow, radius: 8, x: 0, y: 4)
    }
}

//// <-- MODIFIED: You'll need placeholders for these views
//// if they aren't already defined in this file.
//struct MemoryTestView: View {
//    var body: some View { Text("Memory Test View") }
//}
//struct MemoryGalleryView: View {
//    var body: some View { Text("Memory Gallery View") }
//}
//struct SettingsView: View {
//    var body: some View { Text("Settings View") }
//}


#Preview {
    NavigationStack { HomeView() }
        .previewInterfaceOrientation(.landscapeLeft) // or .portrait
        .previewLayout(.fixed(width: 1180, height: 820)) // iPad Air 11" points
}
//import SwiftUI
//import Combine
//
//enum NavigationDestination: Hashable {
//    case recall
//    case memoryTest
//    case memoryGallery
//    case settings
//}
//
//struct HomeView: View {
//    @State private var appear = false
//    @State private var rotate = false
//    @State private var navigationPath = NavigationPath()
//
//
//    var body: some View {
//        GeometryReader { geo in
//            NavigationStack(path: $navigationPath) {
//            ZStack {
//                // Soft background (journal vibe)
//                Palette.paper
//                    .ignoresSafeArea()
//
//                ScrollView {
//                    VStack(spacing: 28) {
//                        // Title + Date (centered at top)
//                        VStack(spacing: 20) {
//                            Text("Hi, John!")
//                                .font(.system(size: 72, design: .serif).weight(.semibold))
//                                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145)) // Explicit dark ink color
//                                .multilineTextAlignment(.center)
//
//                            Text(formattedToday())
//                                .font(.system(size: 32, design: .serif))
//                                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.8))
//                                .multilineTextAlignment(.center)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.top, 30)
//
//                        // Memory ball — large & rotating slowly
//                        Image("memory_ball")
//                            .resizable()
//                            .scaledToFill()
//                            .frame(
//                                width: min(geo.size.width * 0.7, 600),
//                                height: min(geo.size.width * 0.7, 600)
//                            ) // square (1:1)
//                            .clipped()
//                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
//                        //.shadow(color: Palette.shadow, radius: 14, x: 0, y: 10)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 28, style: .continuous)
//                                    .stroke(Palette.ink.opacity(0.06), lineWidth: 1)
//                            )
//                            .rotationEffect(.degrees(rotate ? 360 : 0))
//                            .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: rotate)
//                            .opacity(appear ? 1 : 0)
//                            .animation(.easeInOut(duration: 0.8).delay(0.15), value: appear)
//                            .padding(.top, 80)
//
//                        NavigationLink(value: NavigationDestination.recall) {
//                                HStack(spacing: 12) {
//                                    Image(systemName: "play.circle.fill")
//                                        .font(.system(size: 28))
//                                    Text("Start Recall")
//                                }
//                                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//                                .font(.system(size: 30, design: .rounded).weight(.semibold))
//                                .padding(.vertical, 24)
//                                .padding(.horizontal, 40)
//                                .background(Palette.recallButton)
//                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                                .shadow(color: Palette.shadow, radius: 10, x: 0, y: 6)
//                                .accessibilityLabel("Start Recall")
//                            }
//                        .padding(.top, 10)
//
//                        // Start Recall button
//                        NavigationLink {
//                            RecallPlaceholderView()
//                        } label: {
//                            HStack(spacing: 12) {
//                                Image(systemName: "play.circle.fill")
//                                    .font(.system(size: 28))
//                                Text("Start Recall")
//                            }
//                            .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//                            .font(.system(size: 30, design: .rounded).weight(.semibold))
//                            .padding(.vertical, 24)
//                            .padding(.horizontal, 40)
//                            .background(Palette.recallButton)
//                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                            .shadow(color: Palette.shadow, radius: 10, x: 0, y: 6)
//                            .accessibilityLabel("Start Recall")
//                        }
//                        .padding(.top, 10)
//
//                        // Menu buttons
//                        VStack(spacing: 2) {
//                            // MoCA Memory Test and Memory Gallery in same row
//                            HStack(spacing: 0) {
//                                NavigationLink {
//                                    MemoryTestView()
//                                } label: {
//                                    MenuButton(icon: "brain.head.profile", title: "Memory Test", color: Palette.button)
//                                        .padding(.vertical, 20)
//                                    //.padding(.horizontal,10)
//                                        .padding(.trailing, 5)
//                                }
//
//                                NavigationLink {
//                                    MemoryGalleryView()
//                                } label: {
//                                    MenuButton(icon: "photo.on.rectangle", title: "Memory Gallery", color: Palette.button)
//                                        .padding(.vertical, 20)
//                                    //.padding(.horizontal,10)
//                                        .padding(.leading, 5)
//                                }
//                            }
//                            .padding(.horizontal, 40)
//
//                            // Settings below
//                            NavigationLink {
//                                SettingsView()
//                            } label: {
//                                MenuButton(icon: "gearshape.fill", title: "Settings", color: Palette.settingColor)
//                            }
//                            .padding(.vertical,10)
//                            .padding(.horizontal, 40)
//                        }
//                        .padding(.top, 5)
//                        .padding(.bottom, 10)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal, 5)
//                }
//            }
//        }
//        }
//        .onAppear {
//            appear = true
//            rotate = true
//        }
//        .navigationBarHidden(true)
//    }
//
//    // e.g., "November 7th, 2025"
//    private func formattedToday(_ date: Date = Date()) -> String {
//        let df = DateFormatter()
//        df.dateFormat = "MMMM d, yyyy"
//        let base = df.string(from: date)
//        let day = Calendar.current.component(.day, from: date)
//        let suffix: String
//        switch day {
//        case 11, 12, 13: suffix = "th"
//        default:
//            switch day % 10 {
//            case 1: suffix = "st"
//            case 2: suffix = "nd"
//            case 3: suffix = "rd"
//            default: suffix = "th"
//            }
//        }
//        return base.replacingOccurrences(of: " \(day),", with: " \(day)\(suffix),")
//    }
//}
//
//
//struct MenuButton: View {
//    let icon: String
//    let title: String
//    let color: Color
//
//    var body: some View {
//        HStack(spacing: 16) {
//            Image(systemName: icon)
//                .font(.system(size: 24))
//                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//
//            Text(title)
//                .font(.system(size: 24, design: .rounded).weight(.semibold))
//                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//
//            Spacer()
//
//            Image(systemName: "chevron.right")
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//        }
//        .padding(.vertical, 28)
//        .padding(.horizontal, 24)
//        .background(color)
//        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//        .shadow(color: Palette.shadow, radius: 6, x: 0, y: 4)
//    }
//}
//
//#Preview {
//    NavigationStack { HomeView() }
//        .previewInterfaceOrientation(.landscapeLeft) // or .portrait
//        .previewLayout(.fixed(width: 1180, height: 820)) // iPad Air 11" points
//}

//import SwiftUI
//import Combine // <-- MODIFIED: Need this for .onReceive
//
//// <-- MODIFIED: Create a Hashable enum for our navigation destinations
//enum NavigationDestination: Hashable {
//    case recall
//    case memoryTest
//    case memoryGallery
//    case settings
//}
//
//struct HomeView: View {
//    @State private var appear = false
//    @State private var rotate = false
//    
//    // <-- MODIFIED: Add state for our navigation path
//    @State private var navigationPath = NavigationPath()
//
//    var body: some View {
//        GeometryReader { geo in
//            // <-- MODIFIED: Wrap your content in a NavigationStack
//            // This allows us to control navigation from code.
//            NavigationStack(path: $navigationPath) {
//                ZStack {
//                    // Soft background (journal vibe)
//                    Palette.paper
//                        .ignoresSafeArea()
//
//                    ScrollView {
//                        VStack(spacing: 28) {
//                            // Title + Date (centered at top)
//                            VStack(spacing: 20) {
//                                Text("Hi, John!")
//                                    .font(.system(size: 72, design: .serif).weight(.semibold))
//                                    .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145)) // Explicit dark ink color
//                                    .multilineTextAlignment(.center)
//
//                                Text(formattedToday())
//                                    .font(.system(size: 32, design: .serif))
//                                    .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.8))
//                                    .multilineTextAlignment(.center)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(.top, 30)
//
//                            // Memory ball — large & rotating slowly
//                            Image("memory_ball")
//                                .resizable()
//                                .scaledToFill()
//                                .frame(
//                                    width: min(geo.size.width * 0.7, 600),
//                                    height: min(geo.size.width * 0.7, 600)
//                                ) // square (1:1)
//                                .clipped()
//                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
//                                //.shadow(color: Palette.shadow, radius: 14, x: 0, y: 10)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
//                                        .stroke(Palette.ink.opacity(0.06), lineWidth: 1)
//                                )
//                                .rotationEffect(.degrees(rotate ? 360 : 0))
//                                .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: rotate)
//                                .opacity(appear ? 1 : 0)
//                                .animation(.easeInOut(duration: 0.8).delay(0.15), value: appear)
//                                .padding(.top, 80)
//
//                            // Start Recall button
//                            // <-- MODIFIED: Changed to NavigationLink(value:label:)
//                            NavigationLink(value: NavigationDestination.recall) {
//                                HStack(spacing: 12) {
//                                    Image(systemName: "play.circle.fill")
//                                        .font(.system(size: 28))
//                                    Text("Start Recall")
//                                }
//                                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//                                .font(.system(size: 30, design: .rounded).weight(.semibold))
//                                .padding(.vertical, 24)
//                                .padding(.horizontal, 40)
//                                .background(Palette.recallButton)
//                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                                .shadow(color: Palette.shadow, radius: 10, x: 0, y: 6)
//                                .accessibilityLabel("Start Recall")
//                            }
//                            .padding(.top, 10)
//                            
//                            // Menu buttons
//                            VStack(spacing: 2) {
//                                // MoCA Memory Test and Memory Gallery in same row
//                                HStack(spacing: 0) {
//                                    NavigationLink(value: NavigationDestination.memoryTest) {
//                                        MenuButton(icon: "brain.head.profile", title: "Memory Test", color: Palette.button)
//                                            .padding(.vertical, 20)
//                                            //.padding(.horizontal,10)
//                                            .padding(.trailing, 5)
//                                    }
//                                    
//                                    NavigationLink(value: NavigationDestination.memoryGallery) {
//                                        MenuButton(icon: "photo.on.rectangle", title: "Memory Gallery", color: Palette.button)
//
//                                        .padding(.vertical, 20)
//                                        //.padding(.horizontal,10)
//                                        .padding(.leading, 5)
//                                    }
//                                }
//                                .padding(.horizontal, 40)
//                                
//                                NavigationLink(value: NavigationDestination.settings) {
//                                    MenuButton(icon: "gearshape.fill", title: "Settings", color: Palette.settingColor)
//                                }
//                                .padding(.vertical,10)
//                                .padding(.horizontal, 40)
//                            }
//                            .padding(.top, 5)
//                            .padding(.bottom, 10)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.horizontal, 5)
//                    }
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .startMemoryRecall)) { _ in
//                    // When we "hear" the message, add the recall
//                    // destination to our navigation path.
//                    // This has the same effect as tapping the button.
//                    navigationPath.append(NavigationDestination.recall)
//                }
//                .navigationDestination(for: NavigationDestination.self) { destination in
//                    switch destination {
//                    case .recall:
//                        RecallPlaceholderView()
//                    case .memoryTest:
//                        MemoryTestView()
//                    case .memoryGallery:
//                        MemoryGalleryView()
//                    case .settings:
//                        SettingsView()
//                    }
//                }
//            }
//        }
//        .onAppear {
//            appear = true
//            rotate = true
//        }
//        .navigationBarHidden(true)
//    }
//
//    // e.g., "November 7th, 2025"
//    private func formattedToday(_ date: Date = Date()) -> String {
//        let df = DateFormatter()
//        df.dateFormat = "MMMM d, yyyy"
//        let base = df.string(from: date)
//        let day = Calendar.current.component(.day, from: date)
//        let suffix: String
//        switch day {
//        case 11, 12, 13: suffix = "th"
//        default:
//            switch day % 10 {
//            case 1: suffix = "st"
//            case 2: suffix = "nd"
//            case 3: suffix = "rd"
//            default: suffix = "th"
//            }
//        }
//        return base.replacingOccurrences(of: " \(day),", with: " \(day)\(suffix),")
//    }
//}
//
//
//struct MenuButton: View {
//    let icon: String
//    let title: String
//    let color: Color
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            Image(systemName: icon)
//                .font(.system(size: 24))
//                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//            
//            Text(title)
//                .font(.system(size: 24, design: .rounded).weight(.semibold))
//                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//            
//            Spacer()
//            
//            Image(systemName: "chevron.right")
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
//        }
//        .padding(.vertical, 28)
//        .padding(.horizontal, 24)
//        .background(color)
//        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//        .shadow(color: Palette.shadow, radius: 6, x: 0, y: 4)
//    }
//}
//
