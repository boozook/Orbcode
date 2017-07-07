//
//  MutatorJumpIndexedView.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 10.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly



// MARK: - MutatorJumpIndexedView Class

/**
View for rendering a `MutatorJumpIndexed`.
*/
@objc(BKYMutatorJumpIndexedView)
open class MutatorJumpIndexedView: LayoutView {
	// MARK: - Properties
	
	/// Convenience property accessing `self.layout` as `MutatorJumpIndexedLayout`
	open var MutatorJumpIndexedLayout: MutatorJumpIndexedLayout? {
		return layout as? MutatorJumpIndexedLayout
	}
	
	/// A button for opening the popover settings
	open fileprivate(set) lazy var popoverButton: UIButton = {
		let button = UIButton(type: .custom)
		button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		if let image = ImageLoader.loadImage(named: "settings", forClass: type(of: self)) {
			button.setImage(image, for: .normal)
			button.imageView?.contentMode = .scaleAspectFit
			button.contentHorizontalAlignment = .fill
			button.contentVerticalAlignment = .fill
		}
		button.addTarget(self, action: #selector(openPopover(_:)), for: .touchUpInside)
		return button
	}()
	
	// MARK: - Initializers
	
	/// Initializes the number field view.
	public required init() {
		super.init(frame: CGRect.zero)
		
		addSubview(popoverButton)
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
		
		guard let layout = self.layout else {
			return
		}
		
		runAnimatableCode(animated) {
			if flags.intersectsWith([Layout.Flag_NeedsDisplay, Layout.Flag_UpdateViewFrame]) {
				// Update the view frame
				self.frame = layout.viewFrame
			}
			
			let topPadding = layout.engine.viewUnitFromWorkspaceUnit(4)
			self.popoverButton.contentEdgeInsets = UIEdgeInsetsMake(topPadding, 0, topPadding, 0)
		}
	}
	
	open override func prepareForReuse() {
		super.prepareForReuse()
		frame = CGRect.zero
	}
	
	// MARK: - Private
	
	private dynamic func openPopover(_ sender: UIButton) {
		guard let MutatorJumpIndexedLayout = self.MutatorJumpIndexedLayout else {
			return
		}
		
		let viewController =
			MutatorJumpIndexedViewPopoverController(MutatorJumpIndexedLayout: MutatorJumpIndexedLayout)
		viewController.preferredContentSize = CGSize(width: 220, height: 100)
		
		// Preserve the current input connections so that subsequent mutations don't disconnect them
		MutatorJumpIndexedLayout.preserveCurrentInputConnections()
		
		popoverDelegate?.layoutView(self,
		                            requestedToPresentPopoverViewController: viewController,
		                            fromView: popoverButton)
		
		// Set the arrow direction of the popover to be down/right/left, so it won't
		// obstruct the view of the block
		viewController.popoverPresentationController?.permittedArrowDirections = [.down, .right, .left]
	}
}

// MARK: - MutatorJumpIndexedViewPopoverController Class

/**
Popover used to display the "else-if" and "else" options.
*/
fileprivate class MutatorJumpIndexedViewPopoverController: UITableViewController {
	// MARK: - Properties
	
	/// The mutator to configure
	weak var MutatorJumpIndexedLayout: MutatorJumpIndexedLayout!
	
	// MARK: - Initializers
	
	convenience init(MutatorJumpIndexedLayout: MutatorJumpIndexedLayout) {
		// NOTE: Normally this would be configured as a designated initializer, but there is a problem
		// with UITableViewController initializers. Using a convenience initializer here is a quick
		// fix to the problem (albeit with use of a force unwrapped optional).
		//
		// See here for more details:
		// http://stackoverflow.com/questions/25139494/how-to-subclass-uitableviewcontroller-in-swift
		
		self.init(style: .plain)
		self.MutatorJumpIndexedLayout = MutatorJumpIndexedLayout
	}
	
	// MARK: - Super
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.allowsSelection = false
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
		-> UITableViewCell
	{
		if indexPath.row == 0 {
			// Else-if option
			let accessoryView = IntegerIncrementerView(frame: CGRect(x: 0, y: 0, width: 84, height: 44))
			accessoryView.value = MutatorJumpIndexedLayout.optionsCount
			accessoryView.minimumValue = 1
			accessoryView.delegate = self
			
			let cell = UITableViewCell(style: .default, reuseIdentifier: "ElseIfCell")
			cell.textLabel?.text = "⚓ anchors"
			cell.accessoryView = accessoryView
			
			
			return cell
		} /*else {
			// Else option
			let accessoryView = UISwitch()
			accessoryView.addTarget(self, action: #selector(updateElseCount), for: .valueChanged)
			accessoryView.isOn = MutatorJumpIndexedLayout.elseStatement
			
			let cell = UITableViewCell(style: .default, reuseIdentifier: "ElseCell")
			cell.textLabel?.text = "else"
			cell.accessoryView = accessoryView
			
			return cell
		} */
		else {
			let cell = UITableViewCell(style: .default, reuseIdentifier: "ElseIfCell")
			cell.textLabel?.text = "wtf?"
			return cell
		}
	}
	
	// MARK: - Else Mutation
	
//	fileprivate dynamic func updateElseCount() {
//		if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)),
//			let accessoryView = cell.accessoryView as? UISwitch
//		{
//			MutatorJumpIndexedLayout.elseStatement = accessoryView.isOn
//			try? MutatorJumpIndexedLayout.performMutation()
//		}
//	}
}

extension MutatorJumpIndexedViewPopoverController: IntegerIncrementerViewDelegate {
	// MARK: - Else-If Mutation
	
	fileprivate func integerIncrementerView(
		_ integerIncrementerView: IntegerIncrementerView, didChangeToValue value: Int)
	{
		MutatorJumpIndexedLayout.optionsCount = value
		try? MutatorJumpIndexedLayout.performMutation()
	}
}
