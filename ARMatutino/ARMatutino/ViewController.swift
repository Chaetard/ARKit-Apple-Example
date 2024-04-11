//
//  ViewController.swift
//  ARMatutino
//
//  Created by Joaquin  Ramirez Vila on 10/04/24.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {

    // 1.
    @IBOutlet weak var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        arView.session.delegate = self
        
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        
    }
    
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: arView)
        
        // Raycast
        let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = result.first {
            let worldPos = simd_make_float3(firstResult.worldTransform.columns.3)
            
            let box = createBox()
            placeObject(object: box, location: worldPos)
        }
        
        
    }
    
    func createBox() -> ModelEntity {

        let box = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: true)
        // Que renderizo
        let entity = ModelEntity(mesh: box, materials: [material])
  
        // Agregamos fisica
        let mass: Float = 1.0
        entity.physicsBody = .init(massProperties: .init(mass: mass), material: nil, mode: .dynamic)
        entity.physicsMotion = .init()
        
        // Collision
        let collisionShape = ShapeResource.generateBox(size: SIMD3(x: 0.1, y: 0.1, z: 0.1))
        entity.collision = .init(shapes: [collisionShape], mode: .default, filter: .default)
        
        return entity
    }
    
    func placeObject(object: ModelEntity, location: SIMD3<Float>) {
        
        var newLocation = location
        newLocation.y += 1.0
        
        let anchor = AnchorEntity(world: newLocation)
        
        anchor.addChild(object)
        
        arView.scene.addAnchor(anchor)
        
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            
 
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                // Entidad
                let extent = planeAnchor.extent
                let planeMesh = MeshResource.generatePlane(width: extent.x, depth: extent.z)
                let material = SimpleMaterial(color: .red, isMetallic: false)
                
                let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
                
                let physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
                planeEntity.components.set(physicsBody)
                
                let collisionShape = ShapeResource.generateBox(width: extent.x, height: 0.01, depth: extent.z)
                planeEntity.collision = .init(shapes: [collisionShape], mode: .default, filter: .default)
                
                
                
                let anchorEntity = AnchorEntity(anchor: planeAnchor)
                anchorEntity.addChild(planeEntity)
                arView.scene.addAnchor(anchorEntity)
                
                
            }
            
        }
    }
    
    

}

