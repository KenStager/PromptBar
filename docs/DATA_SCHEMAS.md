# DATA SCHEMAS: PromptBar
*Version 1.0 - Data Model Specification*
*Last Updated: January 2025*

## Overview

This document defines all data structures for PromptBar including SQLite schemas, Swift models, JSON formats, and migration strategies. The design prioritizes search performance (<50ms) and data integrity while supporting 10,000+ prompts.

### Design Principles

1. **Performance First**: Optimized indexes and FTS5 configuration for instant search
2. **Type Safety**: Strong typing in Swift models with validation
3. **Forward Compatibility**: Versioned schemas with migration support
4. **Data Integrity**: Constraints and validation at every layer
5. **Efficient Storage**: Balanced normalization for speed and space

### Data Flow Overview

```
User Input → Swift Models → Validation → SQLite Storage
                                            ↓
                                         FTS5 Index
                                            ↓
                                     Search Results → Swift Models → UI
```

## Database Schema

### Schema Version Table

```sql
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at REAL NOT NULL,
    description TEXT
);
```

### Main Tables

#### Prompts Table

```sql
CREATE TABLE IF NOT EXISTS prompts (
    id TEXT PRIMARY KEY NOT NULL,                  -- UUID
    title TEXT NOT NULL,                          -- User-defined or auto-generated
    content TEXT NOT NULL,                        -- The actual prompt
    description TEXT,                             -- AI-generated description
    category_id INTEGER,                          -- FK to categories
    is_favorite INTEGER NOT NULL DEFAULT 0,       -- Boolean (0/1)
    created_at REAL NOT NULL,                     -- Unix timestamp
    modified_at REAL NOT NULL,                    -- Unix timestamp
    used_count INTEGER NOT NULL DEFAULT 0,        -- Usage tracking
    last_used_at REAL,                           -- Unix timestamp
    
    -- Analysis metadata (nullable until analyzed)
    analysis_version INTEGER,                     -- Version of analysis
    analyzed_at REAL,                            -- When analyzed
    complexity TEXT,                             -- simple/intermediate/advanced
    
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Performance indexes
CREATE INDEX idx_prompts_created_at ON prompts(created_at DESC);
CREATE INDEX idx_prompts_modified_at ON prompts(modified_at DESC);
CREATE INDEX idx_prompts_used_count ON prompts(used_count DESC);
CREATE INDEX idx_prompts_last_used_at ON prompts(last_used_at DESC);
CREATE INDEX idx_prompts_category_id ON prompts(category_id);
CREATE INDEX idx_prompts_is_favorite ON prompts(is_favorite);
```

#### Categories Table

```sql
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,                    -- e.g., "Development", "Writing"
    icon TEXT,                                    -- SF Symbol name
    color TEXT,                                   -- Hex color code
    position INTEGER NOT NULL DEFAULT 0,          -- Display order
    created_at REAL NOT NULL
);

-- Insert default categories
INSERT OR IGNORE INTO categories (name, icon, color, position) VALUES
    ('Development', 'terminal', '#007AFF', 1),
    ('Writing', 'pencil', '#34C759', 2),
    ('Analysis', 'chart.bar', '#FF9500', 3),
    ('Design', 'paintbrush', '#FF2D55', 4),
    ('Other', 'folder', '#8E8E93', 999);
```

#### Tags Table

```sql
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE COLLATE NOCASE,     -- Case-insensitive
    created_at REAL NOT NULL
);

CREATE INDEX idx_tags_name ON tags(name);
```

#### Prompt-Tag Junction Table

```sql
CREATE TABLE IF NOT EXISTS prompt_tags (
    prompt_id TEXT NOT NULL,
    tag_id INTEGER NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,          -- Order within prompt
    
    PRIMARY KEY (prompt_id, tag_id),
    FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX idx_prompt_tags_prompt_id ON prompt_tags(prompt_id);
CREATE INDEX idx_prompt_tags_tag_id ON prompt_tags(tag_id);
```

