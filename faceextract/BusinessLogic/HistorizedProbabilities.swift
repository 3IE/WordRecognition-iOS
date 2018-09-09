//
//  HistorizedProbabilities.swift
//  faceextract
//
//  Created by Benoit Verdier on 29/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import Foundation

class HistorizedProbabilities {
	private static let kProbabilitiesHistoryDefaultLength = 12
	
	let probabilitiesHistoryMaxLength: Int
	private var _previousProbabilites = [[String:Double]]()
	
	init(probabilitiesHistoryMaxLength: Int = kProbabilitiesHistoryDefaultLength) {
		self.probabilitiesHistoryMaxLength = probabilitiesHistoryMaxLength
	}
	
	func appendNewProbability(_ probability: [String:Double]) {
		_previousProbabilites.append(probability)
		if (_previousProbabilites.count > probabilitiesHistoryMaxLength) {
			_previousProbabilites.removeFirst()
		}
	}

	/// an array of previous probabilities, the first one being the oldest
	var history:[[String:Double]] {
		get {
			return _previousProbabilites
		}
	}
	
	var averaged:[String:Double] {
		get {
			return averageProbabilites()
		}
	}
	
	var averagedSortedDesc:[(key: String, value: Double)] {
		get {
			return averageProbabilites().sorted{ $0.value > $1.value}
		}
	}
	
	private func averageProbabilites() -> [String:Double] {
		var averagedProba = [String:Double]()
		var pos = 0
		for proba in _previousProbabilites {
			let coeff =  pow(Double(1 + pos) / Double(_previousProbabilites.count), 0.3)
			for elt in proba {
				let newValue =  Double(elt.value) * coeff
				if let currentValue = averagedProba[elt.key] {
					averagedProba[elt.key] = currentValue + newValue
				}
				else {
					averagedProba[elt.key] = newValue
				}
			}
			pos += 1
		}
		return averagedProba
	}

}
