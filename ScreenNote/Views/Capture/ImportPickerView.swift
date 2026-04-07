import PhotosUI
import SwiftUI

struct ImportPickerView<Label: View>: View {
    @Binding var selection: [PhotosPickerItem]
    let label: () -> Label

    var body: some View {
        PhotosPicker(selection: $selection, maxSelectionCount: 50, matching: .images, photoLibrary: .shared()) {
            label()
        }
    }
}
