//
//  MutatorJumpIndexedLayout.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 10.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly

/**
Associated layout class for `MutatorJumpIndexed`.
*/
public class MutatorJumpIndexedLayout : MutatorLayout {
	
	// MARK: - Properties
	
	/// The model mutator
	private let MutatorJumpIndexed: MutatorJumpIndexed
	
	/// The number of else-if statements
	public var optionsCount: Int {
		get { return MutatorJumpIndexed.optionsCount }
		set { MutatorJumpIndexed.optionsCount = newValue }
	}
	
	/// Flag determining if there is an else statement
//	public var elseStatement: Bool {
//		get { return MutatorJumpIndexed.elseStatement }
//		set { MutatorJumpIndexed.elseStatement = newValue }
//	}
	
	/// Mutator helper used for transitioning between mutations
	private let mutatorHelper = MutatorHelper()
	
	// MARK: - Initializers
	
	public init(mutator: MutatorJumpIndexed, engine: LayoutEngine) {
		self.MutatorJumpIndexed = mutator
		super.init(mutator: mutator, engine: engine)
	}
	
	// MARK: - Super
	
	public override func performLayout(includeChildren: Bool) {
		// Inside a block, this mutator is the size of a settings button
		self.contentSize = WorkspaceSize(width: 32, height: 32)
//		super.contentSize = WorkspaceSize(width: 32, height: 32)
	}
	
	public override func performMutation() throws {
		guard let block = MutatorJumpIndexed.block,
			let layoutCoordinator = self.layoutCoordinator else
		{
			return
		}
		
		// Disconnect connections of existing mutation inputs prior to mutating the block
		let inputs = MutatorJumpIndexed.sortedMutatorInputs()
		try mutatorHelper.disconnectConnectionsInReverseOrder(
			fromInputs: inputs, layoutCoordinator: layoutCoordinator)
		
		// Remove any connected shadow blocks from these inputs
		try mutatorHelper.removeShadowBlocksInReverseOrder(
			fromInputs: inputs, layoutCoordinator: layoutCoordinator)
		
		// Update the definition of the block
		try MutatorJumpIndexed.mutateBlock()
		
		// Update UI
		let blockLayout = try layoutCoordinator.rebuildLayoutTree(forBlock: block)
		
		// Reconnect saved connections
		try mutatorHelper.reconnectSavedTargetConnections(
			toInputs: MutatorJumpIndexed.sortedMutatorInputs(), layoutCoordinator: layoutCoordinator)
		
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
		mutatorHelper.saveTargetConnections(fromInputs: MutatorJumpIndexed.sortedMutatorInputs())
	}
}
