//
//  RecordWordViewController.swift
//  faceextract
//
//  Created by Benoit Verdier on 02/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import UIKit
import ARKit
import Vision

class RecordWordVC: UIViewController, ARSCNViewDelegate {

	@IBOutlet weak var sceneView: ARSCNView!
	@IBOutlet weak var recordedImageView: UIImageView!
	@IBOutlet weak var perfCounterLabel: UILabel!
	@IBOutlet weak var isSpeakingLabel: UILabel!
	@IBOutlet weak var recordingView: UIView!
	@IBOutlet weak var recognitionView: UIView!
	@IBOutlet weak var recognitionStatsTextView: UITextView!

	var session: ARSession {
		return sceneView.session
	}
	var learningMode: LearningMode = .record
	var rendererInSecond = 0
	let dateFormatter = DateFormatter()

	let mlWordModel = WordImageClassifier()
	let mlNeutralModel = NeutralFace()
	let neutralPredictionQueue = DispatchQueue(label: "neutralPredictionQueue")
	
	let speakers = ["Benoit", "Arnaud", "Sofiane", "Anne"]
	var selectedSpeaker = ""
	let trainingWords = ["maison", "chien", "voiture", "marron", "gateau", "bateau", "rouge", "vert", "bleu"]
	var selectedWord = ""
	var previousPerfCounter = Date.distantPast
	
	var waitingForAlertAnswer = false
	var isProcessingEnabled = false
	var isConfirmationEnabled = false

	var needToRecord = false {
		didSet {
			if (oldValue == false && needToRecord == true) {
				startRecording()
			}
			else if (oldValue == true && needToRecord == false) {
				stopRecording()
				processRecording()
			}
		}
	}
	
	var neutralHistory = HistorizedProbabilities()
	var wordImage: WordImage!
	
	var wordRecoRequest: VNCoreMLRequest?
	
	// MARK: - View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initFolderInStorage()
		initMLWordRequest()
		adaptInterfaceToLearningMode()
		wordImage = WordImage(neutralHistory: neutralHistory)
		
		selectedWord = trainingWords.first!
		selectedSpeaker = speakers.first!
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
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
	
	func initMLWordRequest() {
		if let visionModel = try? VNCoreMLModel(for: mlWordModel.model) {
			wordRecoRequest = VNCoreMLRequest(model: visionModel) { request, error in
				if let observations = request.results as? [VNClassificationObservation] {
					let bestProbs = observations.sorted { $0.confidence > $1.confidence }.prefix(min(observations.count, 3))
					DispatchQueue.main.async {
						self.recognitionStatsTextView.text = bestProbs.map{ "\($0.identifier): \(($0.confidence * 100).rounded(toPlaces: 1))%" }.joined(separator: "\n")
					}
				}
			}
			wordRecoRequest?.imageCropAndScaleOption = .scaleFill
		}
	}
	
