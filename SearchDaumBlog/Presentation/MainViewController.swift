//
//  MainViewController.swift
//  SearchDaumBlog
//
//  Created by wons on 2023/02/01.
//

import UIKit
import RxCocoa
import RxSwift

class MainViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    // TODO: subView
    // listView
    // searchBar
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        bind()
        attribute()
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        
    }
    
    private func attribute() {
        title = "다음 검색"
//        view.backgroundColor = .white
    }
    
    private func layout() {
        
    }
}
