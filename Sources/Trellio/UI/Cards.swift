import UIKit
import PTDList
import Combine

public final class TRUICardCell: UICollectionViewListCell, PTDListCell {
    public typealias Item = TRCard
    public func setup(context: PTDListContext<TRUICardCell>) {
        var config = UIListContentConfiguration.valueCell()
        config.text = context.item.name
        if let starred = context.item.starred {
            config.secondaryText = "⭐️ \(starred)"
        }
        contentConfiguration = config
    }
}

open class TRUICardListController: PTDListController<TRUICardCell> {
    
    private var subscriptions = Set<AnyCancellable>()
    
    open var mode: Mode? {
        didSet {
            getCards()
            updateTitle()
        }
    }
    
    private var trList: TRList?
    private var trBoard: TRBoard?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        #if !os(tvOS)
        navigationController?.navigationBar.prefersLargeTitles = true
        #endif
    }
    
    private func getCards() {
        guard let mode = mode else { return }
        let publisher: AnyPublisher<[TRCard], TRError>
        switch mode {
        case let .boardID(board):
            publisher = Trellio.getCards(boardId: board).eraseToAnyPublisher()
            trList = nil
            trBoard = nil
        case let .listID(list):
            publisher = Trellio.getCards(listId: list).eraseToAnyPublisher()
            trList = nil
            trBoard = nil
        case let .board(board):
            publisher = board.getCards().eraseToAnyPublisher()
            trBoard = board
            trList = nil
        case let .list(list):
            publisher = list.getCards().eraseToAnyPublisher()
            trList = list
            trBoard = nil
        }
        
        publisher
            .catch { err -> Empty<[TRCard], Never> in
                print(err)
                return .init()
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.items = $0
            }
            .store(in: &subscriptions)
    }
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getCards()
    }
    
    public enum Mode {
        case boardID(String), board(TRBoard)
        case listID(String), list(TRList)
    }
    
    private func updateTitle() {
        if let list = trList {
            title = list.name
        } else if let board = trBoard {
            title = board.name
        } else {
            title = "Cards"
        }
    }
}