#### Use Cases Table

```sql
CREATE TABLE IF NOT EXISTS use_cases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    prompt_id TEXT NOT NULL,
    description TEXT NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    
    FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE
);

CREATE INDEX idx_use_cases_prompt_id ON use_cases(prompt_id);
```

### Full-Text Search Configuration

```sql
-- FTS5 virtual table for search
CREATE VIRTUAL TABLE IF NOT EXISTS prompts_fts USING fts5(
    id UNINDEXED,                                -- Don't index the ID
    title,                                       -- Searchable
    content,                                     -- Searchable
    description,                                 -- Searchable
    tags,                                        -- Searchable (denormalized)
    
    -- Configure tokenizer for better search
    tokenize='porter unicode61 remove_diacritics 1',
    
    -- Link to main table
    content='prompts',
    content_rowid='rowid'
);

-- Triggers to maintain FTS index
CREATE TRIGGER IF NOT EXISTS prompts_ai AFTER INSERT ON prompts BEGIN
    INSERT INTO prompts_fts(id, title, content, description, tags)
    SELECT 
        new.id,
        new.title,
        new.content,
        new.description,
        GROUP_CONCAT(t.name, ' ')
    FROM prompts p
    LEFT JOIN prompt_tags pt ON p.id = pt.prompt_id
    LEFT JOIN tags t ON pt.tag_id = t.id
    WHERE p.id = new.id
    GROUP BY p.id;
END;

CREATE TRIGGER IF NOT EXISTS prompts_au AFTER UPDATE ON prompts BEGIN
    UPDATE prompts_fts 
    SET title = new.title,
        content = new.content,
        description = new.description
    WHERE id = new.id;
END;

CREATE TRIGGER IF NOT EXISTS prompts_ad AFTER DELETE ON prompts BEGIN
    DELETE FROM prompts_fts WHERE id = old.id;
END;

-- Trigger for tag updates
CREATE TRIGGER IF NOT EXISTS prompt_tags_change AFTER INSERT ON prompt_tags BEGIN
    UPDATE prompts_fts
    SET tags = (
        SELECT GROUP_CONCAT(t.name, ' ')
        FROM prompt_tags pt
        JOIN tags t ON pt.tag_id = t.id
        WHERE pt.prompt_id = new.prompt_id
    )
    WHERE id = new.prompt_id;
END;
```

### Database Configuration

```sql
-- Performance optimizations
PRAGMA journal_mode = WAL;              -- Write-Ahead Logging
PRAGMA synchronous = NORMAL;            -- Balance safety/speed
PRAGMA cache_size = -64000;             -- 64MB cache
PRAGMA temp_store = MEMORY;             -- Temp tables in memory
PRAGMA mmap_size = 268435456;           -- 256MB memory-mapped I/O

-- Foreign key enforcement
PRAGMA foreign_keys = ON;

-- Auto-vacuum to prevent fragmentation
PRAGMA auto_vacuum = INCREMENTAL;
```

## Swift Models

### Domain Models

