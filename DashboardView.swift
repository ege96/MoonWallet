//
//  DashboardView.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//

import SwiftUI
import FirebaseFunctions
import Charts

class DashboardViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var totalIncome: Double = 0.0
    @Published var totalExpenses: Double = 0.0
    @Published var categoryData: [(name: String, totalAmount: Double)] = []
    
    private let functions = Functions.functions(region: "us-central1")
    
    init() {
        fetchTransactions()
    }
    
    private func fetchTransactions() {
        print("Fetching transactions for DashboardViewModel")
        
        functions
            .httpsCallable("get_transactions")
            .call { result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error calling Firebase function: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Successfully called Firebase function")
                    
                    if let data = result?.data as? [String: Any],
                       let transactionsArray = data["transactions"] as? [[String: Any]] {
                        print("Parsing transactions array in DashboardViewModel")
                        
                        var income: Double = 0.0
                        var expenses: Double = 0.0
                        var categoryTotals: [String: Double] = [:]
                        
                        transactionsArray.forEach { transactionDict in
                            let amount = transactionDict["amount"] as? Double ?? 0.0
                            let category = transactionDict["category"] as? String ?? "Uncategorized"
                            
                            if amount > 0 {
                                income += amount
                            } else {
                                expenses += abs(amount)
                            }

                            categoryTotals[category, default: 0.0] += abs(amount)
                        }
                        
                        self.totalIncome = expenses
                        self.totalExpenses = income
                        self.balance = expenses - income
                        self.categoryData = categoryTotals.map { (name: $0.key, totalAmount: $0.value) }
                        
                        print("Updated DashboardViewModel with income: \(income), expenses: \(expenses), and balance: \(self.balance)")
                    } else {
                        print("Error: transactions key is missing or is not an array")
                    }
                }
            }
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var hoveredCategory: (name: String, totalAmount: Double)? = nil

    var body: some View {
        ZStack {
            WhiteBackground()

            VStack(spacing: 20) {
                HStack {
                    Text("MoonWallet")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                

                Text("Balance")
                    .font(.title)
                    .font(.system(size: 19))
                    .foregroundColor(.white)
                
                HStack {
                    
                    Text("$\(viewModel.balance, specifier: "%.2f")")
                        .font(.system(size: 31, weight: .semibold))
                        .foregroundColor(.white)
                }
                Chart(viewModel.categoryData, id: \.name) { item in
                    let percentage = (item.totalAmount / viewModel.categoryData.map { $0.totalAmount }.reduce(0, +)) * 100
                    
                    SectorMark(
                        angle: .value("Total", item.totalAmount),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", item.name))
                    .cornerRadius(3)
                    
                    
                }
                
                .frame(height: 325)
                .padding()
               
                               
                
                
                // Income and Expenses
                HStack(alignment: .center) {
                    VStack {
                        Text("Income")
                            .foregroundColor(.white)
                        Text("$\(viewModel.totalIncome, specifier: "%.2f")")
                            .foregroundColor(.green)
                    }
                    Spacer()
                    VStack {
                        Text("Expenses")
                            .foregroundColor(.white)
                        Text("$\(viewModel.totalExpenses, specifier: "%.2f")")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(15)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    DashboardView()
}

