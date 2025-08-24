import SwiftUI

struct PlaybackView: View {
    @Environment(\.undoManager) private var undoManager
    @Bindable var viewModel: PlaybackViewModel
    
    let dismissAction: () -> Void
    
    var body: some View {
        NavigationStack {
            scrollView
                .navigationTitle(viewModel.show.fileName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
        }
        .alert("Rename", isPresented: $viewModel.state.isPresentingRenameAlert, presenting: viewModel.state.stingToRename) { sting in
            TextField("Sting name", text: $viewModel.state.renameText, prompt: Text(sting.songTitle))
                .textInputAutocapitalization(.words)
                // textField.clearButtonMode = .always
            
            Button("Cancel", role: .cancel) {
                // becomeFirstResponder()     // ensure undo gestures work after a rename
            }
            
            Button("OK", role: .confirm) {
                let renameText = viewModel.state.renameText
                let name = renameText.isEmpty ? nil : renameText
                viewModel.rename(sting, to: name)
                // becomeFirstResponder()     // ensure undo gestures work after a rename
            }
        }
        .alert("Enable Access", isPresented: $viewModel.state.isPresentingMediaLibraryAccessAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            }
        } message: {
            Text("Please enable Media & Apple Music access in the Settings app.")
        }
        .sheet(item: $viewModel.state.stingToEdit) { EditStingView(show: viewModel.show, sting: $0) }
        .sheet(item: $viewModel.state.songPickerOperation) { SongPicker(show: viewModel.show, pickerOperation: $0) }
        .sheet(item: $viewModel.state.filePickerOperation) { FilePicker(show: viewModel.show, pickerOperation: $0) }
        .sheet(isPresented: $viewModel.state.isPresentingSettings) { SettingsView(show: viewModel.show) }
        .sheet(isPresented: $viewModel.state.isPresentingManageStings) { ManageStingsView(show: viewModel.show) }
    }
    
    var scrollView: some View {
        ScrollView {
            StingsGrid(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.top)
            
            AddStingFooterView(viewModel: viewModel)
                .padding()
        }
        .animation(.default, value: viewModel.show.stings)
        .safeAreaInset(edge: .bottom) {
            TransportView(viewModel: viewModel)
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Shows", action: dismissAction)
        }
        
        if !viewModel.show.unavailableSongs.isEmpty || !viewModel.show.unavailableFiles.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.state.isPresentingManageStings = true } label: {
                    Image(systemName: "exclamationmark.circle")
                        .fontWeight(.semibold)
                        .tint(.red)
                }
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button { viewModel.state.isPresentingSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
}


#Preview {
    let viewModel = PlaybackViewModel(show: Show(name: "Preview"))
    PlaybackView(viewModel: viewModel) { }
}
