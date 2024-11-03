//
//  ContentView.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            TabView {
                
                DashboardView()
                    .tabItem {
                        Image(systemName: "moon.stars.fill")
                        Text("Dashboard")
                    }
                
                TransactionsView()
                    .tabItem {
                        Image(systemName: "sparkles")
                        Text("Transactions")
                    }
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Profile")
                    }
                ChatBotView()
                    .tabItem {
                        Image(systemName: "face.smiling")
                        Text("Advisor")
                    }
                
            }
            .accentColor(.purple)
        } else {
            LoginView()
        }
    }
}


#Preview {
    ContentView()
       
}
