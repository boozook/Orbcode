//
//  MutatorAnchorPointer.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 11.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly
import AEXML

/**
A mutator for dynamically adding "else-if" and "else" statements to an "if" block.
*/
@objc(OrbMutatorAnchorPointer)
public class MutatorAnchorPointer: NSObject {
	// MARK: - Properties
	
	/// The target block that will be mutated
	public weak var block: Block?
	
	/// The associated layout of the mutator
	public weak var layout: MutatorLayout?
	
	/// The name of the anchor
	public var anchorName = ""
	
	/// The actual name that's been applied to the anchor
	fileprivate var appliedAnchorName = ""
	
	
	/// The name of the anchor
	public var anchorDefinitionUUID = ""
	
	/// The actual name that's been applied to the anchor
	fileprivate var appliedAnchorDefinitionUUID = ""
}

extension MutatorAnchorPointer: Mutator {
	// MARK: - Mutator Implementation
	
	public func mutateBlock() throws {
		guard let block = self.block else {
			return
		}
		
		// Update name label
		if let field = block.firstField(withName: "NAME") as? FieldLabel {
			field.text = anchorName
		}
		
		// Update "with: " field
//		if let input = block.firstInput(withName: "TOPROW") {
//			let withField = block.firstField(withName: "WITH")
//			if parameters.isEmpty,
//				let field = withField
//			{
//				input.removeField(field)
//			} else if !parameters.isEmpty && withField == nil {
//				input.appendField(FieldLabel(name: "WITH", text: "with:"))
//			}
//		}
		
		// Update parameters
//		var i = 0
//		for parameter in parameters {
//			let inputName = "ARG\(i)"
//			if let input = block.firstInput(withName: inputName) {
//				// Update existing parameter
//				(input.fields[0] as? FieldLabel)?.text = parameter.name
//			} else {
//				// Create new input parameter
//				let parameterBuilder = InputBuilder(type: .value, name: inputName)
//				parameterBuilder.alignment = .right
//				parameterBuilder.appendField(FieldLabel(name: "ARGNAME\(i)", text: parameter.name))
//				block.appendInput(parameterBuilder.makeInput())
//			}
//			
//			i += 1
//		}
//		
//		// Delete extra parameters
//		while let input = block.firstInput(withName: "ARG\(i)") {
//			try block.removeInput(input)
//			i += 1
//		}
		
		appliedAnchorName = anchorName
		appliedAnchorDefinitionUUID = anchorDefinitionUUID;
//		appliedParameters = parameters
	}
	
	public func toXMLElement() -> AEXMLElement {
		let xml = AEXMLElement(name: "mutation", value: nil, attributes: [:])
		xml.attributes["name"] = appliedAnchorName
		xml.attributes["target"] = appliedAnchorDefinitionUUID;
		
//		for parameter in appliedParameters {
//			xml.addChild(name: "arg", value: nil, attributes: [
//				"name": parameter.name,
//				"id": parameter.uuid
//				])
//		}
		
		return xml
	}
	
	public func update(fromXML xml: AEXMLElement) {
		let mutationXML = xml["mutation"]
		
		anchorName = mutationXML.attributes["name"] ?? ""
		anchorDefinitionUUID = mutationXML.attributes["target"] ?? ""
		
//		parameters.removeAll()
//		for parameterXML in (mutationXML["arg"].all ?? []) {
//			if let parameter = parameterXML.attributes["name"] {
//				let uuid = parameterXML.attributes["id"]
//				parameters.append(ProcedureParameter(name: parameter, uuid: uuid))
//			}
//		}
	}
	
	public func copyMutator() -> Mutator {
		let mutator = MutatorAnchorPointer()
		mutator.anchorName = anchorName
		mutator.appliedAnchorName = appliedAnchorName
		mutator.anchorDefinitionUUID = anchorDefinitionUUID
		mutator.appliedAnchorDefinitionUUID = appliedAnchorDefinitionUUID
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
		
		// Add parameter inputs
		var i = 0
		while let input = block.firstInput(withName: "ARG\(i)") {
			inputs.append(input)
			i += 1
		}
		
		return inputs
	}
}
