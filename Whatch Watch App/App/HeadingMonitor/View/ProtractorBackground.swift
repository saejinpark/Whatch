//
//  PretractorBackground.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import SwiftUI

struct ProtractorBackground: View {
    
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: diameter / 2, y:diameter / 2)
            
            ZStack {
                
                ForEach(0..<12) { index in
                    let angle = CGFloat(30 * index)
                    
                    Rectangle()
                        .frame(width: 1, height: diameter * 0.82)
                        .rotationEffect(Angle(degrees: angle))
                    
                    Text("\(Int(angle))°")
                        .rotationEffect(Angle(degrees: -angle - 15))
                        .font(.caption2)
                        .position(center)
                        .offset(y: (diameter / 2 * -1))
                        .rotationEffect(Angle(degrees: angle + 15))
                }
            }
            
            
        }
    }
}


#Preview {
    ProtractorBackground()
}
