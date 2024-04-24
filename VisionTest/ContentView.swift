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
    var body: some View {
        Text("Images (TBD)")
            .font(.largeTitle)
            .foregroundColor(.gray)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
