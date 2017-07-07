package fzzr.comp;

import haxe.xml.Fast;
import fzzr.comp.BlockType;

using StringTools;


class KernelCompilerResult
{
	public var errors(default, null):Map<String, ExprError>;
	public var source(default, null):Null<String>;
	public var lines(default, null):Map<Int, String>;
	public var ignores(default, null):Array<String>;
	public var cerrors:Array<String>;
	public var cinfos:Array<String>;

	public function new(errors, source, lines, ignores, ?cerrors, ?cinfos):Void
	{
		this.lines = lines;
		this.source = source;
		this.errors = errors;
		this.ignores = ignores;
		this.cerrors = cerrors;
		this.cinfos = cinfos;
	}
}

abstract KernelCompilerError(String) to String
{
	public static inline var INVALID_SOURCE_INPUT = "Invalid input workspace source.";
}


@:keep class KernelCompiler
{
	static var log:{info:String -> Void, error:String->Void};


	public static function build(src:String):Null<KernelCompilerResult>
	{
		var infos = [];
		var errors = [];
		log =
		{
			info:function(s) {infos.push(s); trace(s);},
			error:function(s) {errors.push(s); trace('ERR: $s');}
		};

		return try
		{
			var res = _build(src);
			res.cinfos = infos;
			res.cerrors = errors;
			res;
		}
		catch(error:Dynamic)
		{
			var cerror = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
			error.push(cerror);

			trace("ERROR");
			trace(error);
			trace(cerror);

			new KernelCompilerResult(null, null, null, null, errors, infos);
		}
	}

	static function _build(src:String):KernelCompilerResult
	{
		var doc = Xml.parse(src);
		var roots = getRoots(doc);
		var kexprs = buildKernel(roots.kernel);
		var procedures = [for(sub in roots.procedures) buildProcedure(sub, true)];
		var model:Model =
		{
			kernel: kexprs, procedures:procedures, lines:new LinesMap(),
			output:null,
			errors:null,
		};

		// var ignored = roots.ignore;


		// trace('KERNEL exprs: ${kexprs.join("\n\t")}');
		// trace('PROCEDURES:\n${procedures.join("\n\t")}');


		// Expand the ExprMulti(statements):
		function replace(expr:ExprDef, where:Array<ExprDef>, exprs:Array<ExprDef>):Void
		{
			var index = where.indexOf(expr);
			trace('replace [$index] : $expr\n\t\t \\ <- [0/${exprs.length}] : ${exprs[0]}');
			where[index] = exprs[0];
			// for(i in (++index)...exprs.length)
			for(i in 1...exprs.length)
			{
				trace('insert [${index + 1}] <- [$i/${exprs.length}] : ${exprs[i]}');
				where.insert(++index, exprs[i]);
			}
		}
		for(i in 0...kexprs.length) switch(kexprs[i])
		{
			case ExprMulti(statements): replace(kexprs[i], kexprs, statements);
			default: continue;
		}
		for(proc in procedures)
			for(i in 0...proc.exprs.length) switch(proc.exprs[i])
			{
				case ExprMulti(statements): replace(proc.exprs[i], proc.exprs, statements);
				default: continue;
			}
		trace("EXPAND COMPLETE");


		// Now we should finalize the seq:
		// -- find a last expr of the entire doc and add `END` to the end.
		// => then that _virtual anchor_ will get next line-number and all linked jumps will be resolved.
		function finalize():Void
		{
			if(procedures.length == 0 && kexprs.length > 0)
			{
				// finalize kernel:
				var expr = kexprs[kexprs.length - 1];
				switch(expr)
				{
					case ExprVirtual(_): kexprs.push(ExprGen("end", Std.int(Math.random() * 1000)));
					default: null;
				}
			}

			var procedure = procedures[procedures.length - 1];
			if(procedure == null || procedure.exprs.length == 0) return;
			var expr = procedure.exprs[procedure.exprs.length - 1];
			switch(expr)
			{
				case ExprVirtual(_): procedure.exprs.push(ExprGen("end", Std.int(Math.random() * 1000)));
				default: null;
			}
		}
		finalize();
		trace("FINALIZE COMPLETE");


		// Fill the map of each expr => line:
		buildLinesMap(model);
		trace("BUILD LINES COMPLETE");

		// resolve calls & anchors:
		var current:Array<ExprDef> = null;
		var replacer:ExprReplacer = function(a:ExprDef, b:ExprDef):Void
		{
			var index = current.indexOf(a);
			var line = getLineOfExpr(model, a);
			trace('resolve::replacer: $index($line) <- $b');
			if(b != null)
			{
				current[index] = b;
				model.lines.set(b, line);
			}
			else
				trace('resolve::replacer: \t \\ CANCEL because null');
		}
		resolveExprs(model, current = kexprs, replacer);
		for(procedure in procedures)
			resolveExprs(model, current = procedure.exprs, replacer);
		trace("RESOLVE COMPLETE");



		function filterVirtuals(expr:ExprDef):Bool
		{
			return !expr.match(ExprVirtual(_));
		}
		function clean():Void
		{
			model.kernel = kexprs = kexprs.filter(filterVirtuals);
			for(proc in procedures)
				proc.exprs = proc.exprs.filter(filterVirtuals);
		}
		clean();
		trace("CLEAN COMPLETE");


		// OUTPUT:
		model.errors = new Map<String, ExprError>();
		buildOutputSource(model);
		trace("RENDER COMPLETE");


		// prepare result:
		var lines = new Map<Int, String>();
		for(expr in model.lines.keys()) switch(expr)
		{
			case Expr(null, _, _, _) | ExprExt(null, _, _, _) | ExprChain(null, _, _): null;
			case Expr(block, _, _, _) | ExprExt(block, _, _, _) | ExprChain(block, _, _):
				lines.set(getLineOfExpr(model, expr), block.att.id);
			default: null;
		}

		trace("RESULT READY");
		return new KernelCompilerResult(model.errors, model.output, lines,
												  [for(b in roots.ignore) (b != null ? b.att.id : continue)]);
	}

	static function buildOutputSource(model:Model):Void
	{
		trace('KERNEL:');
		var output:String = "";
		var kernel = model.kernel;
		var procedures = model.procedures;
		for(i in 0...kernel.length)
		{
			var res = buildBlockString(kernel[i], model.errors);
			var line = getLineOfExpr(model, kernel[i]);
			if(res != null)
				output += '$line $res\n';
			// trace(line + " : " + (res != null ? res : Std.string(kernel[i])));

		}
		for(procedure in procedures)
		{
			trace('PROCEDURE "${procedure.name}":');
			for(i in 0...procedure.exprs.length)
			{
				var res = buildBlockString(procedure.exprs[i], model.errors);
				var line = getLineOfExpr(model, procedure.exprs[i]);
				if(res != null)
					output += '$line $res\n';
				// trace(line + " : " + (res != null ? res : Std.string(procedure.exprs[i])));
			}
		}
		trace(output);
		model.output = output;
	}


	// resolve part //

	static function buildLinesMap(model:Model):Void
	{
		var prevVirtual:ExprDef = null;
		function set(expr, line):Void
		{
			var line_temp = -1;
			if(model.lines.exists(expr) && line != (line_temp = model.lines.get(expr)) && line_temp != -1)
				trace('Dublicate found in lines: ${model.lines.get(expr)} <== ${expr} ($line).');
				// throw 'Dublicate found in lines: ${model.lines.get(expr)} <== ${expr} ($line).';

			switch(expr)
			{
				case Expr(_,_,_,_) | ExprExt(_,_,_,_) | ExprChain(_,_,_) | ExprToDo(_,_,_) | ExprGen(_):
				{
					if(prevVirtual != null)
					{
						model.lines.set(prevVirtual, line);
						prevVirtual = null;
					}
					model.lines.set(expr, line);
					// trace('\t\t SET: $line == ${model.lines.get(expr)}');
				}

				case ExprVirtual(_):
				{
					prevVirtual = expr;
					-1;
				}

				case ExprMulti(_): -1;
			}
		}

		// for each expr in:
		// 	- kernel
		// 	- each procedure

		var step = 10;
		var line = step;
		for(i in 0...model.kernel.length)
		{
			line += step;
			// trace('SET LINE: [$i] <- $line');
			set(model.kernel[i], line);
			// trace('K: SET LINE: [$i] <- ${model.lines.get(model.kernel[i])}');
		}
		for(procedure in model.procedures)
		{
			for(i in 0...procedure.exprs.length)
			{
				line += step;
				set(procedure.exprs[i], line);
				// trace('P: SET LINE: [$i] <- ${model.lines.get(procedure.exprs[i])}');
				if(procedure.line == -1)
					procedure.line = procedure.lineOffset * step + line;
			}
		}
	}

	static function getVirtualExpr(model:Model, id:String):ExprDef
	{
		var searchIn:Array<ExprDef> -> Null<ExprDef>;
		searchIn = function(exprs:Array<ExprDef>)
		{
			trace('searchIn "$id"');
			for(e in exprs) switch(e)
			{
				case ExprVirtual(_ == id => true): trace('founded virt id "$id"'); return e;
				case ExprMulti(lines): return searchIn(lines);
				default: null;
			}

			return null;
		}

		var vexpr = searchIn(model.kernel);

		if(vexpr == null)
			for(proc in model.procedures)
			{
				vexpr = searchIn(proc.exprs);
				if(vexpr != null)
					return vexpr;
			}

		return vexpr;
	}

	static function getLineOfExpr(model:Model, expr:ExprDef):Int
	{
		return model.lines.exists(expr) ? model.lines.get(expr) : -1;
	}

	static function resolveExprs(model:Model, exprs:Array<ExprDef>, replacer:ExprReplacer):Void
	{
		function arrsIsDifferent(a:Array<ExprDef>, b:Array<ExprDef>):Bool
		{
			if(a.length != b.length) return true;
			for(i in 0...a.length)
				if(a[i] != b[i])
					return true;
			return false;
		}

		function dubLine(from:ExprDef, to:ExprDef):Void
		{
			var line = getLineOfExpr(model, from);
			if(line >= 0)
				model.lines.set(to, line);
		}

		for(expr in exprs) switch(expr)
		{
			case ExprGen(_): null;
			case ExprVirtual(id): null;
			case Expr(_, _, null, _): null;
			case ExprExt(_, _, null, _): null;

			case ExprToDo(block, resolver, next):
			{
				// trace('resolving expr for ${block.name}');
				var oline = getLineOfExpr(model, expr);
				var resolved = resolver(model, expr);

				if(next != null)
				{
					var origin = next;
					function _replacer(_, expr:ExprDef):Void next = expr;
					resolveExprs(model, [next], _replacer);
					if(origin != next)
						replacer(expr, ExprChain(block, "", [resolved, next]));
					else
						replacer(expr, resolved);
				}
				else
					replacer(expr, resolved);

				if(oline != -1)
					model.lines.set(resolved, oline);
			}

			case Expr(block, src, next, error):
			{
				// trace('Expr::${block.att.type} "$src" +${(next != null ? 1 : 0)}');
				var oline = getLineOfExpr(model, expr);
				var changed = false;
				var _next = next;
				function _replacer(_, expr:ExprDef):Void { _next = expr; changed = true; }
				resolveExprs(model, [next], _replacer);
				if(changed)
				{
					var resolved = Expr(block, src, _next, error);
					// trace('Expr::resolve::replacer: $next <- $_next');
					replacer(expr, resolved);
					if(oline != -1)
						model.lines.set(resolved, oline);
				}
				if(oline != -1)
					model.lines.set(expr, oline);
			}

			case ExprExt(block, src, next, post):
			{
				// trace('ExprExt::${block.att.type} "$src" +${(next != null ? 1 : 0)}');
				var oline = getLineOfExpr(model, expr);
				var changed = false;
				var _next = next;
				function _replacer(_, expr:ExprDef):Void { _next = expr; changed = true; }
				resolveExprs(model, [next], _replacer);
				if(changed)
				{
					var resolved = ExprExt(block, src, _next, post);
					// trace('ExprExt::resolve::replacer: $next <- $_next');
					replacer(expr, resolved);
					if(oline != -1)
						model.lines.set(resolved, oline);
				}
				if(oline != -1)
					model.lines.set(expr, oline);
			}

			case ExprChain(block, src, _nexts):
			{
				var oline = getLineOfExpr(model, expr);
				// var line = getLineOfExpr(model, expr);
				// trace('ExprChain:: [$line] ${block.att.type} "$src" +${_nexts.length}');

				// trace('ExprChain::${block.att.type} "$src" +${_nexts.length}');
				function _replacer(a:ExprDef, b:ExprDef):Void
				{
					var index = _nexts.indexOf(a);
					// trace('ExprChain::resolve::replacer: ($index) $a <- $b');

					if(b != null)
						_nexts[index] = b;
					else
						trace('ExprChain::resolve::replacer: \t \\ CANCEL because null');
				}
				resolveExprs(model, _nexts, _replacer);

				// line = getLineOfExpr(model, expr);
				// trace('>> ExprChain:: [$line] ${block.att.type} "$src" +${_nexts.length}');

				if(oline != -1)
					model.lines.set(expr, oline);
			}

			case ExprMulti(statements):
			{
				// trace('ExprMulti:: +${statements.length}');
				function _replacer(a:ExprDef, b:ExprDef):Void
				{
					var index = statements.indexOf(a);
					// trace('ExprMulti::resolve::replacer: ($index) $a <- $b');

					if(b != null)
						statements[index] = b;
					else
						trace('ExprMulti::resolve::replacer: \t \\ CANCEL because null');
				}
				resolveExprs(model, statements, _replacer);
			}
		}
	}



	// build part //

	static function getRoots(doc:Xml)
	{
		var roots = [];
		var invalids = [];
		var kernels = 0;
		var kernel = null;

		// trace('getRoots: ${doc != null}');
		if(doc == null || !doc.elements().hasNext())
		{
			trace('bad doc: $doc ');
			log.error(KernelCompilerError.INVALID_SOURCE_INPUT);
			return {kernel:kernel, procedures:roots, ignore:invalids};
		}

		doc = doc.elements().next();

		for(node in doc.elements())
		{
			var block = new Fast(node);
			if(block.name == "block")
			{
				var type = block.att.type;
				trace('type: $type');
				switch(type : BlockType)
				{
					case KERNEL:
						if(++kernels == 1)
							kernel = block;
						else
							invalids.push(block);

					case "procedures_defnoreturn": roots.push(block);
					default: invalids.push(block);
				}
			}
		}

		return {kernel:kernel, procedures:roots, ignore:invalids};
	}

	static function buildKernel(block:Block):Array<ExprDef>
	{
		if(block == null || !block.hasNode.statement)
			return [];

		var statement = block.node.statement;
		if(!hasBlockNode(statement))
			return [Expr(block, null, EmptyBlockStatment(block))];
		var first = getFirstBlockNode(statement);
		trace('buildKernel with first = ${first.att.type}');
		var exprs = buildStatement(first);
		return exprs;
	}

	/**
	  Create a seq of exprs for the specified procedure block.
	  @param block - block of procedure.
	  @param addOverjump - wrap into the jump-to-and.
	  @return Procedure
	**/
	static function buildProcedure(block:Block, addOverjump:Bool):Procedure
	{
		var name = getNamedFieldNode(block, "NAME").innerData;
		var exprs = buildSub(block, false);
		var empty = exprs.length == 0;
		var wrapped = addOverjump;
		var offset = 0;

		// add return:
		exprs.push(ExprGen("return", block, Std.int(Math.random() * 1000)));

		// add GOTO to the end of subroutine:
		if(addOverjump)
		{
			offset = 1;
			wrapIntoOverjump(exprs, block);
		}

		return {name:name, exprs:exprs, line:-1, lineOffset:offset, wrapped:wrapped};
	}

	static function buildSub(sub:Block, addOverjump:Bool):Array<ExprDef>
	{
		var statement = sub.hasNode.statement ? sub.node.statement : null;
		if(statement == null || !statement.hasNode.block)
			// return [Expr(sub, null, EmptyBlockStatment(sub))];
			return [];
		var first = statement.node.block;
		var exprs = buildStatement(first);
		// trace('SUB exprs: $exprs');
		return exprs;
	}

	static function wrapIntoOverjump(exprs:Array<ExprDef>, parrent:Block):Void
	{
		// var rnd = Math.round(Math.random() * 1000 * Math.random());
		// var anchor = ExprVirtual('${parrent.att.id}:overjump-anchor-$rnd');
		var anchor = ExprVirtual(makeVirtualID(parrent, "overjump-anchor", true));
		function resolver(model:Model, expr:ExprDef):ExprDef
		{
			var line = getLineOfExpr(model, anchor);
			return line >= 0 ? ExprGen('goto $line', Std.int(Math.random() * 1000)) : null;
		}
		exprs.unshift(ExprToDo(parrent, resolver));
		exprs.push(anchor);
	}

	static function makeVirtualID(block:Block, ?name:String, randomize = false):String
	{
		if(name == null)
			name = "";
		else
			name = ':$name';
		var rnd = randomize ? "-" + Math.round(Math.random() * 1000 * Math.random()) : "";
		return '${block.att.id}$name' + rnd;
	}

	static function buildStatement(first:Block):Array<ExprDef>
	{
		trace("BUILD STATEMENT: starts from " + first.name + " " + first.att.type);
		var next = first;
		var lines = [];
		while(next != null)
		{
			var expr = buildBlock(next);
			switch(expr)
			{
				case ExprMulti(statements): lines = lines.concat(statements);
				default: lines.push(expr);
			}

			trace('block build complete: ${next.att.type} :: ${haxe.EnumTools.EnumValueTools.getName(expr)}');
			next = if(next.hasNode.next) next.node.next.node.block else null;
		}

		return lines;
	}

	static function buildBlockString(block:ExprDef, errors:Map<String, ExprError>):Null<String>
	{
		var id = null;
		var error = null;
		var result = switch(block)
		{
			case Expr(_, src, next, null): src + (next != null ? buildBlockString(next, errors) : "");
			case Expr(bl, src, next, err):
			{
				error = err;
				id = (bl != null && bl.has.id ? bl.att.id : "");
				"";
			}

			case ExprExt(_, src, next, post): src + buildBlockString(next, errors) + post;
			case ExprChain(_, src, nexts): src + ([for(i in 0...nexts.length) buildBlockString(nexts[i], errors)].join(""));

			case ExprGen(source, _): source;

			case ExprVirtual(id): '{$block}';
			case ExprMulti(statements): '{$block}';
			case ExprToDo(block, resolver, next): null;
		}

		if(error != null)
			errors.set(id, error);

// #if debug
// 		if(error != null)
// 			throw error;
// #end
		return result;




	}

	static function buildBlock(block:Block, exprForm:ExprForm = null, ?wrap:Bool):ExprDef
	{
		if(block == null)
			return Expr(block, null, InvalidInput(block));

		if(exprForm == null)
			exprForm = Default;

		trace("BUILD BLOCK: " + block.att.type);
		var type = block.att.type;
		var expr = switch(type : BlockType)
		{
			// Orb Variables:
			case ORB_VARIABLE_TIMER: buildTimerGetter(block);
			case ORB_VARIABLE_TIMER_SET: buildTimerSetter(block);
			case ORB_VARIABLE_CTRL: Expr(block, "ctrl");
			case ORB_VARIABLE_CTRL_SET: buildInstrictionWithInpit(block, "ctrl =");
			case ORB_VARIABLE_SPEED: Expr(block, "speed");
			case ORB_VARIABLE_YAW: Expr(block, "yaw");
			case ORB_VARIABLE_PITCH: Expr(block, "pitch");
			case ORB_VARIABLE_ROLL: Expr(block, "roll");
			case ORB_VARIABLE_ACCEL: Expr(block, "accel");
			case ORB_VARIABLE_GYRO: Expr(block, "gyro");
			case ORB_VARIABLE_VBATT: Expr(block, "Vbatt");
			case ORB_VARIABLE_SBATT: Expr(block, "Sbatt");
			case ORB_VARIABLE_CMDROLL: Expr(block, "cmdroll");
			case ORB_VARIABLE_SPDVAL: Expr(block, "spdval");
			case ORB_VARIABLE_HDGVAL: Expr(block, "hdgval");
			case ORB_VARIABLE_CMDRGB: Expr(block, "cmdrgb");
			case ORB_VARIABLE_REDVAL: Expr(block, "redval");
			case ORB_VARIABLE_GRNVAL: Expr(block, "grnval");
			case ORB_VARIABLE_BLUVAL: Expr(block, "bluval");
			case ORB_VARIABLE_ISCONN: Expr(block, "isconn");
			case ORB_VARIABLE_DSHAKE: Expr(block, "dshake");
			case ORB_VARIABLE_ACCELONE: Expr(block, "accelone");
			case ORB_VARIABLE_XPOS: Expr(block, "xpos");
			case ORB_VARIABLE_YPOS: Expr(block, "ypos");
			case ORB_VARIABLE_QZERO: Expr(block, "Qzero");
			case ORB_VARIABLE_QONE: Expr(block, "Qone");
			case ORB_VARIABLE_QTWO: Expr(block, "Qtwo");
			case ORB_VARIABLE_QTHREE: Expr(block, "Qthree");
			case ORB_VARIABLE_ABC:
			{
				var field = getNamedFieldNode(block, "NAME");
				var name = field.innerData;
				var error = name == null || name.trim().length == 0 ? InvalidInput(block) : null;
				Expr(block, name, error);
			}
			case ORB_VARIABLE_ABC_SET:
			{
				var field = getNamedFieldNode(block, "NAME");
				var name = field.innerData;
				var error = name == null || name.trim().length == 0 ? InvalidField(block) : null;
				var input = getNamedValueNode(block, "VALUE");
				if(input == null)
				{
					error = error != null ? ComboError([error, InvalidInput(block)]) : InvalidInput(block);
					Expr(block, '$name = ', error);
				}
				else
				{
					var next = buildBlock(input.node.block);
					Expr(block, '$name = ', next, error);
				}
			}
			case "variables_get":
			{
				var field = getNamedFieldNode(block, "VAR");
				var name = field.innerData;
				var error = name == null || name.trim().length == 0 ? InvalidInput(block) : null;
				Expr(block, name, error);
			}
			case "variables_set":
			{
				var field = getNamedFieldNode(block, "VAR");
				var name = field.innerData;
				var error = name == null || name.trim().length == 0 ? InvalidField(block) : null;
				var input = getNamedValueNode(block, "VALUE");
				if(input == null)
					error = error != null ? ComboError([error, InvalidInput(block)]) : InvalidInput(block);
				var next = buildBlock(input.node.block);
				Expr(block, '$name = ', next, error);
			}

			// Orb Functions:

			case ORB_FUNC_DATA: Expr(block, "TODO:ORB_FUNC_DATA");
			case ORB_FUNC_READ: Expr(block, "TODO:ORB_FUNC_READ");
			case ORB_FUNC_RSTR: Expr(block, "rstr");
			case ORB_FUNC_MATH_SQRT: buildInstrictionWithInpit(block, " sqrt");
			case ORB_FUNC_MATH_RND: buildInstrictionWithInpit(block, " rnd");
			case ORB_FUNC_MATH_RANDOM: Expr(block, "random");
			case ORB_FUNC_MATH_ABS: Expr(block, "abs ", getExprByNamedInputNode(block, "VALUE"));
			case ORB_FUNC_DELAY | ORB_FUNC_DELAY_ALT: buildInstrictionWithInpit(block, "delay");
			case ORB_FUNC_RGB:
			{
				var r = getExprByNamedInputNode(block, "R");
				var g = getExprByNamedInputNode(block, "G");
				var b = getExprByNamedInputNode(block, "B");
				ExprChain(block, "RGB ", [r, Expr(block, ",", g), Expr(block, ",", b)]);
			}
			case ORB_FUNC_RGB_ALT:
			{
				var comps = getExprByNamedInputNode(block, "COMPONENTS", ListOfParams);
				Expr(block, "RGB ", comps);
			}
			case ORB_FUNC_LEDC: buildInstrictionWithInpit(block, "LEDC");
			case ORB_FUNC_BACKLED: buildInstrictionWithInpit(block, "backLED");
			case ORB_FUNC_GOROLL_MODE:
			{
				var mode = getNamedFieldNode(block, "MODE").innerData;
				switch(mode)
				{
					case "0" | "1" | "2": Expr(block, mode);
					default: Expr(block, null, InvalidField(block));
				}
			}
			case ORB_FUNC_GOROLL | ORB_FUNC_GOROLL_ALT:
			{
				var heading = getExprByNamedInputNode(block, "HEADING");
				var speed = getExprByNamedInputNode(block, "SPEED");
				var go = getExprByNamedInputNode(block, "GO");
				// var mode = getNamedFieldNode(block, "GO").innerData;
				// var go = switch(mode)
				// {
				// 	case "0" | "1" | "2": Expr(block, mode);
				// 	default: return Expr(block, null, InvalidField(block));
				// }
				ExprChain(block, "goroll ", [heading, Expr(block, ",", speed), Expr(block, ",", go)]);
			}
			case ORB_FUNC_HEADING | ORB_FUNC_HEADING_ALT: buildInstrictionWithInpit(block, "heading");
			case ORB_FUNC_RAW_MODE:
			{
				var mode = getNamedFieldNode(block, "MODE").innerData;
				switch(mode)
				{
					case "0" | "1" | "2" | "3" | "4": Expr(block, mode);
					default: Expr(block, null, InvalidField(block));
				}
			}
			case ORB_FUNC_RAW | ORB_FUNC_RAW_ALT:
			{
				var lmode = getExprByNamedInputNode(block, "Lmode");
				var rmode = getExprByNamedInputNode(block, "Rmode");
				var lspeed = getExprByNamedInputNode(block, "Lspeed");
				var rspeed = getExprByNamedInputNode(block, "Rspeed");
				ExprChain(block, "raw ",
					[
						lmode,
						Expr(block, ",", lspeed),
						Expr(block, ",", rmode),
						Expr(block, ",", rspeed)
					]
				);
			}
			case ORB_FUNC_LOCATE | ORB_FUNC_LOCATE_ALT:
			{
				var x = getExprByNamedInputNode(block, "X");
				var y = getExprByNamedInputNode(block, "Y");
				ExprChain(block, "locate ", [x, Expr(block, ",", y)]);
			}
			case ORB_FLAG_BASFLG: buildInstrictionWithInpit(block, "basflg");


			// Colour:
			// case COLOUR_PICKER | COLOUR_PICKER_COMPONENTS_LIST:
			case COLOUR_PICKER:
			{
				var hex = getNamedFieldNode(block, "COLOUR").innerData;
				// if(hex.startsWith("#"))
				// 	hex = hex.substring(1);
				if(hex.startsWith("#"))
					hex = "0x" + hex.substring(1);
				var rgb = Std.parseInt(hex);
				// var base = haxe.io.Bytes.ofString("0123456789abcdef");
				// var i = new haxe.crypto.BaseCode(base).decodeBytes(haxe.io.Bytes.ofString(hex.toLowerCase()));
				var r = (rgb >> 16) & 0xff;
				var g = (rgb >> 8) & 0xff;
				var b = rgb & 0xff;

				switch(exprForm)
				{
					// e.g.: X = 16711680
					case Default: Expr(block, Std.string(rgb));
					// e.g.: RGB 255,0,0
					case ListOfParams: Expr(block, [r,g,b].join(","));
				}
			}

			case COLOUR_RANDOM: Expr(block, "TODO:COLOUR_RANDOM");
			case COLOUR_RGB:
			{
				var r = getExprByNamedInputNode(block, "RED");
				var g = getExprByNamedInputNode(block, "GREEN");
				var b = getExprByNamedInputNode(block, "BLUE");
				ExprChain(block, "", [r, Expr(block, ",", g), Expr(block, ",", b)]);
			}

			// Color 0-8:
			case COLOUR_PREDEFINED:
			{
				var value = getNamedFieldNode(block, "COLOUR").innerData;
				Expr(block, value);
			}



			// Math:
			case MATH_NUMBER:
			{
				var field = getNamedFieldNode(block, "NUM");
				var value = field.innerData;
				var error = value == null || value.trim().length == 0 ? InvalidField(block) : null;
				if(Std.parseInt(value) < 0)
					value = '(0$value)'; // (0-X)
				Expr(block, value, error);
			}
			case MATH_CHANGE:
			{
				var field = getNamedFieldNode(block, "VAR");
				var variable = field.innerData;
				var input = getNamedValueNode(block, "DELTA");
				var next = buildBlock(input.node.block);
				var error = (input == null || next == null ? InvalidInput(block) : null);
				return Expr(block, '$variable = $variable +', next, error);
			}
			case ANGLE_BLOCK:
			{
				// var input = getExprByNamedInputNode(block, "ANGLE");
				var field = getNamedFieldNode(block, "ANGLE");
				var value = field.innerData;
				var error = value == null || value.trim().length == 0 ? InvalidField(block) : null;
				if(Std.parseInt(value) < 0)
					value = '(0$value)'; // (0-X)
				Expr(block, value, error);
			}
			case MATH_ARITHMETIC:
			{
				// var wrap = ;
				var op = switch(getNamedFieldNode(block, "OP").innerData)
				{
					case "ADD": wrap = true; "+";
					case "SUB" | "MINUS": wrap = true; "-";
					case "DIVIDE": "/";
					case "MULTIPLY": "*";
					case "POWER": return Expr(block, null, NotImplementedFeature(block, "Operator: POWER"));
					default: return Expr(block, null, InvalidField(block));
				}

				// скобочки:
				// 1. проверяем оператор - если * / то
				// 2. проверяем A и B - если они "комбо/арифметические" типа этого => заворачиваем их в скобки!

				var a = getExprByNamedInputNode(block, "A");
				var b = getExprByNamedInputNode(block, "B");

				if(a == null || b == null)
					Expr(block, null, InvalidInput(block));

				// op + B + ")"
				b = wrap ? ExprExt(block, op, b, ")") : Expr(block, op, b);
				// "(" + A + op + B + ")"
				ExprChain(block, (wrap ? "(" : ""), [a, b]);
			}
			case MATH_NUMBER_PROPERTY:
			{
				// TODO: wrap - detect expr is simple or not:
				// var wrap = true;
				var value = getExprByNamedInputNode(block, "NUMBER_TO_CHECK");
				var expr = switch(getNamedFieldNode(block, "PROPERTY").innerData)
				{
					case "EVEN": ExprExt(block, "(", value, ")%2 = 0");
					case "ODD": ExprExt(block, "(", value, ")%2 ! 0");
					case "PRIME": Expr(block, "0");
					case "WHOLE": Expr(block, "1");
					case "POSITIVE": ExprExt(block, "(", value, ")>0");
					case "NEGATIVE": ExprExt(block, "(", value, ")<0");
					default: return Expr(block, null, InvalidField(block));
				}
				expr;
			}

			case MATH_MODULO: null;
			{
				// wrap always:
				var wrap = true;
				var op = "%";
				var a = getExprByNamedInputNode(block, "DIVIDEND");
				var b = getExprByNamedInputNode(block, "DIVISOR");
				if(a == null || b == null)
					Expr(block, null, InvalidInput(block));

				// op + B + ")"
				b = wrap ? ExprExt(block, op, b, ")") : Expr(block, op, b);
				// "(" + A + op + B + ")"
				ExprChain(block, (wrap ? "(" : ""), [a, b]);
			}



			// Logic:
			case LOGIC_COMPARE, LOGIC_COMPARE_MATH:
			{
				var op = getNamedFieldNode(block, "OP").innerData;
				var va = getNamedValueNode(block, "A");
				var vb = getNamedValueNode(block, "B");
				var a = buildBlock(getFirstBlockNode(va));
				var b = buildBlock(getFirstBlockNode(vb));

				op = switch(op)
				{
					case "EQ": "=";  // eq
					case "NEQ": "!"; // neg
					case "HGH": ">"; // >
					case "LOW": "<"; // <
					default: return Expr(block, null, InvalidField(block));
				}

				// trace('LOGIC_COMPARE_MATH: $a $op $b');

				if(a == null || b == null)
					return Expr(block, null, InvalidInput(block));

				if(wrap)
				{
					b = Expr(getFirstBlockNode(vb), op, b);
					// a = ExprExt(getFirstBlockNode(va), buildBlockString(a), b, ")");
					a = ExprExt(getFirstBlockNode(va), "", ExprChain(block, "", [a, b]), ")");
					Expr(block, "(", a);
				}
				else
				{
					b = Expr(getFirstBlockNode(vb), op, b);
					ExprChain(block, "", [a, b]);
				}
			}
			case LOGIC_OPERATION:
			{
				var a = getExprByNamedInputNode(block, "A");
				var b = getExprByNamedInputNode(block, "B");
				var opv = switch(getNamedFieldNode(block, "OP").innerData)
				{
					case "OR": "or";
					case "AND": "and";
					default: return Expr(block, null, InvalidField(block));
				}

				a = ExprExt(block, "(", a, ")");
				b = ExprExt(block, "(", b, ")");
				var op = Expr(block, opv);
				ExprChain(block, "", [a, op, b]);
			}
			case LOGIC_NEGATE:
			{
				var vbool = getNamedValueNode(block, "BOOL");
				if(!hasBlockNode(vbool))
					return Expr(block, null, InvalidInput(block));

				var bbool = getFirstBlockNode(vbool);
				var boolean = buildBlock(bbool);
				// TODO: wrap = isComplexExpr(boolean)
				var wrap = true;
				if(wrap)
					boolean = ExprExt(bbool, "(", boolean, ")");
				// result: ((V) == 0)
				ExprExt(block, "(", boolean, "=0)");
			}
			case LOGIC_BOOLEAN:
			{
				var boolean = getNamedFieldNode(block, "BOOL");
				if(boolean == null)
					return Expr(block, null, InvalidField(block));

				var value = switch(boolean.innerData)
				{
					case "TRUE": 1;
					case "FALSE": 0;
					default: return Expr(block, null, InvalidField(block));
				}
				Expr(block, Std.string(value));
			}

			// Statements-Blocks: Logic:
			case CONTROLS_IF: buildIf(block);


			// Flow:
			case ORB_END: Expr(block, "end");
			case ORB_RETURN: Expr(block, "return");
			case ORB_RESET: Expr(block, "reset");
			case ORB_FUNC_SLEEP: Expr(block, "TODO:SLEEP");

			// Flow: Jumps:
			case ORB_ANCHOR: ExprVirtual(makeVirtualID(block));
			case ORB_ANCHOR_ID: // | ORB_ANCHOR_VALUE:
			{
				var id = getMutationValue(block, "name");
				var uid = getMutationValue(block, "target");

				function resolver(model:Model, expr:ExprDef):ExprDef
				{
					trace('resolve: search ANCHOR_ID named "$id" ($uid)');
					// 1. search ExprVirtual(id) with same `id`
					// var anchor = getVirtualExpr(model, id);
					var anchor = getVirtualExpr(model, uid);

					if(anchor == null)
						return Expr(block, null, InvalidCall(block));

					// 2. get its line
					var line = getLineOfExpr(model, anchor);
					// 3. return Expr GOSUB to the line
					return Expr(block, '$line');
				}
				ExprToDo(block, resolver);
			}
			case ORB_JUMP:
			{
				var anchor = getExprByNamedInputNode(block, "ANCHOR");
				Expr(block, "goto ", anchor);
			}
			case ORB_GOSUB:
			{
				var anchor = getExprByNamedInputNode(block, "ANCHOR");
				Expr(block, "gosub ", anchor);
			}
			// Flow: Switches:
			case ORB_JUMP_INDEXED:
			{
				var expr = getExprByNamedInputNode(block, "VAR");
				var count = {
					var str = getMutationValue(block, "anchors");
					if(str == null) 0;
					else Std.parseInt(str);
				}
				var anchors = if(count <= 0) [];
				else [for(i in 0...count)
				{
					var x = i == 0 ? i : i + 1; // 1-based indexing
					var e = getExprByNamedInputNode(block, 'ANCHOR$x');
					if(i != 0)
						e = Expr(block, ",", e);
					e;
				}];

				ExprChain(block, "on ", [expr, ExprChain(block, " goto ", anchors)]);
			}
			case ORB_GOSUB_INDEXED:
			{
				var expr = getExprByNamedInputNode(block, "VAR");
				var count = {
					var str = getMutationValue(block, "anchors");
					if(str == null) 0;
					else Std.parseInt(str);
				}
				var anchors = if(count <= 0) [];
				else [for(i in 0...count)
				{
					var x = i == 0 ? i : i + 1; // 1-based indexing
					var e = getExprByNamedInputNode(block, 'ANCHOR$x');
					if(i != 0)
						e = Expr(block, ",", e);
					e;
				}];

				ExprChain(block, "on ", [expr, ExprChain(block, " gosub ", anchors)]);
			}

			case CONTROLS_FOR:
			{
				var variable = getExprByNamedInputNode(block, "VAR");
				var from = getExprByNamedInputNode(block, "FROM");
				var to = getExprByNamedInputNode(block, "TO");
				var step = getExprByNamedInputNode(block, "BY");
				var statements = if(!block.hasNode.statement || !hasBlockNode(block.node.statement))
					return Expr(block, null, EmptyBlockStatment(block));
				else buildStatement(getFirstBlockNode(block.node.statement));

				// build header & finish:
				from = Expr(block, "=", from);
				to = Expr(block, " to ", to);
				step = Expr(block, " step ", step);
				var header = ExprChain(block, "for ", [variable, from, to, step]);
				var finish = Expr(block, "next ", variable);

				statements.unshift(header);
				statements.push(finish);
				ExprMulti(statements);
			}
			case CONTROLS_FOR_SIMPLE:
			{
				var variable = getExprByNamedInputNode(block, "VAR");
				var from = getExprByNamedInputNode(block, "FROM");
				var to = getExprByNamedInputNode(block, "TO");
				var statements = if(!block.hasNode.statement || !hasBlockNode(block.node.statement))
					return Expr(block, null, EmptyBlockStatment(block));
				else buildStatement(getFirstBlockNode(block.node.statement));

				// build header & finish:
				from = Expr(block, "=", from);
				to = Expr(block, " to ", to);
				var header = ExprChain(block, "for ", [variable, from, to]);
				var finish = Expr(block, "next ", variable);

				statements.unshift(header);
				statements.push(finish);
				ExprMulti(statements);
			}


			// Procedures:
			case "procedures_callnoreturn":
			{
				var name = getMutationValue(block, "name");
				function resolver(model:Model, expr:ExprDef):ExprDef
				{
					// trace('resolve: search procedure named "$name"');
					// 1. search procedures_defnoreturn with same `name`
					var procedure = {
						var result = null;
						for(p in model.procedures)
							if(p.name == name)
								result = p;
						result;
					}

					if(procedure == null)
						return Expr(block, null, InvalidCall(block));

					// 2. get its line
					var line = procedure.line;
					// 3. return Expr GOSUB to the line
					return Expr(block, 'gosub $line');
					// return Expr(block, null, NotImplementedFeature(block, "call subroutines"));
				}

				ExprToDo(block, resolver);
			}

			default:
			{
				trace("UnknownBlock: " + type);
				Expr(block, null, UnknownBlock(block));
			}
		}




		// FIXME: for DEBUG only:
		// trace('BLOCK: $type -> $expr');
		// trace('BLOCK: $type -> ${buildBlockString(expr)}');

		return expr;
	}

	static function buildInstrictionWithInpit(block:Block, name:String, ?inp:String):ExprDef
	{
		var expr = null;
		// get value node with block:
		var inputV = getNamedValueNode(block, inp);
		if(inputV == null || !inputV.hasNode.block)
		{
			// get field node with value:
			var inputF = getNamedFieldNode(block, inp);
			if(inputF == null)
				return Expr(block, '$name ', InvalidInput(block));

			expr = Expr(block, '$name ${inputF.innerData}');
		}
		else
		{
			var next = buildBlock(inputV.node.block);
			expr = Expr(block, '$name ', next);
		}

		// if(input == null)
		// 	// error = error != null ? ComboError([error, InvalidInput(block)]) : InvalidInput(block);
		// 	return Expr(block, '$name ', error != null ? ComboError([error, InvalidInput(block)]) : InvalidInput(block));

		return expr;
	}


	// ----- block - utils ----- //

	/**
	  Finds the first field with a given name.

	  @param block - Block node
	  @param name - The field name
	  @return `Null<Field>` - The first field with that name or `Null`
	**/
	static function getNamedFieldNode(block:Block, ?name:String):Null<Field>
	{
		var fields = block.nodes.field;
		// trace('getNamedFieldNode():: fields: ' + [for(f in fields) '(${f.att.name}=${f.innerData})']);
		if(name != null)
			fields = fields.filter(function(f:Field) return f.att.name == name);
		// trace('getNamedFieldNode():: field=> ' + (fields.isEmpty() ? null : fields.first().att.name));
		return fields.first();
	}

	static function getNamedValueNode(block:Block, ?name:String):ValueNode
	{
		var values = block.nodes.value;
		if(name != null)
			values = values.filter(function(f:ValueNode) return f.att.name == name);
		return values.first();
	}

	/** Returns `Expr` by founded Value- or Field- node in the `block`. **/
	static function getExprByNamedInputNode(block:Block, name:String, exprForm:ExprForm = null):ExprDef
	{
		var expr = null;
		// get value node with block:
		var inputV = getNamedValueNode(block, name);
		// if(inputV == null || !inputV.hasNode.block)
		if(!hasBlockNode(inputV))
		{
			// get field node with value:
			var inputF = getNamedFieldNode(block, name);
			if(inputF == null)
				return Expr(block, null, InvalidInput(block));

			expr = Expr(block, inputF.innerData);
		}
		else
			// expr = buildBlock(inputV.node.block);
			expr = buildBlock(getFirstBlockNode(inputV), exprForm);

		return expr;
	}

	static function hasBlockNode(node:Fast):Bool
	{
		return node != null && (node.hasNode.block || node.hasNode.shadow);
	}

	/**
	  Returns first `block` or `shadow` node founded in the `node`.
	  @param node - should contain a `block` or `shadow` node.
	  @return Block or `null`.
	**/
	static function getFirstBlockNode(node:Fast):Null<Block>
	{
		if(node == null) return null;
		return node.hasNode.block ? node.node.block : (node.hasNode.shadow ? node.node.shadow : null);
	}

	/** Get and return `block.mutation.@attr` value. **/
	static function getMutationValue(block:Block, attr:String):Null<String>
	{
		var mutations = block.nodes.mutation;
		mutations = mutations.filter(function(m) return m.has.resolve(attr));
		return mutations.isEmpty() ? null : mutations.first().att.resolve(attr);
	}


	// ---- block-specified ---- //

	static function buildTimerGetter(block:Block):ExprDef
	{
		var prop = "timer";
		var name = getNamedFieldNode(block, "TIMER").innerData;
		var error = switch(name)
		{
			case "A": null;
			case "B": null;
			case "C": null;
			default: InvalidField(block);
		}
		return Expr(block, prop + name, error);
	}

	static function buildTimerSetter(block:Block):ExprDef
	{
		var prop = "timer";
		var name = getNamedFieldNode(block, "TIMER").innerData;
		var error = switch(name)
		{
			case "A": null;
			case "B": null;
			case "C": null;
			default: InvalidField(block);
		}
		var value = getExprByNamedInputNode(block, "VALUE");
		value = Expr(block, " = ", value);
		return Expr(block, prop + name, value, error);
	}

	static function buildIf(block:Block):ExprDef
	{
		// var statement = block.nodes.value.filter(function(v:Block) return v.att.name == "IF0").first();

		// build statement - input:
		var input = getNamedValueNode(block, "IF0");
		if(input == null) return Expr(block, null, InvalidInput(block));

		var statement = input.node.block;
		var expr = buildBlock(statement);
		// trace('statement: ${statement.att.type} -> $expr');

		// TODO: use `hasElse`
		var hasElse = getMutationValue(block, "else") == "1";


		// build DO body:
		var bodyDoFirst = null;
		var bodyElseFirst = null;
		var bodies = block.nodes.statement;
		for(s in bodies) switch(s.att.name)
		{
			case "DO0": if(hasBlockNode(s)) bodyDoFirst = getFirstBlockNode(s);
			case "ELSE": if(hasBlockNode(s)) bodyElseFirst = getFirstBlockNode(s);
			default: continue;
		}

		trace("BUILDING IF DO ELSE...");
		var exprsDO = (bodyDoFirst != null ? buildStatement(bodyDoFirst) : null);
		var exprsELSE = (bodyElseFirst != null ? buildStatement(bodyElseFirst) : null);

		if(exprsDO == null || exprsDO.length == 0)
			return Expr(block, null, EmptyBlockStatment(block));

		if(hasElse && (exprsELSE == null || exprsELSE.length == 0))
			return Expr(block, null, EmptyBlockStatment(block));


		trace('IF ? EXPR: ${buildBlockString(expr, new Map())}');
		trace('IF DO exprs: ${buildBlockString(exprsDO[0], new Map())}');
		trace('IF ELSE exprs: ${buildBlockString(exprsELSE[0], new Map())}');


		function createVirtualSub(exprs:Array<ExprDef>, name:String):{enter:ExprDef, body:ExprDef}
		{
			trace("CREATE_VIRTUAL_SUB: " + exprs.length);

			var enter = ExprVirtual(makeVirtualID(block, '$name-anchor', true));
			exprs.unshift(enter);
			exprs.push(ExprGen("return", block, Std.int(Math.random() * 1000)));
			wrapIntoOverjump(exprs, block);

			// build enter-point & gosub:
			function resolver(model:Model, expr:ExprDef):ExprDef
			{
				trace('IF resolve:: $enter');
				var line = getLineOfExpr(model, enter);
				trace('IF resolve.line:: $line');
				return line >= 0 ? ExprGen('gosub $line', block, Std.int(Math.random() * 1000)) : null;
			}
			var jump = ExprToDo(block, resolver);
			return {enter:jump, body:ExprMulti(exprs)};
		}

		function isSubroutineNeeded(exprs:Array<ExprDef>):Bool
		{
			if(exprs == null || exprs.length == 0) return false;

			var multis = [CONTROLS_IF, CONTROLS_FOR, CONTROLS_FOR_SIMPLE];

			return if(exprs.length == 1) switch(exprs[0])
			{
				case Expr(_.att.type => ORB_JUMP, _,_,_): false;
				case Expr(_.att.type => ORB_JUMP_INDEXED, _,_,_): false;
				case Expr(_.att.type => ORB_GOSUB, _,_,_): false;
				case Expr(_.att.type => ORB_GOSUB_INDEXED, _,_,_): false;

				// case Expr(_.att.type => type, _,_,_): multis.indexOf(type) >= 0;
				// case ExprExt(_.att.type => type, _,_,_): multis.indexOf(type) >= 0;
				// case ExprChain(_.att.type => type, _,_): multis.indexOf(type) >= 0;
				// case ExprToDo(_.att.type => type, _): multis.indexOf(type) >= 0;

				case Expr(_.att.type => type, _,_,_)    |
					  ExprExt(_.att.type => type, _,_,_) |
					  ExprChain(_.att.type => type, _,_) |
					  ExprToDo(_.att.type => type, _): multis.indexOf(type) >= 0;

				// case Expr(_.att.type => CONTROLS_IF, _,_,_): true;
				// case Expr(_.att.type => CONTROLS_FOR, _,_,_): true;
				// case Expr(_.att.type => CONTROLS_FOR_SIMPLE, _,_,_): true;


				default: false;
			}
			else true;
		}
		var exprsDoIsNotSimple = isSubroutineNeeded(exprsDO);
		var exprsElseIsNotSimple = isSubroutineNeeded(exprsELSE);

		trace("DO is MULTI: " + exprsDoIsNotSimple + ' == ${exprsDO.length > 1}');
		trace("ELSE is MULTI: " + exprsElseIsNotSimple + ' == ${exprsELSE != null ? Std.string(exprsELSE.length > 1) : "null"}');
		// return Expr(block, 'if TODO');



		// THEN: gosub here or get first one:
		// var exprDO = exprsDO.length > 1 ? createVirtualSub(exprsDO, "DO") : exprsDO[0];
		var bodyDO = null;
		var exprDO = if(exprsDoIsNotSimple)
		{
			var sub = createVirtualSub(exprsDO, "DO");
			bodyDO = sub.body;
			sub.enter;
		}
		else exprsDO[0];
		// trace('exprDO = ${exprDO} := ${buildBlockString(exprDO)}');
		var exprTHEN = Expr(block, " then ", exprDO);


		// ELSE: gosub here or get first one:
		var bodyELSE = null;
		var exprELSE = if(hasElse)
		{
			var enter = if(exprsElseIsNotSimple)
			{
				var sub = createVirtualSub(exprsELSE, "ELSE");
				bodyELSE = sub.body;
				sub.enter;
			}
			else exprsELSE[0];
			Expr(block, " else ", enter);
		}
		else null;


		// build header - if expr:
		var header = if(!hasElse || exprELSE == null)
			ExprChain(block, 'if ', [expr, exprTHEN]);
		else
			ExprChain(block, 'if ', [expr, exprTHEN, exprELSE]);

		// trace('HEADER: $header\n\t\t\\_ ${buildBlockString(header)}');


		var result = null;
		result = if(bodyDO != null)
			ExprMulti(bodyELSE == null ? [header, bodyDO] : [header, bodyDO, bodyELSE]);
		// {
		// 	if(bodyELSE == null)
		// 		ExprMulti([header, bodyDO]);
		// 	else
		// 		ExprMulti([header, bodyDO, bodyELSE]);
		// }
		else header;

		return result;
	}
}

