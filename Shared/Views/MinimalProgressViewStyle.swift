import SwiftUI

struct MinimalProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0

        return VStack {
            ZStack(alignment: .topLeading) {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.blue)
                        .frame(maxWidth: geo.size.width * CGFloat(fractionCompleted))
                }
            }
            .frame(height: 4)
        }
    }
}
