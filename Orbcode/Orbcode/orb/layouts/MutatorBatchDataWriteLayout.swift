//
//  MutatorBatchDataWriteLayout.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 17.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly

/**
Associated layout class for `MutatorBatchDataWrite`.
*/
public class MutatorBatchDataWriteLayout : MutatorLayout {
	
	// MARK: - Properties
	
	/// The model mutator
	private let MutatorBatchDataWrite: MutatorBatchDataWrite
	
	/// The number of else-if statements
	public var elseIfCount: Int {
		get { return MutatorBatchDataWrite.elseIfCount }
		set { MutatorBatchDataWrite.elseIfCount = newValue }
	}
	
	/// Flag determining if there is an else statement
	//	public var elseStatement: Bool {
	//		get { return MutatorBatchDataWrite.elseStatement }
	//		set { MutatorBatchDataWrite.elseStatement = newValue }
	//	}
	
	/// Mutator helper used for transitioning between mutations
	private let mutatorHelper = MutatorHelper()
	
	// MARK: - Initializers
	
	public init(mutator: MutatorBatchDataWrite, engine: LayoutEngine) {
		self.MutatorBatchDataWrite = mutator
		super.init(mutator: mutator, engine: engine)
	}
	
	// MARK: - Super
	
	public override func performLayout(includeChildren: Bool) {
		// Inside a block, this mutator is the size of a settings button
		self.contentSize = WorkspaceSize(width: 32, height: 32)
		//		super.contentSize = WorkspaceSize(width: 32, height: 32)
	}
	
	public override func performMutation() throws {
		guard let block = MutatorBatchDataWrite.block,
			let layoutCoordinator = self.layoutCoordinator else
		{
			return
		}
		
		// Disconnect connections of existing mutation inputs prior to mutating the block
		let inputs = MutatorBatchDataWrite.sortedMutatorInputs()
		try mutatorHelper.disconnectConnectionsInReverseOrder(
			fromInputs: inputs, layoutCoordinator: layoutCoordinator)
		
		// Remove any connected shadow blocks from these inputs
		try mutatorHelper.removeShadowBlocksInReverseOrder(
			fromInputs: inputs, layoutCoordinator: layoutCoordinator)
		
		// Update the definition of the block
		try MutatorBatchDataWrite.mutateBlock()
		
		// Update UI
		let blockLayout = try layoutCoordinator.rebuildLayoutTree(forBlock: block)
		
		// Reconnect saved connections
		try mutatorHelper.reconnectSavedTargetConnections(
			toInputs: MutatorBatchDataWrite.sortedMutatorInputs(), layoutCoordinator: layoutCoordinator)
		
		//		Layout.animate {
		//			layoutCoordinator.blockBumper.bumpNeighbors(ofBlockLayout: blockLayout, alwaysBumpOthers: true)
		//		}
	}
	
	// MARK: - Pre-Mutation
	
	/**
	For all inputs created by this mutator, save the currently connected target connection for
	each of them. Any subsequent call to `performMutation()` will ensure that these saved target
	connections remain connected to that original input, as long as the input still exists
	post-mutation.
	*/
	public func preserveCurrentInputConnections() {
		mutatorHelper.clearSavedTargetConnections()
		mutatorHelper.saveTargetConnections(fromInputs: MutatorBatchDataWrite.sortedMutatorInputs())
	}
}
