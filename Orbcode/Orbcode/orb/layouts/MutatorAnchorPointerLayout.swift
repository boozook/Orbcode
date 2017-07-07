//
//  MutatorAnchorPointerLayout.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 10.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//


import Foundation
import Blockly
import AEXML

/**
Associated layout class for `MutatorAnchorPointer`.
*/
public class MutatorAnchorPointerLayout : MutatorLayout {
	
	// MARK: - Properties
	
	/// The model mutator
	private let mutatorAnchorPointer: MutatorAnchorPointer
	
	/// The name of the anchor
	public var anchorName: String {
		get { return mutatorAnchorPointer.anchorName }
		set { mutatorAnchorPointer.anchorName = newValue }
	}
	
	/// Mutator helper used for transitioning between mutations
	private let mutatorHelper = MutatorHelper()
	
	/// Table that maps parameter UUIDs to a target connection. This is used for reconnecting inputs
	/// to previously connected connections.
	private var savedTargetConnections: NSMapTable<NSString, Connection> =
		NSMapTable.strongToWeakObjects()
	
	// MARK: - Initializers
	
	public init(mutator: MutatorAnchorPointer, engine: LayoutEngine) {
		self.mutatorAnchorPointer = mutator
		super.init(mutator: mutator, engine: engine)
	}
	
	// MARK: - Super
	
	public override func performLayout(includeChildren: Bool) {
		// A anchor caller is not user-configurable, so set its size to zero
		self.contentSize = .zero
	}
	
	public override func performMutation() throws {
		guard let block = mutatorAnchorPointer.block,
			let layoutCoordinator = self.layoutCoordinator else
		{
			return
		}
		
		// Disconnect connections of existing mutation inputs prior to mutating the block
		let inputs = mutatorAnchorPointer.sortedMutatorInputs()
		try mutatorHelper.disconnectConnectionsInReverseOrder(
			fromInputs: inputs, layoutCoordinator: layoutCoordinator)
		
		// Remove any connected shadow blocks from these inputs
		try mutatorHelper.removeShadowBlocksInReverseOrder(
			fromInputs: inputs, layoutCoordinator: layoutCoordinator)
		
		// Update the definition of the block
		try captureChangeEvent {
			try mutatorAnchorPointer.mutateBlock()
			
			// Update UI
			try layoutCoordinator.rebuildLayoutTree(forBlock: block)
		}
		
		// Reconnect saved connections
		try reconnectSavedTargetConnections()
	}
	
	public override func performMutation(fromXML xml: AEXMLElement) throws {
		// Since this call is most likely being triggered from an event, clear all saved target
		// connections, before updating via XML
		savedTargetConnections.removeAllObjects()
		try super.performMutation(fromXML: xml)
	}
	
	// MARK: - Pre-Mutation
	
	/**
	For all inputs created by this mutator, save the currently connected target connection
	for each of them. Any subsequent call to `performMutation()` will ensure that these saved target
	connections remain connected to that original input, as long as the input still exists
	post-mutation.
	*/
	public func preserveCurrentInputConnections() {
//		let inputs = mutatorAnchorPointer.sortedMutatorInputs()
//		savedTargetConnections.removeAllObjects()
		
//		for (i, input) in inputs.enumerated() {
//			if let targetConnection = input.connection?.targetConnection,
//				i < parameters.count
//			{
//				savedTargetConnections.setObject(targetConnection, forKey: parameters[i].uuid as NSString)
//			}
//		}
	}
	
	// MARK: - Post-Mutation
	
	private func reconnectSavedTargetConnections() throws {
		guard let layoutCoordinator = self.layoutCoordinator else {
			return
		}
		
//		let inputs = mutatorAnchorPointer.sortedMutatorInputs()
		
		// Reconnect inputs
//		for (i, parameter) in parameters.enumerated() {
//			let key = parameter.uuid as NSString
//			
//			if i < inputs.count,
//				let inputConnection = inputs[i].connection,
//				let targetConnection = savedTargetConnections.object(forKey: key)
//			{
//				try layoutCoordinator.connect(inputConnection, targetConnection)
//			}
//		}
	}
}
