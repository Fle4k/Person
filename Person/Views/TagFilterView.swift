import SwiftUI

struct TagFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTag: String?
    @EnvironmentObject private var nameStore: NameStore
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedTag = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("Alle")
                            Spacer()
                            if selectedTag == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(nameStore.allTags, id: \.self) { tag in
                        Button {
                            selectedTag = tag
                            dismiss()
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTag == tag {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
} 