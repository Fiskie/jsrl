//
//  TrackLists.swift
//  jsrl
//
//  Created by Fisk on 12/10/2016.
//  Copyright © 2016 fisk. All rights reserved.
//

import Foundation

class TrackLists {
    var context: Context
    
    init(_ ctx: Context) {
        self.context = ctx
    }
    
    func parseUrl(source: String, callback: @escaping ([String])->()) {
        let url = URL(string: source)
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if let data = data,
                let html = String(data: data, encoding: String.Encoding.utf8) {
                print(html)
                
                callback(self.parse(html))
            }
        }
        
        task.resume()
    }
    
    /**
     Parse a large multi-line script to extract an array of song names.
     */
    func parse(_ body: String) -> [String] {
        let pattern = ".* = \"(.*)\""
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: body, options: [], range: NSRange(location: 0, length: body.characters.count))
        
        return matches.map({
            let range = $0.rangeAt(1)
            
            let start = body.index(body.startIndex, offsetBy: range.location)
            let end = body.index(body.startIndex, offsetBy: range.location + range.length)
            return body.substring(with: start ..< end)
        })
    }
}