private enum ExprDef
{
	Expr(block:Block, source:String, ?next:ExprDef, ?error:ExprError);
	ExprExt(block:Block, source:String, ?next:ExprDef, post:String);
	ExprChain(block:Block, source:String, nexts:Array<ExprDef>);
	ExprToDo(block:Block, resolver:ExprResolver, ?next:ExprDef);

	/** Multiline Expr **/
	ExprMulti(exprs:Array<ExprDef>);

	ExprGen(source:String, ?block:Block, ?rnd:Int);
	/** Pointing to the next line. **/
	ExprVirtual(id:String);
}

private typedef ExprResolver = Model -> ExprDef -> ExprDef;
// private typedef ExprReplacer = Array<ExprDef> -> ExprDef -> ExprDef -> Void;
private typedef ExprReplacer = ExprDef -> ExprDef -> Void;


// private typedef Expr =
// {
// 	var block:Fast;
// 	var source:String;
// 	@:optional var var next:Expr;
// 	@:optional var error:ExprError;
// }
// private typedef ExprForResolve =
// {
// 	< Expr,
// 	var resolved:Bool;
// 	var resolver:{} -> ExprForResolve -> Void;
// }

enum ExprForm
{
	Default;
	ListOfParams;
}


enum ExprError
{
	UnknownBlock(block:Block);
	InvalidDataType(message:String);
	// InvalidBlockStatment(block:Block, message:String);
	EmptyBlockStatment(block:Block);

	InvalidField(parrent:Block);
	InvalidInput(parrent:Block);
	ComboError(errors:Array<ExprError>);

	/** When we can't resolve it. E.g. ProcedureDef not found. **/
	InvalidCall(block:Block);
	NotImplementedFeature(block:Block, message:String);
}

typedef Block = Fast;
typedef Field = Fast;
typedef ValueNode = Fast;


typedef Procedure =
{
	/** Placement (position) of `this` subroutine. **/
	var line:Int;
	/** Placement offset for __internal__ use. **/
	var lineOffset:Int;
	/** True if have jump-to-end as first expr. **/
	var wrapped:Bool;

	var name:String;
	var exprs:Array<ExprDef>;
}


typedef Model =
{
	var kernel:Array<ExprDef>;
	var procedures:Array<Procedure>;

	// var lines:Map<Int, ExprDef>;
	var lines:LinesMap;

	var errors:Map<String, ExprError>;
	var output:Null<String>;
}

typedef LinesMap = haxe.ds.EnumValueMap<ExprDef, Int>;
