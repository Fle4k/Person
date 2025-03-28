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

struct PersonDetailView: View {
    @EnvironmentObject private var viewModel: PersonViewModel
    @State private var editedPerson: Person
    @State private var selectedItem: PhotosPickerItem?
    @State private var newTag: String = ""
    @State private var menuIconColor: Color = .dynamicText
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    init(person: Person) {
        _editedPerson = State(initialValue: person)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Section
                imageSection
                
                // Name Section
                Text("\(editedPerson.firstName) \(editedPerson.lastName)")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.dynamicText)
                    .padding(.top, -10)
                
                // Details Section with Notizen
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
                menuButton
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    editedPerson.imageData = imageData
                    viewModel.updatePerson(editedPerson)
                    updateMenuIconColor(for: image)
                }
            }
        }
        .onChange(of: selectedItem) { oldItem, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    editedPerson.imageData = data
                    viewModel.updatePerson(editedPerson)
                }
            }
        }
        .onChange(of: editedPerson) { oldPerson, newPerson in
            viewModel.updatePerson(editedPerson)
        }
    }
    
    private var imageSection: some View {
        GeometryReader { geo in
            if let imageData = editedPerson.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width)
                    .frame(height: 300)
                    .clipped()
                    .onChange(of: uiImage) { _, newImage in
                        updateMenuIconColor(for: newImage)
                    }
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
            DetailRow(title: "Größe:", text: Binding(
                get: { editedPerson.height ?? "" },
                set: { editedPerson.height = $0 }
            ))
            DetailRow(title: "Haarfarbe:", text: Binding(
                get: { editedPerson.hairColor ?? "" },
                set: { editedPerson.hairColor = $0 }
            ))
            DetailRow(title: "Augenfarbe:", text: Binding(
                get: { editedPerson.eyeColor ?? "" },
                set: { editedPerson.eyeColor = $0 }
            ))
            DetailRow(title: "Merkmale:", text: Binding(
                get: { editedPerson.characteristics ?? "" },
                set: { editedPerson.characteristics = $0 }
            ))
            DetailRow(title: "Style:", text: Binding(
                get: { editedPerson.style ?? "" },
                set: { editedPerson.style = $0 }
            ))
            DetailRow(title: "Typ:", text: Binding(
                get: { editedPerson.type ?? "" },
                set: { editedPerson.type = $0 }
            ))
            DetailRow(title: "# :", 
                     text: $newTag,
                     placeholder: "z.B. Projektname",
                     isTagInput: true,
                     tags: editedPerson.tags,
                     onTagAdd: { tag in
                         editedPerson.tags.insert(tag)
                         viewModel.updatePerson(editedPerson)
                     },
                     onTagRemove: { tag in
                         editedPerson.tags.remove(tag)
                         viewModel.updatePerson(editedPerson)
                     })
            DetailRow(title: "Notizen:", text: $editedPerson.notes, isMultiline: true, isLast: true)
        }
        .padding()
    }
    
    private var menuButton: some View {
        Menu {
            Button {
                showImagePicker()
            } label: {
                Label("Foto hinzufügen", systemImage: "photo")
            }
            
            if editedPerson.imageData != nil {
                Button(role: .destructive) {
                    editedPerson.imageData = nil
                    viewModel.updatePerson(editedPerson)
                } label: {
                    Label("Foto löschen", systemImage: "trash")
                }
            }
            
            if editedPerson.isFavorite {
                Button(role: .destructive) {
                    editedPerson.isFavorite = false
                    viewModel.updatePerson(editedPerson)
                    dismiss()
                } label: {
                    Label("Von Favoriten entfernen", systemImage: "star.slash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(menuIconColor)
        }
    }
    
    private func showImagePicker() {
        showingImagePicker = true
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
    var isTagInput: Bool = false
    var tags: Set<String>? = nil
    var onTagAdd: ((String) -> Void)? = nil
    var onTagRemove: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if isMultiline {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.body)
                    TextEditor(text: text)
                        .frame(minHeight: 100)
                        .foregroundStyle(Color.dynamicText.opacity(0.6))
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else if isTagInput {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.body)
                        Spacer()
                        TextField(placeholder, text: text)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.dynamicText.opacity(0.6))
                            .submitLabel(.done)
                            .onSubmit {
                                if let onTagAdd = onTagAdd {
                                    let tag = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !tag.isEmpty {
                                        onTagAdd(tag)
                                        text.wrappedValue = ""
                                    }
                                }
                            }
                    }
                    
                    if let tags = tags, !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(Array(tags), id: \.self) { tag in
                                TagView(tag: tag) {
                                    onTagRemove?(tag)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else {
                HStack {
                    Text(title)
                        .font(.body)
                    Spacer()
                    TextField(placeholder, text: text)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.dynamicText.opacity(0.6))
                        .submitLabel(.done)
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

#Preview {
    NavigationView {
        PersonDetailView(person: Person(firstName: "Max", lastName: "Mustermann"))
            .environmentObject(PersonViewModel())
    }
} 