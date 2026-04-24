import SwiftUI

struct CoachBubble: View {
    let text: String
    let persona: CoachPersona

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "megaphone.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.accentColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(persona.label).font(.caption).foregroundStyle(.secondary)
                Text(text).font(.body)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
