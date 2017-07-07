//
//  MutatorSupablock.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 19.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly
import AEXML


//@objc(OrbMutatorSupablock)
public class MutatorSupablock: NSObject {
	// MARK: - Properties
	
	/// The target block that will be mutated
	public weak var block: Block?
	
	/// The associated layout of the mutator
	public weak var layout: MutatorLayout?
	
	public var error:String? = nil
//		{
//		didSet {
//			optionsCount = max(optionsCount, 1)
//		}
//	}
	
	
	/// The actual number of else-if statements that have been added to the block
	fileprivate var appliedError:String? = nil;
	
	/// Flag determining if the else statement has actually been added to the block
	// fileprivate var appliedElseStatement = false
}

extension MutatorSupablock: Mutator {
	// MARK: - Mutator Implementation
	
	public func mutateBlock() throws {
		guard let block = self.block else {
			return
		}
		
		if(error != appliedError)
		{
			
		}
		
		appliedError = error;
		
//		if optionsCount > appliedOptionsCount {
//			// let appliedElseCount = appliedElseStatement ? 1 : 0
//			
//			// Add extra else-if statements
//			for count in appliedOptionsCount ..< optionsCount {
//				let i = count + 1 // 1-based indexing
//				let ifBuilder = InputBuilder(type: .value, name: "ANCHOR\(i)")
//				//				ifBuilder.connectionTypeChecks = ["Number"]
//				ifBuilder.connectionTypeChecks = ["AnchorID"]
//				ifBuilder.appendField(FieldLabel(name: "label\(count)", text: "= \(count + 1) :"))
//				ifBuilder.alignment = .right;
//				
//				//				 let doBuilder = InputBuilder(type: .statement, name: "DO\(i)")
//				//				 doBuilder.appendField(FieldLabel(name: "DO", text: "do"))
//				
//				// Insert else-if statement before any applied else input (which would be at the very end)
//				// block.insertInput(ifBuilder.makeInput(), at: (block.inputs.count - appliedElseCount))
//				block.insertInput(ifBuilder.makeInput(), at: (block.inputs.count))
//				// block.insertInput(doBuilder.makeInput(), at: (block.inputs.count - appliedElseCount))
//			}
//		} else if optionsCount < appliedOptionsCount {
//			// Remove extra else-if statements
//			for count in optionsCount ..< appliedOptionsCount {
//				let i = count + 1 // 1-based indexing
//				if let ifInput = block.firstInput(withName: "ANCHOR\(i)")//,
//					// let doInput = block.firstInput(withName: "DO\(i)")
//				{
//					try block.removeInput(ifInput)
//					// try block.removeInput(doInput)
//				}
//			}
//		}
//		appliedOptionsCount = optionsCount
	}
	
	public func toXMLElement() -> AEXMLElement {
		return AEXMLElement(name: "mutation", value: nil);
	}
	
	public func update(fromXML xml: AEXMLElement) {
	}
	
	public func copyMutator() -> Mutator {
		let mutator = MutatorSupablock()
		mutator.error = error
		mutator.appliedError = appliedError
		return mutator
	}
	
	/**
	Returns a list of inputs that have been created by this mutator on `self.block`, sorted in
	ascending order of their index within `self.block.inputs`.
	*/
	public func sortedMutatorInputs() -> [Input] {
		return [];
	}
}
