//
//  SoundManager.swift
//  LogosWallet
//
//  Created by Ben Kray on 8/21/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Foundation
import AVFoundation

struct SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    init() {
        guard let url = Bundle.main.url(forResource: "hint", withExtension: "wav") else {
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            self.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    func play(_ sound: Sound) {
        switch sound {
        case .receive, .send:
            // TODO: change sounds?
            self.player?.play()
        }
    }
}
enum Sound {
    case send
    case receive
}
