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
    
    // SubView
    let searchBar = SearchBar()
    let listView = BlogListView()
    
    // AlertAction 이벤트를 담아 전달해주는 객체
    let alertActionTapped = PublishRelay<AlertAction>()
    
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
        
        // searchbar의 shouldLoadResult 옵저버 이벤트가 발생하면 여기로 값이 전달 됨
        let blogResult = searchBar.shouldLoadResult
            .flatMapLatest {
                SearchBlogNetwork().searchBlog(query: $0) // SearchBlogNetwork로 값을 보냄
            }
            .share() // 스트림 공유
        
        // blogResult는 데이터와 에러를 반환해주는 타입(Result<>)이다.
        // blogResult - 데이터
        let blogValue = blogResult
            .map { data -> DKBlog? in
                guard case .success(let value) = data else {
                    return nil
                }
                return value
            }
            .filter { $0 != nil }
        
        // blogResult - 에러
        let blogError = blogResult
            .map { data -> String? in
                guard case .failure(let error) = data else {
                    return nil
                }
                return error.localizedDescription
            }
            .filter { $0 != nil }
        
        //네트워크를 통해 가져온 값을 CellData로 변환
        let cellData = blogValue
            .map { blog -> [BlogListCellData] in 
                guard let blog = blog else {
                    return []
                }
                
                return blog.documents
                    .map {
                        let thumbnailURL = URL(string: $0.thumbnail ?? "") // string -> URL
                        return BlogListCellData(
                            thumbnailURL: thumbnailURL,
                            name: $0.name,
                            title: $0.title,
                            datetime: $0.datetime
                        )
                    }
            }
        
        //FilterView를 선택했을 때 나오는 alertsheet를 선택했을 때 type
        let sortedType = alertActionTapped
            .filter {
                switch $0 {
                case .title, .datetime:
                    return true
                default:
                    return false
                }
            }
            .startWith(.title) // 초기값
        
        
        //MainViewController -> ListView
        Observable
            .combineLatest(
                sortedType,
                cellData
            ) { type, data -> [BlogListCellData] in
                switch type {
                case .title:
                    return data.sorted { $0.title ?? "" < $1.title ?? "" }
                case .datetime:
                    return data.sorted { $0.datetime ?? Date() > $1.datetime ?? Date() }
                case .cancel, .confirm:
                    return data
                }
            }
            .bind(to: listView.cellData)
            .disposed(by: disposeBag)
        
        
        let alertSheetForSorting = listView.headerView.sortButtonTapped
            .map { _ -> Alert in
                return (title: nil, message: nil, actions: [.title, .datetime, .cancel], style: .actionSheet)
            }
        
        let alertForErrorMessage = blogError
            .do(onNext: { message in
                print("error: \(message ?? "")")
            })
            .map { _ -> Alert in
                return (
                    title: "앗!",
                    message: "예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
                    actions: [.confirm],
                    style: .alert
                )
            }
        
        // 헤더뷰(FilterView)의 필터 버튼이 눌리면, 에러가 발생했을 때 alert이 나타나도록
        Observable
            .merge(
                alertSheetForSorting,
                alertForErrorMessage
            )
            .asSignal(onErrorSignalWith: .empty()) // asSignal : Observalbe -> Signal로 변환
            .flatMapLatest { alert -> Signal<AlertAction> in
                let alertController = UIAlertController(title: alert.title, message: alert.message, preferredStyle: alert.style)
                return self.presentAlertController(alertController, actions: alert.actions)
            }
            .emit(to: alertActionTapped) // 구독(subscribe)
            .disposed(by: disposeBag)
    }
    
    private func attribute() {
        title = "다음 검색"
//        view.backgroundColor = .white
    }
    
    private func layout() {
        [searchBar, listView].forEach { view.addSubview($0) }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        
        listView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// Alert
extension MainViewController {
    typealias Alert = (title: String?, message: String?, actions: [AlertAction], style: UIAlertController.Style)

    enum AlertAction: AlertActionConvertible {
        // AlertAction case
        case title, datetime, cancel
        case confirm
        
        var title: String {
            switch self {
            case .title:
                return "Title"
            case .datetime:
                return "Datetime"
            case .cancel:
                return "취소"
            case .confirm:
                return "확인"
            }
        }
        
        var style: UIAlertAction.Style {
            switch self {
            case .title, .datetime:
                return .default
            case .cancel, .confirm:
                return .cancel
            }
        }
    }
    
    func presentAlertController<Action: AlertActionConvertible>(_ alertController: UIAlertController, actions: [Action]) -> Signal<Action> {
        if actions.isEmpty { return .empty() }
        
        return Observable
            .create { [unowned self] observer in
                for action in actions {
                    alertController.addAction(
                        UIAlertAction(
                            title: action.title,
                            style: action.style,
                            handler: { _ in
                                observer.onNext(action)
                                observer.onCompleted()
                            }
                        )
                    )
                }
                self.present(alertController, animated: true, completion: nil)
                
                return Disposables.create {
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
            .asSignal(onErrorSignalWith: .empty()) // asSignal : Observalbe -> Signal로 변환
        }
}
