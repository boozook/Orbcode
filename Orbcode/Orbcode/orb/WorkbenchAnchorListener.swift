//
//  WorkbenchAnchorListener.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 11.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly


public class WorkbenchAnchorListener: NSObject
{
	// MARK: - Properties
	
	public static let BLOCK_ORB_ANCHOR = ORB_ANCHOR
	public static let BLOCK_ORB_ANCHOR_ID = ORB_ANCHOR_ID
	
//	public weak var workbench: WorkbenchViewController?
	/// The workbench that this coordinator is synchronized with
	public private(set) weak var workbench: WorkbenchViewController? {
		didSet {
			oldValue?.variableNameManager.listeners.remove(self)
			oldValue?.workspace?.listeners.remove(self)
			
			workbench?.workspace?.listeners.add(self)
			workbench?.variableNameManager.listeners.add(self)
		}
	}
	
	/// Manager responsible for keeping track of all anchor names under the workbench
	fileprivate let anchorNameManager = NameManager()
	
	/// Manager responsible for keeping track of all variables under the workbench
	fileprivate var variableNameManager: NameManager? {
		return workbench?.variableNameManager
	}
	
	/// Set of all anchor definition blocks in the main workspace.
	fileprivate var definitionBlocks = WeakSet<Block>()
	
	/// Set of all anchor caller blocks in both the main workspace and toolbox.
	fileprivate var callerBlocks = WeakSet<Block>()
	
	/// Map of block uuid's to their anchor definition name. This is used when a anchor
	/// definition block is renamed and the coordinator needs to rename all existing caller blocks
	/// that used the old anchor name (which is being kept track of here).
	fileprivate var blockAnchorNames = [String: String]()
	
	
	// MARK: - Initializers
	
	public init(workbench: WorkbenchViewController)
	{
		super.init();
		self.workbench = workbench;
		EventManager.sharedInstance.addListener(self)
	}
	
	deinit
	{
		// Unregister all notifications
		NotificationCenter.default.removeObserver(self)
		EventManager.sharedInstance.removeListener(self)
	}
	
//	public override init() {
//		super.init()
//		EventManager.sharedInstance.addListener(self)
//	}
//	
//	deinit {
//		EventManager.sharedInstance.removeListener(self)
//	}
	
	
	
	
	
	// MARK: - Workbench
	
	/**
	Synchronizes this coordinator with a workbench so that all anchor definition/caller blocks
	in the main workspace are in a proper state.
	
	Here are some examples of what can be defined as a "proper" state:
	- Each anchor definition block in the workspace is unique.
	- All anchor definition blocks defined in the workspace must have an associated caller block
	in the toolbox.
	- No anchor caller block exists in the workspace without an associated definition block.
	- All parameters used in anchor definition blocks are created as variables inside
	`workbench.variableNameManager`.
	
	- parameter workbench: The `WorkbenchViewController` to synchronize with. This value is then
	set to `self.workbench` after this method is called.
	- note: `workbench` must have its toolbox and workspace loaded, or else this method does nothing
	but assign `workbench` to `self.workbench`.
	*/
	public func syncWithWorkbench(_ workbench: WorkbenchViewController?)
	{
		
//		print("SYNC !!!");
		// Remove cache of definition and caller blocks
		definitionBlocks.removeAll()
		callerBlocks.removeAll()
		blockAnchorNames.removeAll()
		
		// Set to the new workbench
		self.workbench = workbench
		
		if let workspace = workbench?.workspace,
			workbench?.toolbox != nil
		{
			// Track all definition/caller blocks in the workspace
			for (_, block) in workspace.allBlocks {
				if block.isAnchorDefinition {
					trackAnchorDefinitionBlock(block)
				} else if block.isAnchorPointer {
					trackAnchorCallerBlock(block, autoCreateDefinition: false)
				}
			}
			
			// For every caller block, update its parameters to match its corresponding definition block's
			// parameters or auto-create a definition block if none exists
			for callerBlock in callerBlocks {
				if let definitionBlock = anchorDefinitionBlock(forCallerBlock: callerBlock) {
//					callerBlock.anchorParameters = definitionBlock.anchorParameters
				} else {
					createAnchorDefinitionBlock(fromCallerBlock: callerBlock)
				}
			}
		}
	}
	
