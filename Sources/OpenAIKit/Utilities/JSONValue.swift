import Foundation

/// A type-safe representation of arbitrary JSON values.
///
/// `JSONValue` provides a Swift-native way to work with dynamic JSON data where the
/// structure isn't known at compile time. It supports all JSON types and provides
/// convenient accessors and literal syntax.
///
/// ## Overview
///
/// Use `JSONValue` when:
/// - Working with API responses that have dynamic schemas
/// - Building JSON structures programmatically
/// - Handling function calling arguments in OpenAI API
/// - Processing arbitrary JSON data
///
/// ## Example
///
/// ```swift
/// // Create JSON values using literals
/// let json: JSONValue = [
///     "name": "OpenAI",
///     "year": 2015,
///     "isActive": true,
///     "projects": ["GPT", "DALL-E", "Whisper"],
///     "metadata": [
///         "version": 1.0,
///         "beta": false
///     ]
/// ]
/// 
/// // Access values using dynamic member lookup
/// if let name = json.name?.stringValue {
///     print("Organization: \(name)")
/// }
/// 
/// // Access nested values
/// if let version = json.metadata?.version?.doubleValue {
///     print("Version: \(version)")
/// }
/// 
/// // Access array elements
/// if let firstProject = json.projects?[0]?.stringValue {
///     print("First project: \(firstProject)")
/// }
/// ```
///
/// ## Topics
///
/// ### JSON Types
/// - ``string(_:)``
/// - ``int(_:)``
/// - ``double(_:)``
/// - ``bool(_:)``
/// - ``object(_:)``
/// - ``array(_:)``
/// - ``null``
///
/// ### Accessing Values
/// - ``stringValue``
/// - ``intValue``
/// - ``doubleValue``
/// - ``boolValue``
/// - ``objectValue``
/// - ``arrayValue``
/// - ``isNull``
///
/// ### Dynamic Access
/// - ``subscript(dynamicMember:)``
/// - ``subscript(index:)``
@dynamicMemberLookup
public enum JSONValue: Codable, Sendable {
    /// A JSON string value.
    case string(String)
    
    /// A JSON integer value.
    case int(Int)
    
    /// A JSON floating-point value.
    case double(Double)
    
    /// A JSON boolean value.
    case bool(Bool)
    
    /// A JSON object (dictionary) value.
    case object([String: JSONValue])
    
    /// A JSON array value.
    case array([JSONValue])
    
    /// A JSON null value.
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSON value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
    
    /// Accesses object properties using dot notation.
    ///
    /// Enables dynamic member lookup for JSON objects, allowing you to access
    /// properties as if they were Swift properties.
    ///
    /// - Parameter member: The property name to access.
    /// - Returns: The value associated with the property, or nil if not found or not an object.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let json: JSONValue = ["user": ["name": "Alice", "age": 30]]
    /// 
    /// if let userName = json.user?.name?.stringValue {
    ///     print("User name: \(userName)")
    /// }
    /// ```
    public subscript(dynamicMember member: String) -> JSONValue? {
        if case .object(let dict) = self {
            return dict[member]
        }
        return nil
    }
    
    /// Accesses array elements by index.
    ///
    /// - Parameter index: The zero-based index of the element to access.
    /// - Returns: The element at the specified index, or nil if out of bounds or not an array.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let json: JSONValue = ["colors": ["red", "green", "blue"]]
    /// 
    /// if let firstColor = json.colors?[0]?.stringValue {
    ///     print("First color: \(firstColor)")
    /// }
    /// ```
    public subscript(index: Int) -> JSONValue? {
        if case .array(let arr) = self, index < arr.count {
            return arr[index]
        }
        return nil
    }
    
    /// Extracts the string value if this is a string.
    ///
    /// - Returns: The string value, or nil if this is not a string.
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    /// Extracts the integer value if this is an integer.
    ///
    /// - Returns: The integer value, or nil if this is not an integer.
    public var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
    
    /// Extracts the double value if this is a double.
    ///
    /// - Returns: The double value, or nil if this is not a double.
    public var doubleValue: Double? {
        if case .double(let value) = self { return value }
        return nil
    }
    
    /// Extracts the boolean value if this is a boolean.
    ///
    /// - Returns: The boolean value, or nil if this is not a boolean.
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
    
    /// Extracts the object value if this is an object.
    ///
    /// - Returns: The dictionary value, or nil if this is not an object.
    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
    
    /// Extracts the array value if this is an array.
    ///
    /// - Returns: The array value, or nil if this is not an array.
    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
    
    /// Checks if this value is null.
    ///
    /// - Returns: True if this is a null value, false otherwise.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

// MARK: - Literal Conformances

/// Enables creating JSON string values from string literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = "Hello, World!"
/// ```
extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

/// Enables creating JSON integer values from integer literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = 42
/// ```
extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

/// Enables creating JSON double values from float literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = 3.14159
/// ```
extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

/// Enables creating JSON boolean values from boolean literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = true
/// ```
extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

/// Enables creating JSON objects from dictionary literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = [
///     "name": "OpenAI",
///     "founded": 2015,
///     "isNonProfit": false
/// ]
/// ```
extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        var dict = [String: JSONValue]()
        for (key, value) in elements {
            dict[key] = value
        }
        self = .object(dict)
    }
}

/// Enables creating JSON arrays from array literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = ["GPT-4", "DALL-E", "Whisper"]
/// ```
extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

/// Enables creating JSON null values from nil literals.
///
/// ## Example
/// ```swift
/// let json: JSONValue = nil
/// ```
extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}