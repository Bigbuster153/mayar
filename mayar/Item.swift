//
//  Item.swift
//  mayar
//
//  Created by Ethan Goldwyre on 11/12/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