	// MARK: - Anchor Definition Methods
	
	fileprivate func trackAnchorDefinitionBlock(_ definitionBlock: Block) {
		guard definitionBlock.isAnchorDefinition else {
			return
		}
		
		// Add to set of definition blocks
		definitionBlocks.add(definitionBlock)
		
		// Assign a unique anchor name to the block and add it to the list of known anchor names
		let uniqueAnchorName =
			anchorNameManager.generateUniqueName(definitionBlock.anchorName, addToList: true)
		
		if(uniqueAnchorName != definitionBlock.anchorName) {
			print("RENAME:", definitionBlock.anchorName, uniqueAnchorName);
		}
		
		definitionBlock.anchorName = uniqueAnchorName
		
		// Track block's current anchor name
		blockAnchorNames[definitionBlock.uuid] = uniqueAnchorName
		
		// Upsert variables from block to NameManager
		upsertVariables(fromDefinitionBlock: definitionBlock)
		
		// Create an associated caller anchor to the toolbox
		do {
			if let toolboxAnchorLayoutCoordinator = firstToolboxAnchorLayoutCoordinator(),
				let blockFactory = toolboxAnchorLayoutCoordinator.blockFactory
			{
				print("CREATE callerBlock:", definitionBlock.anchorName, definitionBlock.uuid);
				let callerBlock =
					try blockFactory.makeBlock(name: definitionBlock.associatedAnchorPointerBlockName)
				callerBlock.anchorName = definitionBlock.anchorName
				callerBlock.anchorTargetUUID = definitionBlock.uuid;
//				callerBlock.anchorParameters = definitionBlock.anchorParameters
				try toolboxAnchorLayoutCoordinator.addBlockTree(callerBlock)
				
				// Track this new block as a caller block so it can be updated if the definition changes
				callerBlocks.add(callerBlock)
			}
		} catch let error {
			print("Could not add block to toolbox: \(error)")
		}
	}
	
	fileprivate func untrackAnchorDefinitionBlock(_ definitionBlock: Block) {
		guard definitionBlock.isAnchorDefinition else {
			return
		}
		
		// Remove all caller blocks that use this definition block
		removeAnchorCallerBlocks(forDefinitionBlock: definitionBlock)
		
		// Remove from set of definition blocks
		definitionBlocks.remove(definitionBlock)
		
		// Remove block anchor mapping
		blockAnchorNames[definitionBlock.uuid] = nil
		
		// Remove anchor name from manager
		anchorNameManager.removeName(definitionBlock.anchorName)
	}
	
	fileprivate func upsertVariables(fromDefinitionBlock block: Block) {
//		guard block.isAnchorDefinition,
//			let variableNameManager = self.variableNameManager else {
//				return
//		}
		
//		for parameter in block.anchorParameters {
//			if !variableNameManager.containsName(parameter.name) {
//				// Add name to variable manager
//				do {
//					try variableNameManager.addName(parameter.name)
//				} catch let error {
//					print("Could not add parameter '\(parameter)' as variable: \(error)")
//				}
//			} else {
//				// Update the display name of the parameter
//				variableNameManager.renameDisplayName(parameter.name)
//			}
//		}
	}
	
	fileprivate func createAnchorDefinitionBlock(fromCallerBlock callerBlock: Block) {
		guard let blockFactory = firstToolboxAnchorLayoutCoordinator()?.blockFactory else {
			return
		}
		
		return;
		
		do {
			let definitionBlock = try blockFactory.makeBlock(name: callerBlock.associatedAnchorDefinitionBlockName)
			
			print("CREATE definitionBlock:", callerBlock.anchorName, definitionBlock.uuid);
			
			// For now, set the definition block's anchor name to match the caller block's name.
			// If it's a duplicate of something else already in the workspace, it will automatically
			// get renamed when `trackAnchorDefinitionBlock(...)` is ultimately called.
			definitionBlock.anchorName = callerBlock.anchorName
//			definitionBlock.anchorParameters = callerBlock.anchorParameters
			definitionBlock.position = callerBlock.position + WorkspacePoint(x: 20, y: 20)
			
			try workbench?.workspaceViewController.workspaceLayoutCoordinator?.addBlockTree(
				definitionBlock)
			
			// After the definition block has been added to the workspace, it should have a unique
			// name now. Rename the caller's anchor name to match it.
			callerBlock.anchorName = definitionBlock.anchorName
			callerBlock.anchorTargetUUID = definitionBlock.uuid;
		} catch let error {
			print("Could not create definition block for caller: \(error)")
		}
	}
	
