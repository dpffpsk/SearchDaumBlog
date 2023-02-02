//
//  AlertActionConvertible.swift
//  SearchDaumBlog
//
//  Created by wons on 2023/02/02.
//

import UIKit

protocol AlertActionConvertible {
    var title: String { get }
    var style: UIAlertAction.Style { get }
}
