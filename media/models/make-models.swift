// The model fixtures' steps that need macOS: the texture (drawn in the corpus's own font) before
// make-models.py, and SceneKit's and Model I/O's formats after it. README.md lists every step.
//
//     swift make-models.swift texture
//     swift make-models.swift convert

import AppKit
import ModelIO
import SceneKit
import SceneKit.ModelIO

let folder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
let texture = folder.appendingPathComponent("sample-uv-checker.png")

/// A 1024 × 512 UV checker: 16 columns A–P by 8 rows 1–8, row 1 at the image's bottom, so a
/// model shows a misplaced, flipped or mirrored texture coordinate at a glance.
func drawTexture() {
    let fontURL = folder.appendingPathComponent("../fonts/sample.ttf").standardizedFileURL
    guard let descriptor = (CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor])?.first else {
        fatalError("the corpus font \(fontURL.path) is missing")
    }
    let font = CTFontCreateWithFontDescriptor(descriptor, 24, nil) as NSFont
    let (width, height, columns, rows) = (1024, 512, 16, 8)
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
    else { fatalError("no bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let light = NSColor(srgbRed: 0.95, green: 0.95, blue: 0.96, alpha: 1)
    let dark = NSColor(srgbRed: 0.16, green: 0.38, blue: 0.80, alpha: 1)
    let side = CGFloat(width / columns)
    for row in 0..<rows {
        for column in 0..<columns {
            let cell = NSRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side)
            let isDark = (row + column) % 2 == 1
            (isDark ? dark : light).setFill()
            cell.fill()
            let letter = String(UnicodeScalar(UInt8(65 + column)))
            let label = NSAttributedString(string: "\(letter)\(row + 1)", attributes: [.font: font, .foregroundColor: isDark ? light : dark])
            let size = label.size()
            label.draw(at: NSPoint(x: cell.midX - size.width / 2, y: cell.midY - size.height / 2))
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("no PNG") }
    try! png.write(to: texture)
    print("wrote \(texture.lastPathComponent)")
}

/// sample.scn (SceneKit's archive, its texture embedded so the file stands alone) and sample.abc
/// (Alembic, through Model I/O), both from sample.usda. The archive is written from a fresh scene
/// holding copies of the nodes, and the texture's path is swapped for the image itself: a loaded
/// scene keeps the absolute paths of its source file and texture, and would write them out.
func convert() {
    let source = folder.appendingPathComponent("sample.usda")
    let loaded = try! SCNScene(url: source, options: nil)
    let scene = SCNScene()
    for child in loaded.rootNode.childNodes { scene.rootNode.addChildNode(child.clone()) }
    guard let checker = NSImage(contentsOf: texture) else { fatalError("\(texture.lastPathComponent) is missing") }
    scene.rootNode.enumerateHierarchy { node, _ in
        for material in node.geometry?.materials ?? [] where material.diffuse.contents is URL || material.diffuse.contents is String {
            material.diffuse.contents = checker
        }
    }
    guard scene.write(to: folder.appendingPathComponent("sample.scn"), options: nil, delegate: nil, progressHandler: nil) else {
        fatalError("SceneKit did not write sample.scn")
    }
    try! MDLAsset(url: source).export(to: folder.appendingPathComponent("sample.abc"))
    print("wrote sample.scn, sample.abc")
}

switch CommandLine.arguments.dropFirst().first {
case "texture": drawTexture()
case "convert": convert()
default:
    print("usage: swift make-models.swift texture|convert")
    exit(2)
}
