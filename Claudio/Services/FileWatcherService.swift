import Foundation

/// Service for watching files for changes using DispatchSource
final class FileWatcherService {
    private var sources: [URL: DispatchSourceFileSystemObject] = [:]
    private var fileDescriptors: [URL: Int32] = [:]
    private let queue = DispatchQueue(label: "com.claudio.filewatcher", qos: .utility)
    private var debounceWorkItems: [URL: DispatchWorkItem] = [:]

    deinit {
        stopAll()
    }

    /// Start watching a file for changes
    /// - Parameters:
    ///   - url: The file URL to watch
    ///   - onChange: Callback when file changes
    func watch(_ url: URL, onChange: @escaping () -> Void) {
        // Stop any existing watcher for this file
        stopWatching(url)

        // Ensure the directory exists
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }

        // Open file descriptor
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            print("[FileWatcher] Failed to open file: \(url.path)")
            return
        }
        fileDescriptors[url] = fd

        // Create dispatch source
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.handleFileChange(url: url, onChange: onChange)
        }

        source.setCancelHandler {
            close(fd)
        }

        sources[url] = source
        source.resume()

        print("[FileWatcher] Started watching: \(url.lastPathComponent)")
    }

    /// Stop watching a specific file
    func stopWatching(_ url: URL) {
        if let source = sources[url] {
            source.cancel()
            sources.removeValue(forKey: url)
        }
        if let fd = fileDescriptors[url] {
            close(fd)
            fileDescriptors.removeValue(forKey: url)
        }
        debounceWorkItems[url]?.cancel()
        debounceWorkItems.removeValue(forKey: url)
    }

    /// Stop all file watchers
    func stopAll() {
        for url in Array(sources.keys) {
            stopWatching(url)
        }
    }

    /// Handle file change with debouncing
    private func handleFileChange(url: URL, onChange: @escaping () -> Void) {
        // Cancel any pending work item
        debounceWorkItems[url]?.cancel()

        // Create new debounced work item
        let workItem = DispatchWorkItem { [weak self] in
            guard self != nil else { return }
            DispatchQueue.main.async {
                onChange()
            }
        }

        debounceWorkItems[url] = workItem

        // Schedule with debounce delay
        queue.asyncAfter(
            deadline: .now() + Constants.fileWatcherDebounceInterval,
            execute: workItem
        )
    }
}
