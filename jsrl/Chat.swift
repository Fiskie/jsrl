//
//  Chat.swift
//  jsrl
//

import Foundation

enum ChatFetchError: Error {
    case xmlParserInitFailed
}

class Chat : Resource {
    var recvEndpoint = "/chat/messages.xml"
    var sendEndpoint = "/chat/save.php"
    
    /**
     Fetch the latest chat messages in messages.xml.
     
     - properties:
        - callback: Callback returning an Error (nil if OK) and an array of
                    ChatMessage responses.
    */
    func fetch(_ callback: @escaping (_ err: Error?, _ body: [ChatMessage])->()) {
        let url = URL(string: context.root + recvEndpoint)
        
        DispatchQueue.main.async {
            let parser = XMLParser(contentsOf: url!)
            
            if let parser = parser {
                let chatParser = ChatParser()
                parser.delegate = chatParser
                parser.parse()
                
                callback(nil, chatParser.messages)
            } else {
                callback(ChatFetchError.xmlParserInitFailed, [])
            }
        }
    }
    
    /**
     Post a message to the chat.
     
     - properties:
        - message: A ChatMessage.
        - callback: Callback returning an Error (nil if OK) and an URLResponse.
     */
    func send(_ message: ChatMessage, _ callback: @escaping (_ err: Error?, _ response: URLResponse?)->()) {
        let url = URL(string: context.root + sendEndpoint)
        
        // Create our form string. There's probably a better way to do this
        let form: [String: String] = [
            "chatmessage": message.text,
            "chatpassword": message.password ? "true" : "false",
            "username": message.username
        ]
        
        let formData = form.map({"\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"}).joined(separator: "&")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.httpBody = formData.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            (data, response, error) in
            
            guard let _ = data, let _:URLResponse = response  , error == nil else {
                callback(error, response)
                return
            }
            
            callback(nil, response)
        }
        
        task.resume()
    }
}

/**
 An entity representing a single message digest.
 */
class ChatMessage: CustomStringConvertible {
    /**
     Message text.
     */
    var text: String = ""
    
    /**
     Usernames. May contain HTML
     */
    var username: String = ""
    
    /**
     is a 40-character hash, e.g. 250e7dd82f8dbba1e0463134ea4f7e3dcdb313e3
     
     It is unknown if this field is decryptable or not:
     - it's too long to be an md5 hash
     - doesn't seem to decode as hex or base64
     - is not referenced in the site's obfuscated javascript source
     */
    var ip: String = ""
    
    /**
     Not sure how this field works yet.
     */
    var password: Bool = false
    
    init() {
        
    }
    
    init(username: String, text: String, ip: String) {
        self.username = username
        self.text = text
        self.ip = ip
    }
    
    var description: String {
        return "[ChatMessage] \(username): \(text)"
    }
}
