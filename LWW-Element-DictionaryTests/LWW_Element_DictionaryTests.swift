//
//  LWW_Element_DictionaryTests.swift
//  LWW-Element-DictionaryTests
//
//  Created by Vadim Chistiakov on 06.12.2024.
//

import XCTest
@testable import LWW_Element_Dictionary

final class LWWElementDictionaryTests: XCTestCase {
    
    var dictionary: LWWElementDictionaryImplementation<String, String>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        dictionary = LWWElementDictionaryImplementation<String, String>()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        dictionary = nil
    }
    
    func testAddAndLookup() {
        // Given
        let key = "key"
        let value = "Goodnotes"
        
        // When
        dictionary.add(key: key, value: value)
        
        // Then
        XCTAssertEqual(dictionary.lookup(key: key), value)
    }

    func testUpdateValue() {
        // Given
        let key = "key"
        let value = "Goodnotes"
        let newValue = "Bestnotes"
        
        // When
        dictionary.add(key: key, value: value)
        dictionary.add(key: key, value: newValue, timestamp: Date().addingTimeInterval(10))
        
        // Then
        XCTAssertEqual(dictionary.lookup(key: key), newValue)
    }

    func testRemoveKey() {
        // Given
        let key = "key"
        let value = "Goodnotes"
        
        // When
        dictionary.add(key: key, value: value)
        dictionary.remove(key: key, timestamp: Date().addingTimeInterval(5))
        
        // Then
        XCTAssertNil(dictionary.lookup(key: key))
    }

    func testMergeDictionaries() {
        // Given
        let key = "key"
        let value = "Goodnotes"
        let newValue = "Best"
        let newDict = LWWElementDictionaryImplementation<String, String>()
        let timestamp1 = Date()
        let timestamp2 = Date().addingTimeInterval(10)

        // When
        dictionary.add(key: key, value: value, timestamp: timestamp1)
        newDict.add(key: key, value: newValue, timestamp: timestamp2)

        // Then
        dictionary.merge(with: newDict)
        XCTAssertEqual(dictionary.lookup(key: key), newValue)
    }

    func testCRDTProperties() {
        // Given
        let dict2 = LWWElementDictionaryImplementation<String, String>()
        let key = "key"
        let value = "Goodnotes"
        let newValue = "Best"
        
        // When
        // Ensure state-based convergence
        dictionary.add(key: key, value: value, timestamp: Date())
        dict2.add(key: key, value: newValue, timestamp: Date().addingTimeInterval(5))

        dictionary.merge(with: dict2)
        dict2.merge(with: dictionary)

        // Then
        XCTAssertEqual(dictionary.lookup(key: key), dict2.lookup(key: key))
    }
    
    func testThreadSafety() {
        // Given
        let globalKey = "key"
        let expectation = XCTestExpectation(
            description: "Concurrent operations should complete without crashing or inconsistent state"
        )
        
        let dispatchQueue = DispatchQueue(label: "com.example.testQueue", attributes: .concurrent)
        let group = DispatchGroup()
        
        // Number of operations and threads
        let operationCount = 10_000
        let threadCount = 4
        
        // When
        for thread in 1...threadCount {
            group.enter()
            dispatchQueue.async { [weak self] in
                for i in 0..<operationCount {
                    let key = "\(globalKey)\(thread)-\(i)"
                    self?.dictionary.add(key: key, value: "value\(i)")
                    _ = self?.dictionary.lookup(key: key)
                    if i % 2 == 0 {
                        self?.dictionary.remove(key: key)
                    }
                }
                group.leave()
            }
        }
        
        // Wait for all threads to complete
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self else {
                XCTAssertThrowsError("self is equal nil")
                return
            }
            // Then
            // Verify consistency of the final state
            let finalKeys = self.dictionary.getAll().keys.compactMap { $0 }
            XCTAssertTrue(finalKeys.allSatisfy { $0.starts(with: globalKey) })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