```swift
import Foundation

// MARK: - Core Models

struct Prompt: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var content: String
    var description: String?
    var category: Category?
    var tags: [Tag]
    var isFavorite: Bool
    let createdAt: Date
    var modifiedAt: Date
    var usedCount: Int
    var lastUsedAt: Date?
    
    // Analysis metadata
    var analysisVersion: Int?
    var analyzedAt: Date?
    var complexity: Complexity?
    var useCases: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        description: String? = nil,
        category: Category? = nil,
        tags: [Tag] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        usedCount: Int = 0,
        lastUsedAt: Date? = nil,
        analysisVersion: Int? = nil,
        analyzedAt: Date? = nil,
        complexity: Complexity? = nil,
        useCases: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.description = description
        self.category = category
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.usedCount = usedCount
        self.lastUsedAt = lastUsedAt
        self.analysisVersion = analysisVersion
        self.analyzedAt = analyzedAt
        self.complexity = complexity
        self.useCases = useCases
    }
}

struct Tag: Identifiable, Equatable, Codable, Hashable {
    let id: Int?
    let name: String
    let createdAt: Date
    
    init(id: Int? = nil, name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }
}

struct Category: Identifiable, Equatable, Codable {
    let id: Int
    let name: String
    let icon: String?
    let color: String?
    let position: Int
    
    static let development = Category(id: 1, name: "Development", icon: "terminal", color: "#007AFF", position: 1)
    static let writing = Category(id: 2, name: "Writing", icon: "pencil", color: "#34C759", position: 2)
    static let analysis = Category(id: 3, name: "Analysis", icon: "chart.bar", color: "#FF9500", position: 3)
    static let design = Category(id: 4, name: "Design", icon: "paintbrush", color: "#FF2D55", position: 4)
    static let other = Category(id: 5, name: "Other", icon: "folder", color: "#8E8E93", position: 999)
    
    static let all = [development, writing, analysis, design, other]
}

enum Complexity: String, Codable, CaseIterable {
    case simple = "simple"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - Analysis Models

struct AnalysisResult: Codable {
    let description: String
    let tags: [String]
    let category: String
    let useCases: [String]
    let complexity: String
    let relatedPrompts: [String]
    
    var parsedComplexity: Complexity? {
        Complexity(rawValue: complexity)
    }
    
    var parsedCategory: Category? {
        Category.all.first { $0.name.lowercased() == category.lowercased() }
    }
}

// MARK: - Value Objects

struct SearchQuery {
    let text: String
    let tokens: [String]
    let excludedTokens: [String]
    
    init(text: String) {
        self.text = text
        
        // Parse search operators
        var includeTokens: [String] = []
        var excludeTokens: [String] = []
        
        let components = text.components(separatedBy: .whitespaces)
        for component in components {
            if component.hasPrefix("-") && component.count > 1 {
                excludeTokens.append(String(component.dropFirst()))
            } else if !component.isEmpty {
                includeTokens.append(component)
            }
        }
        
        self.tokens = includeTokens
        self.excludedTokens = excludeTokens
    }
    
    var ftsQuery: String {
        var parts: [String] = []
        
        // Include tokens
        if !tokens.isEmpty {
            parts.append(tokens.map { "\"\($0)\"" }.joined(separator: " "))
        }
        
        // Exclude tokens
        for excluded in excludedTokens {
            parts.append("NOT \"\(excluded)\"")
        }
        
        return parts.joined(separator: " ")
    }
}

// MARK: - Database Models

struct PromptRecord {
    let id: String
    let title: String
    let content: String
    let description: String?
    let categoryId: Int?
    let isFavorite: Bool
    let createdAt: TimeInterval
    let modifiedAt: TimeInterval
    let usedCount: Int
    let lastUsedAt: TimeInterval?
    let analysisVersion: Int?
    let analyzedAt: TimeInterval?
    let complexity: String?
    
    init(from prompt: Prompt) {
        self.id = prompt.id.uuidString
        self.title = prompt.title
        self.content = prompt.content
        self.description = prompt.description
        self.categoryId = prompt.category?.id
        self.isFavorite = prompt.isFavorite
        self.createdAt = prompt.createdAt.timeIntervalSince1970
        self.modifiedAt = prompt.modifiedAt.timeIntervalSince1970
        self.usedCount = prompt.usedCount
        self.lastUsedAt = prompt.lastUsedAt?.timeIntervalSince1970
        self.analysisVersion = prompt.analysisVersion
        self.analyzedAt = prompt.analyzedAt?.timeIntervalSince1970
        self.complexity = prompt.complexity?.rawValue
    }
}
```

### Model Extensions

