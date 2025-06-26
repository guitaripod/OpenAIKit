import Foundation
import OpenAIKit

// Query internal databases through MCP with advanced filtering and aggregation

class MCPDatabaseQuery {
    private let mcpManager: MCPServerManager
    
    init(mcpConfiguration: MCPConfiguration = .defaultConfiguration) {
        self.mcpManager = MCPServerManager(configuration: mcpConfiguration)
    }
    
    // Execute a structured query across multiple databases
    func executeQuery(_ query: DatabaseQuery) async throws -> QueryResult {
        // Build MCP query request
        let mcpRequest = MCPQueryRequest(
            databases: query.databases,
            sqlQuery: query.toSQL(),
            filters: query.filters,
            aggregations: query.aggregations,
            timeout: query.timeout
        )
        
        // Execute query through MCP
        let response = try await mcpManager.executeStructuredQuery(mcpRequest)
        
        // Process and return results
        return QueryResult(
            data: response.rows,
            metadata: response.metadata,
            executionTime: response.executionTime
        )
    }
    
    // Build complex queries with fluent interface
    func query() -> DatabaseQueryBuilder {
        return DatabaseQueryBuilder(mcpManager: mcpManager)
    }
}

// Database query builder for fluent interface
class DatabaseQueryBuilder {
    private let mcpManager: MCPServerManager
    private var databases: [String] = []
    private var fields: [String] = []
    private var conditions: [QueryCondition] = []
    private var joins: [JoinClause] = []
    private var orderBy: [OrderClause] = []
    private var limit: Int?
    
    init(mcpManager: MCPServerManager) {
        self.mcpManager = mcpManager
    }
    
    func from(_ databases: String...) -> DatabaseQueryBuilder {
        self.databases.append(contentsOf: databases)
        return self
    }
    
    func select(_ fields: String...) -> DatabaseQueryBuilder {
        self.fields.append(contentsOf: fields)
        return self
    }
    
    func where(_ field: String, _ operator: QueryOperator, _ value: Any) -> DatabaseQueryBuilder {
        conditions.append(QueryCondition(field: field, operator: `operator`, value: value))
        return self
    }
    
    func join(_ table: String, on: String) -> DatabaseQueryBuilder {
        joins.append(JoinClause(table: table, condition: on))
        return self
    }
    
    func orderBy(_ field: String, _ direction: SortDirection = .ascending) -> DatabaseQueryBuilder {
        orderBy.append(OrderClause(field: field, direction: direction))
        return self
    }
    
    func limit(_ count: Int) -> DatabaseQueryBuilder {
        self.limit = count
        return self
    }
    
    func execute() async throws -> QueryResult {
        let query = DatabaseQuery(
            databases: databases,
            fields: fields,
            conditions: conditions,
            joins: joins,
            orderBy: orderBy,
            limit: limit
        )
        
        let queryExecutor = MCPDatabaseQuery(mcpConfiguration: mcpManager.configuration)
        return try await queryExecutor.executeQuery(query)
    }
}

// Query models
struct DatabaseQuery {
    let databases: [String]
    let fields: [String]
    let conditions: [QueryCondition]
    let joins: [JoinClause]
    let orderBy: [OrderClause]
    let limit: Int?
    let timeout: TimeInterval = 30.0
    
    var filters: [String: Any] {
        var result: [String: Any] = [:]
        for condition in conditions {
            result[condition.field] = [
                "operator": condition.operator.rawValue,
                "value": condition.value
            ]
        }
        return result
    }
    
    var aggregations: [String: String] {
        // Detect aggregation functions in fields
        var aggs: [String: String] = [:]
        for field in fields {
            if field.contains("COUNT(") {
                aggs["count"] = field
            } else if field.contains("SUM(") {
                aggs["sum"] = field
            } else if field.contains("AVG(") {
                aggs["average"] = field
            }
        }
        return aggs
    }
    
