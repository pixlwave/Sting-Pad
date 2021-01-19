import Foundation

class FolderBookmarks {
    
    static let shared = FolderBookmarks()
    
    private(set) var bookmarkDictionary = [URL: Data]()
    
    private var securityScopedURLs = [URL]()
    
    private init() {
        let bookmarks = UserDefaults.standard.array(forKey: "bookmarks") as? [Data] ?? [Data]()
        
        for i in 0..<bookmarks.count {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: bookmarks[i], bookmarkDataIsStale: &isStale) else { return }
            
            if isStale {
                bookmarkDictionary[url] = getBookmark(from: url)
            } else {
                bookmarkDictionary[url] = bookmarks[i]
            }
        }
        
        updateDefaults()    // saves any refreshed bookmarks
    }
    
    private func getBookmark(from url: URL) -> Data? {
        let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScopedAccess { url.stopAccessingSecurityScopedResource() }
        }
        
        return try? url.bookmarkData()
    }
    
    func addBookmark(from url: URL) {
        guard let data = getBookmark(from: url) else { return }
        bookmarkDictionary[url] = data
        updateDefaults()
    }
    
    private func updateDefaults() {
        UserDefaults.standard.set(Array<Data>(bookmarkDictionary.values), forKey: "bookmarks")
    }
    
    func startAccessingSecurityScopedResources() {
        securityScopedURLs = bookmarkDictionary.keys.compactMap { url in
            url.startAccessingSecurityScopedResource() ? url : nil
        }
    }
    
    func stopAccessingSecurityScopedResources() {
        securityScopedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        securityScopedURLs = []
    }
}
