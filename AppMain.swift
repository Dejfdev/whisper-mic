import Cocoa

@main
class AppMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        
        // Starts the main event loop
        app.run()
    }
}
