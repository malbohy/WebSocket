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

import SwiftyJSON

fileprivate let TAG = "ViewController"
fileprivate let AUDIO_TRACK_ID = TAG + "AUDIO"
fileprivate let VIDEO_TRACK_ID = TAG + "VIDEO"
fileprivate let LOCAL_MEDIA_STREAM_ID = TAG + "STREAM"






class ViewController: UIViewController {

    @IBOutlet weak var cameView: UIView!
    // MARK: - IBOutlets
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    var mediaStream: RTCMediaStream!
    var localAudioTrack: RTCAudioTrack!
    
    var localVediosTrack: RTCVideoTrack!
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
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
//        print("")
        
        
        imagePickers = UIImagePickerController()
        
        addCameraInView()
        
        
    }
    
    var imagePickers:UIImagePickerController?

    func addCameraInView(){

    imagePickers = UIImagePickerController()
    if UIImagePickerController.isCameraDeviceAvailable( UIImagePickerController.CameraDevice.rear) {
        imagePickers?.delegate = self
        imagePickers?.sourceType = UIImagePickerController.SourceType.camera

        //add as a childviewcontroller
        addChild(imagePickers!)

        // Add the child's View as a subview
        self.cameView.addSubview((imagePickers?.view)!)
        imagePickers?.view.frame = cameView.bounds
        imagePickers?.allowsEditing = false
        imagePickers?.showsCameraControls = false
        imagePickers?.view.autoresizingMask = [.flexibleWidth,  .flexibleHeight]
        }
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

        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
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
    
    
    var pc:RTCPeerConnection?
    
    @IBAction func recordButtonAction(_ sender: UIButton) {
        
//        ws?.send(text: "hello")
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
        localVediosTrack = peerConnectionFactory.videoTrack(with: peerConnectionFactory.videoSource(), trackId: VIDEO_TRACK_ID)
        
        mediaStream = peerConnectionFactory.mediaStream(withStreamId: LOCAL_MEDIA_STREAM_ID)
        mediaStream.addAudioTrack(localAudioTrack)
        mediaStream.addVideoTrack(localVediosTrack)

        
        pc = prepareNewConnection()
        
//        let trakcs = RTCMediaStreamTrack
        
        mediaStream.audioTracks.forEach { (track) in
            pc!.add(track, streamIds: [mediaStream.streamId])

        }
        mediaStream.videoTracks.forEach { (track) in
            pc!.add(track, streamIds: [mediaStream.streamId])
        }
//        let singleTrack = mediaStream.audioTracks[0] as RTCMediaStreamTrack
        
        
        
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "false"]
        let optionalConstraints = [ "DtlsSrtpKeyAgreement": "true", "RtpDataChannels" : "true", "internalSctpDataChannels" : "true"]
        
        
        pc!.offer(for: RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints)) { (description, error) in
//            print("offer")
//            print(description)
            
            self.pc?.setLocalDescription(description!, completionHandler: { (error) in
                print("setLocalDescription has error : \(error)")
                    
//                RTCSessionDescription(type: .answer, sdp: description!.sdp + "a=x-google-flag:conference\r\n")
//                self.pc?.setRemoteDescription(description!, completionHandler: nil)
                })
            
            
            
            print("offer has error : \(error)")
            
            
            // try again with codec : h264
            let data = ["name":"kbqdm648", "sdp":description!.sdp, "codec":"vp8"]
            
            let transID = Double.random(in: 0...1) * 10000
            let payload:[String : Any] = ["type":"cmd", "transId": transID , "data":data, "name" : "publish"]
            
            let jsonData = try? JSONSerialization.data(withJSONObject:payload)
            
            let json = try? JSON(data: jsonData!)

            
            
            self.ws?.send(json!)
            print("\n\n\n\n")
            print("sent Data ")
            print()
            print("\n\n\n\n")
            
            print("end of offer")
            
        }
        print("data channel \(self.dataChannel.readyState.rawValue)")
        
        
        
