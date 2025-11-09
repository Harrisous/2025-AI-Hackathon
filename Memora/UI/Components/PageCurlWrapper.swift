//
//  PageCurlWrapper.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import UIKit

// Wrapper to present SwiftUI view with UIKit page curl
struct PageCurlPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let content: () -> AnyView
    
    func makeUIViewController(context: Context) -> PageCurlPresenterViewController {
        let controller = PageCurlPresenterViewController()
        controller.coordinator = context.coordinator
        controller.content = content
        controller.onDismiss = {
            isPresented = false
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PageCurlPresenterViewController, context: Context) {
        uiViewController.content = content
        
        if isPresented {
            if uiViewController.presentedViewController == nil {
                uiViewController.presentPageCurl()
            }
        } else {
            if uiViewController.presentedViewController != nil {
                uiViewController.dismissPageCurl()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    class Coordinator {
        @Binding var isPresented: Bool
        
        init(isPresented: Binding<Bool>) {
            self._isPresented = isPresented
        }
    }
}

class PageCurlPresenterViewController: UIViewController {
    var coordinator: PageCurlPresenter.Coordinator?
    var content: (() -> AnyView)?
    var onDismiss: (() -> Void)?
    var hostingController: UIHostingController<AnyView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
    
    func presentPageCurl() {
        guard let content = content else { return }
        
        // Create hosting controller with the SwiftUI view
        let hostingController = UIHostingController(rootView: content())
        
        // Set up modal presentation with page curl
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .partialCurl
        
        // Store reference
        self.hostingController = hostingController
        
        // Present with page curl animation
        present(hostingController, animated: true, completion: nil)
    }
    
    func dismissPageCurl() {
        if let hostingController = hostingController {
            hostingController.dismiss(animated: true) { [weak self] in
                self?.hostingController = nil
                self?.onDismiss?()
            }
        } else if let presented = presentedViewController {
            presented.dismiss(animated: true) { [weak self] in
                self?.onDismiss?()
            }
        }
    }
}

// Alternative approach: Use a custom transition coordinator
class PageCurlTransitionCoordinator: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PageCurlAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PageCurlDismissAnimator()
    }
}

class PageCurlAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(toView)
        
        // Create page curl animation
        let transition = CATransition()
        transition.type = CATransitionType(rawValue: "pageCurl")
        transition.subtype = .fromRight
        transition.duration = transitionDuration(using: transitionContext)
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        containerView.layer.add(transition, forKey: "pageCurl")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration(using: transitionContext)) {
            transitionContext.completeTransition(true)
        }
    }
}

class PageCurlDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        
        let containerView = transitionContext.containerView
        
        // Create reverse page curl animation
        let transition = CATransition()
        transition.type = CATransitionType(rawValue: "pageUnCurl")
        transition.subtype = .fromLeft
        transition.duration = transitionDuration(using: transitionContext)
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        containerView.layer.add(transition, forKey: "pageUnCurl")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration(using: transitionContext)) {
            fromView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}

