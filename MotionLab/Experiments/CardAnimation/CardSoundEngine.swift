//
//  CardSoundEngine.swift
//  MotionLab
//
//  Pre-loaded audio for the business card reveal.
//  Same pattern as FeedbackEngine in CheckmarkView — players are warmed up
//  at init so playback is instant with no first-call latency.
//
//  Required audio files (add to Assets or project root):
//    card_land.wav    — short crisp thud as the card hits the surface
//    card_shimmer.wav — soft metallic chime that rides the shimmer sweep

import AVFoundation

class CardSoundEngine {

    static let shared = CardSoundEngine()

    private var landPlayer:    AVAudioPlayer?
    private var shimmerPlayer: AVAudioPlayer?

    private init() {
#if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
#endif

        landPlayer    = makePlayer(resource: "card_land",    volume: 0.55)
        shimmerPlayer = makePlayer(resource: "card_shimmer", volume: 0.45)
    }

    private func makePlayer(resource: String, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav")
                     ?? Bundle.main.url(forResource: resource, withExtension: "aiff")
                     ?? Bundle.main.url(forResource: resource, withExtension: "mp3")
        else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.volume = volume
        p?.prepareToPlay()
        return p
    }

    /// Fire when the card spring settles — simultaneous with the haptic.
    func playLand() {
        landPlayer?.currentTime = 0
        landPlayer?.play()
    }

    /// Fire when the shimmer sweep begins — rides the visual left-to-right.
    func playShimmer() {
        shimmerPlayer?.currentTime = 0
        shimmerPlayer?.play()
    }
}
