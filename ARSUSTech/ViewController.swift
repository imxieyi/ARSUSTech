//
//  ViewController.swift
//  ARSUSTech
//
//  Created by xieyi on 2017/11/1.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import SceneKit
import SceneKit.ModelIO
import ARKit

enum ModelLevel: String {
    case l1 = "level_0_0_0.scn"
    case l2 = "level_1_0_0.scn"
    case l3 = "level_2_0_0.scn"
    case l4 = "level_3_0_0.scn"
    case l5 = "level_4_0_0.scn"
    case l6 = "level_5_0_0.scn"
    case l7 = "level_6_0_32.scn"
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    @IBOutlet weak var label: UILabel!
    var map: SCNNode! = nil
    
    var level: ModelLevel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.layer.cornerRadius = 5
        label.backgroundColor = UIColor(white: 0, alpha: 0.7)
//        label.isHidden = true
        
        sceneView.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions.insert(ARSCNDebugOptions.showFeaturePoints)
        sceneView.debugOptions.insert(ARSCNDebugOptions.showWorldOrigin)
        
    }
    
    func initModel() {
        // Create a new scene
        //        let path = Bundle.main.path(forResource: "level_0_0_0", ofType: "scn")
        //        let asset = MDLAsset(url: URL(fileURLWithPath: path!))
        //        let scene = SCNScene()
        let scene = SCNScene(named: level.rawValue)!
        map = scene.rootNode.childNode(withName: "mapnode", recursively: false)
        //        map = SCNNode(mdlObject: asset.object(at: 0))
        map.scale = SCNVector3Make(0.002, 0.002, 0.002)
        map.isHidden = true
        //        map = SCNNode()
        //        scene.rootNode.add ChildNode(map)
        //        let scene = SCNScene()
        
        //        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        //        let boxNode = SCNNode(geometry: boxGeometry)
        //        boxNode.position = SCNVector3Make(0, 0, -0.5)
        //        scene.rootNode.addChildNode(boxNode)
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let alert = UIAlertController(title: "Select level", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "1", style: .default, handler: { (_) in self.level = .l1; self.initModel() }))
        alert.addAction(UIAlertAction(title: "2", style: .default, handler: { (_) in self.level = .l2; self.initModel() }))
        alert.addAction(UIAlertAction(title: "3", style: .default, handler: { (_) in self.level = .l3; self.initModel() }))
        alert.addAction(UIAlertAction(title: "4", style: .default, handler: { (_) in self.level = .l4; self.initModel() }))
        alert.addAction(UIAlertAction(title: "5", style: .default, handler: { (_) in self.level = .l5; self.initModel() }))
        alert.addAction(UIAlertAction(title: "6", style: .default, handler: { (_) in self.level = .l6; self.initModel() }))
        alert.addAction(UIAlertAction(title: "7", style: .default, handler: { (_) in self.level = .l7; self.initModel() }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
    var planes: [String: Plane] = [:]
    
    var currentPlaneKey = ""
    var currentAnchor: ARPlaneAnchor! = nil
    
    func mapAnchor(anchor: ARPlaneAnchor) {
//        planeGeometry.width = CGFloat(anchor.extent.x)
//        planeGeometry.height = CGFloat(anchor.extent.z)
        let pos = anchor.transform.columns.3
        map.position = SCNVector3Make(pos.x, pos.y, pos.z)
        // Reference: https://math.stackexchange.com/questions/237369/given-this-transformation-matrix-how-do-i-decompose-it-into-translation-rotati
        var roty = acos(anchor.transform.columns.0.x)
        if anchor.transform.columns.0.z > 0 {
            roty *= -1
        }
        debugPrint("Map position: \(map.position)")
        debugPrint("Map rotation: \(map.rotation)")
//        map.rotation.x = roty
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let panchor = anchor as? ARPlaneAnchor else {
            return
        }
        currentAnchor = panchor
        for uuid in planes.keys {
            planes[uuid]?.removeFromParentNode()
        }
        let plane = Plane(anchor: panchor)
        currentPlaneKey = anchor.identifier.uuidString
        planes[currentPlaneKey] = plane
        node.addChildNode(plane)
        DispatchQueue.main.async {
//            self.label.isHidden = false
            self.label.text = "Tap to place SUSTech model"
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let panchor = anchor as? ARPlaneAnchor else {
            return
        }
        currentAnchor = panchor
        if currentPlaneKey != anchor.identifier.uuidString {
            planes[currentPlaneKey]?.removeFromParentNode()
            currentPlaneKey = anchor.identifier.uuidString
            node.addChildNode(planes[currentPlaneKey]!)
            planes[currentPlaneKey]?.update(anchor: currentAnchor)
        }
        let plane = planes[currentPlaneKey]
        plane?.update(anchor: panchor)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapAnchor(anchor: currentAnchor)
        map.isHidden = false
        planes[currentPlaneKey]?.removeFromParentNode()
        // Stop updating planes
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        DispatchQueue.main.async {
            self.label.isHidden = true
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        planes[anchor.identifier.uuidString]?.removeFromParentNode()
        planes.removeValue(forKey: anchor.identifier.uuidString)
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        let node = SCNNode()
//        return node
//    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

class Plane: SCNNode {
    
    let anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        super.init()
        
        let material = SCNMaterial()
        let img = #imageLiteral(resourceName: "sustech_matrix")
        material.diffuse.contents = img
        planeGeometry.materials = [material]
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        // By default plane is verticle
        planeNode.transform = SCNMatrix4MakeRotation(-.pi/2, 1, 0, 0)
        
        setTextureScale()
        addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        anchor = nil
        planeGeometry = nil
        super.init(coder: aDecoder)
    }
    
    func update(anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        setTextureScale()
    }
    
    func setTextureScale() {
        let width = planeGeometry.width
        let height = planeGeometry.height
        let material = planeGeometry.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material?.diffuse.wrapS = .repeat
        material?.diffuse.wrapT = .repeat
    }
    
}
