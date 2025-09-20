import SwiftUI

struct PlaybackView: View {
    @Bindable var viewModel: PlaybackViewModel
    let dismissAction: () -> Void
    
    @Namespace private var sheets
    
    var body: some View {
        NavigationStack {
            scrollView
                .navigationTitle(viewModel.show.fileName)
                .navigationDocument(viewModel.show.fileURL)
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
        .sheet(item: $viewModel.state.songPickerOperation) {
            SongPicker(show: viewModel.show, pickerOperation: $0)
                .presentationSizing(.fitted)
        }
        .sheet(item: $viewModel.state.filePickerOperation) {
            FilePicker(show: viewModel.show, pickerOperation: $0)
                .presentationSizing(.fitted)
        }
        .sheet(isPresented: $viewModel.state.isPresentingSettings) {
            SettingsView(show: viewModel.show)
                .navigationTransition(.zoom(sourceID: SheetID.settings, in: sheets))
        }
        .sheet(isPresented: $viewModel.state.isPresentingManageStings) {
            ManageStingsView(show: viewModel.show)
                .navigationTransition(.zoom(sourceID: SheetID.manageStings, in: sheets))
        }
    }
    
    var scrollView: some View {
        ScrollView {
            StingsGrid(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.top)
            
            AddStingFooterView(viewModel: viewModel)
                .padding()
        }
        .scrollPosition(id: $viewModel.state.scrollPositionID, anchor: .center)
        .safeAreaInset(edge: .bottom) {
            TransportView(viewModel: viewModel)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: viewModel.cuedSting, scrollToCuedSting)
        .onChange(of: viewModel.show.stings, stingsDidChange)
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
                }
                .tint(.red)
                .matchedTransitionSource(id: SheetID.manageStings, in: sheets)
            }
            
            ToolbarSpacer(.fixed, placement: .primaryAction)
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button { viewModel.state.isPresentingSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .matchedTransitionSource(id: SheetID.settings, in: sheets)
        }
    }
    
    func scrollToCuedSting(previousSting: Sting?, cuedSting: Sting?) {
        guard let cuedSting else { return }
        withAnimation { viewModel.state.scrollPositionID = cuedSting.id }
    }
    
    func stingsDidChange(oldStings: [Sting], newStings: [Sting]) {
        // ensure there's a cued sting if possible
        viewModel.validateCuedSting()
    }
}


#Preview {
    let viewModel = PlaybackViewModel(show: Show(name: "Preview"))
    PlaybackView(viewModel: viewModel) { }
}
