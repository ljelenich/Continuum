//
//  SearchableRecord.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/7/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    func matches(searchTerm: String) -> Bool
}
