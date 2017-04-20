//
//  DataBase.swift
//  testNoveo
//
//  Created by user on 20.04.17.
//  Copyright © 2017 Leonid. All rights reserved.
//

import Foundation
import CoreData

class DataBase {
    //MARK: - Core Data stack
    
    static let instance: DataBase = DataBase()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let url = urls.first {
            return url as NSURL
        } else {
            return FileManager.default.urls(for: .allApplicationsDirectory, in: .userDomainMask).first! as NSURL
        }
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "testNoveo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("test.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        if #available(iOS 10.0, *) {
            return self.persistentContainer.viewContext
        } else {
            let coordinator = self.persistentStoreCoordinator
            var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        }
        
    }()
    
    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "testNoveo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = managedObjectContext
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
    }
    
    func fetchedResultsController<T : NSManagedObject>(entityName: String, keyForSort: String, managedObjet: T.Type, ascending: Bool, predicate: NSPredicate?) -> NSFetchedResultsController<T> {
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest<T>(entityName: entityName)
        let sortDescriptor = NSSortDescriptor(key: keyForSort, ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.includesSubentities = false
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        return fetchedResultsController
    }
    
    func entityForName(entityName: String) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: entityName, in: self.managedObjectContext)!
    }
    
    func clearAllEntityInstances<T:NSManagedObject>(entity: String, managedObject: T.Type) {
        let fetchRequest = NSFetchRequest<T>()
        fetchRequest.entity = self.entityForName(entityName: entity)
        fetchRequest.includesPropertyValues = false
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for result in results {
                managedObjectContext.delete(result)
            }
        } catch {
            print("failed to clear core data")
        }
        saveContext()
    }
}