	fileprivate func renameAnchorDefinitionBlock(_ block: Block, from oldName: String, to newName: String)
	{
		guard block.isAnchorDefinition else {
			return
		}
		
		// Remove old anchor name
		anchorNameManager.removeName(oldName)
		
		// Make sure the new name is unique and add it to the list of anchor names
		let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
		let uniqueName = anchorNameManager.generateUniqueName(trimmedName, addToList: true)
		
		// Assign this unique name back to the block
		blockAnchorNames[block.uuid] = uniqueName
		block.anchorName = uniqueName
		
		// Rename all caller blocks in workspace/toolbox
//		updateAnchorCallers(oldName: oldName, newName: uniqueName, parameters: block.anchorParameters)
		updateAnchorPoints(oldName: oldName, newName: uniqueName, uuid: block.uuid);
	}
	
	fileprivate func anchorDefinitionBlock(forCallerBlock callerBlock: Block) -> Block? {
		return definitionBlocks.first(where: {
			($0.associatedAnchorPointerBlockName == callerBlock.name && anchorNameManager.namesAreEqual(callerBlock.anchorName, $0.anchorName))
			|| ($0.uuid == callerBlock.anchorTargetUUID)
//				&& callerBlock.anchorParameters.map({ $0.name }) == $0.anchorParameters.map({ $0.name })
		})
	}
	
	// MARK: - Anchor Pointer Methods
	
	fileprivate func trackAnchorCallerBlock(_ callerBlock: Block, autoCreateDefinition: Bool) {
		guard callerBlock.isAnchorPointer else {
			return
		}
		
		// Add to set of caller blocks
		callerBlocks.add(callerBlock)
		
		if let definitionBlock = anchorDefinitionBlock(forCallerBlock: callerBlock) {
			// Make sure the anchor pointer block has the exact same parameters as the definition block,
			// so its parameters' connections are properly preserved on parameter renames/re-orderings
//			callerBlock.anchorParameters = definitionBlock.anchorParameters
		} else if autoCreateDefinition {
			// Create definition block
			createAnchorDefinitionBlock(fromCallerBlock: callerBlock)
		}
	}
	
	fileprivate func untrackAnchorCallerBlock(_ callerBlock: Block) {
		guard callerBlock.isAnchorPointer else {
			return
		}
		
		callerBlocks.remove(callerBlock)
	}
	
	fileprivate func removeAnchorCallerBlocks(forDefinitionBlock definitionBlock: Block) {
		guard definitionBlock.isAnchorDefinition else {
			return
		}
		
		do {
			for callerBlock in callerBlocks {
				if anchorNameManager.namesAreEqual(
					callerBlock.anchorName, definitionBlock.anchorName)
				{
					if let toolboxCoordinator = firstToolboxAnchorLayoutCoordinator(),
						toolboxCoordinator.workspaceLayout.workspace.containsBlock(callerBlock)
					{
						// Remove from toolbox
						try toolboxCoordinator.removeBlockTree(callerBlock)
					} else if let workspaceCoordinator =
						workbench?.workspaceViewController?.workspaceLayoutCoordinator,
						workspaceCoordinator.workspaceLayout.workspace.containsBlock(callerBlock)
					{
						// Remove from main workspace
						try workspaceCoordinator.removeBlockTree(callerBlock)
					}
				}
			}
		} catch let error {
			print("Could not remove caller blocks from toolbox/workspace: \(error)")
		}
	}
	
//	fileprivate func updateAnchorCallers(oldName: String, newName: String, parameters: [AnchorParameter])
//	fileprivate func updateAnchorPoints(oldName: String, newName: String)
	fileprivate func updateAnchorPoints(oldName: String, newName: String, uuid: String)
	{
		for callerBlock in callerBlocks {
			if anchorNameManager.namesAreEqual(callerBlock.anchorName, oldName),
				let mutatorCallerLayout = callerBlock.layout?.mutatorLayout as? MutatorAnchorPointerLayout
			{
				// NOTE: mutatorLayout is used here since it will preserve connections for existing inputs
				// if the parameters have been reordered.
				mutatorCallerLayout.preserveCurrentInputConnections()
				mutatorCallerLayout.anchorName = newName
				callerBlock.anchorTargetUUID = uuid;
				
				do {
					try mutatorCallerLayout.performMutation()
					
					if let blockLayout = mutatorCallerLayout.mutator.block?.layout {
						Layout.animate {
							mutatorCallerLayout.layoutCoordinator?.blockBumper
								.bumpNeighbors(ofBlockLayout: blockLayout, alwaysBumpOthers: true)
						}
					}
				} catch let error {
					print("Could not update anchor pointer to match anchor definition: \(error)")
				}
			}
		}
	}
	
