//
//  PageFlipNavigation.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import UIKit

// This file is no longer used - kept for reference only
// The app now uses standard NavigationStack navigation
struct PageFlipNavigationContainer: View {
    @State private var showRecall = false
    
    var body: some View {
        ZStack {
            // Use original HomeView (no arguments)
            HomeView()
            
            // Page curl presenter - overlays on top when showRecall is true
            PageCurlPresenter(isPresented: $showRecall) {
                AnyView(RecallPlaceholderViewWithDismiss(showRecall: $showRecall))
            }
        }
    }
}

// Page curl transition modifier using CATransition
struct PageCurlTransitionModifier: ViewModifier {
    let curled: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                PageCurlBackground(curled: curled)
                    .allowsHitTesting(false)
            )
    }
}

struct PageCurlBackground: UIViewRepresentable {
    let curled: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Apply page curl animation using CATransition
        let transition = CATransition()
        transition.type = CATransitionType(rawValue: "pageCurl")
        transition.subtype = .fromRight
        transition.duration = 0.6
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.fillMode = .both
        uiView.layer.add(transition, forKey: "pageCurlTransition")
    }
}

struct HomeViewWithNavigation: View {
    @Binding var showRecall: Bool
    @State private var appear = false
    @State private var rotate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.paper.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 20) {
                            Text("Hi, John!")
                                .font(.system(size: 72, design: .serif).weight(.semibold))
                                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                                .multilineTextAlignment(.center)
                            
                            Text(formattedToday())
                                .font(.system(size: 32, design: .serif))
                                .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        
                        Image("memory_ball")
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: min(geo.size.width * 0.7, 600),
                                height: min(geo.size.width * 0.7, 600)
                            )
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Palette.ink.opacity(0.06), lineWidth: 1)
                            )
                            .rotationEffect(.degrees(rotate ? 360 : 0))
                            .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: rotate)
                            .opacity(appear ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.15), value: appear)
                            .padding(.top, 90)
                        
                        // Start Recall button - triggers page flip
                        Button {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showRecall = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 28))
                                Text("Start Recall")
                            }
                            .foregroundColor(Color(red: 1.0, green: 1.0, blue: 1.0))
                            .font(.system(size: 30, design: .rounded).weight(.semibold))
                            .padding(.vertical, 24)
                            .padding(.horizontal, 40)
                            .background(Palette.recallButton)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Palette.shadow, radius: 10, x: 0, y: 6)
                            .accessibilityLabel("Start Recall")
                        }
                        .padding(.top, 10)
                        
                        // Menu buttons - use NavigationLink for other pages
                        VStack(spacing: 2) {
                            HStack(spacing: 0) {
                                NavigationLink {
                                    MemoryTestView()
                                } label: {
                                    MenuButton(icon: "brain.head.profile", title: "Memory Test", color: Palette.button)
                                        .padding(.vertical, 20)
                                        .padding(.trailing, 5)
                                }
                                
                                NavigationLink {
                                    MemoryGalleryView()
                                } label: {
                                    MenuButton(icon: "photo.on.rectangle", title: "Memory Gallery", color: Palette.button)
                                        .padding(.vertical, 20)
                                        .padding(.leading, 5)
                                }
                            }
                            .padding(.horizontal, 40)
                            
                            NavigationLink {
                                SettingsView()
                            } label: {
                                MenuButton(icon: "gearshape.fill", title: "Settings", color: Palette.settingColor)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 40)
                        }
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 5)
                }
            }
        }
        .onAppear {
            appear = true
            rotate = true
        }
        .navigationBarHidden(true)
    }
    
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

struct RecallPlaceholderViewWithDismiss: View {
    @Binding var showRecall: Bool
    @StateObject private var chatViewModel: ChatViewModel
    @State private var sidebarExpanded = false
    @Environment(\.dismiss) var dismiss
    
    init(showRecall: Binding<Bool>) {
        self._showRecall = showRecall
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(apiKey: APIConfig.openAIAPIKey))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Text("Memory Recall")
                            .font(.system(size: 72, design: .serif).weight(.semibold))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        ChatView(viewModel: chatViewModel)
                            .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.85)
                            .frame(maxWidth: 800)
                            .padding(.top, 50)
                        
                        Spacer()
                    }
                }
                
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // When view appears, ensure the binding is updated
            if !showRecall {
                showRecall = true
            }
        }
    }
}

