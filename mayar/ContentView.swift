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
                                Text("Price: $\(item.price, specifier: "%.2f")") //specifier ensures that it has 2 decimal points
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
                        Label("Fetch Items", systemImage: "arrow.counterclockwise.circle")
                    }
                }
                ToolbarItem{
                    Button(action: { Task { await fetchData() } }) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
            }
            .onAppear {
                Task { await fetchData() }
            }
            .alert("Error", isPresented: Binding<Bool>( //this will display an alert if there is an error and clear it when okay is clicked
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
        guard let url = URL(string: APIConfig.baseURL) else { //if no url then stop and display
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url) //get the url to send the request to
        request.httpMethod = "POST" //setup the request
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "getAllItems",
            "id": APIConfig.requestID
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody) //convert the request to json

        isFetching = true
        defer { isFetching = false } //defer will run just before the function closes

        do {
            let (data, response) = try await URLSession.shared.data(for: request) //send the request and get the response
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { //if the response is not 200 then stop and display error
                errorMessage = "Invalid server response"
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) { //print the response if one is given
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
                    return AudioItem(id: id, name: name, description: description, price: price, stock: stock, image: image) //return the parsed data
                }
                DispatchQueue.main.async { //tell the os to run this on the main thread, as otherwise UI won't update properly
                    withAnimation { //this will animate the items being updated
                        self.items = parsedItems
                    }
                }
            } else { //if the json is not valid then display error
                errorMessage = "Failed to parse JSON"
            }
        } catch { //if there is an error then display it
            errorMessage = "Error fetching data: \(error.localizedDescription)"
        }
    }
}

struct ItemDetailView: View {
    let item: AudioItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Display the image
                if URL(string: "\(APIConfig.baseImageURL)\(item.image)") != nil {
                    AsyncImage(url: URL(string: "\(APIConfig.baseImageURL)\(item.image)")) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 500, maxHeight: 500) // Limit the size
                    } placeholder: {
                        Color.gray
                            .frame(maxWidth: 500, maxHeight: 500) // Match placeholder size
                    }
                } else {
                    Text("Image not available")
                        .foregroundColor(.secondary)
                }

                // Display the item's details
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

struct AudioItem: Identifiable, Codable { //struct for the audio item
    let id: Int
    let name: String
    let description: String
    let price: Double
    let stock: Int
    let image: String
    
    // Default initializer for manual initialization
    init(id: Int, name: String, description: String, price: Double, stock: Int, image: String) { //this is used whenever the struct is initialized manually
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
    static let baseImageURL = "https://mayar.abertay.ac.uk/~2202089/cmp306/coursework/block1/AudioEquipment/image/"
    static let requestID = "510573"
}

#Preview {
    ContentView()
}
