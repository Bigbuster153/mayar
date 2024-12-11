//
//  ContentView.swift
//  mayar
//
//  Created by Ethan Goldwyre on 11/12/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var isFetching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationSplitView {
            List {
                if items.isEmpty && !isFetching {
                    Text("No items found. Tap 'Fetch Items' to load.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: { Task { await fetchData() } }) {
                        Label("Fetch Items", systemImage: "arrow.down")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear {
            Task { await fetchData() }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func fetchData() async {
        guard let url = URL(string: APIConfig.baseURL) else {
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "getAllItems",
            "id": APIConfig.requestID
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        isFetching = true
        defer { isFetching = false }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Invalid server response"
                return
            }

            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = jsonResponse["result"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    withAnimation {
                        for itemData in result {
                            guard let timestampString = itemData["timestamp"] as? String,
                                  let timestamp = ISO8601DateFormatter().date(from: timestampString) else {
                                print("Invalid item data: \(itemData)")
                                continue
                            }
                            let newItem = Item(timestamp: timestamp)
                            modelContext.insert(newItem)
                        }
                    }
                }
            } else {
                errorMessage = "Failed to parse JSON"
            }
        } catch {
            errorMessage = "Error fetching data: \(error.localizedDescription)"
        }
    }
}

// API configuration struct
struct APIConfig {
    static let baseURL = "https://mayar.abertay.ac.uk/~2202089/cmp306/coursework/block1/AudioEquipment/model/index.php"
    static let requestID = "510573"
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
