//
//  WebSocketResponseModel.swift
//  WebSocket
//
//  Created by Sameh Salama on 6/23/20.
//  Copyright © 2020 Sameh Salama. All rights reserved.
//

import Foundation

struct WebSocketResponseModel: Codable {
    var status:String!
    var data:WebSocketResponseDataModel!
}



struct WebSocketResponseDataModel: Codable {
    var subscribeRequiresAuth:Bool!
    var wsUrl:String!
    var urls:[String]!
    var jwt:String!
    var streamAccountId:String!
}
