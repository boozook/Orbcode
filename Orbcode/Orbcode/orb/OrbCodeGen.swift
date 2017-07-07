//
//  OrbCodeGen.swift
//  Orbcode
//
//  Created by Alexander Kozlovskij on 12.03.17.
//  Copyright © 2017 FZZR. All rights reserved.
//

import Foundation
import Blockly


internal class KernelModel
{
	var root: Block;
	var lines: [KernelLine]?;
	var subroutines: [KernelSubroutine]?;
	
	public init(root: Block)
	{
		self.root = root;
	}
}


internal class KernelLine
{
	var block: Block {
		return blocks[0];
	}
	
	var blocks: [Block];
	
	var source: String;
	
	var index: Int = -1;
	
	
	public init(block: Block, source: String)
	{
		self.blocks = [block];
		self.source = source;
	}
	
	/* public init(block: Block, index: Int, source: String)
	{
		self.block = block;
		self.index = index;
		self.source = source;
	} */
}


internal class KernelSubroutine
{
	var blocks: [Block];
	var lines: [KernelLine]?;
	
	
	public init(blocks: [Block])
	{
		self.blocks = blocks;
	}
}


internal class Expr
{
	var block: Block;
	var source: String?;
	var error: ExprError?;
	
	var next: Expr?;
	
	
	public init(block:Block)
	{
		self.block = block;
	}
	
	public init(block:Block, source:String)
	{
		self.block = block;
		self.source = source;
	}
	
	public init(block:Block, error:ExprError)
	{
		self.block = block;
		self.error = error;
	}
	
	public init(block:Block, source:String? = nil, error:ExprError? = nil)
	{
		self.block = block;
		self.source = source;
		self.error = error;
	}
	
	public init(block:Block, source:String, next:Expr)
	{
		self.block = block;
		self.next = next;
		self.source = source;
	}
}

//typealias ExprResolver<T> = (T, Expr) -> Void
typealias ExprResolver<T> = (T, ExprForResolve<T>) -> Void
internal class ExprForResolve<T> : Expr
{
	var resolved: Bool = false;
	var resolve:ExprResolver<T>;
	
	public init(block:Block, resolve:@escaping ExprResolver<T>)
	{
		self.resolve = resolve;
		super.init(block:block);
	}
	
	public init(block:Block, source:String, resolve:@escaping ExprResolver<T>)
	{
		self.resolve = resolve;
		super.init(block:block, source:source);
	}
	
	public init(block:Block, source:String, next:Expr, resolve:@escaping ExprResolver<T>)
	{
		self.resolve = resolve;
		super.init(block:block, source:source, next:next);
	}
}

enum ExprError: Error
{
//	case UnknownBlock(block:Block?, message:String?)
	case UnknownBlock(block:Block?);
	case InvalidDataType(message:String);
	case InvalidBlockStatment(block:Block?, message:String);
}





@objc(OrbCodeGen)
public class OrbCodeGen: NSObject
{
	public static func buildKernels(roots: [Block]) -> Void
	{
		print("buildKernels: ", roots);
		
		var models = [KernelModel]();
		
		roots.forEach { (root) in
			let model = KernelModel(root: root);
			models.append(model);
			buildModel(model: model);
		}
		
		// TODO: next: resolve links (e.g. JUMP->ANCHOR
	}
	
