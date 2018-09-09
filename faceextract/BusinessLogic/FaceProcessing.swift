//
//  FaceProcessing.swift
//  faceextract
//
//  Created by Benoit Verdier on 08/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import Foundation
import ARKit

class FaceProcessing {
	
	static let regionsToKeep = ["mouth", "jawOpen"]
	static let regionsToDiscard = ["mouthRight", "mouthLeft"]
	
	static func simplifyRecord(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) -> [String:Double] {
		var filteredShapes = blendShapes.filter { regionsToKeep.contains(where: $0.key.rawValue.contains)  }
		filteredShapes = filteredShapes.filter { regionsToDiscard.contains(where: $0.key.rawValue.contains) == false  }
		
		var encodableRecord = [String: Double]()
		filteredShapes.forEach {
			var key = $0.key.rawValue
			//only the left and right version of a feature have "_L" or "_R" postfix so we find it and remove it
			if let range = key.range(of: "_") {
				key = String(key.prefix(upTo: range.lowerBound))
			}
			// their only Left and Right value, so we know when we find an existing value we only need to divide by 2 to get the average
			if let existingValue = encodableRecord[key] {
				encodableRecord[key] = ($0.value.doubleValue + existingValue) / 2
			}
			else {
				encodableRecord[key] = $0.value.doubleValue
			}
		}
		return encodableRecord
	}
	
	static func simplifyRecording(_ recording: [[ARFaceAnchor.BlendShapeLocation: NSNumber]]) -> [[String:Double]] {
		var encodableRecording = [[String:Double]]()
		
		for blendShapes in recording {
			let encodableRecord = FaceProcessing.simplifyRecord(blendShapes)
			encodableRecording.append(encodableRecord)
		}
		
		return encodableRecording
	}
}
