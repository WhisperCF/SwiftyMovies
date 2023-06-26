//
//  FeedLoader.swift
//  TestPlayer
//
//  Created by Christopher Fouts on 5/9/22.
//

import Cocoa

protocol FeedLoaderDelegate {
    func didLoadData()
}

enum FeedType {
    case favorites
    case movies
}

class FeedLoader {
    
    var loaderDelegate: FeedLoaderDelegate!
    
    var movies = [Entry]()
    var favorites = [Entry]()
    var iTunesURLString = "https://itunes.apple.com/us/rss/topmovies/limit=100/json"
    
    // start here
    init() {
        
        // set up placeholder for favorites
        insertPlaceholder()
        
        // load data from remote url
        fetchMovies()
        
    }
    
    // manage data - sent by Collection Views
    func moveMovieItem(from: IndexPath, to: IndexPath) {
        
        let startIndex = from[1]
        let endIndex = to[1]
        
        let item: Entry = movies[startIndex]
        movies.remove(at: startIndex)
        if endIndex > movies.count {
            movies.append(item)
        } else {
            movies.insert(item, at: endIndex)
        }
    }
    
    func moveFavoriteItem(from: IndexPath, to: IndexPath) {
        let startIndex = from[1]
        let endIndex = to[1]
        
        let item: Entry = favorites[startIndex]
        favorites.remove(at: startIndex)
        if endIndex >= favorites.count {
            favorites.insert(item, at: favorites.count - 1)
        } else {
            favorites.insert(item, at: endIndex)
        }
    }
    
    func moveFrom(_ feed: FeedType, start: IndexPath, end: IndexPath) {
        
        let startIndex = start[1]
        let endIndex = end[1]
        
        switch feed {
        case .favorites:
            let item: Entry = favorites[startIndex]
            favorites.remove(at: startIndex)
            
            if endIndex > movies.count {
                movies.append(item)
            } else {
                movies.insert(item, at: endIndex)
            }
        case .movies:
            let item: Entry = movies[startIndex]
            movies.remove(at: startIndex)
            
            if endIndex == 0 {
                favorites.insert(item, at: 0)
            } else if endIndex >= favorites.count{
                favorites.insert(item, at: favorites.count - 1)
            } else {
                favorites.insert(item, at: endIndex)
            }
        }
        
    }
    
    func deleteEntry(_ type: FeedType, at path: IndexPath) {
        
        let index = path[1]
        
        switch type {
        case .favorites:
            favorites.remove(at:index)
        case .movies:
            movies.remove(at: index)
        }
    }
    
    func insertPlaceholder() {
        
        let tempURL = Bundle.main.url(forResource: "newFavorite", withExtension: "png")
        let tempEntry = Entry(title: "Drag to this row to add Favorite...", summary: "Add to Favorites", imageUrl: tempURL!.absoluteString)
        favorites.append(tempEntry)
    }
    
    
    func fetchMovies() {
        let call = NetworkCall()
        
        call.fetchRemoteContent(from: iTunesURLString) { (model: Movies) in
            DispatchQueue.main.async {
                self.movies = model.feed.entry
                self.loaderDelegate.didLoadData()
            }
        }
    }

}
