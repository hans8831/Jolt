//
//  AlarmJsonInfo.swift
//  Jolt
//
//  Created by user on 12/27/16.
//  Copyright © 2016 user. All rights reserved.
//

import UIKit

class AlarmJsonInfo: NSObject, NSCoding {
    private var id: Int!
    private var title: String!
    private var desc: NSAttributedString!
    private var artist: String!
    private var image_url: URL!
    private var song_url: URL!
    
    var infoId: Int {
        get {
            return id
        }
        set {
            id = newValue
        }
    }
    var titleInfo: String {
        get {
            return title
        }
        set {
            title = newValue
        }
    }
    var descriptionInfo: NSAttributedString {
        get {
            return desc
        }
        set {
            desc = newValue
        }
    }
    var artistInfo: String {
        get {
            return artist
        }
        set {
            artist = newValue
        }
    }
    var imageInfo: URL {
        get {
            return image_url
        }
        set {
            image_url = newValue
        }
    }
    var songInfo: URL {
        get {
            return song_url
        }
        set {
            song_url = newValue
        }
    }
    
    override init() {
        self.id = 0
        self.title = ""
        self.desc = NSAttributedString()
        self.artist = ""
        self.image_url = URL(fileURLWithPath: "file:///")
        self.song_url = URL(fileURLWithPath: "file:///")
    }
    init(id: Int, title: String, artist: String, desc: NSAttributedString, song: URL, image: URL) {
        self.id = id
        self.title = title
        self.desc = desc
        self.artist = artist
        self.image_url = image
        self.song_url = song
    }
    required convenience init(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: "id") as! Int
        let title = aDecoder.decodeObject(forKey: "title") as! String
        let artist = aDecoder.decodeObject(forKey: "artist") as! String
        let desc = aDecoder.decodeObject(forKey: "desc") as! NSAttributedString
        let song = aDecoder.decodeObject(forKey: "song") as! URL
        let image = aDecoder.decodeObject(forKey: "image") as! URL
        
        self.init(id: id, title: title, artist: artist, desc: desc, song: song, image: image)
    }
    func encode(with aCoder: NSCoder){
        aCoder.encode(id, forKey: "id")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(artist, forKey: "artist")
        aCoder.encode(desc, forKey: "desc")
        aCoder.encode(image_url, forKey: "image")
        aCoder.encode(song_url, forKey: "song")
    }
}
