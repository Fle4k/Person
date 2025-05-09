import SwiftUI
import PhotosUI

extension UIImage {
    var averageBrightness: CGFloat {
        guard let inputImage = CIImage(image: self) else { return 0 }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else { return 0 }
        guard let outputImage = filter.outputImage else { return 0 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        let brightness = (CGFloat(bitmap[0]) + CGFloat(bitmap[1]) + CGFloat(bitmap[2])) / (3.0 * 255.0)
        return brightness
    }
}

enum Field {
    case merkmale
    case notizen
}

class PersonDetailsItemSource: NSObject, UIActivityItemSource {
    let details: String
    let fileName: String
    var fileURL: URL
    
    init(details: String, firstName: String, lastName: String) {
        self.details = details
        self.fileName = "Person_\(firstName)_\(lastName).txt"
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let initialURL = tempDir.appendingPathComponent(self.fileName)
        
        // Write content to file
        do {
            try details.write(to: initialURL, atomically: true, encoding: .utf8)
            self.fileURL = initialURL
        } catch {
            print("Error writing temporary file: \(error)")
            // Create a new file with a unique name if the first attempt fails
            let uniqueFileName = "\(self.fileName)_\(UUID().uuidString)"
            let fallbackURL = tempDir.appendingPathComponent(uniqueFileName)
            try? details.write(to: fallbackURL, atomically: true, encoding: .utf8)
            self.fileURL = fallbackURL
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileName
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.plain-text"
    }
    
    deinit {
        // Clean up temporary file
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error removing temporary file: \(error)")
        }
    }
}

struct PersonDetailView: View {
    @EnvironmentObject private var nameStore: NameStore
    @State private var editedPerson: Person
    @State private var details: PersonDetails
    @State private var menuIconColor: Color = .dynamicText
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingShareSheet = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var shareItem: PersonDetailsItemSource?
    
    init(person: Person) {
        _editedPerson = State(initialValue: person)
        _details = State(initialValue: PersonDetails())
    }
    
    private var formattedDetails: String {
        var result = ""
        
        // 1. Name
        result += "\(editedPerson.firstName) \(editedPerson.lastName)\n"
        
        // 2. Double spacer
        result += "\n\n"
        
        // 3. Alter
        result += "Alter:\n"
        result += "\(details.age)\n\n"
        
        // 4. Merkmale
        result += "Merkmale:\n"
        result += "\(details.characteristics)\n\n"
        
        // 5. Style
        result += "Style:\n"
        result += "\(details.clothingStyle)\n\n"
        
        // 6. Want
        result += "Want:\n"
        result += "\(details.wants)\n\n"
        
        // 7. Need
        result += "Need:\n"
        result += "\(details.needs)\n\n"
        
        // 8. Notizen
        result += "Notizen:\n"
        result += "\(details.notes)\n"
        
        return result
    }
    
    private var shareItemSource: PersonDetailsItemSource {
        PersonDetailsItemSource(
            details: formattedDetails,
            firstName: editedPerson.firstName,
            lastName: editedPerson.lastName
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                
                Text("\(editedPerson.firstName) \(editedPerson.lastName)")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.dynamicText)
                    .padding(.top, -10)
                
                detailsSection
            }
            .padding(.top, 0)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if focusedField != nil {
                    Button("Done") {
                        focusedField = nil
                    }
                } else {
                    menuButton
                }
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showingImagePicker) {
            PersonImagePicker(image: $selectedImage) { image in
                print("Debug - Image selected, size: \(image.size)")
                
                // First ensure the person is in favorites
                if !editedPerson.isFavorite {
                    print("Debug - Adding person to favorites before saving image")
                    nameStore.addToFavorites(editedPerson)
                }
                
                // Save the image
                nameStore.saveImage(image, for: editedPerson)
                print("Debug - Image saved to store")
                
                // Reload the person from favorites to get the latest data
                if let updatedPerson = nameStore.favorites.first(where: { $0.id == editedPerson.id }) {
                    print("Debug - Found updated person in favorites")
                    print("Debug - Updated person has image: \(updatedPerson.imageData != nil)")
                    editedPerson = updatedPerson
                    selectedImage = image
                } else {
                    print("Debug - WARNING: Could not find updated person in favorites")
                }
                
                updateMenuIconColor(for: image)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let item = shareItem {
                ShareSheet(activityItems: [item]) { activityType, completed, _, error in
                    if completed {
                        // Clean up after successful share
                        shareItem = nil
                    }
                }
            }
        }
        .onAppear {
            print("Debug - PersonDetailView appeared")
            print("Debug - Current person ID: \(editedPerson.id)")
            print("Debug - Current person has image: \(editedPerson.imageData != nil)")
            print("Debug - Current person is favorite: \(editedPerson.isFavorite)")
            
            // Load the latest person data from favorites
            if let updatedPerson = nameStore.favorites.first(where: { $0.id == editedPerson.id }) {
                print("Debug - Found updated person in favorites")
                print("Debug - Updated person has image: \(updatedPerson.imageData != nil)")
                editedPerson = updatedPerson
                
                // Load and update image
                if let image = nameStore.loadImage(for: updatedPerson) {
                    print("Debug - Successfully loaded image from store")
                    selectedImage = image
                    updateMenuIconColor(for: image)
                } else {
                    print("Debug - No image found in store")
                }
            } else {
                print("Debug - Person not found in favorites")
                // If person is not in favorites but marked as favorite, add them
                if editedPerson.isFavorite {
                    print("Debug - Adding person to favorites")
                    nameStore.addToFavorites(editedPerson)
                }
            }
            
            // Load details for this person
            details = nameStore.getDetails(for: editedPerson)
        }
        .onChange(of: showingShareSheet) { _, newValue in
            if newValue {
                shareItem = shareItemSource
            }
        }
        .onDisappear {
            // Save details when leaving the view
            nameStore.saveDetails(details, for: editedPerson)
        }
    }
    
