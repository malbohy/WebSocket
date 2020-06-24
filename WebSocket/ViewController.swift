//
//  ViewController.swift
//  WebSocket
//
//  Created by Sameh Salama on 6/22/20.
//  Copyright © 2020 Sameh Salama. All rights reserved.
//

import UIKit
import SwiftWebSocket
import AVFoundation
import WebRTC



class ViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    var mediaStream: RTCMediaStream!
    var localAudioTrack: RTCAudioTrack!
    var dataChannel: RTCDataChannel!
    
    // MARK: - Properties
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    let publishingToken:String = "9815b6d6175eb8c31d8ec405e49a20f5d394f184ea21ddd5858965c0342085d9"
    var iCEServersResponseModel:ICEServersResponseModel?
    
    var webRTCClient: WebRTCClient?
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        webRTCClient = WebRTCClient()
//        webRTCClient!.delegate = self
        
        
//        webRTCClient!.setup(videoTrack: true, audioTrack: true, dataChannel: true, customFrameCapturer: false)
    }
    
    
    // webrtc
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var peerConnection: RTCPeerConnection! = nil
    var mediaConstraints: RTCMediaConstraints! = nil

//    var socket: SocketIOClient! = nil
    var wsServerUrl: String! = nil
    var peerStarted: Bool = false

    func initWebRTC() {
        RTCInitializeSSL()
        peerConnectionFactory = RTCPeerConnectionFactory()

        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "false"]
        let optionalConstraints = [ "DtlsSrtpKeyAgreement": "true", "RtpDataChannels" : "true", "internalSctpDataChannels" : "true"]


        mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints)

    }
    
    func prepareNewConnection() -> RTCPeerConnection {
        var icsServers: [RTCIceServer] = []
        
        let serverssss = self.iCEServersResponseModel?.iceServers?.iceServers
        for server in serverssss!{
            if let url = server.url,  let userNeme = server.username, let credential = server.credential{
                icsServers.append(RTCIceServer(urlStrings: [url], username:userNeme,credential: credential))
            }
            
        }
        

        let rtcConfig: RTCConfiguration = RTCConfiguration()
        rtcConfig.tcpCandidatePolicy = RTCTcpCandidatePolicy.disabled
        rtcConfig.bundlePolicy = RTCBundlePolicy.maxBundle
        rtcConfig.rtcpMuxPolicy = RTCRtcpMuxPolicy.require
        rtcConfig.iceServers = icsServers;

        peerConnection = peerConnectionFactory.peerConnection(with: rtcConfig, constraints: mediaConstraints, delegate: self)
        peerConnection.add(mediaStream);

        let tt = RTCDataChannelConfiguration();
        tt.isOrdered = false;


        self.dataChannel = peerConnection.dataChannel(forLabel: "testt", configuration: tt)

        self.dataChannel.delegate = self
        print("Make datachannel")
        print("data channel \(self.dataChannel.readyState.rawValue)")

        return peerConnection;
    }
    
    
    
    // MARK: - IBActions
    @IBAction func connectButtonAction(_ sender: UIButton) {
        
//        webRTCClient?.connect(onSuccess: { (_) in
//          print("connected")
//        })
        
//        webRTCClient?.connect(onSuccess: { (description) in
//            print("connected with description")
//            print(description)
//        })
        
        self.getICEServers { [weak self](servers) in
            
            guard let self = self else {return}
            self.iCEServersResponseModel = servers
                self.requestMillicastCredentials { (wsURL, jwt) in
                    guard let wsURL = wsURL, let jwt = jwt else {
                        return
                    }
                    self.connectWebSocket(wsURL: wsURL, jwt: jwt)
                    
                    
                }
            
        }
        
        

        
        
        
        
    }
    
    @IBAction func recordButtonAction(_ sender: UIButton) {
        
        ws?.send(text: "hello")
//        ws?.send(data: )
//        self.ws?.close()
//        print(self.iCEServersResponseModel)
//
//        for server in (self.iCEServersResponseModel?.iceServers?.iceServers)!{
//            print(server.url)
//            print(server.username)
//            print(server.credential)
//            print("\n\n")
//        }
        
        initWebRTC()
        localAudioTrack = peerConnectionFactory.audioTrack(withTrackId: AUDIO_TRACK_ID)
        mediaStream = peerConnectionFactory.mediaStream(withStreamId: LOCAL_MEDIA_STREAM_ID)
        mediaStream.addAudioTrack(localAudioTrack)

        let pc = prepareNewConnection()
        
//        let trakcs = RTCMediaStreamTrack
        
        let singleTrack = mediaStream.audioTracks[0] as RTCMediaStreamTrack
        pc.add(singleTrack, streamIds: [mediaStream.streamId])
        
//        pc.
        
        
        
        
        
        
        
        

//        let tt = RTCDataChannelConfiguration();
//        tt.isOrdered = false;
////
////
//        self.dataChannel = peerConnection.dataChannel(forLabel: "testt", configuration: tt)
        
        
        
        
        
//        print(webRTCClient?.isConnected)
//        webRTCClient?.sendMessge(message: "Hi")
        
    }
    
    // MARK: - Custom Functions
    
    var ws: WebSocket?
    func requestMillicastCredentials(completion: @escaping (String?, String?) -> Void) {
        
        let url = URL(string: "https://director.millicast.com/api/director/publish")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(publishingToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "streamName": "kbqdm648"
        ]
        
        let jsonData: Data? = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else {                    
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }

            
            guard let responseString = String(data: data, encoding: .utf8) else {
                print("failed to stringify data")
                return 
            }
//            print("responseString = \(responseString)")
            
            let jsonData = responseString.data(using: .utf8)!
            let model = try! JSONDecoder().decode(WebSocketResponseModel.self, from: jsonData)
            print("model.data.wsUrl: \(model.data.wsUrl ?? "")")
            print("model.data.jwt: \(model.data.jwt ?? "")")
            
            completion(model.data.wsUrl, model.data.jwt)
        }
        task.resume()
    }
    
    func connectWebSocket(wsURL:String, jwt:String) {
        var messageNum = 0
        let request = URLRequest(url: URL(string:wsURL + "?token=" + jwt)!)
        ws = WebSocket(request: request)
        let send : ()->() = {
            messageNum += 1
            let msg = "\(messageNum): \(NSDate().description)"
            print("send: \(msg)")
            
            self.ws?.send(msg)
            self.messageLabel.text = "send: \(msg)"
            
            
            
            
            
            
            // MARK: - TO-DO - find out how to send microphone output instead of text message
            /*
            ws.binaryType = .nsData
            
            let mp3URL = Bundle.main.url(forResource: "music", withExtension: "mp3")!
            do {
                let fileData = try NSData(contentsOf: mp3URL, options: Data.ReadingOptions.mappedIfSafe)
                let base64String = fileData.base64EncodedString()
                ws.send(data: fileData as Data)
//                ws.send(base64String)
            }
            catch {
                print(error)
            }
            */
        }
        
        
        self.ws?.event.open = {
            print("opened")
            send()
        }
        
        self.ws?.event.close = { code, reason, clean in
            print("close, with reason: \(reason), clean: \(clean)")
        }
        self.ws?.event.error = { error in
            print("error \(error)")
            self.messageLabel.text = "error \(error)"
        }
        self.ws?.event.message = { message in
            self.messageLabel.text = "got message: \(message)"
            if let text = message as? String {
                print("recv: \(text)")
                self.messageLabel.text = "recv: \(text)"
                if messageNum == 10 {
                    self.ws?.close()
                } else {
                    send()
                }
            }
        }
    }
    
    
    func getICEServers(completeHandler:@escaping (_ iceServers:ICEServersResponseModel)->Void){
        let turnURl = "https://turn.millicast.com/webrtc/_turn"
        let serviceUrl = URL(string: turnURl)!
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "PUT"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared

        session.dataTask(with: request) { (data, response, error) in
        if let response = response {
            print("got ICE Response")
            //            print(response)
        }
        if let data = data {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("got ICE JSON")
//                print(json)
                let iCEServersResponseModel = try? JSONDecoder().decode(ICEServersResponseModel.self, from: data)
                if let servers = iCEServersResponseModel{
                    completeHandler(servers)
                }else{
                    print("servers is Empty")
                }
                
                
                
            } catch {
                print(error)
            }
        }
        }.resume()

    }
    
    
    
    
    

}



extension ViewController: RTCPeerConnectionDelegate, RTCDataChannelDelegate{
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
    
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        
    }
}





