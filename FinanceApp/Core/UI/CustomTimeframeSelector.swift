import SwiftUI

struct CustomTimeframeSelector: View {
    @Binding var selectedTimeframe: Timeframe
    @Namespace private var selectorNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { time in
                Text(time.localizedName)
                    .font(.system(size: 10, weight: selectedTimeframe == time ? .bold : .medium))
                    .foregroundStyle(selectedTimeframe == time ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if selectedTimeframe == time {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.1))
                                .matchedGeometryEffect(id: "activeTime", in: selectorNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTimeframe = time
                        }
                    }
            }
        }
        .padding(4)
        .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
        .frame(width: 150)
    }
}
