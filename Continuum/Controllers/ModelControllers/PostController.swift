//
//  PostController.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import UIKit
import CloudKit

class PostController {
    
    static let shared = PostController()
    var posts: [Post] = []
    let publicDB = CKContainer.default().publicCloudDatabase
    
    func addComment(text: String, post: Post, completion: @escaping (Result<Comment?, PostError>) -> Void) {
        let reference = CKRecord.Reference(recordID: post.recordID, action: .none)
        let comment = Comment(text: text, postReference: reference)
        post.comments.append(comment)
        let record = CKRecord(comment: comment)
        publicDB.save(record) { (record, error) in
            if let error = error {
                return completion(.failure(.ckError(error)))
            }
            guard let record = record else { return completion(.failure(.couldNotUnwrap)) }
            let comment = Comment(ckRecord: record)
            self.commentCount(for: post, completion: nil)
            completion(.success(comment))
        }
    }
    
    func createPostWith(photo: UIImage, caption: String, completion: @escaping (Result<Post?, PostError>) -> Void) {
        let post = Post(caption: caption, photo: photo)
        posts.append(post)
        let postRecord = CKRecord(post: post)
        publicDB.save(postRecord) { (record, error) in
            if let error = error {
                return completion(.failure(.ckError(error)))
            }
            guard let record = record,
                  let savedPost = Post(ckRecord: record) else { return completion(.failure(.couldNotUnwrap))}
            print("Saved post successfully")
            completion(.success(savedPost))
        }
    }
    
    func fetchPosts(completion: @escaping (Result<[Post]?, PostError>) -> Void){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PostStrings.recordTypeKey, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                return completion(.failure(.ckError(error)))
            }
            guard let records = records else { return completion(.failure(.couldNotUnwrap)) }
            let posts = records.compactMap{ Post(ckRecord: $0) }
            self.posts = posts
            completion(.success(posts))
        }
    }
    
    func fetchComments(for post: Post, completion: @escaping (Result<[Comment]?, PostError>) -> Void){
        let postRefence = post.recordID
        let predicate = NSPredicate(format: "%K == %@", CommentStrings.recordType, postRefence)
        let commentIDs = post.comments.compactMap({$0.recordID})
        let predicate2 = NSPredicate(format: "NOT(recordID IN %@)", commentIDs)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        let query = CKQuery(recordType: "Comment", predicate: compoundPredicate)
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                return completion(.failure(.ckError(error)))
            }
            guard let records = records else { return completion(.failure(.couldNotUnwrap)) }
            let comments = records.compactMap{ Comment(ckRecord: $0) }
            post.comments.append(contentsOf: comments)
            completion(.success(comments))
        }
    }
    
    func commentCount(for post: Post, completion: ((Bool)-> Void)?){
        post.commentCount = post.comments.count
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: [CKRecord(post: post)], recordIDsToDelete: nil)
        modifyOperation.savePolicy = .changedKeys
        modifyOperation.modifyRecordsCompletionBlock = { (records, _, error) in
            if let error = error{
                print("comment count: \(error.localizedDescription)")
                completion?(false)
                return
            } else {
                completion?(true)
            }
        }
        publicDB.add(modifyOperation)
    }
    
    func addSubscritptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?){
        let postRecordID = post.recordID
        let predicate = NSPredicate(format: "%K = %@", CommentStrings.recordType, postRecordID)
        let subscription = CKQuerySubscription(recordType: "Comment", predicate: predicate, subscriptionID: post.recordID.recordName, options: CKQuerySubscription.Options.firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.title = "New Comment"
        notificationInfo.alertBody = "There is a new comment! Go check it out!"
        notificationInfo.soundName = "default"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = true
        notificationInfo.desiredKeys = [CommentStrings.textKey, CommentStrings.timestampKey]
        subscription.notificationInfo = notificationInfo
        publicDB.save(subscription) { (_, error) in
            if let error = error {
                print(error.localizedDescription)
                completion?(false, error)
                return
            } else {
                print("add subscription success")
                completion?(true, nil)
            }
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool) -> ())?) {
        let subscriptionID = post.recordID.recordName
        publicDB.delete(withSubscriptionID: subscriptionID) { (_, error) in
            if let error = error {
                print("Eemove Error \(error.localizedDescription)")
                completion?(false)
                return
            } else {
                print("Subscription deleted")
                completion?(true)
            }
        }
    }
    
    func checkForSubscription(to post: Post, completion: ((Bool) -> ())?) {
        let subscriptionID = post.recordID.recordName
        publicDB.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            if let error = error {
                print("check of rsubscription error \(error.localizedDescription)")
                completion?(false)
                return
            }
            if subscription != nil {
                print("check for subscription")
                completion?(true)
            } else {
                print("check for subscription error")
                completion?(false)
            }
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?){
        checkForSubscription(to: post) { (isSubscribed) in
            if isSubscribed{
                self.removeSubscriptionTo(commentsForPost: post, completion: { (success) in
                    if success {
                        print("success \(post.caption)")
                        completion?(true, nil)
                    } else {
                        print("Error")
                        completion?(false, nil)
                    }
                })
            } else {
                self.addSubscritptionTo(commentsForPost: post, completion: { (success, error) in
                    if let error = error {
                        print("add subscriotion error \(error.localizedDescription)")
                        completion?(false, error)
                        return
                    }
                    if success {
                        print("success")
                        completion?(true, nil)
                    } else {
                        print("error")
                        completion?(false, nil)
                    }
                })
            }
        }
    }
    
}
