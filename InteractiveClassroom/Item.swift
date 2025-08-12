//
//  Item.swift
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/12.
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
