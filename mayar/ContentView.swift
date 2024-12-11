import SwiftUI

struct ContentView: View {
    @State private var items: [AudioItem] = []
    @State private var isFetching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                if items.isEmpty && !isFetching {
                    Text("No items found. Tap 'Fetch Items' to load.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Price: $\(item.price, specifier: "%.2f")")
                                    .font(.subheadline)
                                Text("Stock: \(item.stock)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Audio Items")
            .toolbar {
                ToolbarItem {
                    Button(action: { Task { await fetchData() } }) {
                        Label("Fetch Items", systemImage: "arrow.down")
                    }
                }
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

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }

            // Parse JSON manually
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let result = json["result"] as? [[String: Any]] {
                let parsedItems = try result.compactMap { item -> AudioItem? in
                    guard
                        let idString = item["id"] as? String,
                        let id = Int(idString),
                        let name = item["name"] as? String,
                        let description = item["description"] as? String,
                        let priceString = item["price"] as? String,
                        let price = Double(priceString),
                        let stockString = item["stock"] as? String,
                        let stock = Int(stockString),
                        let image = item["image"] as? String
                    else {
                        return nil
                    }
                    return AudioItem(id: id, name: name, description: description, price: price, stock: stock, image: image)
                }
                DispatchQueue.main.async {
                    withAnimation {
                        self.items = parsedItems
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

struct ItemDetailView: View {
    let item: AudioItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: "\(APIConfig.baseImageURL)\(item.image)")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                Text(item.name)
                    .font(.largeTitle)
                    .bold()
                Text("Price: $\(item.price, specifier: "%.2f")")
                    .font(.title2)
                Text("Stock: \(item.stock)")
                    .font(.subheadline)
                Divider()
                Text(item.description)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle(item.name)
    }
}

struct AudioItem: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let price: Double
    let stock: Int
    let image: String
    
    // Default initializer for manual initialization
    init(id: Int, name: String, description: String, price: Double, stock: Int, image: String) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.stock = stock
        self.image = image
    }
}

struct APIConfig {
    static let baseURL = "https://mayar.abertay.ac.uk/~2202089/cmp306/coursework/block1/AudioEquipment/model/index.php"
    static let baseImageURL = "https://mayar.abertay.ac.uk/images/"
    static let requestID = "510573"
}

#Preview {
    ContentView()
}
