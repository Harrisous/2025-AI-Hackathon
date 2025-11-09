//
//  PDFViewer.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update if needed
    }
}

struct PDFKitView: View {
    let fileName: String
    
    private var pdfURL: URL? {
        // First try to find in main bundle
        if let url = Bundle.main.url(forResource: fileName, withExtension: "pdf") {
            return url
        }
        
        // Try to find in the project directory (for development)
        if let projectPath = Bundle.main.resourcePath {
            let filePath = (projectPath as NSString).appendingPathComponent("\(fileName).pdf")
            if FileManager.default.fileExists(atPath: filePath) {
                return URL(fileURLWithPath: filePath)
            }
        }
        
        return nil
    }
    
    var body: some View {
        Group {
            if let url = pdfURL {
                PDFViewer(url: url)
                    .background(Palette.paper)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.5))
                    
                    Text("PDF not found: \(fileName).pdf")
                        .font(.system(size: 20, design: .rounded))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Please ensure the PDF is added to the Xcode project and included in the app bundle.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
    }
}

