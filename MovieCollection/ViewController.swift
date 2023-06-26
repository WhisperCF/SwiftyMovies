//
//  ViewController.swift
//  TestPlayer
//
//  Created by Christopher Fouts on 5/9/22.
//

import Cocoa

class ViewController: NSViewController, NSCollectionViewDelegate, FeedLoaderDelegate {
    
    @IBOutlet var favoritesCollection: NSCollectionView!
    @IBOutlet var moviesCollection: NSCollectionView!
    
    let feedLoader = FeedLoader()
    var indexPathsOfItemsBeingDragged: Set<IndexPath>!
    var originCollection: NSCollectionView!
    var draggingItem: NSCollectionViewItem!
    var selectedMovie: Set<IndexPath>!
    var selectedCollection: FeedType!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.wantsLayer = true
        let bgColor = NSColor.black.cgColor
        self.view.layer?.backgroundColor = bgColor
        
        configureMoviesView()
        configureFavoritesView()
        let type = NSPasteboard.PasteboardType.init(rawValue: "drag_type")
        self.favoritesCollection.registerForDraggedTypes([type])
        self.moviesCollection.registerForDraggedTypes([type])
        feedLoader.loaderDelegate = self
        
        // delete key support
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.keyDown(with: $0) {
                return nil // needed to get rid of beep
            } else {
                return $0
            }
        }
    }
    
    func didLoadData() {
        reloadCollections()
    }
    
    func reloadCollections() {
        favoritesCollection.reloadData()
        moviesCollection.reloadData()
    }
    
    private func configureFavoritesView() {
        let layout = NSCollectionViewGridLayout()
        layout.maximumNumberOfRows = 4
        layout.minimumItemSize = NSSize(width:160.0, height: 240.0)
        layout.maximumItemSize = NSSize(width:160.0, height: 260.0)
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        favoritesCollection.collectionViewLayout = layout
        
        favoritesCollection.wantsLayer = true
        
        let bgColor = NSColor.black.cgColor
        
        favoritesCollection.layer?.backgroundColor = bgColor
    }
    
    private func configureMoviesView() {
        let layout = NSCollectionViewGridLayout()
        layout.maximumNumberOfRows = 4
        layout.minimumItemSize = NSSize(width:160.0, height: 240.0)
        layout.maximumItemSize = NSSize(width:160.0, height: 260.0)
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 10.0
        moviesCollection.collectionViewLayout = layout
        
        moviesCollection.wantsLayer = true
        
        let bgColor = NSColor.black.cgColor
        
        moviesCollection.layer?.backgroundColor = bgColor
    }
    
    // MARK: To add delete key support
    private func keyDown(with event: NSEvent) -> Bool {
        if event.charactersIgnoringModifiers == String(UnicodeScalar(NSDeleteCharacter)!) {
            self.deleteSelection(self)
            return true
        } else {
            return false
        }
    }
    
    // MARK: called from first responder
    @IBAction func deleteSelection(_ sender: Any) {
        
        if let first = selectedMovie.first {
            feedLoader.deleteEntry(selectedCollection, at: first)
        }
        
        if selectedCollection == .movies {
            moviesCollection.animator().deleteItems(at: selectedMovie)
        } else {
            favoritesCollection.animator().deleteItems(at: selectedMovie)
        }
        
        reloadCollections()
    }
    
    
    // MARK: handle selection for two collection views
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
        if collectionView == moviesCollection {
            selectedCollection = .movies
        } else {
            selectedCollection = .favorites
        }
        
        selectedMovie = indexPaths
        
        if collectionView == moviesCollection {
            favoritesCollection.deselectAll(self)
        } else {
            moviesCollection.deselectAll(self)
        }
    }
    
    
    
    // MARK: drag and drop
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        
        // no moving the 'Add to Favorites' poster
        let lastIndex = feedLoader.favorites.count - 1
        let indexPath = IndexPath(indexes: [0, lastIndex])
        
        if let pathToCheck = indexPaths.first {
            if pathToCheck == indexPath  && collectionView == favoritesCollection {
                favoritesCollection.deselectAll(self)
                return false
            }
        }
        
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
        
        let data = try? NSKeyedArchiver.archivedData(withRootObject: indexPaths, requiringSecureCoding: false)
        if let data = data {
            let indexData = Data(data)
            let type = NSPasteboard.PasteboardType.init(rawValue: "drag_type")
            pasteboard.declareTypes([type], owner: self)
            pasteboard.setData(indexData, forType: type)

            return true
        } else {
            return false
        }

    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        indexPathsOfItemsBeingDragged = indexPaths
        originCollection = collectionView
        if let first = indexPaths.first {
            draggingItem = collectionView.item(at: first)
        }
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        
        if indexPathsOfItemsBeingDragged == nil {
            return NSDragOperation.copy
        } else {
            return NSDragOperation.move
        }
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        if indexPathsOfItemsBeingDragged != nil {
            for originPath in indexPathsOfItemsBeingDragged {
                if collectionView == originCollection {
                    // move within collection
                    if collectionView == self.moviesCollection {
                        feedLoader.moveMovieItem(from: originPath, to: indexPath)
                        if indexPath[1] <= feedLoader.movies.count - 1 {
                            moviesCollection.animator().moveItem(at: originPath, to: indexPath)
                            moviesCollection.deselectItems(at: [indexPath])
                        } else {
                            let placementIndex = feedLoader.movies.count - 1
                            let fixedIndexPath = IndexPath(indexes: [0, placementIndex])
                            moviesCollection.animator().moveItem(at: originPath, to: fixedIndexPath)
                            moviesCollection.deselectItems(at: [fixedIndexPath])
                        }
                    } else {
                        feedLoader.moveFavoriteItem(from: originPath, to: indexPath)
                        if indexPath[1] <= feedLoader.favorites.count - 2 {
                            favoritesCollection.animator().moveItem(at: originPath, to: indexPath)
                        } else {
                            let placementIndex = feedLoader.favorites.count - 2
                            let fixedIndexPath = IndexPath(indexes: [0, placementIndex])
                            favoritesCollection.animator().moveItem(at: originPath, to: fixedIndexPath)
                            favoritesCollection.deselectItems(at: [fixedIndexPath])
                        }
                        favoritesCollection.deselectItems(at: [indexPath])
                    }
                } else {
                    // move to opposite collection
                    if collectionView == self.favoritesCollection {
                        
                        feedLoader.moveFrom(FeedType.movies, start: originPath, end: indexPath)
                        moviesCollection.animator().deleteItems(at: [originPath])
                        if indexPath[1] <= feedLoader.favorites.count - 2 {
                            favoritesCollection.animator().insertItems(at: [indexPath])
                        } else {
                            let placementIndex = feedLoader.favorites.count - 2
                            let fixedIndexPath = IndexPath(indexes: [0, placementIndex])
                            favoritesCollection.animator().insertItems(at: [fixedIndexPath])
                        }
                        
                    } else {
                        feedLoader.moveFrom(FeedType.favorites, start: originPath, end: indexPath)
                        moviesCollection.animator().insertItems(at: [indexPath])
                        favoritesCollection.animator().deleteItems(at: [originPath])

                    }
                }
                reloadCollections()
            }
        }
        return true
    }

    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
       
        return // remove this return to enable dragging out to delete...
        
        // dragging out of the view to delete 'works' but the default animation back to the original position doesn't clearly communicate that to the user
        guard let first = indexPathsOfItemsBeingDragged.first else { return }
        if operation.rawValue == 0 {
            if collectionView == moviesCollection {
                feedLoader.deleteEntry(.movies, at: first)
                moviesCollection.animator().deleteItems(at: [first])
            } else {
                feedLoader.deleteEntry(.favorites, at: first)
            }
        }
        
        reloadCollections()
    }

}


extension ViewController : NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
                
        let id = NSUserInterfaceItemIdentifier.init(rawValue: "CollectionViewItem")
        let item = collectionView.makeItem(withIdentifier: id, for: indexPath)
        guard let collectionViewItem = item as? CollectionViewItem else {return item}
        
        if collectionView == self.moviesCollection {
            let feedItem = feedLoader.movies[indexPath[1]]
            if let url = URL(string: feedItem.imageUrl[2].label) {
                let title = feedItem.title.label
                let poster = Poster.init(title: title, url: url)
                collectionViewItem.loadImage(poster.url)
                collectionViewItem.poster = poster
                return collectionViewItem
            }
        } else {
            let feedItem = feedLoader.favorites[indexPath[1]]
            if let url = URL(string: feedItem.imageUrl[2].label) {
                let title = feedItem.title.label
                let poster = Poster.init(title: title, url: url)
                collectionViewItem.loadImage(poster.url)
                collectionViewItem.poster = poster
                return collectionViewItem
            }
        }
        
        return item

    }
    
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == moviesCollection {
            return feedLoader.movies.count
        } else {
            return feedLoader.favorites.count
        }
        
    }

}