	// MARK: - Helpers
	
	fileprivate func firstToolboxAnchorLayoutCoordinator() -> WorkspaceLayoutCoordinator? {
		if let toolboxLayout = workbench?.toolboxCategoryViewController.toolboxLayout {
			for (i, category) in toolboxLayout.toolbox.categories.enumerated() {
//				if category.categoryType == .anchor {
				if category.categoryType == .generic && category.name == "Flow" {
					return toolboxLayout.categoryLayoutCoordinators[i]
				}
			}
		}
		
		return nil
	}
}


// MARK: - EventManagerListener Implementation

extension WorkbenchAnchorListener: EventManagerListener {
	
	public func eventManager(_ eventManager: EventManager, didFireEvent event: BlocklyEvent) {
		// Try to handle the event. The first method that returns `true` means it's been handled and
		// we can skip the rest of the checks.
		if let fieldEvent = event as? ChangeEvent,
			fieldEvent.element == .field {
			processFieldChangeEvent(fieldEvent)
		} else if let mutationEvent = event as? ChangeEvent,
			mutationEvent.element == .mutate {
			processMutationChangeEvent(mutationEvent)
		}
	}
	
	private func processFieldChangeEvent(_ fieldEvent: ChangeEvent) {
		guard fieldEvent.element == .field,
			fieldEvent.fieldName == "NAME",
			fieldEvent.workspaceID == workbench?.workspace?.uuid,
			let blockID = fieldEvent.blockID,
			let block = workbench?.workspace?.allBlocks[blockID],
			block.isAnchorDefinition,
			let oldAnchorName = blockAnchorNames[block.uuid],
			let newAnchorName = block.anchorDefinitionNameInput?.text,
			!anchorNameManager.namesAreEqual(oldAnchorName, newAnchorName) else {
				return
		}
		
		// Add additional events to the existing event group
		EventManager.sharedInstance.groupAndFireEvents(groupID: fieldEvent.groupID) {
			if newAnchorName.trimmingCharacters(in: .whitespaces).isEmpty {
				// anchor names shouldn't be empty. Put it back to what it was
				// originally.
				// Note: The field layout is used to reset the anchor name here so that a `ChangeEvent`
				// is automatically created for this change.
				try? block.anchorDefinitionNameInput?.layout?.setValue(
					fromSerializedText: oldAnchorName)
			} else {
				// anchor name has changed for definition block. Rename it.
				renameAnchorDefinitionBlock(block, from: oldAnchorName, to: newAnchorName)
			}
		}
	}
	
