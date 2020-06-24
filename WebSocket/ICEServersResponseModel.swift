// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let iCEServersResponseModel = try? newJSONDecoder().decode(ICEServersResponseModel.self, from: jsonData)

import Foundation

// MARK: - ICEServersResponseModel
struct ICEServersResponseModel: Codable {
    let iceServers: ICEServersResponse?
    let s: String?
    
    private enum CodingKeys : String, CodingKey {
        case iceServers = "v",
        s
    }
    
}

// MARK: - V
struct ICEServersResponse: Codable {
    let iceServers: [IceServer]?
}

// MARK: - IceServer
struct IceServer: Codable {
    let url, username, credential: String?
}
