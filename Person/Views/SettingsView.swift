import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Static content
    private let characteristics = "Nutzerzentrierter Designer mit SwiftUI Ambitionen"
    private let style = "Modern minimalistisch mit Fokus auf Einfachheit und Funktionalität"
    private let want = "Apps zu entwickeln, die einen positiven Einfluss auf das Leben der Menschen haben"
    private let need = "Kontinuierliches Lernen und Verbesserung durch Nutzerfeedback"
    private let notes = "Kontaktiert mich gerne mit Feedback oder Vorschlägen für weitere Namen. Euer Input hilft, diese App für alle besser zu machen."
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                
                Text("Shahin Shokoui")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.dynamicText)
                    .padding(.top, -10)
                
                detailsSection
                
                // METAME Link
                Link(destination: URL(string: "https://metame.de")!) {
                    Image("metame_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                .padding(.vertical, 8)
            }
            .padding(.top, 0)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
//        .navigationTitle("Info")
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .tint(Color.dynamicText)
    }
    
    private var imageSection: some View {
        GeometryReader { geo in
            Image("Shahin_Weiss_BW")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width)
                .frame(height: 300)
                .clipped()
        }
        .frame(height: 300)
    }
    
    private var detailsSection: some View {
        VStack(spacing: 0) {
            // Merkmale
            VStack(alignment: .leading, spacing: 8) {
                Text("Merkmale")
                    .font(.body)
                    .bold()
                TextEditor(text: .constant(characteristics))
                    .frame(minHeight: 60)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .scrollContentBackground(.hidden)
                    .disabled(true)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            // Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Style")
                    .font(.body)
                    .bold()
                TextEditor(text: .constant(style))
                    .frame(minHeight: 60)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .scrollContentBackground(.hidden)
                    .disabled(true)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            // Want
            VStack(alignment: .leading, spacing: 8) {
                Text("Want")
                    .font(.body)
                    .bold()
                Text(want)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            // Need
            VStack(alignment: .leading, spacing: 8) {
                Text("Need")
                    .font(.body)
                    .bold()
                Text(need)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            // Notizen
            VStack(alignment: .leading, spacing: 8) {
                Text("Notizen")
                    .font(.body)
                    .bold()
                TextEditor(text: .constant(notes))
                    .frame(minHeight: 100)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .scrollContentBackground(.hidden)
                    .disabled(true)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 
