//
//  FaceInputExtensions.swift
//  faceextract
//
//  Created by Benoit Verdier on 14/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import Foundation
import ARKit

extension NeutralFaceInput {
	convenience init?(blendshapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
		var encodablesShapes: [String: Double] = FaceProcessing.simplifyRecord(blendshapes)
		guard let mouthLowerDown = encodablesShapes["mouthLowerDown"], let mouthPress = encodablesShapes["mouthPress"], let mouthRollLower = encodablesShapes["mouthRollLower"], let jawOpen = encodablesShapes["jawOpen"], let mouthShrugLower = encodablesShapes["mouthShrugLower"], let mouthShrugUpper = encodablesShapes["mouthShrugUpper"], let mouthDimple = encodablesShapes["mouthDimple"], let mouthStretch = encodablesShapes["mouthStretch"], let mouthUpperUp = encodablesShapes["mouthUpperUp"], let mouthFunnel = encodablesShapes["mouthFunnel"], let mouthClose = encodablesShapes["mouthClose"], let mouthSmile = encodablesShapes["mouthSmile"], let mouthRollUpper = encodablesShapes["mouthRollUpper"], let mouthPucker = encodablesShapes["mouthPucker"], let mouthFrown = encodablesShapes["mouthFrown"]
			else {
				print("NeutralFaceInput: invalid blend shapes")
				return nil
		}
		self.init(jawOpen: jawOpen, mouthClose: mouthClose, mouthDimple: mouthDimple, mouthFrown: mouthFrown, mouthFunnel: mouthFunnel, mouthLowerDown: mouthLowerDown, mouthPress: mouthPress, mouthPucker: mouthPucker, mouthRollLower: mouthRollLower, mouthRollUpper: mouthRollUpper, mouthShrugLower: mouthShrugLower, mouthShrugUpper: mouthShrugUpper, mouthSmile: mouthSmile, mouthStretch: mouthStretch, mouthUpperUp: mouthUpperUp)
	}
}

extension VowelOnFaceInput {
	convenience init?(blendshapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
		var encodablesShapes: [String: Double] = FaceProcessing.simplifyRecord(blendshapes)
		guard let mouthLowerDown = encodablesShapes["mouthLowerDown"], let mouthPress = encodablesShapes["mouthPress"], let mouthRollLower = encodablesShapes["mouthRollLower"], let jawOpen = encodablesShapes["jawOpen"], let mouthShrugLower = encodablesShapes["mouthShrugLower"], let mouthShrugUpper = encodablesShapes["mouthShrugUpper"], let mouthDimple = encodablesShapes["mouthDimple"], let mouthStretch = encodablesShapes["mouthStretch"], let mouthUpperUp = encodablesShapes["mouthUpperUp"], let mouthFunnel = encodablesShapes["mouthFunnel"], let mouthClose = encodablesShapes["mouthClose"], let mouthSmile = encodablesShapes["mouthSmile"], let mouthRollUpper = encodablesShapes["mouthRollUpper"], let mouthPucker = encodablesShapes["mouthPucker"], let mouthFrown = encodablesShapes["mouthFrown"]
			else {
				print("VowelOnFaceInput: invalid blend shapes")
				return nil
		}
		self.init(jawOpen: jawOpen, mouthClose: mouthClose, mouthDimple: mouthDimple, mouthFrown: mouthFrown, mouthFunnel: mouthFunnel, mouthLowerDown: mouthLowerDown, mouthPress: mouthPress, mouthPucker: mouthPucker, mouthRollLower: mouthRollLower, mouthRollUpper: mouthRollUpper, mouthShrugLower: mouthShrugLower, mouthShrugUpper: mouthShrugUpper, mouthSmile: mouthSmile, mouthStretch: mouthStretch, mouthUpperUp: mouthUpperUp)
	}
}
