//
//  FaceStatsTVC.swift
//  faceextract
//
//  Created by Benoit Verdier on 03/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import UIKit
import ARKit

class FaceStatsTVC: UIViewController, UITableViewDelegate, ARSCNViewDelegate, UITableViewDataSource {

	@IBOutlet weak var sceneView: ARSCNView!
	@IBOutlet weak var tableView: UITableView!
	
	var session: ARSession {
		return sceneView.session
	}
	var blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
	var blendShapesMaxValue: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
	var blendShapesMinValue: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
	var sortedShapeLocations: [ARFaceAnchor.BlendShapeLocation] = []
	var rendererCount = 0
	let statsFrequency = 4
	
	// MARK: - View lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupTracking()
		UIApplication.shared.isIdleTimerDisabled = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		session.pause()
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	// MARK: - ARFaceTrackingSetup
	
	func setupTracking() {
		guard ARFaceTrackingConfiguration.isSupported else { return }
		let configuration = ARFaceTrackingConfiguration()
		configuration.isLightEstimationEnabled = false
		session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
	}
	
	// - MARK: ARSCNViewDelegate
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let faceAnchor = anchor as? ARFaceAnchor else { return }
		let regionsToDisplay = ["mouth", "jaw", "cheek"]
		//since apple used an enum, we can use the raw value to get the name of the blend shape and filter it based on what we want to keep
		blendShapes = faceAnchor.blendShapes.filter { regionsToDisplay.contains(where: $0.key.rawValue.contains)  }
		//we initialize our dictionaries of min and max values if it's the first time we get an expression
		if (sortedShapeLocations.count == 0) {
			sortedShapeLocations = blendShapes.keys.sorted{ $0.rawValue > $1.rawValue }
			blendShapesMinValue = blendShapes
			blendShapesMaxValue = blendShapes
		}
		else {
			for elt in blendShapes {
				guard let maxValue = blendShapesMaxValue[elt.key] else { continue }
				guard let minValue = blendShapesMinValue[elt.key] else { continue }
				if (elt.value.floatValue > maxValue.floatValue) { blendShapesMaxValue[elt.key] = elt.value }
				if (elt.value.floatValue < minValue.floatValue) { blendShapesMinValue[elt.key] = elt.value }
			}
		}
		if (rendererCount % statsFrequency == 0) {
			DispatchQueue.main.async { self.tableView.reloadData() }
		}
		rendererCount += 1
	}
	
	// MARK: other
	@IBAction func resetAction(_ sender: Any) {
		blendShapesMinValue = blendShapes
		blendShapesMaxValue = blendShapes
		tableView.reloadData()
	}

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blendShapes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "shapeValuesId", for: indexPath)
		if let cell = cell as? ShapeValuesCell{
			let location = sortedShapeLocations[indexPath.row]
			cell.shapeNameLabel.text = location.rawValue
			if let value = blendShapes[location] {
				cell.currentValueLabel.text = String(format: "%.2f", value.floatValue)
			}
			if let maxValue = blendShapesMaxValue[location], let minValue = blendShapesMinValue[location] {
				cell.maxValueLabel.text = String(format: "%.2f", maxValue.floatValue)
				cell.minValueLabel.text = String(format: "%.2f", minValue.floatValue)
				cell.deltaLabel.text = String(format: "%.2f", maxValue.floatValue - minValue.floatValue)
			}
		}
		return cell
    }

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 20
	}

}
