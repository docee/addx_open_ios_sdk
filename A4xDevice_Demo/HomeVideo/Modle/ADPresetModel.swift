//
//  ADPresetModel.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
public struct ADPresetModel : Codable {
    public var imageUrl : String?
    public var name : String?
    public var id : Int?
    public var coordinate : String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "rotationPointName"
        case imageUrl = "thumbnailUrl"
        case coordinate 
    }
}

public struct ADPresetModelResponse : Codable {
    var list : [ADPresetModel]?
    
//    public static func testData() -> [ADPresetModel] {
//        var array : [ADPresetModel] = []
//        var temp = ADPresetModel()
//        temp.imageUrl = "https://addx-test.s3.cn-north-1.amazonaws.com.cn/img/121542_11984235.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20191121T102634Z&X-Amz-SignedHeaders=host&X-Amz-Expires=172800&X-Amz-Credential=AKIAWLWALEBSL32LBZJI%2F20191121%2Fcn-north-1%2Fs3%2Faws4_request&X-Amz-Signature=c7b57427921bf94647a0d946cd94f5aa2271a1a21ae2216f219b2b0f875df7b2"
//        temp.name = String.kRandom(Words: 2, isCap: true)
//        array.append(temp)
//
//        temp = ADPresetModel()
//        temp.imageUrl = "https://addx-test.s3.cn-north-1.amazonaws.com.cn/img/121543_41270478.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20191121T102634Z&X-Amz-SignedHeaders=host&X-Amz-Expires=172800&X-Amz-Credential=AKIAWLWALEBSL32LBZJI%2F20191121%2Fcn-north-1%2Fs3%2Faws4_request&X-Amz-Signature=b71b93b73f4003dd2d1e6cbd22413485c36dc056a3cf645df910505427771ee5"
//        temp.name = String.kRandom(Words: 2, isCap: true)
//        array.append(temp)
//
//        temp = ADPresetModel()
//        temp.imageUrl = "https://addx-test.s3.cn-north-1.amazonaws.com.cn/img/121544_66495076.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20191121T102634Z&X-Amz-SignedHeaders=host&X-Amz-Expires=172800&X-Amz-Credential=AKIAWLWALEBSL32LBZJI%2F20191121%2Fcn-north-1%2Fs3%2Faws4_request&X-Amz-Signature=9672c2ae1e5f037891aef9382eec52d9c29c184f44cecf284d18d22bb31c5ab8"
//        temp.name = String.kRandom(Words: 2, isCap: true)
//        array.append(temp)
//
//        return array
//    }
}
 

