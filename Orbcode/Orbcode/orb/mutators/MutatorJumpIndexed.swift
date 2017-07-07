//
//  MutatorJumpIndexed.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 10.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly
import AEXML

/**
A mutator for dynamically adding "else-if" and "else" statements to an "if" block.
*/
@objc(OrbJumpIndexedMutator)
public class MutatorJumpIndexed: NSObject {
	// MARK: - Properties

	/// The target block that will be mutated
	public weak var block: Block?

	/// The associated layout of the mutator
	public weak var layout: MutatorLayout?

	/// The number of else-if statements that should be added to the block
	public var optionsCount = 1 {
		didSet {
			optionsCount = max(optionsCount, 1)
		}
	}

	/// Flag determining if an else statement should be added to the block
	// public var elseStatement = false

	/// The actual number of else-if statements that have been added to the block
	fileprivate var appliedOptionsCount = 1

	/// Flag determining if the else statement has actually been added to the block
	// fileprivate var appliedElseStatement = false
}

extension MutatorJumpIndexed: Mutator {
	// MARK: - Mutator Implementation

	public func mutateBlock() throws {
		guard let block = self.block else {
			return
		}
		
		if optionsCount > appliedOptionsCount {
			// let appliedElseCount = appliedElseStatement ? 1 : 0

			// Add extra else-if statements
			for count in appliedOptionsCount ..< optionsCount {
				let i = count + 1 // 1-based indexing
				let ifBuilder = InputBuilder(type: .value, name: "ANCHOR\(i)")
//				ifBuilder.connectionTypeChecks = ["Number"]
				ifBuilder.connectionTypeChecks = ["AnchorID"]
				ifBuilder.appendField(FieldLabel(name: "label\(count)", text: "= \(count + 1) :"))
				ifBuilder.alignment = .right;
				
//				 let doBuilder = InputBuilder(type: .statement, name: "DO\(i)")
//				 doBuilder.appendField(FieldLabel(name: "DO", text: "do"))

				// Insert else-if statement before any applied else input (which would be at the very end)
				// block.insertInput(ifBuilder.makeInput(), at: (block.inputs.count - appliedElseCount))
				block.insertInput(ifBuilder.makeInput(), at: (block.inputs.count))
				// block.insertInput(doBuilder.makeInput(), at: (block.inputs.count - appliedElseCount))
			}
		} else if optionsCount < appliedOptionsCount {
			// Remove extra else-if statements
			for count in optionsCount ..< appliedOptionsCount {
				let i = count + 1 // 1-based indexing
				if let ifInput = block.firstInput(withName: "ANCHOR\(i)")//,
					// let doInput = block.firstInput(withName: "DO\(i)")
				{
					try block.removeInput(ifInput)
					// try block.removeInput(doInput)
				}
			}
		}
		appliedOptionsCount = optionsCount
	}

	public func toXMLElement() -> AEXMLElement {
		return AEXMLElement(name: "mutation", value: nil, attributes: [ "anchors": String(optionsCount) ])
	}

	public func update(fromXML xml: AEXMLElement) {
		let mutationXML = xml["mutation"]
		optionsCount = Int(mutationXML.attributes["anchors"] ?? "") ?? 0
	}

	public func copyMutator() -> Mutator {
		let mutator = MutatorJumpIndexed()
		mutator.optionsCount = optionsCount
		mutator.appliedOptionsCount = appliedOptionsCount
		return mutator
	}

	/**
	Returns a list of inputs that have been created by this mutator on `self.block`, sorted in
	ascending order of their index within `self.block.inputs`.
	*/
	public func sortedMutatorInputs() -> [Input] {
		guard let block = self.block else {
			return []
		}

		var inputs = [Input]()

		for count in 0 ..< appliedOptionsCount {
			let i = count + 1 // 1-based indexing
			if let ifInput = block.firstInput(withName: "ANCHOR\(i)")//,
				// let doInput = block.firstInput(withName: "DO\(i)")
			{
				inputs.append(ifInput)
				// inputs.append(doInput)
			}
		}

		// if let input = block.firstInput(withName: "ELSE"), appliedElseStatement {
		// 	inputs.append(input)
		// }

		return inputs
	}
}
