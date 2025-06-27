import XCTest
@testable import OpenAIKit

final class JSONValueTests: XCTestCase {
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    // MARK: - Basic Type Tests
    
    func testStringValue() throws {
        let value = JSONValue.string("Hello, World!")
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .string(let str) = decoded {
            XCTAssertEqual(str, "Hello, World!")
        } else {
            XCTFail("Expected string value")
        }
    }
    
    func testIntValue() throws {
        let value = JSONValue.int(42)
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .int(let num) = decoded {
            XCTAssertEqual(num, 42)
        } else {
            XCTFail("Expected int value")
        }
    }
    
    func testDoubleValue() throws {
        let value = JSONValue.double(3.14159)
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .double(let num) = decoded {
            XCTAssertEqual(num, 3.14159, accuracy: 0.00001)
        } else {
            XCTFail("Expected double value")
        }
    }
    
    func testBoolValue() throws {
        let trueValue = JSONValue.bool(true)
        let falseValue = JSONValue.bool(false)
        
        let encodedTrue = try encoder.encode(trueValue)
        let decodedTrue = try decoder.decode(JSONValue.self, from: encodedTrue)
        
        let encodedFalse = try encoder.encode(falseValue)
        let decodedFalse = try decoder.decode(JSONValue.self, from: encodedFalse)
        
        if case .bool(let val) = decodedTrue {
            XCTAssertTrue(val)
        } else {
            XCTFail("Expected bool true value")
        }
        
        if case .bool(let val) = decodedFalse {
            XCTAssertFalse(val)
        } else {
            XCTFail("Expected bool false value")
        }
    }
    
    func testNullValue() throws {
        let value = JSONValue.null
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .null = decoded {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected null value")
        }
    }
    
    // MARK: - Collection Type Tests
    
    func testArrayValue() throws {
        let value = JSONValue.array([
            .string("first"),
            .int(2),
            .bool(true),
            .null
        ])
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .array(let arr) = decoded {
            XCTAssertEqual(arr.count, 4)
            
            if case .string(let str) = arr[0] {
                XCTAssertEqual(str, "first")
            } else {
                XCTFail("Expected string at index 0")
            }
            
            if case .int(let num) = arr[1] {
                XCTAssertEqual(num, 2)
            } else {
                XCTFail("Expected int at index 1")
            }
            
            if case .bool(let val) = arr[2] {
                XCTAssertTrue(val)
            } else {
                XCTFail("Expected bool at index 2")
            }
            
            if case .null = arr[3] {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected null at index 3")
            }
        } else {
            XCTFail("Expected array value")
        }
    }
    
    func testObjectValue() throws {
        let value = JSONValue.object([
            "name": .string("John Doe"),
            "age": .int(30),
            "verified": .bool(true),
            "nickname": .null,
            "scores": .array([.int(95), .int(87), .int(92)])
        ])
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .object(let dict) = decoded {
            XCTAssertEqual(dict.count, 5)
            
            if case .string(let name) = dict["name"] {
                XCTAssertEqual(name, "John Doe")
            } else {
                XCTFail("Expected string for name")
            }
            
            if case .int(let age) = dict["age"] {
                XCTAssertEqual(age, 30)
            } else {
                XCTFail("Expected int for age")
            }
            
            if case .bool(let verified) = dict["verified"] {
                XCTAssertTrue(verified)
            } else {
                XCTFail("Expected bool for verified")
            }
            
            if case .null = dict["nickname"] {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected null for nickname")
            }
            
            if case .array(let scores) = dict["scores"] {
                XCTAssertEqual(scores.count, 3)
            } else {
                XCTFail("Expected array for scores")
            }
        } else {
            XCTFail("Expected object value")
        }
    }
    
    // MARK: - Nested Structure Tests
    
    func testNestedStructure() throws {
        let value = JSONValue.object([
            "user": .object([
                "id": .int(123),
                "profile": .object([
                    "name": .string("Alice"),
                    "tags": .array([.string("developer"), .string("swift")])
                ])
            ]),
            "settings": .object([
                "darkMode": .bool(true),
                "fontSize": .double(14.5)
            ])
        ])
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .object(let root) = decoded,
           case .object(let user) = root["user"],
           case .object(let profile) = user["profile"],
           case .array(let tags) = profile["tags"] {
            XCTAssertEqual(tags.count, 2)
            if case .string(let tag1) = tags[0] {
                XCTAssertEqual(tag1, "developer")
            }
        } else {
            XCTFail("Failed to navigate nested structure")
        }
    }
    
    // MARK: - Raw JSON Decoding Tests
    
