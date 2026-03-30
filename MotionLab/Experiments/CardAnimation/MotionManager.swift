//
//  MotionManager.swift
//  MotionLab
//
//  Experiment 10 — Business Card Animation
//
//  Two-stage motion pipeline:
//
//  Stage 1 — CoreMotion feeds raw pitch/roll at 60fps.
//             Raw sensor data is noisy — even a still phone produces
//             tiny jitter values that make the card tremble slightly.
//
//  Stage 2 — CADisplayLink runs a spring physics loop synced to the
//             screen refresh (60fps, or 120fps on ProMotion devices).
//             Each frame:
//               a) Low-pass filter blends the new sensor reading in slowly,
//                  smoothing out the noise when the phone is still.
//               b) A spring pulls the published value toward the filtered
//                  target with velocity and damping — so fast flicks carry
//                  momentum and settle naturally, like a physical object.
//
//  The card reads `pitch` and `roll` exactly as before.
//  It has no idea any of this is happening.

import CoreMotion
import SwiftUI
import QuartzCore

@Observable
class MotionManager {
    private let manager = CMMotionManager()
    private var displayLink: CADisplayLink?

    // Raw sensor target — updated by CoreMotion at 60fps
    private var targetPitch: Double = 0
    private var targetRoll:  Double = 0

    // Low-pass filtered target — blends new readings in gradually
    // to remove the micro-jitter present even when the phone is still
    private var filteredPitch: Double = 0
    private var filteredRoll:  Double = 0

    // Spring velocity — carries momentum between frames
    // This is what makes a quick flick overshoot and settle
    private var pitchVelocity: Double = 0
    private var rollVelocity:  Double = 0

    // Published values — spring-smoothed, synced to display refresh
    // These are the only values BusinessCardView touches
    var pitch: Double = 0
    var roll:  Double = 0

    // Low-pass alpha: fraction of the new reading blended in each frame
    // 0 = frozen, 1 = raw (no filtering). 0.12 is smooth but responsive.
    private let lowPassAlpha:   Double = 0.12

    // Spring constants
    // Strength: how hard the spring pulls toward the target each frame
    // Damping:  how much velocity bleeds off per frame (lower = more bounce)
    private let springStrength: Double = 0.18
    private let damping:        Double = 0.76

    func start() {
        guard manager.isDeviceMotionAvailable else { return }

        // CoreMotion — raw attitude at 60fps
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data, let self else { return }
            self.targetPitch = data.attitude.pitch
            self.targetRoll  = data.attitude.roll
        }

        // CADisplayLink — spring physics loop, locked to screen refresh
        // Automatically runs at 120fps on ProMotion devices
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step() {
        // Stage a: low-pass filter — smooths jitter when phone is still
        filteredPitch = filteredPitch * (1 - lowPassAlpha) + targetPitch * lowPassAlpha
        filteredRoll  = filteredRoll  * (1 - lowPassAlpha) + targetRoll  * lowPassAlpha

        // Stage b: spring physics — pull toward filtered target
        pitchVelocity += (filteredPitch - pitch) * springStrength
        rollVelocity  += (filteredRoll  - roll)  * springStrength

        // Bleed off energy — gives the card mass and natural settle
        pitchVelocity *= damping
        rollVelocity  *= damping

        // Advance position
        pitch += pitchVelocity
        roll  += rollVelocity
    }
}
