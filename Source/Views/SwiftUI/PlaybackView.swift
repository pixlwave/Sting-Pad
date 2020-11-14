import SwiftUI
import MediaPlayer

struct PlaybackView: View {
    @EnvironmentObject var show: Show
    @EnvironmentObject var controller: PlaybackController
    
    @State var isPresentingMediaPicker = false
    @State var isPresentingFilePicker = false
    @State var isPresentingSettings = false
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 15) {
                    ForEach(show.stings) { sting in
                        StingCellUI(sting: sting)
                            .onTapGesture {
                                Engine.shared.play(sting)
                            }
                            .contextMenu {
                                Button {
                                    controller.pickerOperation = .insert(0)
                                    pickStingFromLibrary()
                                } label: {
                                    Label("Insert Song Here", systemImage: "square.stack")
                                }
                            }
                    }
                }
                .padding()
                
                HStack(spacing: 20) {
                    FooterCell(label: "Music Library")
                        .onTapGesture {
                            pickStingFromLibrary()
                        }
                    FooterCell(label: "Files")
                        .onTapGesture {
                            isPresentingFilePicker = true
                        }
                }
                .padding()
                
                Spacer(minLength: 90)  // TODO: Use actual insets
            }
            .overlay(
                TransportViewUI(),
                alignment: .bottom
            )
            .navigationBarTitle(show.fileName, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Shows") {
                        controller.engine.stopSting()
                        
                        show.close { success in
                            dismiss?()
                        }
                    }
                }
                ToolbarItem {
                    Button {
                        isPresentingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $isPresentingMediaPicker) {
                MediaPicker()
            }
            .sheet(isPresented: $isPresentingFilePicker) {
                FilePicker()
            }
            .sheet(isPresented: $isPresentingSettings) {
                SettingsView(show: controller.show)
            }
            .onReceive(controller.$cuedSting) { _ in
                controller.validateCuedSting()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
    // MARK: Functions from PlaybackViewController
    
    func requestMediaLibraryAuthorization(successHandler: @escaping () -> Void) {
        MPMediaLibrary.requestAuthorization { authorizationStatus in
            if authorizationStatus == .authorized {
                DispatchQueue.main.async { successHandler() }
            }
        }
    }
    
    func presentMediaLibraryAccessAlert() {
        let alert = UIAlertController(title: "Enable Access",
                                      message: "Please enable Media & Apple Music access in the Settings app.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        }))
//        self.present(alert, animated: true)
    }
    
    func pickStingFromLibrary() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            if MPMediaLibrary.authorizationStatus() == .notDetermined {
                requestMediaLibraryAuthorization(successHandler: { self.pickStingFromLibrary() })
            } else {
                presentMediaLibraryAccessAlert()
            }
            
            return
        }
        
        #if targetEnvironment(simulator)
        // pick a random file from the file system as no library is available on the simulator
        loadRandomTrackFromHostFileSystem()
        #else
        
        isPresentingMediaPicker = true
        #endif
    }
    
    #if targetEnvironment(simulator)
    func loadRandomTrackFromHostFileSystem() {
        guard let sharedFiles = try? FileManager.default.contentsOfDirectory(atPath: "/Users/Shared/Music") else { return }
        
        let audioFiles = sharedFiles.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".m4a") }
        guard audioFiles.count > 0 else { fatalError() }
        let file = audioFiles[Int.random(in: 0..<audioFiles.count)]
        let url = URL(fileURLWithPath: "/Users/Shared/Music").appendingPathComponent(file)
        
        if let sting = Sting(url: url) {
            controller.load(sting)
        }
    }
    #endif
}


struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}
