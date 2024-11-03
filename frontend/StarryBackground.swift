//
//  StarryBackground.swift
//  iWallet
//
//  Created by Ronald Huang on 11/2/24.
//

import SwiftUI

struct StarryBackground: View {
    @State private var animateStars = false

    var body: some View {
        ZStack {
            ForEach(0..<100) { _ in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 2)
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .offset(y: animateStars ? -20 : 20)
            }
        }
        .background(LinearGradient(gradient: Gradient(colors: [.black, .gray]), startPoint: .top, endPoint: .bottom))
        .onAppear {
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: true)) {
                animateStars.toggle()
            }
        }
    }
}


#Preview {
    StarryBackground()
}
