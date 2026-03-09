//
//  ArcadeTheme.swift
//  Math Mission
//
//  Created by Oz on 3/7/26.
//

import SwiftUI
import SceneKit

enum ArcadePalette {
    static let spaceTop = Color(red: 0.04, green: 0.08, blue: 0.16)
    static let spaceBottom = Color(red: 0.01, green: 0.02, blue: 0.07)
    static let dust = Color(red: 0.63, green: 0.36, blue: 0.21)
    static let dustSoft = Color(red: 0.80, green: 0.58, blue: 0.38)
    static let signal = Color(red: 0.98, green: 0.46, blue: 0.18)
    static let signalBright = Color(red: 1.00, green: 0.69, blue: 0.34)
    static let signalMuted = Color(red: 0.73, green: 0.35, blue: 0.17)
    static let panelTop = Color(red: 0.22, green: 0.25, blue: 0.31)
    static let panelBottom = Color(red: 0.11, green: 0.13, blue: 0.18)
    static let panelEdge = Color.white.opacity(0.10)
    static let panelLine = Color.white.opacity(0.16)
    static let coolLine = Color(red: 0.64, green: 0.78, blue: 0.94)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textMuted = Color.white.opacity(0.48)
    static let success = Color(red: 0.48, green: 0.87, blue: 0.52)
    static let warning = Color(red: 0.99, green: 0.74, blue: 0.24)
    static let danger = Color(red: 0.93, green: 0.33, blue: 0.27)
}

struct BeveledPanelShape: InsettableShape {
    var cut: CGFloat = 16
    var insetAmount: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        let minX = rect.minX + insetAmount
        let minY = rect.minY + insetAmount
        let maxX = rect.maxX - insetAmount
        let maxY = rect.maxY - insetAmount
        let bevel = min(cut, min(rect.width, rect.height) * 0.25)
        
        var path = Path()
        path.move(to: CGPoint(x: minX + bevel, y: minY))
        path.addLine(to: CGPoint(x: maxX - bevel, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY + bevel))
        path.addLine(to: CGPoint(x: maxX, y: maxY - bevel))
        path.addLine(to: CGPoint(x: maxX - bevel, y: maxY))
        path.addLine(to: CGPoint(x: minX + bevel, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: maxY - bevel))
        path.addLine(to: CGPoint(x: minX, y: minY + bevel))
        path.closeSubpath()
        return path
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

struct ArcadeBackground: View {
    enum Variant {
        case standard
        case quiet
    }
    
    var variant: Variant = .standard
    
    var body: some View {
        GeometryReader { geometry in
            let isQuiet = variant == .quiet
            
            ZStack {
                LinearGradient(
                    colors: [ArcadePalette.spaceTop, ArcadePalette.spaceBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                RadialGradient(
                    colors: [ArcadePalette.signalMuted.opacity(isQuiet ? 0.16 : 0.28), .clear],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                )
                .ignoresSafeArea()
                
                RadialGradient(
                    colors: [ArcadePalette.coolLine.opacity(isQuiet ? 0.10 : 0.16), .clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.6
                )
                .ignoresSafeArea()
                
                ArcadeStarField(
                    starCount: isQuiet ? 28 : 48,
                    baseOpacity: isQuiet ? 0.14 : 0.25,
                    opacityVariation: isQuiet ? 0.18 : 0.45
                )
                if !isQuiet {
                    ArcadeScanLines()
                    ArcadeCornerBrackets()
                }
                ArcadeGridAccent(intensity: isQuiet ? 0.45 : 1.0)
            }
        }
    }
}

private struct ArcadeStarField: View {
    let starCount: Int
    let baseOpacity: CGFloat
    let opacityVariation: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<starCount, id: \.self) { index in
                    let size = CGFloat((index % 3) + 1) * 1.8
                    let x = pseudoValue(index * 31 + 7) * geometry.size.width
                    let y = pseudoValue(index * 17 + 11) * geometry.size.height
                    let opacity = baseOpacity + pseudoValue(index * 23 + 3) * opacityVariation
                    
                    Circle()
                        .fill(Color.white.opacity(opacity))
                        .frame(width: size, height: size)
                        .position(x: x, y: y)
                }
            }
        }
    }
    
    private func pseudoValue(_ seed: Int) -> CGFloat {
        let value = (seed * 73 + 19) % 100
        return CGFloat(value) / 100.0
    }
}

private struct ArcadeScanLines: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                ForEach(0..<Int(geometry.size.height / 8), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.025))
                        .frame(height: 1)
                }
            }
            .ignoresSafeArea()
        }
        .blendMode(.softLight)
    }
}

private struct ArcadeGridAccent: View {
    let intensity: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Path { path in
                    for index in 0..<7 {
                        let y = CGFloat(index) * 34 + 140
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.55, y: y - 42))
                    }
                }
                .stroke(ArcadePalette.coolLine.opacity(0.10 * intensity), lineWidth: 1)
                
                Path { path in
                    for index in 0..<5 {
                        let x = CGFloat(index) * 56 + 24
                        path.move(to: CGPoint(x: x, y: 110))
                        path.addLine(to: CGPoint(x: x + 42, y: 320))
                    }
                }
                .stroke(ArcadePalette.panelEdge.opacity(0.50 * intensity), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ArcadeCornerBrackets: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                cornerBracket
                    .frame(width: 56, height: 56)
                    .position(x: 42, y: 72)
                cornerBracket
                    .rotationEffect(.degrees(90))
                    .frame(width: 56, height: 56)
                    .position(x: geometry.size.width - 42, y: 72)
                cornerBracket
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .position(x: 42, y: geometry.size.height - 72)
                cornerBracket
                    .rotationEffect(.degrees(180))
                    .frame(width: 56, height: 56)
                    .position(x: geometry.size.width - 42, y: geometry.size.height - 72)
            }
        }
        .allowsHitTesting(false)
    }
    
    private var cornerBracket: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(ArcadePalette.signal.opacity(0.75))
                .frame(width: 40, height: 3)
            Rectangle()
                .fill(ArcadePalette.signal.opacity(0.75))
                .frame(width: 3, height: 40)
        }
    }
}

