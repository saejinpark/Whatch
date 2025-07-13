//
//  PretractorBackground.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import SwiftUI

struct ProtractorBackground: View {
    let radius: CGFloat = 120
    let tickLength: CGFloat = 10
    
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: diameter / 2, y:diameter / 2)
            
            ZStack {
                
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: diameter)
                Circle()
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: diameter * 0.82)
                ForEach(0..<36) { index in
                    let angle = CGFloat(10 * index)
                    
                    
                    Text("\(Int(angle))°")
                        .rotationEffect(Angle(degrees: -angle))
                        .font(.caption2)
                        .position(center)
                        .offset(y: (diameter / 10 * -1))
                        .rotationEffect(Angle(degrees: angle))
                }
                
                
                ForEach(0..<12) { index in
                    let angle = CGFloat(30 * index)
                    
                    Rectangle()
                        .frame(width: 1, height: diameter * 0.82)
                        .rotationEffect(Angle(degrees: angle))
                }
                
                Circle()
                    .frame(width: 30)
                
                ForEach(0..<360) { index in
                    let angle = CGFloat(index)
                    
                    Rectangle()
                        .frame(width: 1, height: 5)
                        .position(center)
                        .offset(y: (diameter / 7 * -1))
                        .rotationEffect(Angle(degrees: angle))
                }
                ForEach(0..<72) { index in
                    let angle = CGFloat(index * 5)
                    
                    Rectangle()
                        .frame(width: 2, height: 10)
                        .position(center)
                        .offset(y: (diameter / 7 * -1))
                        .rotationEffect(Angle(degrees: angle))
                }
            }
            
            
        }
    }
}


#Preview {
    ProtractorBackground()
}
