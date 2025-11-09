//
//  CaregiverDashboardView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import SafariServices

struct CaregiverDashboardView: View {
    @State private var sidebarExpanded = false
    let urlString = "https://sparklingly-kempt-terese.ngrok-free.dev/"
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    Palette.paper.ignoresSafeArea()
                    
                    SafariView(url: URL(string: urlString)!)
                }
                
                FoldableSidebar(isExpanded: $sidebarExpanded)
            }
        }
        .navigationBarHidden(true)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    NavigationStack {
        CaregiverDashboardView()
    }
}

