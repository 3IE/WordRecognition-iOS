//
//  SelectionVC.swift
//  faceextract
//
//  Created by Benoit Verdier on 13/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import UIKit

class SelectionVC: UIViewController {

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "RecordWordSegue":
			guard let dest = segue.destination as? RecordWordVC else { return }
			dest.learningMode = .record
		case "RecognizeWordSegue":
			guard let dest = segue.destination as? RecordWordVC else { return }
			dest.learningMode = .recognize
		case "RecordVowelSegue":
			guard let dest = segue.destination as? RecordVowelVC else { return }
			dest.learningMode = .record
			dest.vowelMode = .vowelRecognition
		case "DetectNeutralSegue":
			guard let dest = segue.destination as? RecordVowelVC else { return }
			dest.learningMode = .recognize
			dest.vowelMode = .neutralRecognition
		case "RecognizeVowelSegue":
			guard let dest = segue.destination as? RecordVowelVC else { return }
			dest.learningMode = .recognize
			dest.vowelMode = .vowelRecognition
		default:
			print("")
		}
    }
	
}
