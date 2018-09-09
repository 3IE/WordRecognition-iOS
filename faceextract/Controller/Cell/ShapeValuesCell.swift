//
//  ShapeValuesCell.swift
//  faceextract
//
//  Created by Benoit Verdier on 03/08/2018.
//  Copyright © 2018 EPITA. All rights reserved.
//

import UIKit

class ShapeValuesCell: UITableViewCell {

	@IBOutlet weak var shapeNameLabel: UILabel!
	@IBOutlet weak var currentValueLabel: UILabel!
	@IBOutlet weak var minValueLabel: UILabel!
	@IBOutlet weak var maxValueLabel: UILabel!
	@IBOutlet weak var deltaLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
