//
//  CollectionViewItem.swift
//  TestPlayer
//
//  Created by Christopher Fouts on 5/9/22.
//

import Cocoa

class CollectionViewItem: NSCollectionViewItem {
    

    var poster: Poster? {
        didSet {
            guard isViewLoaded else { return }
            
            if let poster = poster {
                imageView?.image = NSImage(named: "loading")
                textField?.stringValue = poster.title
            } else {
                imageView?.image = nil
                textField?.stringValue = ""
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            view.layer?.borderWidth = isSelected ? 5.0 : 0.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor
        
        view.layer?.borderColor = NSColor.white.cgColor
        view.layer?.borderWidth = 0.0
    }
    
    
    func loadImage(_ url: URL) {
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.imageView?.image = NSImage(data: data)
            }
            
            // TODO: add error handling
//            if let error = error {
//
//                print(error.localizedDescription)
//            }
//
//            if let response = response {
//                dump(response)
//            }
            
        }
        .resume()
    }
}
