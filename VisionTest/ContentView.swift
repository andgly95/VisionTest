import SwiftUI
import RealityKit
import RealityKitContent

struct Message: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            ImagesView()
                .tabItem {
                    Label("Images", systemImage: "photo")
                }
        }
    }
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var isApiError: Bool = false
    @State private var isChangingModel: Bool = false
    @State private var model: String = "gpt-4-turbo"
    
    let modelOptions = ["gpt-4-turbo", "gpt-3.5-turbo"]
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        HStack {
                            Text(message.role.capitalized)
                                .font(.headline)
                                .foregroundColor(message.role == "assistant" ? .green : .yellow)
                            Text(message.content)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(8)
            }
            
            HStack {
                TextField("Enter a message", text: $inputText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button(action: handleSendMessage) {
                    Text("Send")
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(inputText.isEmpty || isLoading)
                }
            }
            
            if isChangingModel {
                Picker("Model", selection: $model) {
                    ForEach(modelOptions, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            } else {
                Button(model) {
                    isChangingModel = true
                }
                .foregroundColor(.white)
                .font(.caption)
            }
        }
        .padding()
        .onAppear(perform: fetchInitialMessage)
    }
    
    func fetchInitialMessage() {
        isLoading = true
        
        let url = URL(string: "https://f759-70-23-243-115.ngrok-free.app/generate_chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a chatbot. You are designed to assist users with their queries."
                ]
            ]
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
                DispatchQueue.main.async {
                    isApiError = true
                    isLoading = false
                }
                return
            }
            
            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                let assistantMessage = Message(role: "assistant", content: responseText)
                DispatchQueue.main.async {
                    messages = [assistantMessage]
                    isLoading = false
                }
            }
        }.resume()
    }
    
    func handleSendMessage() {
        let newMessage = Message(role: "user", content: inputText)
        isLoading = true
        
        let url = URL(string: "https://f759-70-23-243-115.ngrok-free.app/generate_chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages.map { ["role": $0.role, "content": $0.content] } + [["role": "user", "content": inputText]]
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }
            
            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                let newMessages = messages + [newMessage, Message(role: "assistant", content: responseText)]
                DispatchQueue.main.async {
                    messages = newMessages
                    inputText = ""
                    isLoading = false
                }
            }
        }.resume()
    }
}


struct ImagesView: View {
    @State private var prompt: String = ""
    @State private var generatedImage: String = ""
    @State private var isLoading: Bool = false
    @State private var model: String = "dall-e-3"
    @State private var showImageHistory: Bool = true
    @State private var imageHistory: [String] = []
    
    let modelOptions = ["dall-e-3", "dall-e-2"]
    
    var body: some View {
        VStack(spacing: 16) {
                VStack {
                    TextEditor(text: $prompt)
                        .cornerRadius(8)
                        .overlay(
                            Group {
                                if prompt.isEmpty {
                                    Text("Enter a prompt for the image generator")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 16)
                                        .padding(.top, 16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        )
                    
                    Button(action: handleGenerateImage) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Generate Image")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cornerRadius(50)
                    .disabled(prompt.isEmpty || isLoading)
                    
                    Picker("Model", selection: $model) {
                        ForEach(modelOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top)
                    
                    if !generatedImage.isEmpty {
                        AsyncImage(url: URL(string: generatedImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .border(Color.white, width: 8)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                    }
                }
            
            
            if !imageHistory.isEmpty {
                GroupBox {
                    VStack {
                        HStack {
                            Text("Image History")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                imageHistory = []
                                // TODO: Remove image history from local storage
                            }) {
                                Text("Clear History")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        if showImageHistory {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                                    ForEach(imageHistory, id: \.self) { item in
                                        Button(action: {
                                            generatedImage = item
                                        }) {
                                            AsyncImage(url: URL(string: item)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(height: 100)
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("Image history hidden")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            // TODO: Load image history from local storage
        }
    }
    
    func handleGenerateImage() {
        isLoading = true
        
        let url = URL(string: "https://f759-70-23-243-115.ngrok-free.app/generate_image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "size": "1024x1024",
            "quality": "standard",
            "n": 1
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    generatedImage = responseText
                    imageHistory.insert(responseText, at: 0)
                    // TODO: Save image history to local storage
                    isLoading = false
                }
            }
        }.resume()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
