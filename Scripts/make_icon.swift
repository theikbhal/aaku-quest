import AppKit
let out = CommandLine.arguments[1]
let s: CGFloat = 1024
let img = NSImage(size: NSSize(width: s, height: s))
img.lockFocus()
let rect = NSRect(x: 0, y: 0, width: s, height: s).insetBy(dx: 60, dy: 60)
let path = NSBezierPath(roundedRect: rect, xRadius: 200, yRadius: 200)
NSGradient(colors: [NSColor(red: 0.55, green: 0.85, blue: 0.4, alpha: 1), NSColor(red: 0.1, green: 0.5, blue: 0.25, alpha: 1)])!.draw(in: path, angle: -90)
let str = NSAttributedString(string: "🥬", attributes: [.font: NSFont.systemFont(ofSize: 560)])
let sz = str.size()
str.draw(at: NSPoint(x: (s - sz.width) / 2, y: (s - sz.height) / 2))
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
