import SwiftUI

struct LessonsView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("W fazie budowy")
                .font(.title2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.03).ignoresSafeArea())
    }
}
