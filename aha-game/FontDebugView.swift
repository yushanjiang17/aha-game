// FontDebugView.swift
import SwiftUI

struct FontDebugView: View {
    @State private var allFonts: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(allFonts, id: \.self) { fontName in
                    Text(fontName)
                        .font(.custom(fontName, size: 18))
                        .padding(.vertical, 2)
                }
            }
            .padding()
        }
        .onAppear {
            var found: [String] = []
            print("🔍 Scanning all loaded fonts...")
            for family in UIFont.familyNames.sorted() {
                print("🎭 FAMILY: \(family)")
                for name in UIFont.fontNames(forFamilyName: family).sorted() {
                    print("   → \(name)")
                    found.append(name)
                }
            }
            allFonts = found
        }
    }
}

#Preview {
    FontDebugView()
}
