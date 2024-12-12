import SwiftUI

struct ContentView: View {
    
    //global variables
    @State private var items: [AudioItem] = [] // List of items fetched from the server
    @State private var isFetching = false // Flag to indicate if data is being fetched
    @State private var errorMessage: String? // Error message to display in an alert
    @State private var searchID: String = "" // Text field for ID input
    
    var body: some View {
        NavigationView {
            VStack {
                
                // Search input field
                TextField("Enter ID to search", text: $searchID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List {
                    if items.isEmpty && !isFetching {
                        Text("No items found. Tap 'Search' or 'Refresh' to load.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("Price: $\(item.price, specifier: "%.2f")") //the specifier will format the price to 2 decimal places
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
                        Button(action: { Task { await fetchData() } }) { //call fetchdata when clicked
                            Label("Refresh", systemImage: "arrow.counterclockwise.circle")
                        }
                    }
                    ToolbarItem {
                        Button(action: { Task { await fetchItemByID(searchID: searchID) } }) { //call fetchItemByID when clicked
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    }
                }
                .onAppear {
                    Task { await fetchData() } // Fetch data when the view appears
                }
                .alert("Error", isPresented: Binding<Bool>(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { //if there is an error message, show the alert
                    Button("OK", role: .cancel) {}
                } message: {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                    }
                }
            }
        }
    }
    
    public func fetchData() async { //fetch data from the server
        
        guard let url = URL(string: APIConfig.baseURL) else { //check if the url is valid
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url) //setting up the request (json)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [ //request body, has to be in this order
            "jsonrpc": "2.0",
            "method": "getAllItems",
            "id": APIConfig.requestID
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody) //convert to json
        
        isFetching = true //set the fetching flag to true
        defer { isFetching = false } //defer will set to false when function is closing
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request) //fetch the data
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { //if the response is not okay, show an error
                errorMessage = "Invalid server response"
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) { //debugging, show the response from server
                print("Raw JSON response: \(jsonString)")
            }
            
            // Parse JSON
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
                    return AudioItem(id: id, name: name, description: description, price: price, stock: stock, image: image) //create an item object using the data pulled out of json
                }
                DispatchQueue.main.async { //ensure this is run on main thread to update UI, and animate changes
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
    
    private func fetchItemByID(searchID: String) async {
        
        guard let url = URL(string: APIConfig.baseURL) else { //check if the url is valid
            errorMessage = "Invalid URL"
            return
        }
        
        let requestBody: [String: Any] = [ //prepare the request body, has to be in this order
            "jsonrpc": "2.0",
            "method": "getItemById",
            "params": searchID,
            "id": APIConfig.requestID
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") //further setup
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody) //encode into json
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request) //fetch the data from the server
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { //if the response is not okay, show an error
                errorMessage = "Invalid server response"
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) { // Debugging, show the response from the server
                print("Raw JSON Response: \(responseString)") // Debugging
            }
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], // Parse JSON
               let result = json["result"] as? [String: Any] {
                
                // Extract relevant fields from the result
                if let id = result["id"] as? Int,
                   let name = result["name"] as? String,
                   let description = result["description"] as? String,
                   let price = result["price"] as? Double,
                   let stock = result["stock"] as? Int,
                   let image = result["image"] as? String {
                    
                    // Create an AudioItem object
                    let fetchedItem = AudioItem(
                        id: id,
                        name: name,
                        description: description,
                        price: price,
                        stock: stock,
                        image: image
                    )
                    
                    print("Fetched Item: \(fetchedItem)") // Debugging
                    // Update the UI with the fetched item
                    DispatchQueue.main.async {
                        self.items = [fetchedItem] // Replace list with the fetched item
                    }
                } else {
                    errorMessage = "Missing required fields in JSON response"
                }
            } else {
                errorMessage = "Failed to parse JSON"
            }
        } catch {
            errorMessage = "Error fetching data: \(error.localizedDescription)"
        }
    }
}

struct ItemDetailView: View { //view for an individual item selected
    let item: AudioItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if URL(string: "\(APIConfig.baseImageURL)\(item.image)") != nil { //check if the image is available
                    AsyncImage(url: URL(string: "\(APIConfig.baseImageURL)\(item.image)")) { image in //load the image by appending the image name to the location to look for it
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 500, maxHeight: 500)
                    } placeholder: { //if the image is not available or whilst loading, show a placeholder
                        Color.gray
                            .frame(maxWidth: 500, maxHeight: 500)
                    }
                } else { //if the image is not available, show text
                    Text("Image not available")
                        .foregroundColor(.secondary)
                }

                Text(item.name) //display the item details
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

struct AudioItem: Identifiable, Codable { //model for an audio item
    let id: Int
    let name: String
    let description: String
    let price: Double
    let stock: Int
    let image: String
}

struct APIConfig { //configuration for the API
    static let baseURL = "https://mayar.abertay.ac.uk/~2202089/cmp306/coursework/block1/AudioEquipment/model/index.php"
    static let baseImageURL = "https://mayar.abertay.ac.uk/~2202089/cmp306/coursework/block1/AudioEquipment/image/"
    static let requestID = "510573"
}

#Preview {
    ContentView()
}
