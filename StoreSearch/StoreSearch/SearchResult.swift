//
//  SearchResult.swift
//  StoreSearch
//
//  Created by liushun on 16/1/21.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class SearchResult {
    var name = ""
    var artistName = ""
    var artworkURL60 = ""
    var artworkURL100 = ""
    var storeURL = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
    
    // 一些自定义页面显示文字的风格
    func kindForDisplay() -> String {
        switch kind {
        case "album": return "Album"
        case "audiobook": return "Audio Book"
        case "book": return "Book"
        case "ebook": return "E-Book"
        case "feature-movie": return "Movie"
        case "music-video": return "Music Video"
        case "podcast": return "Podcast"
        case "software": return "App"
        case "song": return "Song"
        case "tv-episode": return "TV Episode"
        default: return kind
        }
    }
}

func < (first: SearchResult,second: SearchResult) -> Bool {
    return first.name.localizedStandardCompare(second.name) == .OrderedAscending
}

func > (first: SearchResult,second: SearchResult) -> Bool {
    return first.name.localizedStandardCompare(second.name) == .OrderedDescending
}
