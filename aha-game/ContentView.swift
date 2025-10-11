//
//  ContentView.swift
//  aha-game
//
//  Created by Sabrina Jiang on 10/10/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    var body: some View {
        GameView() // ✅ Direct game launch
    }
}

// MARK: - GameView
struct GameView: View {
    // Game state
    @State private var beatTimer: Timer? = nil
    @State private var beatTime: Date = Date()
    @State private var score = 0
    @State private var streak = 0
    @State private var showKeepGoing = false
    @State private var heartIsHappy = true

    // Audio
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioStarted = false // ✅ NEW — start audio only on first tap

    // Animation state
    @State private var handScale: CGFloat = 1.0
    @State private var heartPulse: Bool = false

    // Constants
    let bpm: Double = 103
    var beatInterval: Double { 60.0 / bpm } // ≈ 0.582s per beat
    let tolerance: Double = 0.15            // tap accuracy window

    var body: some View {
        ZStack {
            // ✅ Fixed background that won’t shift
            Image("aha-game-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    // 💥 KEEP GOING visual feedback
                    if showKeepGoing {
                        VStack {
                            Image("aha-game-keepgoing")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.75)
                                .transition(.opacity)
                                .padding(.top, 40)
                            Spacer()
                        }
                    }

                    // ❤️ Heart + ✋ Hands center stack
                    VStack {
                        Spacer()

                        ZStack {
                            // ❤️ Heart (pulses on beat)
                            Image(heartIsHappy ? "aha-game-happyheart" : "aha-game-sadheart")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.9)
                                .scaleEffect(heartPulse ? 1.06 : 1.0)
                                .animation(.easeInOut(duration: 0.16), value: heartPulse)
                                .animation(.easeInOut(duration: 0.2), value: heartIsHappy)

                            // ✋ Hands (press to trigger audio + scoring)
                            Button(action: {
                                // 🎵 FIRST TAP starts the audio + beat
                                if !audioStarted {
                                    audioStarted = true
                                    startBeatSync()
                                    playBeatLoop()
                                }

                                // Press animation
                                withAnimation(.easeInOut(duration: 0.08)) { handScale = 1.08 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.45)) { handScale = 1.0 }
                                }

                                // ✅ Scoring
                                handleTap()
                            }) {
                                Image("aha-game-hands")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width * 1)
                                    .scaleEffect(handScale)
                                    .offset(y: geometry.size.height * -0.0045)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                        Spacer()

                        // 🔢 Score display
                        Text("Score: \(score)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                            .offset (x:0, y:-850)
                    }
                }
            }
        }
        .onAppear {
            // 🚫 No audio here — wait for first tap
        }
    }

    // MARK: - Beat Sync (WAV BPM-driven timing)
    func startBeatSync() {
        beatTimer?.invalidate()
        beatTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { _ in
            beatTime = Date()

            // 💓 Trigger heartbeat pulse
            withAnimation { heartPulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation { heartPulse = false }
            }
        }
        RunLoop.main.add(beatTimer!, forMode: .common)
    }

    // MARK: - Tap Scoring
    func handleTap() {
        let diff = abs(Date().timeIntervalSince(beatTime))

        if diff < tolerance {
            score += 1
            streak += 1
            heartIsHappy = true

            if streak % 5 == 0 {
                withAnimation { showKeepGoing = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { showKeepGoing = false }
                }
            }
        } else {
            streak = 0
            heartIsHappy = false
        }
    }

    // 🎵 Play WAV on loop ONLY when triggered
    func playBeatLoop() {
        guard let url = Bundle.main.url(forResource: "stayin-alive", withExtension: "wav") else {
            print("⚠️ stayin-alive.wav not found in bundle.")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("⚠️ Error playing WAV: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}


