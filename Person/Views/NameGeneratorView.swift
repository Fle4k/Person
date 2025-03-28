import SwiftUI

struct NameGeneratorView: View {
    @Binding var isDrawerPresented: Bool
    @Binding var hasGeneratedNames: Bool
    @ObservedObject var viewModel: PersonViewModel
    @State private var selectedGender: Gender = .female
    @State private var selectedNationality: Nationality = .german
    @State private var selectedDecade: String = "Egal"
    @State private var useAlliteration: Bool = false
    @State private var useDoubleName: Bool = false
    @State private var showingGeneratedNames = false
    @State private var generatedNames: [Person] = []
    @State private var sheetDetent: PresentationDetent = .height(40)
    @Environment(\.colorScheme) var colorScheme
    
    private let decades = ["Egal", "1940", "1950", "1960", "1970", "1980", "1990", "2000"]
    
    var toggleTint: Color {
        colorScheme == .dark ? Color.dynamicText.opacity(0.6) : Color.dynamicFill
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geometry.size.height * 0.08)
                
                // Gender Picker
                Picker("Gender", selection: $selectedGender) {
                    Text(Gender.female.displayName).tag(Gender.female)
                    Text(Gender.male.displayName).tag(Gender.male)
                    Text(Gender.diverse.displayName).tag(Gender.diverse)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Spacer()
                    .frame(height: geometry.size.height * 0.04)
                
                // Options List
                VStack(spacing: 0) {
                    // Herkunftsland
                    HStack {
                        Text("Herkunftsland")
                            .foregroundStyle(Color.dynamicText)
                        Spacer()
                        Picker("", selection: $selectedNationality) {
                            Text(Nationality.german.displayName).tag(Nationality.german)
                            Text(Nationality.british.displayName).tag(Nationality.british)
                        }
                        .tint(Color.dynamicText)
                    }
                    .padding()
                    
                    Divider()
                        .background(Color.dynamicText.opacity(0.2))
                    
                    // Decade Picker
                    HStack {
                        Text("Dekade")
                            .foregroundStyle(Color.dynamicText)
                        Spacer()
                        Picker("", selection: $selectedDecade) {
                            ForEach(decades, id: \.self) { decade in
                                Text(decade == "Egal" ? decade : "\(decade)er").tag(decade)
                            }
                        }
                        .tint(Color.dynamicText)
                    }
                    .padding()
                    
                    Divider()
                        .background(Color.dynamicText.opacity(0.2))
                    
                    // Toggles
                    Toggle("Alliteration", isOn: $useAlliteration)
                        .padding()
                        .tint(toggleTint)
                        .foregroundStyle(Color.dynamicText)
                    
                    Divider()
                        .background(Color.dynamicText.opacity(0.2))
                    
                    Toggle("Doppelnamen", isOn: $useDoubleName)
                        .padding()
                        .tint(toggleTint)
                        .foregroundStyle(Color.dynamicText)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Generate Button
                Button(action: generateName) {
                    Text("Namen Generieren")
                        .font(.title3)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.dynamicFill)
                        .foregroundStyle(Color.dynamicBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                .padding(.bottom, geometry.size.height * 0.05)
            }
        }
        .navigationTitle("Name Generator")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingGeneratedNames) {
            NavigationStack {
                GeneratedNamesListView(
                    names: generatedNames,
                    sheetDetent: $sheetDetent
                )
            }
        }
    }
    
    private func generateName() {
        generatedNames.removeAll()
        
        // Generate multiple names based on settings
        for _ in 0..<5 { // Generate 5 names
            if let person = viewModel.generatePerson(
                gender: selectedGender,
                nationality: selectedNationality,
                decade: selectedDecade,
                useAlliteration: useAlliteration,
                useDoubleName: useDoubleName
            ) {
                generatedNames.append(person)
            }
        }
        
        hasGeneratedNames = true
        showingGeneratedNames = true
    }
}

#Preview {
    NavigationStack {
        NameGeneratorView(
            isDrawerPresented: .constant(false),
            hasGeneratedNames: .constant(false),
            viewModel: PersonViewModel()
        )
    }
} 