```swift
// MARK: - Validation

extension Prompt {
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= 50000 &&
        tags.count <= 10
    }
    
    func validate() throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyTitle
        }
        
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyContent
        }
        
        if content.count > 50000 {
            throw ValidationError.contentTooLong
        }
        
        if tags.count > 10 {
            throw ValidationError.tooManyTags
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyTitle
    case emptyContent
    case contentTooLong
    case tooManyTags
    case invalidTag(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Title cannot be empty"
        case .emptyContent:
            return "Prompt content cannot be empty"
        case .contentTooLong:
            return "Prompt content exceeds 50,000 characters"
        case .tooManyTags:
            return "Maximum 10 tags allowed"
        case .invalidTag(let tag):
            return "Invalid tag: \(tag)"
        }
    }
}

// MARK: - Search Helpers

extension Prompt {
    var searchableText: String {
        [title, content, description ?? "", tags.map { $0.name }.joined(separator: " ")]
            .joined(separator: " ")
            .lowercased()
    }
    
    func matches(query: SearchQuery) -> Bool {
        let searchText = searchableText
        
        // All include tokens must match
        for token in query.tokens {
            if !searchText.contains(token.lowercased()) {
                return false
            }
        }
        
        // No exclude tokens should match
        for excluded in query.excludedTokens {
            if searchText.contains(excluded.lowercased()) {
                return false
            }
        }
        
        return true
    }
}
```

## JSON Schemas

### Import/Export Format

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "exported_at", "prompts"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$",
      "description": "Schema version (e.g., '1.0')"
    },
    "exported_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp"
    },
    "app_version": {
      "type": "string",
      "description": "PromptBar version that created export"
    },
    "prompts": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/prompt"
      }
    }
  },
  "definitions": {
    "prompt": {
      "type": "object",
      "required": ["id", "title", "content", "created_at", "modified_at"],
      "properties": {
        "id": {
          "type": "string",
          "format": "uuid"
        },
        "title": {
          "type": "string",
          "minLength": 1,
          "maxLength": 200
        },
        "content": {
          "type": "string",
          "minLength": 1,
          "maxLength": 50000
        },
        "description": {
          "type": ["string", "null"],
          "maxLength": 500
        },
        "category": {
          "type": ["string", "null"],
          "enum": ["Development", "Writing", "Analysis", "Design", "Other", null]
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^[a-z0-9-_]+$",
            "minLength": 2,
            "maxLength": 30
          },
          "maxItems": 10
        },
        "is_favorite": {
          "type": "boolean",
          "default": false
        },
        "created_at": {
          "type": "string",
          "format": "date-time"
        },
        "modified_at": {
          "type": "string",
          "format": "date-time"
        },
        "used_count": {
          "type": "integer",
          "minimum": 0,
          "default": 0
        },
        "last_used_at": {
          "type": ["string", "null"],
          "format": "date-time"
        },
        "analysis": {
          "$ref": "#/definitions/analysis"
        }
      }
    },
    "analysis": {
      "type": "object",
      "properties": {
        "version": {
          "type": "integer"
        },
        "analyzed_at": {
          "type": "string",
          "format": "date-time"
        },
        "complexity": {
          "type": "string",
          "enum": ["simple", "intermediate", "advanced"]
        },
        "use_cases": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

#### Example Export File

```json
{
  "version": "1.0",
  "exported_at": "2024-01-15T10:30:00Z",
  "app_version": "1.0.0",
  "prompts": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Python Async Debugger",
      "content": "Help me debug this Python async/await code. Identify potential race conditions, deadlocks, or improper await usage:\n\n```python\n{code}\n```\n\nExplain what's wrong and provide a corrected version.",
      "description": "Analyzes Python async code for common concurrency issues",
      "category": "Development",
      "tags": ["python", "debugging", "async", "concurrency"],
      "is_favorite": true,
      "created_at": "2024-01-10T08:00:00Z",
      "modified_at": "2024-01-14T15:30:00Z",
      "used_count": 12,
      "last_used_at": "2024-01-14T15:30:00Z",
      "analysis": {
        "version": 1,
        "analyzed_at": "2024-01-10T08:00:30Z",
        "complexity": "intermediate",
        "use_cases": [
          "Finding race conditions in async code",
          "Debugging deadlocks in asyncio",
          "Identifying missing await keywords"
        ]
      }
    }
  ]
}
```

### Ollama API Schemas

#### Analysis Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["model", "prompt"],
  "properties": {
    "model": {
      "type": "string",
      "description": "Model identifier",
      "default": "llama3.2:3b"
    },
    "prompt": {
      "type": "string",
      "description": "The analysis prompt with instructions"
    },
    "stream": {
      "type": "boolean",
      "default": false,
      "description": "Whether to stream the response"
    },
    "options": {
      "type": "object",
      "properties": {
        "temperature": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "default": 0.3
        },
        "top_p": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "default": 0.9
        },
        "num_predict": {
          "type": "integer",
          "minimum": 1,
          "default": 200
        },
        "stop": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "default": ["```", "\n\n"]
        }
      }
    },
    "format": {
      "type": "string",
      "enum": ["json"],
      "description": "Response format"
    }
  }
}
```

#### Analysis Response

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["model", "created_at", "response", "done"],
  "properties": {
    "model": {
      "type": "string"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "response": {
      "type": "string",
      "description": "JSON string containing analysis result"
    },
    "done": {
      "type": "boolean"
    },
    "context": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    },
    "total_duration": {
      "type": "integer"
    },
    "load_duration": {
      "type": "integer"
    },
    "prompt_eval_duration": {
      "type": "integer"
    },
    "eval_duration": {
      "type": "integer"
    }
  }
}
```

