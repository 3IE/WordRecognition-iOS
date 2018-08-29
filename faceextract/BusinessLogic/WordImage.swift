//
//  WordImage.swift
//  faceextract
//
//  Created by Benoit Verdier on 29/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import Foundation
import ARKit

class WordImage {
	private static let kMaxSamplesCountPerRecording = 120
	private static let kMaxSamplesCountInBuffer = 200
	private static let kNeedToRecordMeaningThreshold: Double = 120/100
	private static let kNeedToRecordNeutralThreshold: Double = 140/100
	
	var isRecording: Bool = false
	
	private var expressionsBuffer = [[ARFaceAnchor.BlendShapeLocation: NSNumber]]()
	private var _recordedExpressionsCount = 0
	var recordedExpressionsCount: Int {
		get { return _recordedExpressionsCount }
	}
	let neutralHistory: HistorizedProbabilities
	
	init(neutralHistory: HistorizedProbabilities) {
		self.neutralHistory = neutralHistory
	}
	
	func appendNewExpression(_ expression: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
		expressionsBuffer.append(expression)
		if (expressionsBuffer.count > WordImage.kMaxSamplesCountInBuffer) {
			expressionsBuffer.removeFirst()
		}
		if (isRecording) {
			_recordedExpressionsCount += 1
		}
	}
	
	/// predict the need to record based on the neutral history
	func predictNeedToRecord(isCurrentlyRecording: Bool) -> Bool {
		guard neutralHistory.history.count > 0 else {
			print("unable to predict with an empty history")
			return false
		}
		let averagedProba = neutralHistory.averagedSortedDesc
		if let bestProba = averagedProba.first, let secondProba = averagedProba.last {
			let shouldRecordNow = (bestProba.key != "neutral")
			let certainty = bestProba.value / secondProba.value
			// we only take into account the recording decision if we are above a certain threashold
			if (shouldRecordNow != isCurrentlyRecording && (shouldRecordNow && certainty > WordImage.kNeedToRecordMeaningThreshold || shouldRecordNow == false && certainty > WordImage.kNeedToRecordNeutralThreshold)) {
				return shouldRecordNow
			}
		}
		return isCurrentlyRecording
	}
	
	func startRecording() {
		_recordedExpressionsCount = 0
		isRecording = true
	}
	
	func stopRecording() {
		isRecording = false
	}
	
	private static func grayImageFromBytes(_ bytes: [UInt8], imgWidth: Int) -> UIImage? {
		let modulo = bytes.count % imgWidth
		let imgHeight = bytes.count / imgWidth
		if (modulo != 0) {
			return nil
		}
		
		let bytesPerPixel = 1
		guard let data = CFDataCreate(nil, bytes, bytes.count) else{ return nil }
		let provider = CGDataProvider(data: data)
		guard let cgImg = CGImage(width: imgWidth, height: imgHeight, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: bytesPerPixel * imgWidth, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: [], provider: provider!, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return nil }
		let img = UIImage(cgImage: cgImg)
		return img
	}
	
	/// Enhance the values (0.0...1.0) to help the image recognition.
	/// We can do this because usually when we speak the values are less that 0.5
	/// The function clip the values above 1.0
	private static func enhanceRecording(_ simplifiedRecording: [[String:Double]], factor: Float) -> [[String:Double]] {
		let enchancedRecording = simplifiedRecording.map { record -> [String:Double] in
			var enhancedRecord = [String:Double]()
			for elt in record {
				enhancedRecord[elt.key] = min(elt.value * 2, 1.0)
			}
			return enhancedRecord
		}
		return enchancedRecording
	}
	
	/// aggregate the recording by putting all the features values from a discrete time  into a single array
	private static func imageFrom(_ recording: [[String:Double]], addPadding: Bool) -> UIImage? {
		guard let featureCount = recording.first?.count, featureCount > 0 else {
			return nil
		}
		var recordingValues = [UInt8]()
		let trimmedRecording = recording.prefix(upTo: min(WordImage.kMaxSamplesCountPerRecording, recording.count))
		
		for record in trimmedRecording {
			let sortedRecord = record.sorted { $0.key > $1.key }
			let values = sortedRecord.map{ ($0.value * 255).rounded() }
			//we have to check if the values are less that 0 due to the float representation approximation
			let safeValues = values.map{ $0 < 0 ? 0 : ($0 > 255 ? 255 : UInt8($0)) }
			recordingValues.append(contentsOf: safeValues)
		}
		if (addPadding && trimmedRecording.count < WordImage.kMaxSamplesCountPerRecording) {
			let missingCount = WordImage.kMaxSamplesCountPerRecording - trimmedRecording.count
			let toto = [UInt8](repeating: 0, count: missingCount * featureCount)
			recordingValues.append(contentsOf: toto)
		}
		
		let img = WordImage.grayImageFromBytes(recordingValues, imgWidth: featureCount)
		return img
	}
	
	func wordImageFromExpressions() -> UIImage? {
		guard neutralHistory.history.count > 0 else {
			print("unable to determine the right window of expressions containing the word because neutral has not been monitored")
			return nil
		}
		// we want to process the samples that led to the detection (and a few extra ones before)
		let samplesCountToProcess = min(recordedExpressionsCount + neutralHistory.probabilitiesHistoryMaxLength, WordImage.kMaxSamplesCountPerRecording, expressionsBuffer.count)
		// we alse remove part of the sample that led to stopping the recording
		let recordingToProcess = expressionsBuffer.suffix(from: expressionsBuffer.count - samplesCountToProcess).prefix(samplesCountToProcess - neutralHistory.probabilitiesHistoryMaxLength / 3)
		let simplifiedRecording = FaceProcessing.simplifyRecording(Array(recordingToProcess))
		let enhancedRecording = WordImage.enhanceRecording(simplifiedRecording, factor: 2.0)
		
		return WordImage.imageFrom(enhancedRecording, addPadding: false)
	}
}