    func testDecodingFromRawJSON() throws {
        let json = """
        {
            "string": "test",
            "number": 42,
            "decimal": 3.14,
            "boolean": true,
            "null": null,
            "array": [1, 2, 3],
            "object": {
                "nested": "value"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let value = try decoder.decode(JSONValue.self, from: data)
        
        if case .object(let dict) = value {
            XCTAssertEqual(dict.count, 7)
            
            // Check each type is correctly decoded
            if case .string(let str) = dict["string"] {
                XCTAssertEqual(str, "test")
            }
            
            if case .int(let num) = dict["number"] {
                XCTAssertEqual(num, 42)
            }
            
            if case .double(let dec) = dict["decimal"] {
                XCTAssertEqual(dec, 3.14, accuracy: 0.01)
            }
            
            if case .bool(let bool) = dict["boolean"] {
                XCTAssertTrue(bool)
            }
            
            if case .null = dict["null"] {
                XCTAssertTrue(true)
            }
            
            if case .array(let arr) = dict["array"] {
                XCTAssertEqual(arr.count, 3)
            }
            
            if case .object(let obj) = dict["object"],
               case .string(let nested) = obj["nested"] {
                XCTAssertEqual(nested, "value")
            }
        } else {
            XCTFail("Expected object at root")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyCollections() throws {
        let emptyArray = JSONValue.array([])
        let emptyObject = JSONValue.object([:])
        
        let encodedArray = try encoder.encode(emptyArray)
        let decodedArray = try decoder.decode(JSONValue.self, from: encodedArray)
        
        let encodedObject = try encoder.encode(emptyObject)
        let decodedObject = try decoder.decode(JSONValue.self, from: encodedObject)
        
        if case .array(let arr) = decodedArray {
            XCTAssertTrue(arr.isEmpty)
        } else {
            XCTFail("Expected empty array")
        }
        
        if case .object(let dict) = decodedObject {
            XCTAssertTrue(dict.isEmpty)
        } else {
            XCTFail("Expected empty object")
        }
    }
    
    func testLargeNumbers() throws {
        let largeInt = JSONValue.int(Int.max)
        let largeDouble = JSONValue.double(Double.greatestFiniteMagnitude)
        
        let encodedInt = try encoder.encode(largeInt)
        let decodedInt = try decoder.decode(JSONValue.self, from: encodedInt)
        
        let encodedDouble = try encoder.encode(largeDouble)
        let decodedDouble = try decoder.decode(JSONValue.self, from: encodedDouble)
        
        if case .int(let num) = decodedInt {
            XCTAssertEqual(num, Int.max)
        } else {
            XCTFail("Expected large int")
        }
        
        if case .double(let num) = decodedDouble {
            XCTAssertEqual(num, Double.greatestFiniteMagnitude)
        } else {
            XCTFail("Expected large double")
        }
    }
    
    // MARK: - Value Comparison Tests
    
    func testValueComparison() {
        // Test that values can be extracted and compared
        let string1 = JSONValue.string("test")
        let string2 = JSONValue.string("test")
        
        if case .string(let s1) = string1,
           case .string(let s2) = string2 {
            XCTAssertEqual(s1, s2)
        }
        
        let int1 = JSONValue.int(42)
        let int2 = JSONValue.int(42)
        
        if case .int(let i1) = int1,
           case .int(let i2) = int2 {
            XCTAssertEqual(i1, i2)
        }
        
        let bool1 = JSONValue.bool(true)
        let bool2 = JSONValue.bool(true)
        
        if case .bool(let b1) = bool1,
           case .bool(let b2) = bool2 {
            XCTAssertEqual(b1, b2)
        }
    }
    
    // MARK: - Special Character Tests
    
    func testSpecialCharacters() throws {
        let value = JSONValue.object([
            "emoji": .string("🎉🚀"),
            "unicode": .string("αβγδ"),
            "escaped": .string("Line 1\\nLine 2\\tTabbed"),
            "quotes": .string("He said \"Hello\"")
        ])
        
        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(JSONValue.self, from: encoded)
        
        if case .object(let dict) = decoded {
            if case .string(let emoji) = dict["emoji"] {
                XCTAssertEqual(emoji, "🎉🚀")
            }
            
            if case .string(let unicode) = dict["unicode"] {
                XCTAssertEqual(unicode, "αβγδ")
            }
            
            if case .string(let escaped) = dict["escaped"] {
                XCTAssertEqual(escaped, "Line 1\\nLine 2\\tTabbed")
            }
            
            if case .string(let quotes) = dict["quotes"] {
                XCTAssertEqual(quotes, "He said \"Hello\"")
            }
        } else {
            XCTFail("Expected object with special characters")
        }
    }
}