#### Parsed Analysis Result

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["description", "tags", "category"],
  "properties": {
    "description": {
      "type": "string",
      "minLength": 10,
      "maxLength": 500
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-z0-9-_]+$"
      },
      "minItems": 1,
      "maxItems": 5
    },
    "category": {
      "type": "string",
      "enum": ["Development", "Writing", "Analysis", "Design", "Other"]
    },
    "use_cases": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 5
    },
    "complexity": {
      "type": "string",
      "enum": ["simple", "intermediate", "advanced"]
    },
    "related_prompts": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Suggested related prompt IDs"
    }
  }
}
```

### Preferences Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "general": {
      "type": "object",
      "properties": {
        "launch_at_startup": {
          "type": "boolean",
          "default": true
        },
        "show_in_dock": {
          "type": "boolean",
          "default": false
        },
        "hotkey": {
          "type": "object",
          "properties": {
            "key_code": {
              "type": "integer"
            },
            "modifiers": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": ["cmd", "shift", "alt", "ctrl"]
              }
            }
          }
        }
      }
    },
    "ollama": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": true
        },
        "base_url": {
          "type": "string",
          "format": "uri",
          "default": "http://localhost:11434"
        },
        "model": {
          "type": "string",
          "default": "llama3.2:3b"
        },
        "timeout": {
          "type": "integer",
          "minimum": 1,
          "maximum": 30,
          "default": 5
        },
        "auto_retry": {
          "type": "boolean",
          "default": true
        }
      }
    },
    "storage": {
      "type": "object",
      "properties": {
        "backup_enabled": {
          "type": "boolean",
          "default": true
        },
        "backup_frequency": {
          "type": "string",
          "enum": ["daily", "weekly", "monthly"],
          "default": "daily"
        },
        "backup_location": {
          "type": "string"
        },
        "max_backups": {
          "type": "integer",
          "minimum": 1,
          "maximum": 30,
          "default": 7
        }
      }
    },
    "appearance": {
      "type": "object",
      "properties": {
        "theme": {
          "type": "string",
          "enum": ["system", "light", "dark"],
          "default": "system"
        },
        "accent_color": {
          "type": "string",
          "pattern": "^#[0-9A-Fa-f]{6}$"
        }
      }
    }
  }
}
```

