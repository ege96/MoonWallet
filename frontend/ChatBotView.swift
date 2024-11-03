//
//  ChatBotView.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//


import SwiftUI
import FirebaseFunctions

struct ChatBotView: View {
    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    private let functions = Functions.functions(region: "us-central1")

    var body: some View {
        VStack {
            Text("🚀   Galaxy Advisor   🌌")
                .font(.title)
                .foregroundColor(.white)
                .padding(.top)
                .bold()
            
            ScrollView {
                ForEach(messages) { message in
                    MessageRow(message: message)
                }
            }
            .background(Color.clear)
            .scrollContentBackground(.hidden)
            .padding(.horizontal)

            HStack {
                TextField("Send a prompt to the stars...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.purple)

                Button(action: sendMessage) {
                    Text("Launch")
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .background(Color.purple)
                        .cornerRadius(10)
                        .font(.title)
                }
            }
            .padding()
        }
        .background(ChatBotBackground().edgesIgnoringSafeArea(.all))
        .onAppear {
            addMessage(from: "ChatGPT", content: "🌠 Welcome! I am your personal financial advisor from a galaxy far far away! How can I assist you on your journey today?")
        }
    }

    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        addMessage(from: "User", content: userInput)
        getAIResponse(for: userInput)
        
        // Clear the input
        userInput = ""
    }

    private func getAIResponse(for message: String) {
        functions
            .httpsCallable("get_ai_assistance")
            .call(["message": message]) { result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error getting AI response: \(error.localizedDescription)")
                        addMessage(from: "ChatGPT", content: "🚨 Error: Message could not be sent to ChatGPT.")
                        return
                    }
                    
                    if let data = result?.data as? [String: Any],
                       let response = data["response"] as? String {
                        addMessage(from: "ChatGPT", content: response)
                    } else {
                        addMessage(from: "ChatGPT", content: "🤖 Sorry, I didn't understand that.")
                    }
                }
            }
    }

    private func addMessage(from sender: String, content: String) {
        let message = ChatMessage(id: UUID(), sender: sender, content: content)
        messages.append(message)
    }
}

struct MessageRow: View {
    var message: ChatMessage

    var body: some View {
        HStack {
            if message.sender == "User" {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(Image(systemName: "moon.stars.fill")
                                .foregroundColor(.white)
                                .padding(5), alignment: .topTrailing)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(Image(systemName: "rocket.fill")
                                .foregroundColor(.white)
                                .padding(5), alignment: .topLeading)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct ChatMessage: Identifiable {
    var id: UUID
    var sender: String
    var content: String
}

#Preview {
    ChatBotView()
}
