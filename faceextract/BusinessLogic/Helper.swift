//
//  Helper.swift
//  faceextract
//
//  Created by Benoit Verdier on 02/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import Foundation
import UIKit

class Helper {
	static func displayFlashSubview(inView view: UIView, withDuration duration: TimeInterval) {
		let flashView = UIView(frame: view.frame)
		flashView.isOpaque = false
		flashView.backgroundColor = UIColor.red
		flashView.isUserInteractionEnabled = false
		flashView.alpha = 0.6
		view.addSubview(flashView)
		UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
			flashView.alpha = 0
		}, completion: { hasCompleted in
			flashView.removeFromSuperview()
		})
	}
	
	static func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}
	
	static func saveWordImage(_ image: UIImage, word: String, speaker: String, dateFormatInFilename dateFormatter: DateFormatter) {
		do {
			let formatedDate = (dateFormatter.string(from: Date()))
			let folderUrl = Helper.getDocumentsDirectory().appendingPathComponent(word)
			let imageName = "\(speaker)-\(word)-\(formatedDate).png"
			let filenameUrl = folderUrl.appendingPathComponent(imageName)
			try image.pngData()?.write(to: filenameUrl)
			print("\(imageName) saved")
		}
		catch {
			print("unable to save wordimage")
		}
	}
}

extension Double {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}

extension Float {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> Float {
		let divisor = pow(10.0, Float(places))
		return (self * divisor).rounded() / divisor
	}
}

extension UIImage {
	func resizedImage(_ newSize: CGSize, interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
		guard self.size != newSize else { return self }
		
		UIGraphicsBeginImageContextWithOptions(newSize, true, 1);
		
		guard let context = UIGraphicsGetCurrentContext() else { return self }
		context.interpolationQuality = interpolationQuality
		
		self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage!
	}
}
