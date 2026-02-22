import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    
    // Set initial window size
    let initialSize = NSSize(width: 1400, height: 900)
    self.setFrame(NSRect(origin: windowFrame.origin, size: initialSize), display: true)
    
    // Set minimum window size to prevent RenderFlex overflow
    self.contentMinSize = NSSize(width: 1000, height: 700)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
