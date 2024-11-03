//
//  ProfileView.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//

import LinkKit
import SwiftUI
import FirebaseFunctions

struct PlaidView: View {
    @State private var isPresentingLink = false
    @State private var error: String? = nil
    @State private var isLoading = false
    @StateObject private var linkManager = PlaidLinkManager()
    
    var body: some View {
        ZStack(alignment: .leading) {
            backgroundColor.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("WELCOME")
                    .foregroundColor(plaidBlue)
                    .font(.system(size: 12, weight: .bold))
                
                Text("Link Your Account")
                    .font(.system(size: 32, weight: .light))
                
                versionInformation()
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Button(action: {
                        initiateLink()
                    }, label:  {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 312)
                        } else {
                            Text("Open Plaid Link")
                                .font(.system(size: 17, weight: .medium))
                                .frame(width: 312)
                        }
                    })
                    .padding()
                    .foregroundColor(.white)
                    .background(plaidBlue)
                    .cornerRadius(4)
                    .disabled(isLoading)
                }
                .frame(height: 56)
            }
            .padding(EdgeInsets(top: 16, leading: 32, bottom: 0, trailing: 32))
        }
        .onChange(of: linkManager.linkToken) { token in
            if let token = token {
                createAndPresentLink(with: token)
            }
        }
        .onChange(of: linkManager.error) { newError in
            if let errorStr = newError {
                error = errorStr
                isLoading = false
            }
        }
        .fullScreenCover(
            isPresented: $isPresentingLink,
            onDismiss: { isPresentingLink = false },
            content: {
                if let linkController = linkManager.linkController {
                    linkController
                        .ignoresSafeArea(.all)
                } else {
                    Text("Error: LinkController not initialized")
                }
            }
        )
    }
    
    private let backgroundColor: Color = Color(
        red: 247 / 256,
        green: 249 / 256,
        blue: 251 / 256,
        opacity: 1
    )
    
    private let plaidBlue: Color = Color(
        red: 0,
        green: 191 / 256,
        blue: 250 / 256,
        opacity: 1
    )
    
    private func versionInformation() -> some View {
        let linkKitBundle  = Bundle(for: PLKPlaid.self)
        let linkKitVersion = linkKitBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        let linkKitBuild   = linkKitBundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String)!
        let linkKitName    = linkKitBundle.object(forInfoDictionaryKey: kCFBundleNameKey as String)!
        let versionText = "\(linkKitName) \(linkKitVersion)+\(linkKitBuild)"
        
        return Text(versionText)
            .foregroundColor(.gray)
            .font(.system(size: 12))
    }
    
    private func initiateLink() {
        isLoading = true
        error = nil
        linkManager.initiatePlaidLink()
    }
    
    private func createAndPresentLink(with token: String) {
        let configuration = createLinkTokenConfiguration(token: token)
        
        // Create handler with configuration
        let createResult = Plaid.create(configuration)
        
        switch createResult {
        case .failure(let createError):
            error = "Link Creation Error: \(createError.localizedDescription)"
            isLoading = false
        case .success(let handler):
            linkManager.linkController = LinkController(handler: handler)
            isLoading = false
            isPresentingLink = true
        }
    }
    
    private func createLinkTokenConfiguration(token: String) -> LinkTokenConfiguration {
        var linkConfiguration = LinkTokenConfiguration(token: token) { success in
            print("public-token: \(success.publicToken) metadata: \(success.metadata)")
            linkManager.storePlaidData(publicToken: success.publicToken)
            isPresentingLink = false
        }
        
        linkConfiguration.onExit = { exit in
            if let error = exit.error {
                print("exit with \(error)\n\(exit.metadata)")
            } else {
                print("exit with \(exit.metadata)")
            }
            isPresentingLink = false
        }
        
        linkConfiguration.onEvent = { event in
            print("Link Event: \(event)")
        }
        
        return linkConfiguration
    }
}

class PlaidLinkManager: ObservableObject {
    @Published var linkToken: String?
    @Published var error: String?
    @Published var isLoading = false
    var linkController: LinkController?
    
    private let functions = Functions.functions(region: "us-central1")
    
    func initiatePlaidLink() {
        isLoading = true
        error = nil
        
        functions
            .httpsCallable("initiate_plaid_link")
            .call() { [weak self] result, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        return
                    }
                    
                    if let data = result?.data as? [String: Any],
                       let linkToken = data["link_token"] as? String {
                        self.linkToken = linkToken
                    } else {
                        self.error = "Invalid response format"
                    }
                }
            }
    }
    
    func storePlaidData(publicToken: String) {
        isLoading = true
        error = nil
        
        let data = ["public_token": publicToken]
        
        functions
            .httpsCallable("store_plaid_data")
            .call(data) { [weak self] result, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        return
                    }
                    print("Successfully stored Plaid data")
                }
            }
    }
}

#Preview {
    PlaidView()
}
