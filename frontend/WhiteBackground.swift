//
//  WhiteBackground.swift
//  iWallet3
//
//  Created by Ronald Huang on 11/3/24.
//

import SwiftUI

struct WhiteBackground: View {
    @State private var animateStars = false

    var body: some View {
        ZStack {
            ForEach(0..<100) { _ in
                Circle()
                    .fill(Color.white.opacity(2))
                    .frame(width: 2, height: 2)
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .offset(y: animateStars ? -20 : 20)
            }
        }
        .background(LinearGradient(gradient: Gradient(colors: [.gray, .white]), startPoint: .top, endPoint: .bottom))
        .onAppear {
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: true)) {
                animateStars.toggle()
            }
        }
    }
}

#Preview {
    WhiteBackground()
}
