//
//  MutatorSupablockView.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 19.04.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly



// MARK: - MutatorSupablockView Class

/**
View for rendering a `MutatorSupablock`.
*/
@objc(BKYMutatorSupablockView)
open class MutatorSupablockView: LayoutView {
	// MARK: - Properties
	
	/// Convenience property accessing `self.layout` as `MutatorSupablockLayout`
	open var mutatorSupablockLayout: MutatorSupablockLayout? {
		return layout as? MutatorSupablockLayout
	}
	
	/// A button for opening the popover settings
	open fileprivate(set) lazy var popoverErrorButton: UIButton = {
		let button = UIButton(type: .custom)
		button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		if let image = ImageLoader.loadImage(named: "exclamation-mark", forClass: type(of: self)) {
			button.setImage(image, for: .normal)
			button.imageView?.contentMode = .scaleAspectFit
			button.contentHorizontalAlignment = .fill
			button.contentVerticalAlignment = .fill
		}
		button.addTarget(self, action: #selector(showErrorView(_:)), for: .touchUpInside)
		return button
	}()
	
	// MARK: - Initializers
	
	/// Initializes the number field view.
	public required init() {
		super.init(frame: CGRect.zero)
		
		addSubview(popoverErrorButton)
	}
	
	/**
	:nodoc:
	- Warning: This is currently unsupported.
	*/
	public required init?(coder aDecoder: NSCoder) {
		fatalError("Called unsupported initializer")
	}
	
	// MARK: - Super
	
	open override func refreshView(
		forFlags flags: LayoutFlag = LayoutFlag.All, animated: Bool = false)
	{
		super.refreshView(forFlags: flags, animated: animated)
		
		guard let layout = self.layout else { return }
		guard let mutatorSupablockLayout = self.mutatorSupablockLayout else { return }
		
		if(mutatorSupablockLayout.error != nil) {
			print("M:View - need show the BTN");
		}
		
		if(mutatorSupablockLayout.error == nil /*&& subviews.index(of: popoverErrorButton) != nil*/) {
//			popoverErrorButton.removeFromSuperview();
//			popoverErrorButton.imageView?.isHidden
			popoverErrorButton.isHidden = true;
		} else /*if(mutatorSupablockLayout.error != nil && subviews.index(of: popoverErrorButton) == nil)*/ {
//			addSubview(popoverErrorButton);
			popoverErrorButton.isHidden = false;
			print("M:View - the BTN was ADDED.");
		}
		
		runAnimatableCode(animated) {
			if flags.intersectsWith([Layout.Flag_NeedsDisplay, Layout.Flag_UpdateViewFrame]) {
				// Update the view frame
				self.frame = layout.viewFrame
			}
			
			let topPadding = layout.engine.viewUnitFromWorkspaceUnit(4)
			self.popoverErrorButton.contentEdgeInsets = UIEdgeInsetsMake(topPadding, 0, topPadding, 0)
		}
	}
	
	open override func prepareForReuse() {
		super.prepareForReuse()
		frame = CGRect.zero
	}
	
	// MARK: - Private
	
	private dynamic func showErrorView(_ sender: UIButton)
	{
		guard let mutatorSupablockLayout = self.mutatorSupablockLayout else {
			return
		}
		
		let renameView = UIAlertController(title: "Error:", message: mutatorSupablockLayout.error, preferredStyle: .alert);
//		renameView.popoverPresentationController?.permittedArrowDirections = [.down, .right, .left]
		let okay = UIAlertAction(title: "Okay", style: .default, handler: nil);
		renameView.addAction(okay);
		popoverDelegate?.layoutView(self, requestedToPresentViewController: renameView);
		if #available(iOS 9, *) {
			renameView.preferredAction = okay;
		}
	}
}
