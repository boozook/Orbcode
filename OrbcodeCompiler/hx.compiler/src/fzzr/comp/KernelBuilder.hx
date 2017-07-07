package fzzr.comp;

import fzzr.comp.KernelCompiler;

using StringTools;

@:keep class KernelBuilder
{
	public static function build(src:String):KernelBuildResult
	{
		var result = KernelCompiler.build(src);
		var lines = [];
		var errors = [];
		for(uuid in result.errors.keys())
		{
			errors.push(uuid);
			errors.push(errorToString(result.errors.get(uuid)));
		}
		for(l in result.lines.keys())
		{
			lines.push(Std.string(l));
			lines.push(result.lines.get(l));
		}

		return {
			src: result.source.trim(),
			errors: errors,
			lines: lines,
			ignores:result.ignores,
			cerrors:result.cerrors,
			cinfos:result.cinfos,
		};
	}

	static function errorToString(err:ExprError):String
	{
		return "trouble description: " + Std.string(err);
	}
}

