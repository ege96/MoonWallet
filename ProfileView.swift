//
//  ProfileView.swift
//  iWallet3
//
//  Created by Ronald Huang on 11/3/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = true
    @State private var isPresentingPlaid = false
    @State private var userEmail: String = "Loading..."
    @State private var isAccountLinked = false // Track account link status

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Add the background view inside the VStack, not ignoring safe areas
                SpaceBackgroundView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                     // Ensures background doesn't extend to tab area

                Spacer() // Adds space so the background doesn't extend to the bottom
            }
            
            VStack(spacing: 20) {
                // Profile Information Section
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email: \(userEmail)")
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack {
                        Text("Account Linked:")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(isAccountLinked ? "✅" : "❌")
                            .font(.headline)
                            .foregroundColor(isAccountLinked ? .green : .red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                
                Spacer().frame(height: 50)
                
                // Button to Link Bank Account
                Button(action: {
                    isPresentingPlaid = true
                    isAccountLinked = true
                }) {
                    Text("Link Your Bank Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .fullScreenCover(isPresented: $isPresentingPlaid) {
                    PlaidView()
                }
                
                Spacer()
                
                // Log Out Button
                Button(action: {
                    isLoggedIn = false
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .onAppear(perform: fetchUserInfo)
        }
    }

    private func fetchUserInfo() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "No email available"
        } else {
            userEmail = "User not logged in"
        }
    }
}

#Preview {
    ProfileView()
}