struct ArcadePanel<Content: View>: View {
    let accent: Color
    let content: Content
    
    init(accent: Color = ArcadePalette.signal, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            BeveledPanelShape(cut: 18)
                .fill(
                    LinearGradient(
                        colors: [ArcadePalette.panelTop.opacity(0.93), ArcadePalette.panelBottom.opacity(0.90)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            BeveledPanelShape(cut: 18)
                .stroke(ArcadePalette.panelLine, lineWidth: 1.2)
            
            BeveledPanelShape(cut: 18)
                .inset(by: 8)
                .stroke(accent.opacity(0.14), lineWidth: 1.3)
            
            content
                .padding(20)
        }
        .shadow(color: accent.opacity(0.14), radius: 10, y: 6)
    }
}

struct ArcadeSectionHeader: View {
    let eyebrow: String
    let title: String
    var description: String? = nil
    var accent: Color = ArcadePalette.signal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.custom("Exo 2 SemiBold", size: 12))
                .foregroundColor(ArcadePalette.textSecondary)
                .tracking(1.6)
            Text(title.uppercased())
                .font(.custom("Orbitron-Bold", size: 26))
                .foregroundColor(ArcadePalette.textPrimary)
            if let description {
                Text(description)
                    .font(.custom("Exo 2 Medium", size: 15))
                    .foregroundColor(ArcadePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.10)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .padding(.top, 4)
        }
    }
}

struct ArcadeStatusPill: View {
    let text: String
    var accent: Color = ArcadePalette.signal
    
    var body: some View {
        Text(text.uppercased())
            .font(.custom("Exo 2 SemiBold", size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(accent.opacity(0.18))
                    .overlay(
                        Capsule()
                            .stroke(accent.opacity(0.45), lineWidth: 1.2)
                    )
            )
    }
}

struct ArcadePrimaryActionLabel: View {
    let title: String
    var subtitle: String? = nil
    var enabled: Bool = true
    
    var body: some View {
        VStack(spacing: subtitle == nil ? 0 : 2) {
            Text(title.uppercased())
                .font(.custom("Orbitron-Bold", size: 22))
                .foregroundColor(.white.opacity(enabled ? 1.0 : 0.65))
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(.custom("Exo 2 SemiBold", size: 11))
                    .foregroundColor(.white.opacity(enabled ? 0.75 : 0.45))
                    .tracking(1.2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .background(
            BeveledPanelShape(cut: 14)
                .fill(
                    LinearGradient(
                        colors: enabled
                            ? [ArcadePalette.signalBright, ArcadePalette.signal, ArcadePalette.signalMuted]
                            : [ArcadePalette.panelTop, ArcadePalette.panelBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            BeveledPanelShape(cut: 14)
                .stroke(enabled ? Color.white.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
        .shadow(color: enabled ? ArcadePalette.signal.opacity(0.35) : .clear, radius: 14, y: 8)
    }
}

struct ArcadeSecondaryActionLabel: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.custom("Exo 2 SemiBold", size: 17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                BeveledPanelShape(cut: 12)
                    .fill(
                        LinearGradient(
                            colors: [ArcadePalette.panelTop.opacity(0.95), ArcadePalette.panelBottom.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                BeveledPanelShape(cut: 12)
                    .stroke(ArcadePalette.panelLine, lineWidth: 1.3)
            )
    }
}

struct ArcadeAssetPreviewView: UIViewRepresentable {
    let modelName: String
    var isDimmed: Bool = false
    var cameraZ: Float = 6
    var scale: Float = 1.0
    var yRotation: Float = Float.pi / 5
    var rotationDuration: Double = 8.0
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false
        sceneView.isUserInteractionEnabled = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.45, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.color = UIColor(red: 1.0, green: 0.83, blue: 0.65, alpha: 1.0)
        keyLight.position = SCNVector3(x: 5, y: 8, z: 10)
        scene.rootNode.addChildNode(keyLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.color = UIColor(red: 0.65, green: 0.78, blue: 0.95, alpha: 0.8)
        fillLight.position = SCNVector3(x: -6, y: 3, z: 6)
        scene.rootNode.addChildNode(fillLight)
        
        if let assetScene = SCNScene(named: "art.scnassets/\(modelName)") {
            let assetNode = SCNNode()
            for child in assetScene.rootNode.childNodes {
                assetNode.addChildNode(child)
            }
            
            assetNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            assetNode.eulerAngles = SCNVector3(x: 0.12, y: yRotation, z: 0)
            scene.rootNode.addChildNode(assetNode)
            
            if isDimmed {
                assetNode.enumerateChildNodes { node, _ in
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.16, alpha: 1.0)
                    node.geometry?.firstMaterial?.emission.contents = UIColor.black
                    node.geometry?.firstMaterial?.specular.contents = UIColor.black
                    node.geometry?.firstMaterial?.lightingModel = .constant
                }
            }
            
            let rotateAction = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: 0.8, z: 0, duration: rotationDuration)
            )
            assetNode.runAction(rotateAction)
        }
        
        let camera = SCNCamera()
        camera.fieldOfView = 38
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0.35, z: cameraZ)
        scene.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