	func initFolderInStorage() {
		for word in trainingWords {
			let directoryUrl = Helper.getDocumentsDirectory().appendingPathComponent(word)
			if (!FileManager.default.fileExists(atPath: directoryUrl.path)) {
				do {
					try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false)
				}
				catch {
					print("unable to create '\(word)' folder ")
				}
			}
		}
	}
	
	func adaptInterfaceToLearningMode() {
		recordingView.isHidden = !(learningMode == .record)
		recognitionView.isHidden = !(learningMode == .recognize)
		if (learningMode == .recognize) {
			isProcessingEnabled = true
		}
	}

	// MARK: - IBAction
	
	@IBAction func switchRecordingAction(_ sender: UISwitch) {
		isProcessingEnabled = sender.isOn
	}
	
	@IBAction func switchConfirmRecordingAction(_ sender: UISwitch) {
		isConfirmationEnabled = sender.isOn
	}
	
	// MARK: - Other
	
	func startRecording() {
		wordImage.startRecording()
		DispatchQueue.main.async {
			self.recordedImageView.isHidden = true
			self.isSpeakingLabel.isHidden = false
		}
	}
	
	func stopRecording() {
		wordImage.stopRecording()
		DispatchQueue.main.async {
			self.isSpeakingLabel.isHidden = true
		}
	}
	
	func saveWordImageWithAlert(_ img: UIImage) {
		if (isConfirmationEnabled) {
			waitingForAlertAnswer = true
			DispatchQueue.main.async {
				let alert = UIAlertController(title: "Image save ?", message: "Do you want to keep this recording ?", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
					Helper.saveWordImage(img, word: self.selectedWord, speaker: self.selectedSpeaker, dateFormatInFilename: self.dateFormatter)
					self.waitingForAlertAnswer = false
				}))
				alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
					self.waitingForAlertAnswer = false
				}))
				self.present(alert, animated: true, completion: nil)
			}
		}
		else {
			Helper.saveWordImage(img, word: self.selectedWord, speaker: self.selectedSpeaker, dateFormatInFilename: self.dateFormatter)
		}
	}
	
	func processRecording() {
		guard let img = wordImage.wordImageFromExpressions() else { return }
		self.displayWordImage(img)
		if (isProcessingEnabled) {
			switch (learningMode) {
			case .record:
				saveWordImageWithAlert(img)
			case .recognize:
				recognizeWordImage(img)
			}
		}
	}
	
	func recognizeWordImage(_ img: UIImage) {
		let resizedImg = img.resizedImage(CGSize(width: 299, height: 299), interpolationQuality: .none)
		if let request = wordRecoRequest, let cgImg = resizedImg.cgImage {
			let handler = VNImageRequestHandler(cgImage: cgImg)
			do {
				try handler.perform([request])
			}
			catch {
			}
		}
	}
	
	var hideImageTask: DispatchWorkItem? = nil
	func displayWordImage(_ image: UIImage) {
		DispatchQueue.main.async {
			self.recordedImageView.image = image
			self.recordedImageView.layer.magnificationFilter = .nearest
			self.recordedImageView.isHidden = false
		}
		if let hideImageTask = hideImageTask {
			hideImageTask.cancel()
		}
		hideImageTask = DispatchWorkItem {
			self.recordedImageView.isHidden = true
		}
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(10), execute: hideImageTask!)
	}
	
	// MARK: - ARFaceTrackingSetup
	
	func setupTracking() {
		guard ARFaceTrackingConfiguration.isSupported else { return }
		let configuration = ARFaceTrackingConfiguration()
		configuration.isLightEstimationEnabled = false
		session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
	}
	
	// - MARK: ARSCNViewDelegate
	
	func computePerformance() {
		if (Date().timeIntervalSince(previousPerfCounter) > TimeInterval(1)) {
			previousPerfCounter = Date()
			let copy = rendererInSecond
			DispatchQueue.main.async {
				self.perfCounterLabel.text = "\(copy)/sec"
			}
			rendererInSecond = 0
		}
		rendererInSecond += 1
	}
	
	func recordOnNeutralDetection(blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber]) {
		neutralPredictionQueue.async {
			guard let input = NeutralFaceInput(blendshapes: blendShapes) else { return }
			let prediction: NeutralFaceOutput
			do { prediction = try self.mlNeutralModel.prediction(input: input) }
			catch { return }
			self.neutralHistory.appendNewProbability(prediction.vowelProbability)
			self.needToRecord = self.wordImage.predictNeedToRecord(isCurrentlyRecording: self.needToRecord)
		}
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let faceAnchor = anchor as? ARFaceAnchor else { return }
		wordImage.appendNewExpression(faceAnchor.blendShapes)
		computePerformance()
		if (!waitingForAlertAnswer) {
			recordOnNeutralDetection(blendShapes: faceAnchor.blendShapes)
		}
	}
}

// MARK: - PickerView delegate

extension RecordWordVC: UIPickerViewDelegate, UIPickerViewDataSource{
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 2
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case 0:
			return speakers.count
		default:
			return trainingWords.count
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		switch component {
		case 0:
			return speakers[row]
		default:
			return trainingWords[row]
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		switch component {
		case 0:
			selectedSpeaker = speakers[row]
		default:
			selectedWord = trainingWords[row]
		}


	}
}
