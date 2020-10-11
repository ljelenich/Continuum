//
//  Comment.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import Foundation
import CloudKit

struct CommentStrings {
    static let recordType = "Comment"
    static let textKey = "text"
    static let timestampKey = "timestamp"
    fileprivate static let postKey = "post"
}

class Comment {
    let text: String
    let timestamp: Date
    let recordID: CKRecord.ID
    let postReference: CKRecord.Reference?
    weak var post: Post?
    
    init(text: String, timestamp: Date = Date(), recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), postReference: CKRecord.Reference?) {
        self.text = text
        self.timestamp = timestamp
        self.recordID = recordID
        self.postReference = postReference
    }
}

extension Comment {
    convenience init?(ckRecord: CKRecord) {
        guard let text = ckRecord[CommentStrings.textKey] as? String,
              let timestamp = ckRecord[CommentStrings.timestampKey] as? Date else { return nil }
        let postReference = ckRecord[CommentStrings.postKey] as? CKRecord.Reference
        self.init(text: text, timestamp: timestamp, recordID: ckRecord.recordID, postReference: postReference)
    }
}

extension CKRecord {
    convenience init(comment: Comment) {
        self.init(recordType: CommentStrings.recordType, recordID: comment.recordID)
        self.setValuesForKeys([
            CommentStrings.textKey : comment.text,
            CommentStrings.timestampKey : comment.timestamp
        ])
        if let reference = comment.postReference {
            self.setValue(reference, forKey: CommentStrings.postKey)
        }
    }
}