    func toSQL() -> String {
        var sql = "SELECT \(fields.isEmpty ? "*" : fields.joined(separator: ", "))"
        sql += " FROM \(databases.joined(separator: ", "))"
        
        for join in joins {
            sql += " JOIN \(join.table) ON \(join.condition)"
        }
        
        if !conditions.isEmpty {
            let whereClause = conditions.map { "\($0.field) \($0.operator.sqlOperator) ?" }.joined(separator: " AND ")
            sql += " WHERE \(whereClause)"
        }
        
        if !orderBy.isEmpty {
            let orderClause = orderBy.map { "\($0.field) \($0.direction.sql)" }.joined(separator: ", ")
            sql += " ORDER BY \(orderClause)"
        }
        
        if let limit = limit {
            sql += " LIMIT \(limit)"
        }
        
        return sql
    }
}

struct QueryCondition {
    let field: String
    let `operator`: QueryOperator
    let value: Any
}

struct JoinClause {
    let table: String
    let condition: String
}

struct OrderClause {
    let field: String
    let direction: SortDirection
}

enum QueryOperator: String {
    case equals = "eq"
    case notEquals = "neq"
    case greaterThan = "gt"
    case lessThan = "lt"
    case contains = "contains"
    case startsWith = "starts_with"
    
    var sqlOperator: String {
        switch self {
        case .equals: return "="
        case .notEquals: return "!="
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .contains: return "LIKE"
        case .startsWith: return "LIKE"
        }
    }
}

enum SortDirection {
    case ascending
    case descending
    
    var sql: String {
        switch self {
        case .ascending: return "ASC"
        case .descending: return "DESC"
        }
    }
}

// Query result model
struct QueryResult {
    let data: [[String: Any]]
    let metadata: QueryMetadata
    let executionTime: TimeInterval
    
    var count: Int { data.count }
    
    func toJSON() throws -> Data {
        return try JSONSerialization.data(withJSONObject: [
            "data": data,
            "metadata": metadata.toDictionary(),
            "executionTime": executionTime
        ], options: .prettyPrinted)
    }
}

struct QueryMetadata {
    let totalRows: Int
    let affectedDatabases: [String]
    let queryPlan: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "totalRows": totalRows,
            "affectedDatabases": affectedDatabases
        ]
        if let queryPlan = queryPlan {
            dict["queryPlan"] = queryPlan
        }
        return dict
    }
}

// MCP query request/response models
struct MCPQueryRequest {
    let databases: [String]
    let sqlQuery: String
    let filters: [String: Any]
    let aggregations: [String: String]
    let timeout: TimeInterval
}

struct MCPQueryResponse {
    let rows: [[String: Any]]
    let metadata: QueryMetadata
    let executionTime: TimeInterval
}

// Extension for executing structured queries
extension MCPServerManager {
    func executeStructuredQuery(_ request: MCPQueryRequest) async throws -> MCPQueryResponse {
        let queryURL = configuration.serverURL.appendingPathComponent("query/execute")
        
        var urlRequest = URLRequest(url: queryURL)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = request.timeout
        
        let payload: [String: Any] = [
            "databases": request.databases,
            "query": request.sqlQuery,
            "filters": request.filters,
            "aggregations": request.aggregations
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        return MCPQueryResponse(
            rows: json["rows"] as? [[String: Any]] ?? [],
            metadata: QueryMetadata(
                totalRows: json["totalRows"] as? Int ?? 0,
                affectedDatabases: json["databases"] as? [String] ?? [],
                queryPlan: json["queryPlan"] as? String
            ),
            executionTime: json["executionTime"] as? TimeInterval ?? 0
        )
    }
}

// Example usage
func demonstrateMCPQuery() async {
    let mcpQuery = MCPDatabaseQuery()
    
    do {
        // Fluent query example
        let result = try await mcpQuery.query()
            .from("customers", "orders")
            .select("customers.name", "COUNT(orders.id) as order_count", "SUM(orders.total) as total_spent")
            .join("orders", on: "customers.id = orders.customer_id")
            .where("orders.created_at", .greaterThan, "2024-01-01")
            .where("customers.status", .equals, "active")
            .orderBy("total_spent", .descending)
            .limit(10)
            .execute()
        
        print("Top 10 customers by spending:")
        print("Total results: \(result.count)")
        print("Execution time: \(result.executionTime)s")
        
        if let jsonData = try? result.toJSON(),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    } catch {
        print("Query error: \(error)")
    }
}