//        pc.setLocalDescription(, completionHandler: )
//        pc.
        
        
        
        
        
        let mp3URL = Bundle.main.url(forResource: "music", withExtension: "mp3")!
        do {
            let fileData = try NSData(contentsOf: mp3URL, options: Data.ReadingOptions.mappedIfSafe)
            
//            ws!.send(data: fileData as Data)
//                ws.send(base64String)
        }
        catch {
            print(error)
        }
        
        
        
        
        

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
        
//        ws = WebSocket(url: URL(string: "wss://echo.websocket.org")!)
        
        
        let send : ()->() = {
            messageNum += 1
            
//            let msg = JSON(["mesg": "\(messageNum): \(NSDate().description)"])
//            print("sent: \(msg)")
            
//            self.ws?.send(msg)
//            self.messageLabel.text = "sent: \(msg)"
            self.messageLabel.text = "sent: "
            
            // MARK: - TO-DO - find out how to send microphone output instead of text message
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
            
            self.messageLabel.text = "recv: \(message)"
            self.messageLabel.text = "got message: \(message)"
            self.handelRemoteResponse(message: message)
            if let text = message as? String {
//                print("recv: \(text)")
//                self.messageLabel.text = "recv: \(text)"
                if messageNum == 10 {
//                    self.ws?.close()
                } else {
//                    send()
                }
            }
        }
        
        self.ws?.delegate = self
    }
    
    
    func handelRemoteResponse(message:Any){
        print("\n\n recv: \(JSON(message))\n\n")
        let jsonString = message as! String
        
        let data = jsonString.data(using: .utf8)
//        print(jsonData.rawData())
//        let streamStartingResponseModel = try? JSONDecoder().decode(StreamStartingResponseModel.self, from: jsonData!)
        let streamStartingResponseModel = try? JSONDecoder().decode(StreamStartingResponseModel.self, from: data!)
        
        let remoteSDP = (streamStartingResponseModel?.data?.sdp)!
        
        let sdpStringRequiredSubString = "\na=extmap-allow-mixed"
//        if remoteSDP.contains(sdpStringRequiredSubString){
//            print("found sub string string")
//            let splittedSDP = remoteSDP.split(separator: "\n")
//            let filteredArray = splittedSDP.filter {$0.trimmingCharacters(in: .whitespacesAndNewlines) != "a=extmap-allow-mixed"}
//            let trimmedString = filteredArray.joined(separator: "\n")
            
        let rtcDesc = RTCSessionDescription(type: .answer, sdp: remoteSDP + "a=x-google-flag:conference\r\n")
        
        self.pc?.setRemoteDescription(rtcDesc, completionHandler: { (error) in
            if let err = error{
                print("set remote descrion faield \(err)")
            }
        })
            
//        }
        
        
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


extension ViewController:WebSocketDelegate{
    func webSocketOpen() {
        print("opened")
    }
    
    func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
        print("closed")
    }
    
    func webSocketError(_ error: NSError) {
        print("error")
    }
    
    func webSocketMessageData(_ data: Data) {
        print("got message")
    }
    
    
}




