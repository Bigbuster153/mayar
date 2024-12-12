//
//  mayarTests.swift
//  mayarTests
//
//  Created by Ethan Goldwyre on 11/12/2024.
//

import XCTest
@testable import mayar // Ensure you import the module containing the app's code

final class mayarTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup code: runs before each test method
        // This could be used to initialize mock data or reset states if needed
    }

    override func tearDownWithError() throws {
        // Teardown code: runs after each test method
        // Clean up resources if needed
    }

    // MARK: - JSON Parsing Tests

    func testValidJSONParsing() throws {
        // Normal test: valid JSON should be parsed correctly
        
        // Arrange
        let validJSON = """
        {
            "id": 1,
            "name": "Klipsch Reference Series R-41M",
            "description": "High-quality bookshelf speakers",
            "price": 299.99,
            "stock": 5,
            "image": "image1.jpg"
        }
        """.data(using: .utf8)!
        
        // Act
        do {
            let item = try JSONDecoder().decode(AudioItem.self, from: validJSON)
            
            // Assert
            XCTAssertEqual(item.id, 1, "ID should match")
            XCTAssertEqual(item.name, "Klipsch Reference Series R-41M", "Name should match")
            XCTAssertEqual(item.price, 299.99, "Price should match")
            XCTAssertEqual(item.stock, 5, "Stock should match")
            XCTAssertEqual(item.image, "image1.jpg", "Image filename should match")
        } catch {
            XCTFail("Failed to parse valid JSON: \(error)")
        }
    }

    func testInvalidJSONParsing() throws {
        // Exceptional test: invalid JSON (incorrect data types) should fail to parse
        
        // Arrange
        let invalidJSON = """
        {
            "id": "invalid",
            "name": "Klipsch Reference Series R-41M",
            "description": "High-quality bookshelf speakers",
            "price": "invalid",
            "stock": "invalid",
            "image": "image1.jpg"
        }
        """.data(using: .utf8)!
        
        // Act & Assert
        XCTAssertThrowsError(try JSONDecoder().decode(AudioItem.self, from: invalidJSON)) { error in
            // Assert that decoding failure produces the expected error type
            XCTAssertTrue(error is DecodingError, "Expected DecodingError but got \(error)")
        }
    }

    func testEmptyJSONParsing() throws {
        // Exceptional test: empty JSON should fail gracefully
        
        // Arrange
        let emptyJSON = Data() // Empty data
        
        // Act & Assert
        XCTAssertThrowsError(try JSONDecoder().decode(AudioItem.self, from: emptyJSON)) { error in
            // Assert that decoding failure produces the expected error type
            XCTAssertTrue(error is DecodingError, "Expected DecodingError but got \(error)")
        }
    }
    
    func testMalformedJSONParsing() throws {
        // Exceptional test: malformed JSON should fail to parse
        
        // Arrange
        let malformedJSON = """
        {
            "id": 1,
            "name": "Klipsch Reference Series R-41M"
        """.data(using: .utf8)!
        
        // Act & Assert
        XCTAssertThrowsError(try JSONDecoder().decode(AudioItem.self, from: malformedJSON)) { error in
            // Assert that decoding failure produces the expected error type
            XCTAssertTrue(error is DecodingError, "Expected DecodingError but got \(error)")
        }
    }

    // MARK: - URL Configuration Tests

    func testAPIBaseURL() throws {
        // Normal test: Verify the API base URL is valid
        
        // Arrange & Act
        let url = URL(string: APIConfig.baseURL)
        
        // Assert
        XCTAssertNotNil(url, "API base URL should be a valid URL")
        XCTAssertEqual(url?.absoluteString, "https://mayar.abertay.ac.uk/~2202089/cmp306/coursework/block1/AudioEquipment/model/index.php", "URL should match the expected base URL")
    }

    // MARK: - Performance Tests

    func testPerformanceFetchingItems() throws {
        // Performance test: Measure the time to fetch data from the API
        
        measure {
            // Arrange: Set up expectations for asynchronous tests
            let expectation = self.expectation(description: "Fetching data from API")
            
            Task {
                // Act: Simulate the fetch process
                await ContentView().fetchData() // Replace with your actual fetch function
                expectation.fulfill()
            }
            
            // Assert: Wait for the result
            waitForExpectations(timeout: 5, handler: nil)
        }
    }

    // MARK: - Extreme and Boundary Tests

    func testExtremePriceValue() throws {
        // Extreme test: Check if an extremely high price value is handled correctly
        
        // Arrange
        let extremePriceJSON = """
        {
            "id": 1,
            "name": "Expensive Audio Equipment",
            "description": "An extremely expensive item.",
            "price": 9999999.99,
            "stock": 1,
            "image": "expensive_item.jpg"
        }
        """.data(using: .utf8)!
        
        // Act
        do {
            let item = try JSONDecoder().decode(AudioItem.self, from: extremePriceJSON)
            
            // Assert
            XCTAssertEqual(item.price, 9999999.99, "Price should match the extreme value")
        } catch {
            XCTFail("Failed to parse extreme price JSON: \(error)")
        }
    }

    func testZeroStockItem() throws {
        // Boundary test: Check handling of zero stock
        
        // Arrange
        let zeroStockJSON = """
        {
            "id": 2,
            "name": "Out of Stock Speakers",
            "description": "Currently out of stock.",
            "price": 199.99,
            "stock": 0,
            "image": "out_of_stock.jpg"
        }
        """.data(using: .utf8)!
        
        // Act
        do {
            let item = try JSONDecoder().decode(AudioItem.self, from: zeroStockJSON)
            
            // Assert
            XCTAssertEqual(item.stock, 0, "Stock should be zero")
        } catch {
            XCTFail("Failed to parse zero stock JSON: \(error)")
        }
    }
    
    // Define a struct to match the top-level JSON structure
    struct ItemResponse: Codable {
        let result: [AudioItem]
    }

    
    func testLargeNumberOfItemsParsing() throws {
        // Extreme test: Test parsing a large array of items
        
        // Arrange: Create a large JSON array
        let largeJSON = """
        {
            "result": [
                {"id": 1, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 2, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 3, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 4, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 5, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 6, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 7, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 8, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 9, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 10, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 11, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 12, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 13, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 14, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 15, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 16, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 17, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 18, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 19, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 20, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 21, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 22, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 23, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 24, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 25, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 26, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 27, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"},
                {"id": 28, "name": "Item 1", "description": "Item description", "price": 100.00, "stock": 10, "image": "image1.jpg"},
                {"id": 29, "name": "Item 2", "description": "Item description", "price": 100.00, "stock": 10, "image": "image2.jpg"},
                {"id": 30, "name": "Item 3", "description": "Item description", "price": 100.00, "stock": 10, "image": "image3.jpg"}
            ]
        }
        """.data(using: .utf8)!
        
        // Act
            do {
                let response = try JSONDecoder().decode(ItemResponse.self, from: largeJSON)
                
                // Assert
                XCTAssertEqual(response.result.count, 30, "There should be 30 items in the result array")
            } catch {
                XCTFail("Failed to parse large JSON array: \(error)")
            }
        }
}
