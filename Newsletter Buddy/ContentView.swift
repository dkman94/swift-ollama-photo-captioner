//
//  ContentView.swift
//  Newsletter Buddy
//
//  Created by Deepak Kumar on 2/9/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @ObservedObject var viewModel: NewsLetterViewModel = NewsLetterViewModel()
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            HStack {
                VStack {
                    Text("Drop your image here")
                        .font(.system(size: 18.0, weight: .bold, design: .rounded))
                    viewModel.droppedImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .onDrop(of: [UTType.image], delegate: self)
                }
                VStack {
                    ZStack {
                        if viewModel.isGeneratingResponse {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.4))
                                .overlay(
                                    ProgressView()
                                )
                                .frame(width: 600, height: 200)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.4))
                                .overlay(
                                    Text(viewModel.modelResponse)
                                )
                                .frame(width: 600, height: 200)
                        }
                    }
                    if (viewModel.shouldShowDescriptionUpdateOption) {
                        HStack {
                            TextField(viewModel.descriptionUpdatePrompt, text: $viewModel.descriptionUpdateValue)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(4)
                                .frame(width: 400)
                                .padding(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                            Button {
                                viewModel.promptUpdateRequest()
                            } label: {
                                Image(systemName: "chevron.right.circle")
                            }

                        }
                    }
                }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            }
        }
    }
}


extension ContentView : DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        guard let providers = info.itemProviders(for: [UTType.fileURL.description]).first else { return false }
        providers.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
            if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                let image = NSImage(contentsOf: url)
                image?.size = CGSize(width: 300.0, height: 300.0)
                guard let nsImage = image else {
                    return
                }
                self.viewModel.imageData = NSData(contentsOf: url)
                DispatchQueue.main.async {
                    self.viewModel.droppedImage = Image(nsImage: nsImage)
                }
                self.viewModel.makePhotoInitializationRequest()
            }
        })
        return true
    }
    
    func dropEntered(info: DropInfo) {
        DispatchQueue.main.async {
            guard let inputDropZoneImage = NSImage(named: "inputDropZone") else {
                return
            }
            self.viewModel.droppedImage = Image(nsImage:inputDropZoneImage)
        }
    }
    
    func dropExited(info: DropInfo) {
        guard let inputNsImage = NSImage(named: "input") else {
            return
        }
        DispatchQueue.main.async {
            self.viewModel.droppedImage = Image(nsImage: inputNsImage)
        }
    }
}
