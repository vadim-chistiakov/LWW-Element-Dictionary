//
//  LWWElementDictionaryInterface.swift
//  LWW-Element-Dictionary
//
//  Created by Vadim Chistiakov on 06.12.2024.
//

import Foundation

protocol LWWElementDictionaryInterface {
    associatedtype Key: Hashable
    associatedtype Value
    
    // Add or update a key-value pair with a timestamp
    func add(key: Key, value: Value, timestamp: Date)

    // Remove a key with a timestamp
    func remove(key: Key, timestamp: Date)

    // Lookup a value by key
    func lookup(key: Key) -> Value?

    // Merge two LWW-Element-Dictionaries
    func merge(with other: Self)

    // Get all current valid key-value pairs
    func getAll() -> [Key: Value]
}
