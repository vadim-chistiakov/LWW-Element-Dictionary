//
//  ThreadSafetyDictionary.swift
//  LWW-Element-Dictionary
//
//  Created by Vadim Chistiakov on 06.12.2024.
//

import Foundation

final class ThreadSafeDictionary<Key: Hashable, Value>: Sequence {
    
    private var dictionary = [Key: Value]()
    private let queue = DispatchQueue(
        label: "com.goodnotes.threadsafe.Dictionary",
        attributes: .concurrent
    )

    subscript(key: Key) -> Value? {
        get {
            var value: Value?
            queue.sync {
                value = dictionary[key]
            }
            return value
        }
        set(newValue) {
            queue.async(flags: .barrier) { [weak self] in
                self?.dictionary[key] = newValue
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.dictionary.removeAll()
        }
    }

    func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            self?.dictionary.removeValue(forKey: key)
        }
    }

    func contains(key: Key) -> Bool {
        var contains = false
        queue.sync {
            contains = dictionary[key] != nil
        }
        return contains
    }

    var count: Int {
        var count = 0
        queue.sync {
            count = dictionary.count
        }
        return count
    }
    
    var values: [Value] {
        queue.sync {
            return Array(dictionary.values)
        }
    }
    
    // Sequence conformation

    typealias Iterator = Dictionary<Key, Value>.Iterator

    func makeIterator() -> Iterator {
        var snapshot: [Key: Value] = [:]
        queue.sync {
            snapshot = dictionary
        }
        return snapshot.makeIterator()
    }
}
