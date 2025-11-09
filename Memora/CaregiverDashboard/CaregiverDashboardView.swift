//
//  CaregiverDashboardView.swift
//  Memerai
//
//  Created by Rae Wang on 11/9/25.
//


//
//  CaregiverDashboardView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import SafariServices

struct CaregiverDashboardView: View {
    let urlString = "https://caregiver-dashboard-c0zm9isss-timxjls-projects.vercel.app/"
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.paper.ignoresSafeArea()
                
                SafariView(url: URL(string: urlString)!)
                    //.padding(.top,20)
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
