//
//  MutatorRegisterHelper.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 10.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly


@objc(OrbMutatorRegister)
public class MutatorRegisterHelper: NSObject
{
	public static func registerWorkbenchListener(workbench:WorkbenchViewController)
	{
		workbench.addCoordinator(coordinator: WorkbenchAnchorListener(workbench: workbench));
	}
	
	public static func updateBlockExtensions(inBlockFactory factory:BlockFactory)
	{
		
		var extensions = [String: BlockExtension]();
		
		extensions[ORB_JUMP_INDEXED_MUTATOR] = BlockExtensionClosure { block in
			try! block.setMutator(MutatorJumpIndexed());
		}
		
		extensions[ORB_ANCHOR_SELECTOR] = BlockExtensionClosure { block in
			try! block.setMutator(MutatorAnchorPointer());
		}
		
		extensions[ORB_FUNC_READ_MUTATOR] = BlockExtensionClosure { block in
			try! block.setMutator(MutatorBatchDataRead());
		}
		
		extensions[ORB_FUNC_DATA_MUTATOR] = BlockExtensionClosure { block in
			try! block.setMutator(MutatorBatchDataWrite());
		}
		
		extensions[ORB_SUPABLOCK_MUTATOR] = BlockExtensionClosure { block in
			try! block.setMutator(MutatorSupablock());
		}

		
		factory.updateBlockExtensions(extensions);
	}
	
	public static func registerLayouts(inBuilder builder:LayoutBuilder, andFactory factory:ViewFactory)
	{
		if(builder.layoutFactory is DefaultLayoutFactory)
		{
			let factory = builder.layoutFactory as! DefaultLayoutFactory;
			
			factory.registerLayoutCreator(forMutatorType: MutatorJumpIndexed.self) {
				(mutator: Mutator, engine: LayoutEngine) -> MutatorLayout in
				return MutatorJumpIndexedLayout(mutator: mutator as! MutatorJumpIndexed, engine: engine)
			}
			
			factory.registerLayoutCreator(forMutatorType: MutatorAnchorPointer.self) {
				(mutator: Mutator, engine: LayoutEngine) -> MutatorLayout in
				return MutatorAnchorPointerLayout(
					mutator: mutator as! MutatorAnchorPointer, engine: engine)
			}
			
			
			factory.registerLayoutCreator(forMutatorType: MutatorBatchDataWrite.self) {
				(mutator: Mutator, engine: LayoutEngine) -> MutatorLayout in
				return MutatorBatchDataWriteLayout(
					mutator: mutator as! MutatorBatchDataWrite, engine: engine)
			}
			
			factory.registerLayoutCreator(forMutatorType: MutatorBatchDataRead.self) {
				(mutator: Mutator, engine: LayoutEngine) -> MutatorLayout in
				return MutatorBatchDataReadLayout(
					mutator: mutator as! MutatorBatchDataRead, engine: engine)
			}
			
			factory.registerLayoutCreator(forMutatorType: MutatorSupablock.self) {
				(mutator: Mutator, engine: LayoutEngine) -> MutatorLayout in
				return MutatorSupablockLayout(
					mutator: mutator as! MutatorSupablock, engine: engine)
			}
		}
		
		// register in ViewFactory:
		factory.registerLayoutType(MutatorJumpIndexedLayout.self, withViewType: MutatorJumpIndexedView.self.self);
		factory.registerLayoutType(MutatorSupablockLayout.self, withViewType: MutatorSupablockView.self.self);
	}
}


