//
//  PostDetailTableViewController.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var followButton: UIButton!
    
    
    //MARK: - Properties
    var post: Post? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = post?.caption
    }
    
    //MARK: - Actions
    @IBAction func commentButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add a comment", message: "", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Add comment here..."
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let commentAction = UIAlertAction(title: "Add Comment", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text, !text.isEmpty,
                  let post = self.post else { return }
            PostController.shared.addComment(text: text, post: post) { (comment) in
                switch comment {
                case .success(_):
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(commentAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        guard let comment = post?.caption else { return }
        let share = UIActivityViewController(activityItems: [comment], applicationActivities: nil)
        present(share, animated: true)
    }
    
    @IBAction func followPostButtonTapped(_ sender: Any) {
        guard let post = post else { return }
        PostController.shared.toggleSubscriptionTo(commentsForPost: post, completion: { (success, error) in
            if let error = error{
                print(error.localizedDescription)
                return
            }
            self.updateFollowPostButtonText()
        })
    }
    
    //MARK: - Helper Functions
    func fetchComments() {
        guard let post = post else { return }
        PostController.shared.fetchComments(for: post) { (_) in
            DispatchQueue.main.async {
                PostController.shared.commentCount(for: post) { (result) in
                    switch result {
                    case true:
                        print("Success")
                    case false:
                        print("Error")
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func updateViews() {
        guard let post = post else { return }
        photoImageView.image = post.photo
        tableView.reloadData()
        updateFollowPostButtonText()
    }
    
    func updateFollowPostButtonText(){
        guard let post = post else { return }
        PostController.shared.checkForSubscription(to: post) { (found) in
            DispatchQueue.main.async {
                let followPostButtonText = found ? "Unfollow" : "Follow"
                self.followButton.setTitle(followPostButtonText, for: .normal)
            }
        }
    }
    
    func presentCommentAlertController() {
        let alertController = UIAlertController(title: "Add a Comment", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Type comment here..."
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let commentAction = UIAlertAction(title: " Add Comment", style: .default) { (_) in
            guard let commentText = alertController.textFields?.first?.text, !commentText.isEmpty,
                let post = self.post else { return }
            PostController.shared.addComment(text: commentText, post: post, completion: { (comment) in
            })
            self.tableView.reloadData()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(commentAction)
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post?.comments.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        let comment = post?.comments[indexPath.row]
        cell.textLabel?.text = comment?.text
        cell.detailTextLabel?.text = comment?.timestamp.stringWith(dateStyle: .short, timeStyle: .short)
        return cell
    }
}
