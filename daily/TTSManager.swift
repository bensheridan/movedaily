import Foundation
import AVFoundation
import SwiftUI
internal import Combine

class TTSManager: NSObject, ObservableObject {
    static let shared = TTSManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        // Stop any current speech before starting new one
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
    }

    /// Adds an utterance to the end of the speech queue without interrupting
    /// what is currently playing. Use for chained start-of-exercise announcements.
    func queue(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
