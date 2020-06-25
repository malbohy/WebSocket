//
//  elbohyViewController.swift
//  WebSocket
//
//  Created by mohamed albohy on 6/24/20.
//  Copyright © 2020 Sameh Salama. All rights reserved.
//

import UIKit
import AVFoundation


class elbohyViewController: UIViewController {

    var recordingSession: AVAudioSession!
    var whistleRecorder: AVAudioRecorder!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func startStream(_ sender: Any) {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
//                        self.loadFailUI()
                    }
                }
            }
        } catch {
            print("error")
            
        }
    }
    
    func loadRecordingUI() {
        if whistleRecorder == nil {
               startRecording()
           } else {
//               finishRecording(success: true)
           }
    }
    
    func startRecording (){
        let audioURL = elbohyViewController.getWhistleURL()
        print(audioURL.absoluteString)

        // 4
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // 5
            whistleRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            whistleRecorder.delegate = self
            whistleRecorder.record()
        } catch {
//            finishRecording(success: false)
        }
    }
    
    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getWhistleURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent("whistle.m4a")
    }
    
}

extension elbohyViewController:AVAudioRecorderDelegate{
    
}