extension ViewController: RTCDataChannelDelegate{
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print(peerConnection.connectionState.rawValue)
        print(#function)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
    print(#function)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print(#function)
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print(#function)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("\(#function), new state \(newState.rawValue)" )
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

        print("\(#function), new state \(newState.rawValue)" )
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print(#function)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print(#function)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print(#function)
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print(#function)
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        print(#function)
    }
}


extension ViewController: RTCPeerConnectionDelegate{
    
    
    
}




//{"type":"cmd","transId":4067.4135088288567,"name":"publish","data":{"name":"kbqdm648","sdp":"v=0\r\no=- 292404632969147590 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0 1\r\na=msid-semantic: WMS 1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111 103 104 9 0 8 106 105 13 110 112 113 126\r\nc=IN IP4 0.0.0.0\r\na=rtcp:9 IN IP4 0.0.0.0\r\na=ice-ufrag:Wpl4\r\na=ice-pwd:abE1zfuYgO8/AaJH3EN4jNLR\r\na=ice-options:trickle\r\na=fingerprint:sha-256 42:7F:88:89:30:54:06:66:E7:6B:38:58:AD:34:44:DF:91:03:42:F5:9B:04:CC:22:01:66:F6:DA:16:99:BC:17\r\na=setup:actpass\r\na=mid:0\r\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\na=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\na=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\na=sendrecv\r\na=msid:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE d62ab2ff-8fc9-42cd-9f4c-4fcccdd1a676\r\na=rtcp-mux\r\na=rtpmap:111 opus/48000/2\r\na=rtcp-fb:111 transport-cc\r\na=fmtp:111 minptime=10;useinbandfec=1\r\na=rtpmap:103 ISAC/16000\r\na=rtpmap:104 ISAC/32000\r\na=rtpmap:9 G722/8000\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:106 CN/32000\r\na=rtpmap:105 CN/16000\r\na=rtpmap:13 CN/8000\r\na=rtpmap:110 telephone-event/48000\r\na=rtpmap:112 telephone-event/32000\r\na=rtpmap:113 telephone-event/16000\r\na=rtpmap:126 telephone-event/8000\r\na=ssrc:82668464 cname:o8Ul5+BnprjMXlym\r\na=ssrc:82668464 msid:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE d62ab2ff-8fc9-42cd-9f4c-4fcccdd1a676\r\na=ssrc:82668464 mslabel:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE\r\na=ssrc:82668464 label:d62ab2ff-8fc9-42cd-9f4c-4fcccdd1a676\r\nm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 102 122 127 121 125 107 108 109 124 120 123 119 114 115 116\r\nc=IN IP4 0.0.0.0\r\na=rtcp:9 IN IP4 0.0.0.0\r\na=ice-ufrag:Wpl4\r\na=ice-pwd:abE1zfuYgO8/AaJH3EN4jNLR\r\na=ice-options:trickle\r\na=fingerprint:sha-256 42:7F:88:89:30:54:06:66:E7:6B:38:58:AD:34:44:DF:91:03:42:F5:9B:04:CC:22:01:66:F6:DA:16:99:BC:17\r\na=setup:actpass\r\na=mid:1\r\na=extmap:14 urn:ietf:params:rtp-hdrext:toffset\r\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\na=extmap:13 urn:3gpp:video-orientation\r\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\na=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay\r\na=extmap:11 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type\r\na=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing\r\na=extmap:8 http://tools.ietf.org/html/draft-ietf-avtext-framemarking-07\r\na=extmap:9 http://www.webrtc.org/experiments/rtp-hdrext/color-space\r\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\na=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id\r\na=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id\r\na=sendrecv\r\na=msid:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE a1974d14-387b-4d26-b1a8-7b4dc9c45140\r\na=rtcp-mux\r\na=rtcp-rsize\r\na=rtpmap:96 VP8/90000\r\na=rtcp-fb:96 goog-remb\r\na=rtcp-fb:96 transport-cc\r\na=rtcp-fb:96 ccm fir\r\na=rtcp-fb:96 nack\r\na=rtcp-fb:96 nack pli\r\na=rtpmap:97 rtx/90000\r\na=fmtp:97 apt=96\r\na=rtpmap:98 VP9/90000\r\na=rtcp-fb:98 goog-remb\r\na=rtcp-fb:98 transport-cc\r\na=rtcp-fb:98 ccm fir\r\na=rtcp-fb:98 nack\r\na=rtcp-fb:98 nack pli\r\na=fmtp:98 profile-id=0\r\na=rtpmap:99 rtx/90000\r\na=fmtp:99 apt=98\r\na=rtpmap:100 VP9/90000\r\na=rtcp-fb:100 goog-remb\r\na=rtcp-fb:100 transport-cc\r\na=rtcp-fb:100 ccm fir\r\na=rtcp-fb:100 nack\r\na=rtcp-fb:100 nack pli\r\na=fmtp:100 profile-id=2\r\na=rtpmap:101 rtx/90000\r\na=fmtp:101 apt=100\r\na=rtpmap:102 H264/90000\r\na=rtcp-fb:102 goog-remb\r\na=rtcp-fb:102 transport-cc\r\na=rtcp-fb:102 ccm fir\r\na=rtcp-fb:102 nack\r\na=rtcp-fb:102 nack pli\r\na=fmtp:102 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42001f\r\na=rtpmap:122 rtx/90000\r\na=fmtp:122 apt=102\r\na=rtpmap:127 H264/90000\r\na=rtcp-fb:127 goog-remb\r\na=rtcp-fb:127 transport-cc\r\na=rtcp-fb:127 ccm fir\r\na=rtcp-fb:127 nack\r\na=rtcp-fb:127 nack pli\r\na=fmtp:127 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42001f\r\na=rtpmap:121 rtx/90000\r\na=fmtp:121 apt=127\r\na=rtpmap:125 H264/90000\r\na=rtcp-fb:125 goog-remb\r\na=rtcp-fb:125 transport-cc\r\na=rtcp-fb:125 ccm fir\r\na=rtcp-fb:125 nack\r\na=rtcp-fb:125 nack pli\r\na=fmtp:125 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f\r\na=rtpmap:107 rtx/90000\r\na=fmtp:107 apt=125\r\na=rtpmap:108 H264/90000\r\na=rtcp-fb:108 goog-remb\r\na=rtcp-fb:108 transport-cc\r\na=rtcp-fb:108 ccm fir\r\na=rtcp-fb:108 nack\r\na=rtcp-fb:108 nack pli\r\na=fmtp:108 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42e01f\r\na=rtpmap:109 rtx/90000\r\na=fmtp:109 apt=108\r\na=rtpmap:124 H264/90000\r\na=rtcp-fb:124 goog-remb\r\na=rtcp-fb:124 transport-cc\r\na=rtcp-fb:124 ccm fir\r\na=rtcp-fb:124 nack\r\na=rtcp-fb:124 nack pli\r\na=fmtp:124 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=4d0032\r\na=rtpmap:120 rtx/90000\r\na=fmtp:120 apt=124\r\na=rtpmap:123 H264/90000\r\na=rtcp-fb:123 goog-remb\r\na=rtcp-fb:123 transport-cc\r\na=rtcp-fb:123 ccm fir\r\na=rtcp-fb:123 nack\r\na=rtcp-fb:123 nack pli\r\na=fmtp:123 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640032\r\na=rtpmap:119 rtx/90000\r\na=fmtp:119 apt=123\r\na=rtpmap:114 red/90000\r\na=rtpmap:115 rtx/90000\r\na=fmtp:115 apt=114\r\na=rtpmap:116 ulpfec/90000\r\na=ssrc-group:FID 4138666451 3080902777\r\na=ssrc:4138666451 cname:o8Ul5+BnprjMXlym\r\na=ssrc:4138666451 msid:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE a1974d14-387b-4d26-b1a8-7b4dc9c45140\r\na=ssrc:4138666451 mslabel:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE\r\na=ssrc:4138666451 label:a1974d14-387b-4d26-b1a8-7b4dc9c45140\r\na=ssrc:3080902777 cname:o8Ul5+BnprjMXlym\r\na=ssrc:3080902777 msid:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE a1974d14-387b-4d26-b1a8-7b4dc9c45140\r\na=ssrc:3080902777 mslabel:1AXF8Ht1VPB6S5SorvDtsnRzqiDgJDCzVWcE\r\na=ssrc:3080902777 label:a1974d14-387b-4d26-b1a8-7b4dc9c45140\r\n","codec":"h264"}}



extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
}
