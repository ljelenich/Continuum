//
//  PostListTableViewController.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var postSearchBar: UISearchBar!
    
    //MARK: - Properties
    var resultsArray: [SearchableRecord] = []
    var isSearching = false
    var dataSource: [SearchableRecord] {
        return isSearching ? resultsArray : PostController.shared.posts
    }

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Posts"
        postSearchBar.delegate = self
        performFullSync(completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.resultsArray = PostController.shared.posts
            self.tableView.reloadData()
        }
    }
    
    func performFullSync(completion:((Bool) ->Void)?){
        
//        self.activityView.isHidden = false
//        self.activityIndicator.startAnimating()
        
        PostController.shared.fetchPosts { (result) in
            
            switch result {
                
            case .failure(let error):
                self.presentSimpleAlertWith(title: "An error occurred", message: error.localizedDescription)
                print(error.localizedDescription)
                completion?(false)
            case .success(let posts):
                DispatchQueue.main.async {
//                    self.activityView.isHidden = true
//                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()
                    completion?(posts != nil)
                }
            }
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell else { return UITableViewCell() }
        let post = dataSource[indexPath.row] as? Post
        cell.post = post
        cell.updateViews()
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                  let destinationVC = segue.destination as? PostDetailTableViewController else { return }
            let post = PostController.shared.posts[indexPath.row]
            destinationVC.post = post
        }
    }
}

extension PostListTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            resultsArray = PostController.shared.posts.filter {
                $0.matches(searchTerm: searchText)
            }
            tableView.reloadData()
        } else {
            resultsArray = PostController.shared.posts
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        postSearchBar.showsCancelButton = false
        resultsArray = PostController.shared.posts
        tableView.reloadData()
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        postSearchBar.showsCancelButton = true
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        postSearchBar.showsCancelButton = false
        isSearching = false
    }
}
