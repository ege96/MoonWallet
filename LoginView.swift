//
//  LoginView.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isCreatingAccount = false
    
    var body: some View {
        ZStack {
            StarryBackground()
            
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .center) {
                    HStack {
                        Image("Moon")
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 100))
                            .frame(width: 225, height: 225)
                    }
                }
                
                HStack {
                    Text(isCreatingAccount ? "Create Account" : "Login to MoonWallet")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding()
                    
                    
                }
                
    
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
    
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding()
                }
                
                // Acc Button
                Button(action: {
                    isCreatingAccount ? createAccount() : loginUser()
                }) {
                    Text(isCreatingAccount ? "Create Account" : "Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.gray)
                        .cornerRadius(10)
                }
                
                // Acc Creation
                Button(action: {
                    isCreatingAccount.toggle()
                }) {
                    Text(isCreatingAccount ? "Already have an account? Login" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
    }
    
    // Login function (Firebase)
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            isLoggedIn = true
        }
    }
    
    // Create account function (Firebase)
    private func createAccount() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            isLoggedIn = true
        }
    }
}

#Preview {
    LoginView()
}
