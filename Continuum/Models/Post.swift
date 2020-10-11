//
//  Post.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import UIKit
import CloudKit

struct PostStrings {
    static let recordTypeKey = "Post"
    fileprivate static let captionKey = "caption"
    fileprivate static let timestampKey = "timestamp"
    fileprivate static let commentsKey = "comments"
    fileprivate static let commentCountKey = "commentCount"
    fileprivate static let photoKey = "photo"
}
class Post {
    var photoData: Data?
    var timestamp: Date
    var caption: String
    var comments: [Comment]
    var commentCount: Int
    var recordID: CKRecord.ID
    
    var photo: UIImage? {
        get {
            guard let data = photoData else { return nil }
            return UIImage(data: data)
        } set {
            photoData = newValue?.jpegData(compressionQuality: 0.5)
        }
    }

    var photoAsset: CKAsset? {
        guard let data = photoData else { return nil }
        let tempDirectory = NSTemporaryDirectory()
        let tempDirectoryURL = URL(fileURLWithPath: tempDirectory)
        let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        do {
            try data.write(to: fileURL)
        } catch {
            print(error.localizedDescription)
        }
        return CKAsset(fileURL: fileURL)
    }
    
    init(caption: String, timestamp: Date = Date(), comments: [Comment] = [], recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), photo: UIImage? = nil, commentCount: Int = 0) {
        self.caption = caption
        self.timestamp = timestamp
        self.comments = comments
        self.recordID = recordID
        self.commentCount = commentCount
        self.photo = photo
    }
}

extension Post: SearchableRecord {
    func matches(searchTerm: String) -> Bool {
        if caption.lowercased().contains(searchTerm.lowercased()) {
            return true
        } else {
            return false
        }
    }
}

extension Post {
    convenience init?(ckRecord: CKRecord) {
        guard let caption = ckRecord[PostStrings.captionKey] as? String,
              let timestamp = ckRecord[PostStrings.timestampKey] as? Date,
              let commentCount = ckRecord[PostStrings.commentCountKey] as? Int else { return nil }
        
        var foundPhoto: UIImage?
        if let photoAsset = ckRecord[PostStrings.photoKey] as? CKAsset {
            do {
                let data = try Data(contentsOf: photoAsset.fileURL!)
                foundPhoto = UIImage(data: data)
            } catch {
                print("Could not transform asset to data")
            }
        }
        
        self.init(caption: caption, timestamp: timestamp, comments: [], recordID: ckRecord.recordID, photo: foundPhoto, commentCount: commentCount)
    }
}

extension CKRecord {
    convenience init(post: Post) {
        self.init(recordType: PostStrings.recordTypeKey, recordID: post.recordID)
        self.setValuesForKeys([
            PostStrings.captionKey : post.caption,
            PostStrings.timestampKey : post.timestamp,
            PostStrings.commentCountKey : post.commentCount
        ])
        
        if post.photoAsset != nil {
            self.setValue(post.photoAsset, forKey: PostStrings.photoKey)
        }
    }
}