	private func processMutationChangeEvent(_ mutationEvent: ChangeEvent) {
		guard mutationEvent.element == .mutate,
			mutationEvent.workspaceID == workbench?.workspace?.uuid,
			let blockID = mutationEvent.blockID,
			let block = workbench?.workspace?.allBlocks[blockID],
			block.isAnchorDefinition else {
				return
		}
		
		// Add additional events to the existing event group
		EventManager.sharedInstance.groupAndFireEvents(groupID: mutationEvent.groupID) {
			// A anchor definition block inside the main workspace has been mutated.
			// Update the anchor pointers and upsert the variables from this block.
//			updateAnchorCallers(oldName: block.anchorName, newName: block.anchorName, parameters: block.anchorParameters)
			updateAnchorPoints(oldName: block.anchorName, newName: block.anchorName, uuid: block.uuid);
			upsertVariables(fromDefinitionBlock: block)
		}
	}
	
	
//	weak var anchors: [Block];
	
//	public func eventManager(_ eventManager: EventManager, didFireEvent event: BlocklyEvent) {
//		guard event.workspaceID == workbench?.workspace?.uuid && event.type != MoveEvent.EVENT_TYPE else {
//			return
//		}
//		
//		print("UPDATE: ", event);
	
		
		
//		if(event.type == CreateEvent.EVENT_TYPE)
//		{
//			let block = workbench?.workspace?.allBlocks[event.blockID!];
//			if(block?.name == ORB_ANCHOR)
//			{
//				print("listen this block: ", block?.name as Any);
//				listenAnchor(anchor: block!);
//			}
//			if(block?.name == ORB_ANCHOR_ID)
//			{
//				print("listen this block: ", block?.name as Any);
//				listenAnchorPointer(anchor: block!);
//			}
//			
//		} else if(event.type == DeleteEvent.EVENT_TYPE)
//		{
//			let block = workbench?.workspace?.allBlocks[event.blockID!];
//			if(block?.name == ORB_ANCHOR) {
//				print("UNlisten this block: ", block?.name as Any);
//				unlistenAnchor(anchor: block!);
//			}
//			if(block?.name == ORB_ANCHOR_ID)
//			{
//				print("UNlisten this block: ", block?.name as Any);
//				unlistenAnchorPointer(anchor: block!);
//			}
//		} else if(event.type == ChangeEvent.EVENT_TYPE)
//		{
//			if let fieldEvent = event as? ChangeEvent, fieldEvent.element == .field
//			{
//				let block = workbench?.workspace?.allBlocks[event.blockID!];
//				print("CHANGED block: ", block?.name as Any);
//				
//				if(block?.name == ORB_ANCHOR)
//				{
//					updateAnchorPointers(only_id: (block?.uuid)!);
//				}
//				
//			} else if let mutationEvent = event as? ChangeEvent, mutationEvent.element == .mutate {
//				let block = workbench?.workspace?.allBlocks[event.blockID!];
//				print("MUTATED block: ", block?.name as Any);
//				
//				if(block?.name == ORB_ANCHOR)
//				{
//					updateAnchorPointers(only_id: (block?.uuid)!);
//				}
//			}
//			
//		}
//	}
}


extension WorkbenchAnchorListener: WorkspaceListener {
	// MARK: - WorkspaceListener Implementation
	
	public func workspace(_ workspace: Workspace, willAddBlock block: Block) {
		if block.isAnchorPointer && anchorDefinitionBlock(forCallerBlock: block) == nil {
			// No anchor block exists for this caller in the workspace.
			// Automatically create it first before adding in the caller block to the workspace. This
			// makes sure that events are ordered in such a way that they can be properly undone.
			createAnchorDefinitionBlock(fromCallerBlock: block)
		}
	}
	
	public func workspace(_ workspace: Workspace, didAddBlock block: Block) {
		if block.isAnchorDefinition {
			trackAnchorDefinitionBlock(block)
		} else if block.isAnchorPointer {
// TODO: FIXME: (possible err `false/true`)			trackAnchorCallerBlock(block, autoCreateDefinition: true)
			trackAnchorCallerBlock(block, autoCreateDefinition: false);
		}
	}
	
	public func workspace(_ workspace: Workspace, willRemoveBlock block: Block) {
		if block.isAnchorDefinition {
			// Remove all caller blocks for the definition before removing the definition block. If
			// the caller blocks are removed after the definition block, then it causes problems undoing
			// the event stack where a caller block is recreated without any definition block. Reversing
			// the order fixes this problem.
			removeAnchorCallerBlocks(forDefinitionBlock: block)
		}
	}
	
	public func workspace(_ workspace: Workspace, didRemoveBlock block: Block) {
		if block.isAnchorDefinition {
			untrackAnchorDefinitionBlock(block)
		} else if block.isAnchorPointer {
			untrackAnchorCallerBlock(block)
		}
	}
}

extension WorkbenchAnchorListener: NameManagerListener
{
	// MARK: - NameManagerListener Implementation
	