	static func buildModel(model: KernelModel) -> Void
	{
		print("buildModel: ", model.root);
		
		// TODO: here process full tree
		// and write lines-modeles
		
		if(model.lines == nil) {
			model.lines = [];
		}
		
		
		var count = 0;
		let root = model.root;
		var block = Optional(root);
		var rows = model.lines;
		
		repeat
		{
			print("build block: ", block?.name as Any);
			
			let type = block?.name;
			let statements = block?.statements;
			
			if(type == ORB_BLOCK_KERNEL) {
				if(statements?.count != 0 && statements?[0].connectedBlock != nil) {
					// OLD METHOD:
					var next = statements?[0].connectedBlock;
					while(next != nil) {
						if let expr = blockToStr(block: next) {
							rows?.append(KernelLine(block: block!, source: expr));
						}
						next = next?.nextBlock;
					}
					// NEW METHOD:
//					var next = statements?[0].connectedBlock;
					next = statements?[0].connectedBlock;
					while(next != nil) {
						let expr = blockToExpr(block: next, model:model);
//						rows?.append(KernelLine(block: block!, source: expr));
						next = next?.nextBlock;
					}
				} else {
					print("TODO: mark kernel as empty & return");
					break;
				}
			}
			else if(type == ORB_END) {
				rows?.append(KernelLine(block: block!, source: "end"))
			}
			else if(type == ORB_RESET) {
				rows?.append(KernelLine(block: block!, source: "reset"))
			}
			else if(type == ORB_RETURN) {
				rows?.append(KernelLine(block: block!, source: "return"))
			}
				
				// System Variables
				
			else if(type == ORB_VARIABLE_TIMER) {
				let timerExpr = timerGetterBlockToExpr(block: block!);
				rows?.append(KernelLine(block: block!, source: timerExpr ?? "WTF__ERROR"))
			}
			else if(type == ORB_VARIABLE_TIMER_SET) {
				
				let timerExpr = timerSetterBlockToExpr(block: block!);
				if(timerExpr == nil) {
					print("TODO: return ERROR: obscure error when timer_set to string.");
					break;
				}
				rows?.append(KernelLine(block: block!, source: timerExpr ?? "WTF__ERROR"))
			}
				
				// default - break
				
			else {
				break;
			}
			
			count += 1;
			block = block?.nextBlock;
			print("prepare for next...");
			print("nextBlock:", block as Any);
//			if(block == nil && statements?.count != 0) {
//				block = statements?[0].connectedBlock;
////				if(block == nil) {
////					block = statements[0].connectedShadowBlock;
////				}
//			}
		} while((block != nil) && count <= 1000);
		
		print("BUILD", root.name, "COMPLETE");
		var src = "";
		let joiner = "\n";
		let rcount = rows?.count ?? 0;
		
		if(rcount > 0) {
			for i in 0...(rcount - 1) {
				print("ROW:", i, rows?[i].index as Any, ":", rows?[i].source as Any);
				src += (rows?[i].source)! + joiner;
			}
		}
		
		print("SRC:\n" + src);
	}
	
	
	static func buildBlocksInStatement(statement: Input, rows: [KernelLine]) -> Void
	{
		
	}
	
	
	static func createSubroutine(chain: [Block]) -> KernelSubroutine
	{
		let sub = KernelSubroutine(blocks: chain);
		
		return sub;
	}
	
	static func createJump(from: Block, to:Block) -> ExprForResolve<KernelModel>
	{
		return ExprForResolve(block:from, source:"TODO:JUMP", resolve: { (model, expr) in
			print("resolve::", expr);
		})
	}
	
	
	static func chainToSubToExpr(first: Block?) -> String?
	{
		var count = 0;
		var block = first;
		var blocks = [Block]();
		repeat
		{
			if(block != nil) {
				blocks.append(block!);
			}
			
			count += 1;
			block = block?.nextBlock;
		} while((block != nil) && count <= 1000);
		
		let sub = createSubroutine(chain: blocks);
		
		return "MULTILINE_EXPR__GOSUB_TO_VIRT_FUNC";
	}
	
	
	
