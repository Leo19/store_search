//
//  Search.swift
//  StoreSearch
//
//  Created by liushun on 16/1/29.
//  Copyright © 2016年 liushun. All rights reserved.
//

import Foundation

typealias SearchComplete = (Bool) -> Void

class Search {
    //var searchResults = [SearchResult]()
    //var hasSearched = false
    //var isLoading = false
    
    // 用一个实例变量存储NSURLSessionDataTask做一些容错处理
    private var dataTask: NSURLSessionDataTask? = nil
    
    // 本类可以set其他的类智能读它
    private(set) var state: State = .NotSearchedYet
    
    // 搜索的种类
    enum Category: Int {
        case All = 0
        case Music = 1
        case Software = 2
        case EBooks = 3
        
        var entityName: String {
            switch self {
                case .All: return ""
                case .Music: return "musicTrack"
                case .Software: return "software"
                case .EBooks: return "ebook"
            }
        }
    }
    
    // 搜索状态
    enum State {
        case NotSearchedYet
        case Loading
        case NoResults
        case Results([SearchResult])
    }
    
    func performSearchForText(text: String, category: Category, completion: SearchComplete) {
        print("Searching...")
        if !text.isEmpty {
            // 防止用户点了多次搜索按钮后，因为延迟覆盖了上一次搜索结果
            // 还有一个好处就是，如果用户只点了一次就不会cancel，因为是Optional直接是nil了
            dataTask?.cancel()
        
            // 加载中
            // isLoading = true
            state = .Loading
        
            // 搜索过就置为true
            //hasSearched = true
            //searchResults = [SearchResult]()
        
            let url = urlWithSearchText(text,category: category)
            let session = NSURLSession.sharedSession()
            dataTask = session.dataTaskWithURL(url,completionHandler: {
                data, response, error in
                var success = false
                self.state = .NotSearchedYet
                if let error = error where error.code == -999 {
                    return
                }
                // 两个隐式解包，避免写嵌套着写if else 了
                if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 200,let data = data, dictionary = self.parseJSON(data) {
                    
                    // 搜索结果
                    var searchResults = self.parseDictionary(dictionary)
                    if searchResults.isEmpty {
                        self.state = .NoResults
                    } else {
                        searchResults.sortInPlace(<)
                        self.state = .Results(searchResults)
                    }

                    print("Success!")
                    success = true
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    // 本类中自定义的一个闭包
                    completion(success)
                }
                })
                dataTask?.resume()
            }
    }
    
    // 第一步将地址翻译成NSURL
    func urlWithSearchText(searchText: String, category: Category) -> NSURL {
        let entityName = category.entityName
        
        // 要去除一下特殊字符例如空格或者 < > 等
        let escapedSearchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        let urlString = String(format: "http://itunes.apple.com/search?term=%@&limit=150&entity=%@", escapedSearchText, entityName)
        let url = NSURL(string: urlString)
        return url!
    }
    
    // 解析JSON
    func parseJSON(data: NSData) -> [String: AnyObject]? {
        // NSData 类型的实际上是16进制序列
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    // 深度解析json串中的字典 AnyObject其实是为了兼容OC
    func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult]{
        // 1.
        guard let array = dictionary["results"] as? [AnyObject] else {
            print("Expected 'results' array")
            return []
        }
        // 2.
        var searchResults = [SearchResult]()
        for resultDict in array {
            // 3.
            if let resultDict = resultDict as? [String: AnyObject] {
                // 下面的if let如果wrapperType不等于track这个就是空的所以用Optional
                var searchResult: SearchResult?
                
                if let wrapperType = resultDict["wrapperType"] as? String {
                    print("=======wrapperType: \(wrapperType)")
                    switch wrapperType {
                    case "track":
                        searchResult = parseTrack(resultDict)
                    case "audiobook":
                        searchResult = parseAudioBook(resultDict)
                    case "software":
                        searchResult = parseSoftware(resultDict)
                    default:
                        break
                    }
                } else if let kind = resultDict["kind"] as? String where kind == "ebook" {
                    searchResult = parseEBook(resultDict)
                }
                
                if let result = searchResult {
                    searchResults.append(result)
                }
                // 4.kind和wrapperType是区分歌曲/视频/eBook这些json的最重要的两个字段
                //                if let wrapperType = resultDict["wrapperType"] as? String, let kind = resultDict["kind"] as? String {
                //                    print("wrapperType: \(wrapperType), kind: \(kind)")
                //                }
            }
        }
        return searchResults
    }
    
    // 一些列的解析不同的属性值
    func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        // as! String? 表示强转成optional String，而as? String表示转换成String但是
        // 本身可能会失败，并且为nil
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? Double {
            searchResult.price = price
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    // 解析AudioBook相关的属性
    func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["collectionPrice"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    // 解析软件的相关属性
    func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    // 解析EBook的相关属性
    func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genres: AnyObject = dictionary["genres"] {
            searchResult.genre = (genres as! [String]).joinWithSeparator(", ")
        }
        return searchResult
    }
}
