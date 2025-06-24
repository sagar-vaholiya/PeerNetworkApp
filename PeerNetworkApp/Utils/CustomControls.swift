//
//  CustomControls.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import SwiftUI

struct BouncyHeartView: View {
    @State private var animate = false
    @Binding var isVisible: Bool

    var body: some View {
        GeometryReader { geo in
            if isVisible {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .onAppear {
                        withAnimation(.interpolatingSpring(stiffness: 200, damping: 5)) {
                            animate = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            isVisible = false
                        }
                    }
            }
        }
    }
}

struct IconLabelButton: View {
    let systemImageName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text(label)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ViewVisibilityModifier: ViewModifier {
    let onChange: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ViewVisiblePreferenceKey.self,
                                    value: geometry.frame(in: .global).intersects(UIScreen.main.bounds))
                }
            )
            .onPreferenceChange(ViewVisiblePreferenceKey.self, perform: onChange)
    }
}

private struct ViewVisiblePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

extension View {
    func onVisibilityChange(_ onChange: @escaping (Bool) -> Void) -> some View {
        self.modifier(ViewVisibilityModifier(onChange: onChange))
    }
}
