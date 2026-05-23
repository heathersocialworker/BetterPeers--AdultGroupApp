//
//  ContentView.swift
//  BetterEDU Resources
//
//  Created by McTyler Tong on 10/16/24.
//

import SwiftUI
import GoogleGenerativeAI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("BetterEDU Resources App Testing Push/Pull From XCode")
        }
        .padding()
        .onAppear {
            // This tells the app to run the test as soon as the screen loads
            testGemini()
        }
    }
    
    // Here is the function that talks to Gemini
    func testGemini() {
        // 1. Initialize the AI (MAKE SURE TO PASTE YOUR ACTUAL COPIED KEY BELOW!)
        let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: "AIzaSyCciJC2Dg6hoQ7jWggn2ewU8s45FsF7olE")
        
        // 2. Ask it a question!
        Task {
            do {
                let response = try await model.generateContent("Give me one good tip for college students in Nevada.")
                if let text = response.text {
                    print("🤖 Gemini says: \(text)")
                }
            } catch {
                print("❌ Error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
}