	static func blockToExpr(block: Block?, model:KernelModel) -> Expr
	{
		let ERROR_UNKNOWN_INPUT = "ERROR_UNKNOWN_INPUT";
		
		let t = block?.name;
		
		// Orb Variables:
		
		if(t == ORB_VARIABLE_TIMER) {
			return Expr(block:block!, source:timerGetterBlockToExpr(block: block!));
		} else if(t == ORB_VARIABLE_TIMER_SET) {
			return Expr(block:block!, source:timerSetterBlockToExpr(block: block!));
		} else if(t == ORB_VARIABLE_CTRL) {
			return Expr(block:block!, source:"ctrl");
		} else if(t == ORB_VARIABLE_CTRL_SET) {
			return Expr(block:block!, source:"ctrl = ", next:blockToExpr(block: block?.firstInputValueBlock, model:model));
		} else if(t == ORB_VARIABLE_SPEED) {
			return Expr(block:block!, source:"speed");
		} else if(t == ORB_VARIABLE_YAW) {
			return Expr(block:block!, source:"yaw");
		} else if(t == ORB_VARIABLE_PITCH) {
			return Expr(block:block!, source:"pitch");
		} else if(t == ORB_VARIABLE_ROLL) {
			return Expr(block:block!, source:"roll");
		} else if(t == ORB_VARIABLE_ACCEL) {
			return Expr(block:block!, source:"accel");
		} else if(t == ORB_VARIABLE_GYRO) {
			return Expr(block:block!, source:"gyro");
		} else if(t == ORB_VARIABLE_VBATT) {
			return Expr(block:block!, source:"Vbatt");
		} else if(t == ORB_VARIABLE_SBATT) {
			return Expr(block:block!, source:"Sbatt");
		} else if(t == ORB_VARIABLE_CMDROLL) {
			return Expr(block:block!, source:"cmdroll");
		} else if(t == ORB_VARIABLE_SPDVAL) {
			return Expr(block:block!, source:"spdval");
		} else if(t == ORB_VARIABLE_HDGVAL) {
			return Expr(block:block!, source:"hdgval");
		} else if(t == ORB_VARIABLE_CMDRGB) {
			return Expr(block:block!, source:"cmdrgb");
		} else if(t == ORB_VARIABLE_REDVAL) {
			return Expr(block:block!, source:"redval");
		} else if(t == ORB_VARIABLE_GRNVAL) {
			return Expr(block:block!, source:"grnval");
		} else if(t == ORB_VARIABLE_BLUVAL) {
			return Expr(block:block!, source:"bluval");
		} else if(t == ORB_VARIABLE_ISCONN) {
			return Expr(block:block!, source:"isconn");
		} else if(t == ORB_VARIABLE_DSHAKE) {
			return Expr(block:block!, source:"dshake");
		} else if(t == ORB_VARIABLE_ACCELONE) {
			return Expr(block:block!, source:"accelone");
		} else if(t == ORB_VARIABLE_XPOS) {
			return Expr(block:block!, source:"xpos");
		} else if(t == ORB_VARIABLE_YPOS) {
			return Expr(block:block!, source:"ypos");
		} else if(t == ORB_VARIABLE_QZERO) {
			return Expr(block:block!, source:"Qzero");
		} else if(t == ORB_VARIABLE_QONE) {
			return Expr(block:block!, source:"Qone");
		} else if(t == ORB_VARIABLE_QTWO) {
			return Expr(block:block!, source:"Qtwo");
		} else if(t == ORB_VARIABLE_QTHREE) {
			return Expr(block:block!, source:"Qthree");
		} else if(t == ORB_VARIABLE_ABC) {
			return Expr(block:block!, source:abcVariableGetterBlockToExpr(block: block!));
		} else if(t == ORB_VARIABLE_ABC_SET) {
			return Expr(block:block!, source:abcVariableSetterBlockToExpr(block: block!));
		} else if(t == "variables_get") {
			return Expr(block:block!, source:(block?.firstField(withName: "VAR") as! FieldVariable).variable);
		} else if(t == "variables_set") {
			let name = (block?.firstField(withName: "VAR") as! FieldVariable).variable;
			let src = name + " = " + (blockToStr(block: block?.getNamedInputValueBlock(name: "VALUE")) ?? ERROR_UNKNOWN_INPUT) + "";
			return Expr(block:block!, source:src);
		}
		
		
			// Orb Functions:
			
		else if(t == ORB_FUNC_DATA) {
//			return nil;
		} else if(t == ORB_FUNC_READ) {
//			return nil;
		} else if(t == ORB_FUNC_RSTR) {
			return Expr(block:block!, source:"rstr");
		} else if(t == ORB_FUNC_MATH_SQRT) {
			return Expr(block:block!, source:"sqrt \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_MATH_RND) {
			return Expr(block:block!, source:"rnd \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_MATH_RANDOM) {
			return Expr(block:block!, source:"random");
		} else if(t == ORB_FUNC_MATH_ABS) {
			return Expr(block:block!, source:"abs \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_DELAY) {
			return Expr(block:block!, source:"delay \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_RGB) {
//			return nil;
		} else if(t == ORB_FUNC_LEDC) {
			return Expr(block:block!, source:"LEDC \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_BACKLED) {
			return Expr(block:block!, source:"backLED \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_GOROLL) {
//			return nil;
		} else if(t == ORB_FUNC_HEADING) {
			return Expr(block:block!, source:"heading \(blockToStr(block: block?.firstInputValueBlock))");
		} else if(t == ORB_FUNC_RAW) {
//			return nil;
		} else if(t == ORB_FUNC_LOCATE) {
//			return nil;
		} else if(t == ORB_FLAG_BASFLG) {
			return Expr(block:block!, source:"basflg \(blockToStr(block: block?.firstInputValueBlock))");
		}
		
		
			
		// .....:
		
		
		
		// Statements: Logic:
		
		else if(t == "controls_if") {
			let statements = block?.statements;
			let statmnt_DO0 = statements?[0];
			let block_DO0 = statmnt_DO0?.connectedBlock ?? statmnt_DO0?.connectedShadowBlock;
			
			if(block_DO0 == nil) {
				return Expr(block:block!, error:ExprError.InvalidBlockStatment(block:block, message:"EMPTY statmnt DO in IF block"));
			}
			
			var result_expr = "";
			let arg = blockToStr(block: block?.getNamedInputValueBlock(name: "IF0")) ?? ERROR_UNKNOWN_INPUT;
			var block_ELSE:Optional<Block>;
			var statmnt_ELSE:Optional<Input>;
			if((statements?.count)! > 1) {
				statmnt_ELSE = statements?[1];
				block_ELSE = statmnt_ELSE?.connectedBlock ?? statmnt_ELSE?.connectedShadowBlock;
				if(block_ELSE == nil) {
					return Expr(block:block!, error:ExprError.InvalidBlockStatment(block:block, message:"EMPTY statmnt ELSE in IF block"));
				}
			}
			
			
			var resolver_DO:ExprResolver<KernelModel>?;
			var resolver_ELSE:ExprResolver<KernelModel>?;
			
			
			// build DO0:
			var expr_DO0 = blockToStr(block: block_DO0);
			if(block_DO0?.nextBlock != nil)
			{
				print("create virtual function for multiline IF:DO0 statement");
				expr_DO0 = chainToSubToExpr(first: block_DO0);
				
				resolver_DO = { (KernelModel, expr) in
					// TODO: find anchor and use its ID (line)
				}
			}
			
			
			
			
			
			
			// build result expr:
			if(block_ELSE == nil)
			{
				result_expr = "if \(arg) then \(expr_DO0!)";
			}
			else
			{
				if(block_ELSE?.nextBlock != nil)
				{
					print("create virtual function for multiline IF:ELSE statement");
					let gosub_expr = chainToSubToExpr(first: block_ELSE);
					result_expr = "if \(arg) then \(expr_DO0!) else \(gosub_expr)";
					
					resolver_ELSE = { (KernelModel, expr) in
						// TODO: find anchor and use its ID (line)
					}
				}
				else {
					let expr_ELSE = blockToStr(block: block_ELSE) ?? ERROR_UNKNOWN_INPUT;
					result_expr = "if \(arg) then \(expr_DO0!) else \(expr_ELSE)";
				}
			}
			
//			return result_expr;
			
//			var result:ExprForResolve;
//			result = ExprForResolve(block:block!, resolve: { (KernelModel, expr) in
//				if(resolver_DO != nil) {
//					resolver_DO(model, expr)
//				}
//			}) as Expr
			
//			return ExprForResolve(block:block!, resolve: { (KernelModel, expr) in
//				if(resolver_DO != nil) {
//					resolver_DO(model, expr)
//				}
//			}) as Expr;
		}
		
		
		
		return Expr(block:block!, error:ExprError.UnknownBlock(block:block));
	}
	
	
	static func blockToStr(block: Block?) -> String?
	{
		 if(block == nil) { return nil; }
		
		let ERROR_UNKNOWN_INPUT = "ERROR_UNKNOWN_INPUT";
		
		let t = block?.name;
		
		// Orb Variables:
		
		if(t == ORB_VARIABLE_TIMER) {
			return timerGetterBlockToExpr(block: block!);
		} else if(t == ORB_VARIABLE_TIMER_SET) {
			return timerSetterBlockToExpr(block: block!);
		} else if(t == ORB_VARIABLE_CTRL) {
			return "ctrl";
		} else if(t == ORB_VARIABLE_CTRL_SET) {
			return "ctrl = " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_VARIABLE_SPEED) {
			return "speed";
		} else if(t == ORB_VARIABLE_YAW) {
			return "yaw";
		} else if(t == ORB_VARIABLE_PITCH) {
			return "pitch";
		} else if(t == ORB_VARIABLE_ROLL) {
			return "roll";
		} else if(t == ORB_VARIABLE_ACCEL) {
			return "accel";
		} else if(t == ORB_VARIABLE_GYRO) {
			return "gyro";
		} else if(t == ORB_VARIABLE_VBATT) {
			return "Vbatt";
		} else if(t == ORB_VARIABLE_SBATT) {
			return "Sbatt";
		} else if(t == ORB_VARIABLE_CMDROLL) {
			return "cmdroll";
		} else if(t == ORB_VARIABLE_SPDVAL) {
			return "spdval";
		} else if(t == ORB_VARIABLE_HDGVAL) {
			return "hdgval";
		} else if(t == ORB_VARIABLE_CMDRGB) {
			return "cmdrgb";
		} else if(t == ORB_VARIABLE_REDVAL) {
			return "redval";
		} else if(t == ORB_VARIABLE_GRNVAL) {
			return "grnval";
		} else if(t == ORB_VARIABLE_BLUVAL) {
			return "bluval";
		} else if(t == ORB_VARIABLE_ISCONN) {
			return "isconn";
		} else if(t == ORB_VARIABLE_DSHAKE) {
			return "dshake";
		} else if(t == ORB_VARIABLE_ACCELONE) {
			return "accelone";
		} else if(t == ORB_VARIABLE_XPOS) {
			return "xpos";
		} else if(t == ORB_VARIABLE_YPOS) {
			return "ypos";
		} else if(t == ORB_VARIABLE_QZERO) {
			return "Qzero";
		} else if(t == ORB_VARIABLE_QONE) {
			return "Qone";
		} else if(t == ORB_VARIABLE_QTWO) {
			return "Qtwo";
		} else if(t == ORB_VARIABLE_QTHREE) {
			return "Qthree";
		} else if(t == ORB_VARIABLE_ABC) {
			return abcVariableGetterBlockToExpr(block: block!);
		} else if(t == ORB_VARIABLE_ABC_SET) {
			return abcVariableSetterBlockToExpr(block: block!);
		} else if(t == "variables_get") {
			return (block?.firstField(withName: "VAR") as! FieldVariable).variable;
		} else if(t == "variables_set") {
			let name = (block?.firstField(withName: "VAR") as! FieldVariable).variable;
			return name + " = " + (blockToStr(block: block?.getNamedInputValueBlock(name: "VALUE")) ?? ERROR_UNKNOWN_INPUT) + "";
		}
		
		
		// Orb Functions:
			
		else if(t == ORB_FUNC_DATA) {
			return nil;
		} else if(t == ORB_FUNC_READ) {
			return nil;
		} else if(t == ORB_FUNC_RSTR) {
			return "rstr";
		} else if(t == ORB_FUNC_MATH_SQRT) {
			return "sqrt " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_MATH_RND) {
			return "rnd " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_MATH_RANDOM) {
			return "random";
		} else if(t == ORB_FUNC_MATH_ABS) {
			return "abs " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_DELAY) {
			return "delay " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_RGB) {
			return nil;
		} else if(t == ORB_FUNC_LEDC) {
			return "LEDC " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_BACKLED) {
			return "backLED " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_GOROLL) {
			return nil;
		} else if(t == ORB_FUNC_HEADING) {
			return "heading " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_FUNC_RAW) {
			return nil;
		} else if(t == ORB_FUNC_LOCATE) {
			return nil;
		} else if(t == ORB_FLAG_BASFLG) {
			return "basflg " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		}
		
		// Math:
			
		else if(t == "math_number") {
			let value = (block?.firstField(withName: "NUM") as! FieldNumber).textValue;
			return value.range(of: "-") != nil ? "(0" + value + ")" : value;
		} else if(t == "math_change") {
			let name = (block?.firstField(withName: "VAR") as! FieldVariable).variable;
			let inp = blockToStr(block: block?.firstInputValueBlock);
			return inp != nil ? (name + " = " + name + " + " + inp!) : nil;
		}else if(t == "angle_block") {
			let inp = block?.inputs[0];
			let field = inp?.fields[1] as! FieldAngle;
			let value = field.angle;
			return value < 0 ? "(0" + String(value) + ")" : String(value);
		} else if(t == "math_arithmetic") {
			let opi = block?.getFirstDropdownFieldIndex(name: "OP");
			var op = "";
			switch(opi!) {
				case 0: op = "+";
				case 1: op = "-";
				case 2: op = "*";
				case 3: op = "/";
				default: return nil;
			}
			
			// скобочки:
			// 1. проверяем оператор - если * / то
			// 2. проверяем A и B - если они "комбо/арифметические" типа этого => заворачиваем их в скобки!
			
			let inpA = block?.firstInput(withName: "A");
			let inpB = block?.firstInput(withName: "B");
			let a = blockToStr(block: inpA?.connectedBlock ?? inpA?.connectedShadowBlock);
			let b = blockToStr(block: inpB?.connectedBlock ?? inpB?.connectedShadowBlock);
			
			if(a == nil || b == nil) { return nil; }
			return a! + " " + op + " " + b!;
		} else if(t == "math_number_property") {
			let op = block?.getFirstDropdownFieldIndex(name: "PROPERTY");
			let value = (blockToStr(block: block?.getNamedInputValueBlock(name: "NUMBER_TO_CHECK")) ?? ERROR_UNKNOWN_INPUT);
			var expr = "";
			switch(op!) {
				case 0: expr = "" + String(value) + "%2 = 0"; // even
				case 1: expr = "" + String(value) + "%2 ! 0"; // odd
				case 2: expr = "0"; // prime
				case 3: expr = "1"; // whole
				case 4: expr = "" + String(value) + ">0"; // positive
				case 5: expr = "" + String(value) + "<0"; // negative
				default: return nil;
			}
			return expr;
		} else if(t == "math_modulo") {
			let a = (blockToStr(block: block?.getNamedInputValueBlock(name: "DIVIDEND")) ?? ERROR_UNKNOWN_INPUT);
			let b = (blockToStr(block: block?.getNamedInputValueBlock(name: "DIVISOR")) ?? ERROR_UNKNOWN_INPUT);
			return "(" + a + "%" + b + ")";
		}
			
			
		// Logic:
			
		else if(t == LOGIC_COMPARE_MATH) {
			var op = "";
			let opi = block?.getFirstDropdownFieldIndex(name: "OP");
			let a = (blockToStr(block: block?.getNamedInputValueBlock(name: "A")) ?? ERROR_UNKNOWN_INPUT);
			let b = (blockToStr(block: block?.getNamedInputValueBlock(name: "B")) ?? ERROR_UNKNOWN_INPUT);
			switch(opi!) {
			case 0: op = "="; // eq
			case 1: op = "!"; // neg
			case 2: op = ">"; // >
			case 3: op = "<"; // <
			default: return nil;
			}
			return "(" + a + op + b + ")";
		}
			
		// Statements: Logic:
		
		else if(t == "controls_if") {
			let statements = block?.statements;
			let statmnt_DO0 = statements?[0];
			let block_DO0 = statmnt_DO0?.connectedBlock ?? statmnt_DO0?.connectedShadowBlock;
			
			if(block_DO0 == nil) {
				return "ERROR: EMPTY statmnt DO in IF block";
			}
			
			var result_expr = "";
			let arg = blockToStr(block: block?.getNamedInputValueBlock(name: "IF0")) ?? ERROR_UNKNOWN_INPUT;
			var block_ELSE:Optional<Block>;
			var statmnt_ELSE:Optional<Input>;
			if((statements?.count)! > 1) {
				statmnt_ELSE = statements?[1];
				block_ELSE = statmnt_ELSE?.connectedBlock ?? statmnt_ELSE?.connectedShadowBlock;
				if(block_ELSE == nil) {
					return "ERROR: EMPTY statmnt ELSE in IF block";
				}
			}
			
			
			// build DO0:
			var expr_DO0 = blockToStr(block: block_DO0);
			if(block_DO0?.nextBlock != nil)
			{
				print("create virtual function for multiline IF:DO0 statement");
				expr_DO0 = chainToSubToExpr(first: block_DO0);
			}
			
			
			
			// build result expr:
			if(block_ELSE == nil)
			{
				result_expr = "if \(arg) then \(expr_DO0!)";
			}
			else
			{
				if(block_ELSE?.nextBlock != nil)
				{
					print("create virtual function for multiline IF:ELSE statement");
					let gosub_expr = chainToSubToExpr(first: block_ELSE);
					result_expr = "if \(arg) then \(expr_DO0!) else \(gosub_expr)";
				}
				else {
					let expr_ELSE = blockToStr(block: block_ELSE) ?? ERROR_UNKNOWN_INPUT;
					result_expr = "if \(arg) then \(expr_DO0!) else \(expr_ELSE)";
				}
			}
			
			return result_expr;
		}
			
		// Colours:
		
		// Statements:
		
		// Procedures:
		
		// Flow: Loops:
			
		else if(t == "controls_for") {
			let statmnt = block?.statements?[0];
			let variable = (block?.firstField(withName: "VAR") as! FieldVariable).variable;
			let from = blockToStr(block: block?.getNamedInputValueBlock(name: "FROM"));
			let to = blockToStr(block: block?.getNamedInputValueBlock(name: "TO"));
			let step = blockToStr(block: block?.getNamedInputValueBlock(name: "BY"));
			if(from == nil || to == nil || step == nil) {
				print("TODO: throw ERROR: invalid input");
				return nil;
			}
			if(statmnt == nil || (statmnt!.connectedBlock == nil && statmnt!.connectedShadowBlock == nil))
			{
				print("TODO: throw ERROR: for statements is empty.");
				return nil;
			}
			
//			let start = "for " + variable + "=" + from + " to " + to + " step " + step;
			let start = "for \(variable)=\(from) to \(to) step \(step)";
			let finish = "next " + variable;
			// TODO: return ROWs !
			return nil;
		} else if(t == "controls_for_simple") {
			
			return nil;
		}
		
		// Flow: Jumps:
		
		else if(t == ORB_JUMP) {
			return "goto " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_GOSUB) {
			return "gosub " + (blockToStr(block: block?.firstInputValueBlock) ?? ERROR_UNKNOWN_INPUT) + "";
		} else if(t == ORB_ANCHOR) {
			return nil;
		} else if(t == ORB_ANCHOR_ID) {
			return nil;
		} else if(t == ORB_ANCHOR_VALUE) {
			return nil;
		} else if(t == ORB_JUMP_INDEXED) {
			return nil;
		} else if(t == ORB_GOSUB_INDEXED) {
			return nil;
		} else if(t == ORB_END) {
			return "end";
		} else if(t == ORB_RETURN) {
			return "return";
		} else if(t == ORB_RESET) {
			return "reset";
		} else if(t == ORB_FUNC_SLEEP) {
			return nil;
		}
		
		
		
		return nil;
	}
	
	
	// MARK - timerABC
	
	
	static func timerGetterBlockToExpr(block: Block) -> String?
	{
		let prop = "timer";
		var name = "";
		
		switch block.getFirstDropdownFieldIndex(name: "TIMER") {
			case 0: name = "A";
			case 1: name = "B";
			case 2: name = "C";
			default:name = "ERROR";
		}
		return prop + name;
	}

	static func timerSetterBlockToExpr(block: Block) -> String?
	{
		let timerX = timerGetterBlockToExpr(block: block);
		if(timerX == nil) {
			print("TODO: return ERROR: obscure error when timer to string.");
			return nil;
		}
		
		let valueBlock = block.firstInputValueBlock;
		if(valueBlock == nil) {
			print("TODO: return ERROR: input is empty");
			return nil;
		}
		
		let value = blockToStr(block: valueBlock!);
		if(value == nil)
		{
			print("TODO: return ERROR: input is unknown or not implmntd yet:", valueBlock?.name as Any);
			return nil;
		}
		
		return timerX! + " = " + (value ?? "ERROR_UNKNOWN");
	}
	
	
	// MARK - user variables
	
	
	static func abcVariableGetterBlockToExpr(block: Block) -> String?
	{
		return block.getFirstDropdownFieldOption(name: "NAME")?.value;
	}
	
	static func abcVariableSetterBlockToExpr(block: Block) -> String?
	{
		let name = abcVariableGetterBlockToExpr(block: block);
		if(name == nil) {
			print("TODO: return ERROR: obscure error when variable to string.");
			return nil;
		}
		
		let valueBlock = block.firstInputValueBlock;
		if(valueBlock == nil) {
			print("TODO: return ERROR: input is empty");
			return nil;
		}
		
		let value = blockToStr(block: valueBlock!);
		if(value == nil)
		{
			print("TODO: return ERROR: input is unknown or not implmntd yet:", valueBlock?.name as Any);
			return nil;
		}
		
		return name! + " = " + (value ?? "ERROR_UNKNOWN");
	}

	
	
	
	public static func validateTopBlocks(roots: [Block]) -> Void
	{
		
	}
}



// MARK: - Block Extension Methods

fileprivate extension Block
{
	var statements: [Input]? {
		return inputs.filter({ (input) -> Bool in
			input.type == .statement;
		})
	}
	
	
	var firstInputValueBlock: Block? {
		return inputs[0].connectedBlock ?? inputs[0].connectedShadowBlock;
	}
	
	func getNamedInputValueBlock(name: String) -> Block? {
		let inp = firstInput(withName: name);
		return inp?.connectedBlock ?? inp?.connectedShadowBlock;
	}
	
	
	func getFirstDropdownFieldIndex(name: String) -> Int {
		return (firstField(withName: name) as! FieldDropdown).selectedIndex;
	}
	
	func getFirstDropdownFieldOption(name: String) -> FieldDropdown.Option? {
		return (firstField(withName: name) as! FieldDropdown).selectedOption;
	}
	
}















