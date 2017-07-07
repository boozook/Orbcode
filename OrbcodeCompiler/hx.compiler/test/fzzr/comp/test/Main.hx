package fzzr.comp.test;

import haxe.unit.TestRunner;


/**
	Created by Alexander "fzzr" Kozlovskij
**/
class Main
{
	public static function main():Void
	{
		var runner = new TestRunner();
		// runner.add(new BlocksTest());

		var cases = [
			"case1",
			"case2",
			"case3",
			"case4",
			"anchors",
			"prog1",
			"invalid-inpts",
			"ignored",
		];
		for(id in cases)
			runner.add(new FullTest(id));
		// runner.add(new FullTest(cases[7]));

		var success = runner.run();
#if sys
		Sys.exit(success ? 0 : 1);
#elseif flash
		flash.system.System.exit(success ? 0 : 1);
#end
	}
}