## Data Relationships

### Entity Relationship Diagram

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   prompts   │──────<│ prompt_tags  │>──────│    tags     │
├─────────────┤       ├──────────────┤       ├─────────────┤
│ id (PK)     │       │ prompt_id(FK)│       │ id (PK)     │
│ title       │       │ tag_id (FK)  │       │ name        │
│ content     │       │ position     │       │ created_at  │
│ category_id │       └──────────────┘       └─────────────┘
│ ...         │              
└─────────────┘              
       │                     
       │                     
       ▼                     
┌─────────────┐       ┌──────────────┐
│ categories  │       │  use_cases   │
├─────────────┤       ├──────────────┤
│ id (PK)     │       │ id (PK)      │
│ name        │       │ prompt_id(FK)│
│ icon        │       │ description  │
│ color       │       │ position     │
└─────────────┘       └──────────────┘
```

### Relationship Rules

1. **Prompt → Category**: Many-to-One (nullable)
   - A prompt can belong to one category
   - Deleting a category sets prompt category to NULL

2. **Prompt ↔ Tags**: Many-to-Many
   - A prompt can have multiple tags (max 10)
   - A tag can be used by multiple prompts
   - Junction table maintains order (position)

3. **Prompt → Use Cases**: One-to-Many
   - A prompt can have multiple use cases
   - Use cases are deleted when prompt is deleted

## Indexing Strategy

### Query Performance Optimization

```sql
-- Frequent queries and their indexes

-- 1. Recent prompts (home screen)
-- Query: SELECT * FROM prompts ORDER BY created_at DESC LIMIT 5
-- Index: idx_prompts_created_at

-- 2. Favorites
-- Query: SELECT * FROM prompts WHERE is_favorite = 1 ORDER BY modified_at DESC
-- Index: idx_prompts_is_favorite, idx_prompts_modified_at

-- 3. Category browsing
-- Query: SELECT * FROM prompts WHERE category_id = ? ORDER BY created_at DESC
-- Index: idx_prompts_category_id

-- 4. Most used
-- Query: SELECT * FROM prompts ORDER BY used_count DESC LIMIT 10
-- Index: idx_prompts_used_count

-- 5. Full-text search
-- Query: SELECT * FROM prompts_fts WHERE prompts_fts MATCH ?
-- Index: Built-in FTS5 index

-- 6. Tag filtering
-- Query: SELECT DISTINCT p.* FROM prompts p 
--        JOIN prompt_tags pt ON p.id = pt.prompt_id 
--        WHERE pt.tag_id IN (?)
-- Index: idx_prompt_tags_tag_id

-- Compound indexes for complex queries
CREATE INDEX idx_prompts_favorite_modified 
    ON prompts(is_favorite, modified_at DESC);

CREATE INDEX idx_prompts_category_created 
    ON prompts(category_id, created_at DESC);
```

### FTS5 Optimization

```sql
-- Optimize FTS index periodically
INSERT INTO prompts_fts(prompts_fts) VALUES('optimize');

-- Rebuild FTS index if needed
INSERT INTO prompts_fts(prompts_fts) VALUES('rebuild');

-- Check FTS integrity
INSERT INTO prompts_fts(prompts_fts, rank) VALUES('integrity-check', 1);
```

## Migration Strategy

### Migration Structure

```swift
struct Migration {
    let version: Int
    let description: String
    let up: (SQLiteDatabase) throws -> Void
    let down: ((SQLiteDatabase) throws -> Void)?
}

