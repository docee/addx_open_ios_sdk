//
//  StringEncryption.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 5/25/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
extension String {
    func base64Encoding()->String
    {
        let plainData = self.data(using: String.Encoding.utf8)
        let base64String = plainData?.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue:0))
        return base64String!
    }
    

    func base64Decoding()->String
    {
        let decodedData = NSData(base64Encoded: self, options: NSData.Base64DecodingOptions.init(rawValue: 0))
        let decodedString = NSString(data: decodedData! as Data, encoding: String.Encoding.utf8.rawValue)! as String
        return decodedString
    }
    
    func toDictionary() -> NSDictionary {
        let blankDict : NSDictionary = [:]
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            } catch {
                Log.vLog(level: .error, "extension StringtoDictionary error: \(error.localizedDescription)")
            }
        }
        return blankDict
    }
}
