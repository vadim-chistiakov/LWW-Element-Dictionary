//
//  LWWElementDictionaryDefault.swift
//  LWW-Element-Dictionary
//
//  Created by Vadim Chistiakov on 06.12.2024.
//

import Foundation

// Last-Write-Wins-Element-Dictionary implementation
struct LWWElementDictionaryImplementation<Key: Hashable, Value>: LWWElementDictionaryInterface {
    
    typealias Element = (value: Value, timestamp: Date)
    
    private var addSet: ThreadSafeDictionary<Key, Element>
    private var removeSet: ThreadSafeDictionary<Key, Date>

    init() {
        self.addSet = ThreadSafeDictionary<Key, Element>()
        self.removeSet = ThreadSafeDictionary<Key, Date>()
    }
    
    func add(key: Key, value: Value, timestamp: Date = Date()) {
        // Do nothing if existing timestamp bigger than new one
        if let (_, existingTimestamp) = addSet[key], existingTimestamp > timestamp {
            return
        }
        addSet[key] = Element(value: value, timestamp: timestamp)
    }

    func remove(key: Key, timestamp: Date = Date()) {
        // Do nothing if existing timestamp bigger than target
        if let existingTimestamp = removeSet[key], existingTimestamp > timestamp {
            return
        }
        removeSet[key] = timestamp
    }

    func lookup(key: Key) -> Value? {
        guard let element = addSet[key],
              let removeTimestamp = removeSet[key] else {
            return addSet[key]?.value
        }
        return element.timestamp > removeTimestamp ? element.value : nil
    }

    func merge(with other: LWWElementDictionaryImplementation) {
        for (key, (value, timestamp)) in other.addSet {
            if let (_, existingTimestamp) = addSet[key], existingTimestamp > timestamp {
                continue
            }
            addSet[key] = Element(value: value, timestamp: timestamp)
        }

        for (key, timestamp) in other.removeSet {
            if let existingTimestamp = removeSet[key], existingTimestamp > timestamp {
                continue
            }
            removeSet[key] = timestamp
        }
    }

    func getAll() -> [Key: Value] {
        var result: [Key: Value] = [:]
        for (key, (value, addTimestamp)) in addSet {
            if let removeTimestamp = removeSet[key], removeTimestamp >= addTimestamp {
                continue
            }
            result[key] = value
        }
        return result
    }
}