let migrations: [Migration] = [
    Migration(
        version: 1,
        description: "Initial schema",
        up: { db in
            // Create all tables
            try db.execute(initialSchema)
        },
        down: nil
    ),
    
    Migration(
        version: 2,
        description: "Add analysis fields",
        up: { db in
            try db.execute("""
                ALTER TABLE prompts ADD COLUMN analysis_version INTEGER;
                ALTER TABLE prompts ADD COLUMN analyzed_at REAL;
                ALTER TABLE prompts ADD COLUMN complexity TEXT;
            """)
        },
        down: { db in
            // SQLite doesn't support DROP COLUMN
            // Would need to recreate table
        }
    ),
    
    Migration(
        version: 3,
        description: "Add use_cases table",
        up: { db in
            try db.execute("""
                CREATE TABLE IF NOT EXISTS use_cases (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    prompt_id TEXT NOT NULL,
                    description TEXT NOT NULL,
                    position INTEGER NOT NULL DEFAULT 0,
                    FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE
                );
                CREATE INDEX idx_use_cases_prompt_id ON use_cases(prompt_id);
            """)
        },
        down: { db in
            try db.execute("DROP TABLE use_cases;")
        }
    )
]
```

### Migration Process

```swift
func runMigrations(database: SQLiteDatabase) throws {
    // Get current version
    let currentVersion = try getCurrentVersion(database)
    
    // Run pending migrations
    for migration in migrations where migration.version > currentVersion {
        Logger.info("Running migration \(migration.version): \(migration.description)")
        
        try database.transaction { db in
            // Backup before migration
            try backupDatabase()
            
            // Run migration
            try migration.up(db)
            
            // Update version
            try db.execute("""
                INSERT INTO schema_version (version, applied_at, description)
                VALUES (?, ?, ?);
            """, [migration.version, Date().timeIntervalSince1970, migration.description])
        }
    }
}
```

## Validation Rules

### Data Integrity Constraints

```swift
struct ValidationRules {
    // Prompt validation
    static let titleMinLength = 1
    static let titleMaxLength = 200
    static let contentMinLength = 1
    static let contentMaxLength = 50_000
    static let descriptionMaxLength = 500
    static let maxTags = 10
    
    // Tag validation
    static let tagMinLength = 2
    static let tagMaxLength = 30
    static let tagPattern = "^[a-z0-9-_]+$"
    
    // Search validation
    static let searchMaxLength = 200
    static let searchMinLength = 1
    
    // Import validation
    static let maxImportSize = 10_000_000 // 10MB
    static let maxPromptsPerImport = 1000
}

func validatePrompt(_ prompt: Prompt) throws {
    // Title validation
    let trimmedTitle = prompt.title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedTitle.count >= ValidationRules.titleMinLength else {
        throw ValidationError.titleTooShort
    }
    guard trimmedTitle.count <= ValidationRules.titleMaxLength else {
        throw ValidationError.titleTooLong
    }
    
    // Content validation
    let trimmedContent = prompt.content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedContent.count >= ValidationRules.contentMinLength else {
        throw ValidationError.contentEmpty
    }
    guard trimmedContent.count <= ValidationRules.contentMaxLength else {
        throw ValidationError.contentTooLong
    }
    
    // Tag validation
    guard prompt.tags.count <= ValidationRules.maxTags else {
        throw ValidationError.tooManyTags
    }
    
    let tagRegex = try NSRegularExpression(pattern: ValidationRules.tagPattern)
    for tag in prompt.tags {
        let range = NSRange(location: 0, length: tag.name.utf16.count)
        guard tagRegex.firstMatch(in: tag.name, range: range) != nil else {
            throw ValidationError.invalidTagFormat(tag.name)
        }
    }
}
```

## Performance Considerations

### Query Optimization

```sql
-- Use prepared statements for all queries
-- Example: Search query with proper escaping
PREPARE search_stmt AS
    SELECT p.*, snippet(prompts_fts, -1, '<mark>', '</mark>', '...', 20) as snippet
    FROM prompts p
    JOIN prompts_fts ON p.id = prompts_fts.id
    WHERE prompts_fts MATCH $1
    ORDER BY rank
    LIMIT 50;

