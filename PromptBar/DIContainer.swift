import Foundation
import AppKit

final class DIContainer {
    static let shared = DIContainer()
    private var instances: [String: Any] = [:]
    private var factories: [String: Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () throws -> T) {
        factories[String(describing: type)] = factory
    }
    
    func resolve<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)
        print("DIContainer: Resolving \(key)")
        
        // Check if we already have an instance (singleton pattern)
        if let instance = instances[key] as? T {
            print("DIContainer: Returning existing instance for \(key)")
            return instance
        }
        
        // Create new instance using factory
        guard let factory = factories[key] as? () throws -> T else {
            print("DIContainer: ERROR - Dependency \(T.self) not registered")
            fatalError("Dependency \(T.self) not registered")
        }
        
        print("DIContainer: Creating new instance for \(key)")
        let instance = try factory()
        instances[key] = instance
        print("DIContainer: Instance created for \(key)")
        return instance
    }
    
    func registerDependencies() {
        register(SQLiteDatabase.self) {
            let db = SQLiteDatabase()
            do {
                try db.open()
                print("DIContainer: Database opened successfully")
                
                // Run migrations immediately after opening
                let migrator = DatabaseMigrator(database: db)
                do {
                    try migrator.migrate()
                    print("DIContainer: Migrations completed successfully")
                } catch {
                    print("DIContainer: Migration failed with error: \(error)")
                    print("DIContainer: Detailed error: \(String(describing: error))")
                    
                    // Show error and throw it up to be caught
                    DispatchQueue.main.async {
                        self.showDatabaseError(error)
                    }
                    throw error
                }
                
                return db
            } catch {
                print("DIContainer: Database open failed: \(error.localizedDescription)")
                print("DIContainer: Full error: \(error)")
                
                // Show error and throw it up to be caught
                DispatchQueue.main.async {
                    self.showDatabaseError(error)
                }
                throw error
            }
        }
        
        register(PromptRepository.self) {
            do {
                let database = try DIContainer.shared.resolve(SQLiteDatabase.self)
                return SQLitePromptRepository(database: database)
            } catch {
                print("DIContainer: Failed to resolve SQLiteDatabase for PromptRepository: \(error)")
                throw error
            }
        }
        
        register(OllamaClient.self) {
            return OllamaClient()
        }
    }
    
    private func showDatabaseError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "PromptBar Error"
        alert.informativeText = "\(error)"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Reset Database")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Reset database
            resetDatabase()
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func resetDatabase() {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
        let dbPath = appSupportURL.appendingPathComponent("promptbar.db")
        
        do {
            try FileManager.default.removeItem(at: dbPath)
            print("Database reset successfully")
            // Re-register dependencies
            registerDependencies()
        } catch {
            print("Failed to reset database: \(error)")
        }
    }
}