    private var imageSection: some View {
        GeometryReader { geo in
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width)
                    .frame(height: 300)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: geo.size.width)
                    .frame(height: 300)
            }
        }
        .frame(height: 300)
    }
    
    private var detailsSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Alter")
                    .font(.body)
                    .bold()
                TextField("", text: $details.age)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Merkmale")
                    .font(.body)
                    .bold()
                TextEditor(text: $details.characteristics)
                    .frame(minHeight: 20)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .focused($focusedField, equals: .merkmale)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Style")
                    .font(.body)
                    .bold()
                TextEditor(text: $details.clothingStyle)
                    .frame(minHeight: 20)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Want")
                    .font(.body)
                    .bold()
                TextEditor(text: $details.wants)
                    .frame(minHeight: 20)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Need")
                    .font(.body)
                    .bold()
                TextEditor(text: $details.needs)
                    .frame(minHeight: 20)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.dynamicText.opacity(0.2))
                .padding(.leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notizen")
                    .font(.body)
                    .bold()
                TextEditor(text: $details.notes)
                    .frame(minHeight: 20)
                    .foregroundStyle(Color.dynamicText.opacity(0.6))
                    .focused($focusedField, equals: .notizen)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .padding()
    }
    
    private var menuButton: some View {
        Menu {
            Button {
                showingImagePicker = true
            } label: {
                Label("Foto hinzufügen", systemImage: "photo")
            }
            
            if selectedImage != nil {
                Button(role: .destructive) {
                    withAnimation {
                        selectedImage = nil
                        nameStore.deleteImage(for: editedPerson)
                        menuIconColor = .dynamicText
                    }
                } label: {
                    Label("Foto löschen", systemImage: "trash")
                }
            }
            
            Button {
                showingShareSheet = true
            } label: {
                Label("Teilen", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(menuIconColor)
        }
    }
    
    private func updateMenuIconColor(for image: UIImage) {
        let brightness = image.averageBrightness
        menuIconColor = brightness > 0.5 ? .black : .white
    }
}

struct DetailRow: View {
    let title: String
    var text: Binding<String>
    var placeholder: String = ""
    var isMultiline: Bool = false
    var isLast: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    @Binding var parentFocused: Bool
    
    private var formattedText: Binding<String> {
        Binding(
            get: {
                if title == "Merkmale:" {
                    if inputText.isEmpty {
                        return "• "
                    }
                    let lines = inputText.components(separatedBy: .newlines)
                    return lines.map { line in
                        if line.trimmingCharacters(in: .whitespaces).isEmpty {
                            return "• "
                        }
                        return line.starts(with: "• ") ? line : "• " + line
                    }.joined(separator: "\n")
                }
                return inputText
            },
            set: { newValue in
                if title == "Merkmale:" {
                    let lines = newValue.components(separatedBy: .newlines)
                    inputText = lines.map { line in
                        if line.trimmingCharacters(in: .whitespaces).isEmpty {
                            return "• "
                        }
                        return line.starts(with: "• ") ? line : "• " + line
                    }.joined(separator: "\n")
                } else {
                    inputText = newValue
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isMultiline {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.body)
                    TextEditor(text: formattedText)
                        .frame(minHeight: 20)
                        .foregroundStyle(Color.dynamicText.opacity(0.6))
                        .focused($isFocused)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else {
                HStack {
                    Text(title)
                        .font(.body)
                    Spacer()
                    TextField(placeholder, text: $inputText)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.dynamicText.opacity(0.6))
                        .submitLabel(.done)
                        .focused($isFocused)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            
            if !isLast {
                Divider()
                    .background(Color.dynamicText.opacity(0.2))
                    .padding(.leading)
            }
        }
        .onAppear {
            inputText = text.wrappedValue
        }
        .onChange(of: inputText) { _, newValue in
            text.wrappedValue = newValue
        }
        .onChange(of: isFocused) { _, newValue in
            parentFocused = newValue
        }
    }
}

extension View {
    func placeholder(_ shouldShow: Bool, _ text: String) -> some View {
        overlay(
            Text(text)
                .foregroundStyle(Color.dynamicText.opacity(0.6))
                .multilineTextAlignment(.trailing)
                .allowsHitTesting(false)
                .opacity(shouldShow ? 1 : 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
        )
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.white : Color.black)
        )
        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var maxWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for (index, row) in rows.enumerated() {
            var rowWidth: CGFloat = 0
            let rowHeight = row.first?.sizeThatFits(.unspecified).height ?? 0
            
            // Calculate row width
            for (subviewIndex, subview) in row.enumerated() {
                rowWidth += subview.sizeThatFits(.unspecified).width
                if subviewIndex < row.count - 1 {
                    rowWidth += spacing
                }
            }
            
            maxWidth = max(maxWidth, rowWidth)
            totalHeight += rowHeight
            
            // Add spacing between rows, except for the last row
            if index < rows.count - 1 {
                totalHeight += spacing
            }
        }
        
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRow = 0
        var x: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > (proposal.width ?? .infinity) {
                currentRow += 1
                rows.append([])
                x = size.width + spacing
            } else {
                x += size.width + spacing
            }
            
            rows[currentRow].append(subview)
        }
        
        return rows
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onCompletion: (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = onCompletion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PersonDetailView(person: Person(
            firstName: "Max",
            lastName: "Mustermann",
            gender: .male,
            nationality: .german,
            decade: "1990"
        ))
        .environmentObject(NameStore())
    }
} 