-- Use covering indexes where possible
CREATE INDEX idx_prompts_covering 
    ON prompts(id, title, created_at, modified_at, used_count)
    WHERE is_favorite = 1;

-- Analyze tables periodically
ANALYZE prompts;
ANALYZE prompts_fts;
```

### Memory Optimization

```swift
// Use lazy loading for large content
struct LazyPrompt {
    let id: UUID
    let title: String
    let preview: String // First 200 chars
    private let repository: PromptRepository
    
    func loadFullContent() async throws -> String {
        guard let prompt = try await repository.fetch(id: id) else {
            throw PromptError.notFound
        }
        return prompt.content
    }
}

// Batch operations for better performance
func importPrompts(_ prompts: [Prompt]) async throws {
    try await repository.transaction { db in
        // Insert in batches of 100
        for batch in prompts.chunked(into: 100) {
            try await db.insertBatch(batch)
        }
        
        // Rebuild FTS index once at end
        try await db.execute("INSERT INTO prompts_fts(prompts_fts) VALUES('rebuild');")
    }
}
```

## Example Data

### Sample Prompts

```swift
let samplePrompts = [
    Prompt(
        title: "Swift Async Error Handler",
        content: """
        Create a Swift error handling wrapper for async functions that:
        1. Retries failed operations with exponential backoff
        2. Logs errors with context
        3. Provides fallback values
        4. Tracks error metrics
        
        Include unit tests and usage examples.
        """,
        category: .development,
        tags: [
            Tag(name: "swift"),
            Tag(name: "error-handling"),
            Tag(name: "async"),
            Tag(name: "ios")
        ]
    ),
    
    Prompt(
        title: "Blog Post Outline Generator",
        content: """
        Create a detailed blog post outline on the topic: [TOPIC]
        
        Include:
        - Compelling headline options (3-5)
        - Introduction hook
        - Main sections with key points
        - Supporting examples/data needed
        - Call-to-action options
        - SEO keywords to target
        
        Tone: Professional but conversational
        Length: 1500-2000 words
        """,
        category: .writing,
        tags: [
            Tag(name: "blogging"),
            Tag(name: "content"),
            Tag(name: "seo"),
            Tag(name: "outline")
        ]
    )
]
```

### Sample Analysis Results

```json
{
  "description": "Generates comprehensive blog post outlines with SEO optimization",
  "tags": ["blogging", "content", "seo", "outline", "writing"],
  "category": "Writing",
  "use_cases": [
    "Creating blog post structures",
    "SEO content planning",
    "Content calendar planning"
  ],
  "complexity": "intermediate",
  "related_prompts": ["headline-generator", "seo-optimizer"]
}
```

## Data Lifecycle

### Prompt Lifecycle States

```
Created → Analyzed → Used → Modified → Archived/Deleted

States:
- Created: Initial save, pending analysis
- Analyzed: Ollama processing complete
- Active: In regular use
- Stale: Not used in 90+ days
- Archived: Soft deleted (future feature)
```

### Data Retention

```swift
struct DataRetention {
    // Cleanup old search cache
    static func cleanupSearchCache(olderThan: TimeInterval = 3600) {
        // Remove cached searches older than 1 hour
    }
    
    // Archive stale prompts (future)
    static func archiveStalePrompts(unusedDays: Int = 90) {
        // Move to archive table
    }
    
    // Backup retention
    static func cleanupOldBackups(keepLast: Int = 7) {
        // Delete backups older than retention period
    }
}
```

## Summary

This data schema design provides:
- ✅ Sub-50ms search performance via FTS5
- ✅ Flexible tagging and categorization
- ✅ Forward-compatible migration support
- ✅ Type-safe Swift models with validation
- ✅ Comprehensive import/export capabilities
- ✅ Optimized indexes for all query patterns

The schema balances normalization with performance, using denormalization (tags in FTS) where it significantly improves search speed.

---
*Version 1.0 - Ready for Implementation*