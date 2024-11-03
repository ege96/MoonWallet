//
//  TransactionsView.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFunctions

struct TransactionsView: View {
    @State private var monthlyTransactions: [(month: String, transactions: [PlaidTransaction], totalSpent: Double, balance: Double)] = []
    private let functions = Functions.functions(region: "us-central1")
    
    var body: some View {
        ZStack {
            StarryBackground() // Custom background
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                Text("Recent Transactions")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top)
                    .bold()
                
                List {
                    ForEach(monthlyTransactions, id: \.month) { monthData in
                        // Month header with balance
                        HStack {
                            Spacer()
                            Text(monthData.month)
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                            Text("$\(monthData.balance, specifier: "%.2f")")
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .cornerRadius(8)
                        .listRowInsets(EdgeInsets()) // Ensures header has padding similar to rows
                        .listRowBackground(Color.clear) // Makes header background transparent
                        
                        // Transactions for the month
                        ForEach(monthData.transactions) { transaction in
                            TransactionRow(title: transaction.name, amount: transaction.amount)
                                .listRowBackground(Color.clear) // Makes individual row backgrounds clear
                        }
                        
                        
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear) // Ensures the List itself has a clear background
                
                Spacer()
            }
            .padding(.horizontal)
            .onAppear(perform: fetchTransactions)
        }
    }
    
    private func fetchTransactions() {
        print("Starting fetchTransactions")
        
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
                        print("Parsing transactions array")
                        
                        let transactions = transactionsArray.compactMap { transactionDict -> PlaidTransaction? in
                            let transaction_id = transactionDict["transaction_id"] as? String ?? UUID().uuidString
                            let account_id = transactionDict["account_id"] as? String ?? ""
                            let amount = transactionDict["amount"] as? Double ?? 0.0
                            let category = transactionDict["category"] as? String ?? "Uncategorized"
                            let date = (transactionDict["date"] as? Timestamp)?.dateValue() ?? Date()
                            let name = transactionDict["name"] as? String ?? "Unknown"
                            let payment_channel = transactionDict["payment_channel"] as? String ?? "Unknown"
                            let pending = transactionDict["pending"] as? Bool ?? false
                            let subcategory = transactionDict["subcategory"] as? String ?? ""
                            let timestamp = (transactionDict["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            let merchant_name = transactionDict["merchant_name"] as? String ?? "Unknown Merchant"
                            let logo = transactionDict["logo"] as? String ?? ""
                            
                            return PlaidTransaction(
                                id: transaction_id,
                                account_id: account_id,
                                amount: amount,
                                date: date,
                                name: name,
                                merchant_name: merchant_name,
                                payment_channel: payment_channel,
                                pending: pending,
                                category: category,
                                subcategory: subcategory,
                                timestamp: timestamp,
                                logo: logo
                            )
                        }
                        
                        // Sort transactions by date in descending order
                        let sortedTransactions = transactions.sorted { $0.date > $1.date }
                        
                        // Group transactions by month and calculate total spent and balance per month
                        var balance = 0.0
                        let groupedByMonth = Dictionary(grouping: sortedTransactions) { transaction -> String in
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MMMM yyyy"
                            return dateFormatter.string(from: transaction.date)
                        }
                        
                        self.monthlyTransactions = groupedByMonth.map { (month, transactions) in
                            let totalSpent = transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
                            
                            // Month balance
                            let monthBalance = transactions.reduce(balance) { currentBalance, transaction in
                                if transaction.amount > 0 {
                                    return currentBalance + transaction.amount
                                } else {
                                    return currentBalance - transaction.amount
                                }
                            }
                            

                            balance = monthBalance
                            
                            return (month: month, transactions: transactions, totalSpent: totalSpent, balance: monthBalance)
                        }.sorted { $0.month > $1.month }
                        
                        print("Processed monthly transactions: \(self.monthlyTransactions)")
                    } else {
                        print("Error: transactions key is missing or is not an array")
                    }
                }
            }
    }
}

// Displays each transaction's name and amount
struct TransactionRow: View {
    var title: String
    var amount: Double
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text(amount < 0 ? "$\(abs(amount), specifier: "%.2f")" : "-$\(amount, specifier: "%.2f")")
                .foregroundColor(amount < 0 ? .green : .red)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct PlaidTransaction: Codable, Identifiable {
    var id: String
    let account_id: String
    let amount: Double
    let date: Date
    let name: String
    let merchant_name: String?
    let payment_channel: String
    let pending: Bool
    let category: String
    let subcategory: String?
    let timestamp: Date
    let logo: String?
}

#Preview {
    TransactionsView()
}
