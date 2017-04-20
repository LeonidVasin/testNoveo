//
//  MenuTableViewController.swift
//  testNoveo
//
//  Created by user on 20.04.17.
//  Copyright © 2017 Leonid. All rights reserved.
//

import UIKit
import ReachabilitySwift
import CoreData
import MWFeedParser

class MenuTableViewController: UITableViewController {

    var fetchResultController: NSFetchedResultsController<Chanel> = {
        let requset = NSFetchRequest<Chanel>(entityName: "Chanel")
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        requset.sortDescriptors = [nameSortDescriptor]
        let fetchResultController = NSFetchedResultsController<Chanel>(fetchRequest: requset, managedObjectContext: DataBase.instance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchResultController.performFetch()
        } catch {
            print(error)
        }
        return fetchResultController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
    }
    
    //MARK: - button actions
    @IBAction func addChanel(_ sender: UIBarButtonItem) {
        if (Reachability()?.isReachable)! {
        
            let alert = UIAlertController(title: "New Channel", message: "Add a new RSS", preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
                let textField = alert.textFields?.first
                guard let text = textField?.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                    return
                }
                do {
                    let feedParser = MWFeedParser(feedURL: URL(string: text))
                    feedParser?.connectionType = ConnectionTypeSynchronously
                    if feedParser?.parse() == true {
                        self.showAlertError(at: "Incorrect kink")
                    } else {
                        guard let entity = NSEntityDescription.entity(forEntityName: "Chanel", in: DataBase.instance.managedObjectContext) else {
                            return
                        }
                        let chanel = Chanel(entity: entity, insertInto: DataBase.instance.managedObjectContext)
                        chanel.url = text
                        DataBase.instance.saveContext()
                    }
                }
            }
            alert.addAction(saveAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            showAlertError(at: "Please check the connection to the Internet")
        }
    }
    
    func showAlertError(at text: String) {
        let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        default:
            if let count = self.fetchResultController.fetchedObjects?.count {
                return count
            } else {
                return 0
            }
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell", for: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "All"
        case 1:
            cell.textLabel?.text = "Favorites"
        default:
            cell.textLabel?.text = fetchResultController.fetchedObjects?[indexPath.row - 2].name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2 {
            return true
        } else {
            return false
        }
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let chanel = self.fetchResultController.object(at: IndexPath(row: indexPath.row - 2, section: 0))
        let deleteAction = UITableViewRowAction(style: .normal, title: "Del") { (action, indexPath) in
            DataBase.instance.managedObjectContext.delete(chanel)
            DataBase.instance.saveContext()
        }
        let favoriteAction = UITableViewRowAction(style: .normal, title: chanel.isFavorite ? "Fave": "UnFave") { (action, indexPath) in
            chanel.isFavorite = !chanel.isFavorite
            DataBase.instance.saveContext()
        }
        
        return [deleteAction, favoriteAction]
    }
}

extension MenuTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            let ip = IndexPath(row: (indexPath?.row)!, section: 2)
            self.tableView.deleteRows(at: [ip], with: .automatic)
        case .update:
            let ip = IndexPath(row: (indexPath?.row)!, section: 2)
            self.tableView.reloadRows(at: [ip], with: .automatic)
        case .insert:
            if let chanel = anObject as? Chanel {
                let ip = IndexPath(row: (newIndexPath?.row)!, section: 2)
                let cell = self.tableView.cellForRow(at: ip)
                cell?.textLabel?.text = chanel.name
            }
        default:
            break
        }
    }
}
