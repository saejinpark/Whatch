//
//  HeadingMonitorContentView.swift
//  Whatch
//
//  Created by 박세진 on 7/12/25.
//

import SwiftUI

struct HeadingMonitorContentView: View {
    @StateObject var manager = HeadingMonitorManager.shared
    
    var myHeading: Double? {
        manager.heading?.trueHeading
    }
    
    var otherHeading: Double {
        manager.anotherTrueHeading
    }
    
    var relativeAngle: Double? {
        guard let myHeading else { return nil }
        let diff = otherHeading - myHeading
        return (diff < 0 ? diff + 360 : diff).truncatingRemainder(dividingBy: 360)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                ProtractorBackground()
                CenteredContainer {
                    if let myHeading {
                        Image(systemName: "location.north.line.fill")
                            .font(.system(size: diameter / 2, weight: .thin))
                            .rotationEffect(.degrees(otherHeading + 12))
                            .rotationEffect(.degrees(-myHeading))
                    }
                }

            }
                        
        }
    }
}


#Preview {
    HeadingMonitorContentView()
}