	public func nameManager(_ nameManager: NameManager, shouldRemoveName name: String) -> Bool {
//		if nameManager == workbench?.variableNameManager {
//			// If any of the anchors use the variables, disable this action
//			for block in definitionBlocks {
//				for parameter in block.anchorParameters {
//					if nameManager.namesAreEqual(name, parameter.name) {
//						// Found a parameter using this name
//						let message = "Can't delete the variable \"\(name)\" because it's part of the " +
//						"function definition \"\(block.anchorName)\""
//						
//						let alert = UIAlertView(title: "Error", message: message, delegate: nil,
//						                        cancelButtonTitle: nil, otherButtonTitles: "OK")
//						alert.show()
//						return false
//					}
//				}
//			}
//		}
		return true
	}
	
	public func nameManager(
		_ nameManager: NameManager, didRenameName oldName: String, toName newName: String)
	{
//		if nameManager == workbench?.variableNameManager {
			// Update all anchor definitions that use this variable
//			for block in definitionBlocks {
//				// NOTE: mutatorLayout is used here since it will generate a notification after
//				// the mutation has been performed. When this notification fires, `WorkbenchAnchorListener`
//				// listens to it and updates any associated caller blocks in the workspace to match
//				// the new definition.
//				if let mutatorLayout = block.layout?.mutatorLayout as? MutatorAnchorDefinitionLayout {
//					var updateMutator = false
//					for (i, parameter) in mutatorLayout.parameters.enumerated() {
//						if nameManager.namesAreEqual(oldName, parameter.name) {
//							mutatorLayout.parameters[i].name = newName
//							updateMutator = true
//						}
//					}
					
//					if updateMutator {
//						do {
//							try mutatorLayout.performMutation()
//							
//							if let blockLayout = mutatorLayout.mutator.block?.layout {
//								Layout.animate {
//									mutatorLayout.layoutCoordinator?.blockBumper
//										.bumpNeighbors(ofBlockLayout: blockLayout, alwaysBumpOthers: true)
//								}
//							}
//						} catch let error {
//							print("Could not update mutator parameter variables: \(error)")
//						}
//					}
//				}
//			}
//		}
	}
}





// MARK: - Coordinator Implementation

extension WorkbenchAnchorListener: Coordinator
{
	
	/// Block name for the anchor definition
//	public static let BLOCK_DEFINITION_NO_RETURN = "orb_anchor"
	/// Block name for the anchor caller(id-accessor)
//	public static let BLOCK_CALLER_NO_RETURN = "orb_anchor_id"
	
	
//	public func syncWithWorkbench(_ workbench: WorkbenchViewController?) {
//		print("SYNC !!!");
	
//		workbench?.workspace?.allBlocks.forEach({ (pair:(uuid: String, block: Block)) in
//			if(pair.block.name == ORB_ANCHOR) {
//				listenAnchor(anchor: pair.block);
//			}
//			if(pair.block.name == ORB_ANCHOR_ID) {
//				listenAnchorPointer(anchor: pair.block);
//			}
//		})
		
//		updateAnchorPointers();
//	}
}





// MARK: - Block Extension Methods

