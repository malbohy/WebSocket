// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let streamStartingResponseModel = try? newJSONDecoder().decode(StreamStartingResponseModel.self, from: jsonData)

import Foundation

// MARK: - StreamStartingResponseModel
struct StreamStartingResponseModel: Codable {
    let type: String?
    let transID: Double?
    let data: DataClass?

    enum CodingKeys: String, CodingKey {
        case type
        case transID = "transId"
        case data
    }
}

// MARK: - DataClass
struct DataClass: Codable {
    let uuid: String?
    let feedID: Int?
    let publisherID, streamID, sdp: String?

    enum CodingKeys: String, CodingKey {
        case uuid
        case feedID = "feedId"
        case publisherID = "publisherId"
        case streamID = "streamId"
        case sdp
    }
}
