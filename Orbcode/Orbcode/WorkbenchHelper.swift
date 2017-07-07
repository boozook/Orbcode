//
//  WorkbenchHelper.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 20.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly

@objc(OrbWorkbenchHelper)
public class WorkbenchHelper: NSObject
{
	public static func markAllBlocksAsValid(inWorkbench workbench:WorkbenchViewController)
	{
		workbench.workspace?.allBlocks.forEach({ (item:(uuid: String, block: Block)) in
			item.block.disabled = false;
		})
	}
	
	public static func markBlockAsInvalid(inWorkbench workbench:WorkbenchViewController, uuid:String)
	{
		guard let block = workbench.workspace?.allBlocks[uuid] else { return; }
		let color = workbench.engine.config.color(for: DefaultLayoutConfig.BlockStrokeHighlightColor);
		workbench.engine.config.setColor(UIColor.red, for: DefaultLayoutConfig.BlockStrokeHighlightColor);
		workbench.highlightBlock(blockUUID: block.uuid);
		workbench.engine.config.setColor(color, for: DefaultLayoutConfig.BlockStrokeHighlightColor);
		
		
		//		block.disabled = true;
		//		print("MUTATOR of Invalid block \(uuid)", block.mutator ?? "---");
		//
		//		guard let mutator = (block.mutator as? MutatorSupablock ?? nil) else { return; }
		//		mutator.error = message;
		//		try? workbench.layoutBuilder.buildLayout(forMutator: mutator, engine: (mutator.layout?.engine)!);
		////		mutator.layout?.performMutation()
		////		mutator.layout?.layoutCoordinator.block
		////		block.notifyDidUpdateBlock()
		//		print("Invalidated block \(uuid) \(block.name).");
	}
	
	
	
	public static func markUndeletableBlocks(inWorkbench workbench:WorkbenchViewController)
	{
		workbench.workspace?.topLevelBlocks().forEach({ (block:Block) in
			if(block.name == ORB_BLOCK_KERNEL) {
				block.deletable = false;
				print("Block \(block.name) marked as undeletable!");
			}
		})
	}
	
	
	
	public static func enableAllBlocks(inWorkbench workbench:WorkbenchViewController)
	{
//		workbench.workspace?.allBlocks.forEach({ (item:(uuid: String, block: Block)) in
//			item.block.disabled = false;
//		})
	}
	
	public static func disableBlockAsIgnored(inWorkbench workbench:WorkbenchViewController, uuid:String)
	{
//		workbench.view
		guard let block = workbench.workspace?.allBlocks[uuid] else { return; }
		let color = workbench.engine.config.color(for: DefaultLayoutConfig.BlockStrokeHighlightColor);
		workbench.engine.config.setColor(UIColor.yellow, for: DefaultLayoutConfig.BlockStrokeHighlightColor);
		workbench.highlightBlock(blockUUID: block.uuid);
		workbench.engine.config.setColor(color, for: DefaultLayoutConfig.BlockStrokeHighlightColor);
	}
	
	
	
	public static func resetBlockErrors()
	{
		
	}
	
	public static func resetBlockInfos()
	{
		
	}
	
	public static func addBlockError(uuid:String, message:String)
	{
//		guard let block = workbench.workspace?.allBlocks[uuid] else { return; }
//		let color = workbench.engine.config.color(for: DefaultLayoutConfig.BlockStrokeHighlightColor);
//		workbench.engine.config.setColor(UIColor.yellow, for: DefaultLayoutConfig.BlockStrokeHighlightColor);
//		workbench.highlightBlock(blockUUID: block.uuid);
//		workbench.engine.config.setColor(color, for: DefaultLayoutConfig.BlockStrokeHighlightColor);
	}
	
	public static func addBlockInfo(uuid:String, message:String)
	{
		
	}
}


