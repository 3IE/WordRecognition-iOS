//
//  RecordVowelVC.swift
//  faceextract
//
//  Created by Benoit Verdier on 26/07/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import UIKit
import ARKit

class RecordVowelVC: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
	
	@IBOutlet weak var sceneView: ARSCNView!
	@IBOutlet weak var recognitionView: UIView!
	@IBOutlet weak var recordingView: UIView!
	@IBOutlet weak var recognitionStatsTextView: UITextView!
	@IBOutlet weak var predictionLabel: UILabel!
	
	var session: ARSession {
		return sceneView.session
	}
	
	let vowel = ["a","e","i","o","u", "neutral"]
	let regionsToRecord = ["mouth", "jawOpen"]
	let regionsToDiscard = ["mouthRight", "mouthLeft"]
	var selectedVowel: String = ""
	var learningMode: LearningMode = .record
	var vowelMode: VowelLearningSubMode = .vowelRecognition
	
	var latestBlendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
	var recordedExpressions: [[String:Encodable]] = []
	
	let vowelModel = VowelOnFace()
	let neutralModel = NeutralFace()
	var vowelHistory = HistorizedProbabilities()
	let kProbabilitiesHistoryMaxCount = 15

	// MARK: - View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		session.delegate = self
		if let vowel = vowel.first {
			selectedVowel = vowel
		}
		adaptInterfaceToLearningMode()
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
	
	func adaptInterfaceToLearningMode() {
		recognitionView.isHidden = (learningMode == .record)
		recordingView.isHidden = (learningMode == .recognize)
	}
	
	// MARK: other

	func printStats() {
		print("number of records : \(recordedExpressions.count)")
		var vowelStats = [String:Int]()
		recordedExpressions.forEach { expression in
			if let vowel = expression["vowel"] as? String {
				if let currentValue = vowelStats[vowel] {
					vowelStats[vowel] = currentValue + 1
				}
				else {
					vowelStats[vowel] = 1
				}
			}
		}
		print(vowelStats)
	}
	
	@IBAction func recordFaceAction(_ sender: Any) {
		var encodablesShapes: [String: Encodable] = FaceProcessing.simplifyRecord(latestBlendShapes)
		encodablesShapes["vowel"] = selectedVowel
		recordedExpressions.append(encodablesShapes)
		printStats()
		
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: recordedExpressions, options: .prettyPrinted)
			if let str = String(data: jsonData, encoding: .utf8) {
				let filename = (vowelMode == .vowelRecognition) ? "vowelTrainingData.json" : "neutralTrainingData.json"
				let fileUrl = Helper.getDocumentsDirectory().appendingPathComponent(filename)
				try str.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
			}
			Helper.displayFlashSubview(inView: self.view, withDuration: 0.3)
		}
		catch {
			print("unable to save json")
		}
	}
	
	@IBAction func clearAction(_ sender: Any) {
		recordedExpressions.removeAll(keepingCapacity: false)
		print(recordedExpressions)
	}
	
	// MARK: - recognition
	
	func printablesProbabilies(_ probabilities: [String:Double], maxCount: Int = Int.max) -> String {
		let bestSortedProbs = probabilities.sorted{ $0.value > $1.value}.prefix(min(probabilities.count, maxCount))
		return bestSortedProbs.map{ "\($0.key): \(($0.value * 100).rounded(toPlaces: 1))%" }.joined(separator: "\n")
	}
	
	func detectVowel(_ blendshapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
		let probabilities: [String:Double]
		do {
			switch vowelMode {
			case .neutralRecognition:
				guard let input = NeutralFaceInput(blendshapes: blendshapes) else { return }
				let predictions = try neutralModel.prediction(input: input)
				probabilities = predictions.vowelProbability
			case .vowelRecognition:
				guard let input = VowelOnFaceInput(blendshapes: blendshapes) else { return }
				let predictions = try vowelModel.prediction(input: input)
				probabilities = predictions.vowelProbability
			}
		}
		catch {
			print("prediction failure")
			return
		}
		
		vowelHistory.appendNewProbability(probabilities)
		if let best = vowelHistory.averagedSortedDesc.first {
			DispatchQueue.main.async {
				self.predictionLabel.text = best.key
			}
		}
		
		DispatchQueue.main.async {
			self.recognitionStatsTextView.text = self.printablesProbabilies(probabilities, maxCount: 2)
		}
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
		latestBlendShapes = faceAnchor.blendShapes
		if (learningMode == .recognize) {
			detectVowel(latestBlendShapes)
		}
	}
}

extension RecordVowelVC: UIPickerViewDelegate, UIPickerViewDataSource{
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return vowel.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return vowel[row]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		selectedVowel = vowel[row]
	}
}
