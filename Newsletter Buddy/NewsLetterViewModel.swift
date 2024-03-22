//
//  NewsLetterViewModel.swift
//  Newsletter Buddy
//
//  Created by Deepak Kumar on 2/9/24.
//

import Foundation
import SwiftUI

class NewsLetterViewModel: ObservableObject {
    
    let localhostURL = "http://127.0.0.1:11434/api/chat"
    
    struct OllamaRequest: Codable {
        let model: String
        let messages: [OllamaChatMessage]
        let stream: Bool
        let keepAlive: String
        
        enum CodingKeys: String, CodingKey {
            case model = "model"
            case messages = "messages"
            case stream = "stream"
            case keepAlive = "keep_alive"
        }
    }
    
    struct OllamaChatMessage: Codable {
        let role: String
        let content: String
        var images: [String]? = nil
        
        enum CodingKeys: String, CodingKey {
            case role = "role"
            case content = "content"
            case images = "images"
        }
    }
    
    struct OllamaResponse: Codable {
        let model: String
        let createdAt: String
        let message: OllamaChatMessage
        let done: Bool
        
        enum CodingKeys: String, CodingKey {
            case model = "model"
            case createdAt = "created_at"
            case message = "message"
            case done = "done"
        }
    }
    
    @Published var droppedImage: Image = Image(systemName: "wand.and.stars")
    @Published var modelResponse: String = "Prompt will generated here after uploading your image..."
    @Published var isGeneratingResponse: Bool = false
    @Published var shouldShowDescriptionUpdateOption = false
    var descriptionUpdatePrompt: String = "How would you like to update the description?"
    @Published var descriptionUpdateValue: String = "How would you like to update the description?"
    var imageData: NSData?
    
    private var messageHistory: [OllamaChatMessage] = []
    
    func makePhotoInitializationRequest() {
        DispatchQueue.main.async { [weak self] in
            self?.isGeneratingResponse = true
        }
        guard let url = URL(string: localhostURL) else {
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encoder = JSONEncoder()
            guard let imageData = imageData?.base64EncodedString(options: .endLineWithCarriageReturn) else {
                return
            }
            let attachedImageMessage = OllamaChatMessage(role: "user", content: "describe this image", images: [imageData])
            let requestBody = OllamaRequest(model: "llava", messages: [attachedImageMessage], stream: false, keepAlive: "30m")
            let data = try encoder.encode(requestBody)
            urlRequest.httpBody = data
            
            let request = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                
                guard error == nil else {
                    print("error is request \(error)")
                    return
                }
                
                if let data = data {
                    print(String(data: data, encoding: String.Encoding.utf8))
                    guard let decodedResponse = try? JSONDecoder().decode(OllamaResponse.self, from: data) else {
                        print("json decoding error")
                        return
                    }
                    self.messageHistory.append(attachedImageMessage)
                    self.messageHistory.append(decodedResponse.message)
                    DispatchQueue.main.async {
                        self.isGeneratingResponse = false
                        self.modelResponse = decodedResponse.message.content
                        self.shouldShowDescriptionUpdateOption = true
                    }
                }else {
                    print("data response error")
                }
            }
            request.resume()
            
        } catch {
            print("request error")
        }
    }
    
    func promptUpdateRequest() {
        guard let url = URL(string: localhostURL) else {
            return
        }
        self.isGeneratingResponse = true
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encoder = JSONEncoder()
            let promptUpdateMessage = OllamaChatMessage(role: "user", content: descriptionUpdateValue)
            messageHistory.append(promptUpdateMessage)
            let requestBody = OllamaRequest(model: "llava", messages: messageHistory, stream: false, keepAlive: "30m")
            let data = try encoder.encode(requestBody)
            urlRequest.httpBody = data
            
            let request = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                
                guard error == nil else {
                    print("error is request \(error)")
                    return
                }
                
                if let data = data {
                    print(String(data: data, encoding: String.Encoding.utf8))
                    guard let decodedResponse = try? JSONDecoder().decode(OllamaResponse.self, from: data) else {
                        print("json decoding error")
                        return
                    }
                    self.messageHistory.append(promptUpdateMessage)
                    self.messageHistory.append(decodedResponse.message)
                    DispatchQueue.main.async {
                        self.isGeneratingResponse = false
                        self.modelResponse = decodedResponse.message.content
                        self.shouldShowDescriptionUpdateOption = true
                    }
                }else {
                    print("data response error")
                }
            }
            request.resume()
            
        } catch {
            print("request error")
        }
    }
    
}
