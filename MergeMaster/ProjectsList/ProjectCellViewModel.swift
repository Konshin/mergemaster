//
//  ProjectCellViewModel.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation
import RxSwift

struct ProjectCellViewModel {
    let name: String
    let url: String
    let selected: Observable<Bool>
}
