//
//  AddMemoryView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct AddMemoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var memoryStorage: MemoryStorage
    @State private var selectedImage: UIImage?
    @State private var personName: String = ""
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Photo area
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 300)
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No photo selected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section {
                    TextField("Person's Name", text: $personName)
                } header: {
                    Text("Person's Name")
                }
                
                Section {
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        }
                    }) {
                        Label("Take Picture", systemImage: "camera.fill")
                    }
                    
                    Button(action: {
                        showPhotoPicker = true
                    }) {
                        Label("Photo Album", systemImage: "photo.on.rectangle")
                    }
                }
                
                Section {
                    Button(action: {
                        saveMemory()
                    }) {
                        HStack {
                            Spacer()
                            Text("Upload")
                            Spacer()
                        }
                    }
                    .disabled(selectedImage == nil || personName.isEmpty)
                }
            }
            .navigationTitle("Add Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(selectedImage: $selectedImage)
            }
        }
    }
    
    private func saveMemory() {
        guard let image = selectedImage, !personName.isEmpty else { return }
        
        if memoryStorage.addMemory(personName: personName, image: image) {
            dismiss()
        }
    }
}

// Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddMemoryView(memoryStorage: MemoryStorage.shared)
}

