//
//  Feed.swift
//  TestPlayer
//
//  Created by Christopher Fouts on 5/9/22.
//

import Cocoa


struct Movies: Codable {
    
    let feed: Feed
}

struct Feed: Codable {
    
    let entry: [Entry]
}

class Entry: NSObject, NSCoding, Codable {
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "im:image"
        case title = "im:name"
        case summary
    }
    
    struct Label: Codable {
        let label: String
    }
    
    let title: Label
    let summary: Label
    let imageUrl: [Label]
    let image: NSImage? // unused for now... maybe we want to cache images at some point?
    
    init(title: String, summary: String, imageUrl: String) {
        self.title = Label(label: title)
        self.summary = Label(label: summary)
        self.imageUrl = [Label(label: imageUrl), Label(label: imageUrl), Label(label: imageUrl)] // kinda hacky... this is to match the JSON placement of the larger image
        self.image = nil
    }
    
    
    // for drag and drop
    func encode(with coder: NSCoder) {
        coder.encode(title, forKey: "title")
        coder.encode(summary, forKey: "summary")
        coder.encode(imageUrl, forKey: "imageUrl")
    }
    
    required init?(coder: NSCoder) {
        title = coder.decodeObject(forKey: "title") as? Label ?? Label.init(label: "unknown title")
        summary = coder.decodeObject(forKey: "summary") as? Label ?? Label.init(label: "unknown summary")
        let unknownLabel = Label.init(label: "unknown urls")
        imageUrl = coder.decodeObject(forKey: "imageUrl") as? [Label] ?? [unknownLabel]
        image = nil
        
    }
    
    // for JSON decode
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        imageUrl = try container.decode([Label].self, forKey: .imageUrl)
        title = try container.decode(Label.self, forKey: .title)
        summary = try container.decode(Label.self, forKey: .summary)
        image = nil
    }


}


