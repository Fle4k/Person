import SwiftUI

struct NameGeneratorView: View {
    @EnvironmentObject var nameStore: NameStore
    @ObservedObject var viewModel: PersonViewModel
    @State private var selectedGender: Gender = .female
    @State private var selectedNationality: Nationality = .german
    @State private var selectedDecade: String = "Alle"
    @State private var useAlliteration = false
    @State private var useDoubleName = false
    @State private var sheetDetent: PresentationDetent = .large
    @Binding var showingGeneratedNames: Bool
    @Binding var hasGeneratedNames: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private let decades = ["Alle", "1940", "1950", "1960", "1970", "1980", "1990", "2000"]
    
    var toggleTint: Color {
        colorScheme == .dark ? Color.dynamicText.opacity(0.6) : Color.dynamicFill
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 20) {
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
                    .tint(Color.dynamicFill)
                    .onAppear {
                        // Customize segmented control appearance
                        let appearance = UISegmentedControl.appearance()
                        appearance.selectedSegmentTintColor = UIColor(Color.dynamicFill)
                        appearance.setTitleTextAttributes([.foregroundColor: UIColor(Color.dynamicBackground)], for: .selected)
                        appearance.setTitleTextAttributes([.foregroundColor: UIColor(Color.dynamicText)], for: .normal)
                    }
                    
                    Spacer()
                        .frame(height: geometry.size.height * 0.04)
                    
                    // Options List
                    VStack(spacing: 0) {
                        // Herkunftsland
                        HStack {
                            Text("Herkunft")
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
                                    Text(decade == "Alle" ? decade : "\(decade)er").tag(decade)
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
                    Button(action: generateAndShowNames) {
                        Text("Namen Generieren")
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.dynamicFill)
                            .foregroundColor(Color.dynamicBackground)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.size.height * 0.05)
                }
            }
        }
        .tint(Color.dynamicText)
        .sheet(isPresented: $showingGeneratedNames) {
            NavigationStack {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 60)
                    
                    GeneratedNamesListView(
                        names: viewModel.generatedNames,
                        sheetDetent: $sheetDetent
                    )
                    .environmentObject(nameStore)
                    .tint(Color.dynamicText)
                }
            }
            .presentationDetents([.large], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .tint(Color.dynamicText)
        }
    }
    
    private func generateAndShowNames() {
        // Clear previous names
        viewModel.generatedNames.removeAll()
        
        // Check if data is loaded
        guard viewModel.isDataLoaded else {
            print("Debug - Waiting for data to load...")
            viewModel.loadNamesData()
            return
        }
        
        print("Debug - Data is loaded, generating alphabetical names")
        
        // Generate alphabetical names
        let alphabeticalNames = viewModel.generateAlphabeticalNames(
            gender: selectedGender,
            nationality: selectedNationality,
            decade: selectedDecade,
            useDoubleName: useDoubleName,
            useAlliteration: useAlliteration
        )
        
        // Sort by last name and add to viewModel
        viewModel.generatedNames = alphabeticalNames.sorted { $0.lastName.lowercased() < $1.lastName.lowercased() }
        
        print("Debug - Generated \(viewModel.generatedNames.count) alphabetical names")
        
        if !viewModel.generatedNames.isEmpty {
            // Set both states at once
            withAnimation {
                hasGeneratedNames = true
                showingGeneratedNames = true
            }
            print("Debug - Sheet should now be showing with \(viewModel.generatedNames.count) names")
        } else {
            print("Debug - Failed to generate any names")
        }
    }
}

#Preview {
    NavigationStack {
        NameGeneratorView(
            viewModel: PersonViewModel(),
            showingGeneratedNames: .constant(false),
            hasGeneratedNames: .constant(false)
        )
    }
} 
