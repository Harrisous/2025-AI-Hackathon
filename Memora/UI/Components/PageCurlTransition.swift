//
//  PageCurlTransition.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import UIKit

// UIKit wrapper for page curl transition
struct PageCurlViewController: UIViewControllerRepresentable {
    let content: () -> AnyView
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PageCurlContainerViewController {
        let controller = PageCurlContainerViewController()
        controller.content = content
        controller.isPresented = $isPresented
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PageCurlContainerViewController, context: Context) {
        uiViewController.updateContent(isPresented: isPresented)
    }
}

class PageCurlContainerViewController: UIViewController {
    var content: (() -> AnyView)?
    var isPresented: Binding<Bool>?
    private var hostingController: UIHostingController<AnyView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
    }
    
    func updateContent(isPresented: Bool) {
        guard let content = content else { return }
        
        if isPresented {
            presentPageCurl(content: content)
        } else {
            dismissPageCurl()
        }
    }
    
    private func presentPageCurl(content: () -> AnyView) {
        let hostingController = UIHostingController(rootView: content())
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .partialCurl
        
        // Animate the page curl
        self.present(hostingController, animated: true) {
            self.hostingController = hostingController
        }
    }
    
    private func dismissPageCurl() {
        if let hostingController = hostingController {
            hostingController.dismiss(animated: true) {
                self.hostingController = nil
            }
        }
    }
}

// Alternative: Use CATransition for page curl effect
struct PageCurlModifier: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .background(PageCurlView(isPresented: isPresented))
    }
}

struct PageCurlView: UIViewRepresentable {
    let isPresented: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented {
            // Apply page curl animation
            let transition = CATransition()
            transition.type = .reveal
            transition.subtype = .fromRight
            transition.duration = 0.6
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            uiView.layer.add(transition, forKey: "pageCurl")
        }
    }
}