fileprivate extension Block {
	var isAnchorDefinition: Bool {
		return name == WorkbenchAnchorListener.BLOCK_ORB_ANCHOR;
	}
	
	var isAnchorPointer: Bool {
		return name == WorkbenchAnchorListener.BLOCK_ORB_ANCHOR_ID;
	}
	
	var anchorDefinitionNameInput: FieldInput? {
		return isAnchorDefinition ? firstField(withName: "NAME") as? FieldInput : nil
	}
	
//	var mutatorAnchorDefinition: MutatorAnchorDefinition? {
//		return mutator as? MutatorAnchorDefinition
//	}
	
	var mutatorAnchorPointer: MutatorAnchorPointer? {
		return mutator as? MutatorAnchorPointer
	}
	
	var anchorName: String {
		get {
			if isAnchorDefinition {
				return anchorDefinitionNameInput?.text ?? ""
			} else if isAnchorPointer {
				return mutatorAnchorPointer?.anchorName ?? ""
			} else {
				return ""
			}
		}
		set {
			if isAnchorDefinition {
				anchorDefinitionNameInput?.text = newValue
			} else if isAnchorPointer {
				mutatorAnchorPointer?.anchorName = newValue
				try? mutatorAnchorPointer?.mutateBlock()
			}
		}
	}
	
	var anchorTargetUUID: String {
		get {
			if isAnchorPointer {
				return mutatorAnchorPointer?.anchorDefinitionUUID ?? "";
			} else {
				return ""
			}
		}
		set {
			if isAnchorPointer {
				mutatorAnchorPointer?.anchorDefinitionUUID = newValue
				try? mutatorAnchorPointer?.mutateBlock()
			}
		}
	}
	
//	var anchorParameters: [AnchorParameter] {
//		get {
//			return mutatorAnchorPointer?.parameters ?? mutatorAnchorDefinition?.parameters ?? []
//		}
//		set {
//			if isAnchorDefinition {
//				mutatorAnchorDefinition?.parameters = newValue
//				try? mutatorAnchorDefinition?.mutateBlock()
//			} else if isAnchorPointer {
//				mutatorAnchorPointer?.parameters = newValue
//				try? mutatorAnchorPointer?.mutateBlock()
//			}
//		}
//	}
	
	var associatedAnchorPointerBlockName: String {
		switch name {
		case WorkbenchAnchorListener.BLOCK_ORB_ANCHOR:
			return WorkbenchAnchorListener.BLOCK_ORB_ANCHOR_ID
//		case WorkbenchAnchorListener.BLOCK_DEFINITION_RETURN:
//			return WorkbenchAnchorListener.BLOCK_CALLER_RETURN
		default:
			return ""
		}
	}
	
	var associatedAnchorDefinitionBlockName: String {
		switch name {
		case WorkbenchAnchorListener.BLOCK_ORB_ANCHOR_ID:
			return WorkbenchAnchorListener.BLOCK_ORB_ANCHOR
//		case WorkbenchAnchorListener.BLOCK_CALLER_RETURN:
//			return WorkbenchAnchorListener.BLOCK_DEFINITION_RETURN
		default:
			return ""
		}
	}
}





// ---------------------- //

/**
Holds a set of objects of a specific type, where each object is weakly-referenced.

- NOTE: This object should not be used in code that requires high performance (e.g. in render
operations), as it is slow.
*/
fileprivate struct WeakSet<Element: AnyObject> {
	// MARK: - Properties
	
	/// Returns an array of all objects
	public var all: [Element] {
		return _objects.allObjects
	}
	
	/// Wrapper of a set of weakly-referenced objects
	private var _boxedObjects = WrapperBox<NSHashTable<Element>>(NSHashTable.weakObjects())
	/// Set of immutable objects
	private var _objects: NSHashTable<Element> {
		return _boxedObjects.unbox
	}
	/// Set of mutable objects
	private var _mutableObjects: NSHashTable<Element> {
		mutating get {
			if !isKnownUniquelyReferenced(&_boxedObjects) {
				// `_boxedObjects` is being referenced by another `WeakSet` struct (that must have been
				// created through a copied assignment). Create a copy of `_boxedObjects` so that both
				// structs now reference a different set of objects.
				_boxedObjects = WrapperBox(_objects.copy() as! NSHashTable)
			}
			return _boxedObjects.unbox
		}
	}
	
	// MARK: - Public
	
	/**
	Adds an object to the set.
	*/
	public mutating func add(_ object: Element) {
		_mutableObjects.add(object)
	}
	
	/**
	Removes an object from the set.
	*/
	public mutating func remove(_ object: Element) {
		_mutableObjects.remove(object)
	}
	
	/**
	Removes all objects from the set.
	*/
	public mutating func removeAll() {
		_mutableObjects.removeAllObjects()
	}
}

extension WeakSet : Sequence {
	// MARK: - Sequence - Implementation
	
	public typealias Iterator = AnyIterator<Element>
	
	public func makeIterator() -> Iterator {
		var index = 0
		let allObjects = self.all
		
		// Create `AnyGenerator` with the closure used for retrieving the next element in the sequence
		return AnyIterator {
			if index < allObjects.count {
				let nextObject = allObjects[index]
				index += 1
				return nextObject
			}
			return nil
		}
	}
}

/**
Object for wrapping any element inside a class. This is specifically being used for
implementing efficient copy-on-write functionality within custom structs. It allows us to
check if the target element is being referenced by multiple objects via
`isUniquelyReferencedNonObjC(:)` and to only perform copies if this check returns true.

For an example of usage, see `WeakSet`.
*/
internal final class WrapperBox<Element> {
	// MARK: - Properties
	
	/// The element that was boxed
	let unbox: Element
	
	// MARK: - Initializers
	
	init(_ element: Element) {
		unbox = element
	}
}
