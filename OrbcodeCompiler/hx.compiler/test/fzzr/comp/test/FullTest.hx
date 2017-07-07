package fzzr.comp.test;

import haxe.unit.TestCase;

import fzzr.comp.KernelCompiler;


/**
	Created by Alexander "fzzr" Kozlovskij
 **/
class FullTest extends TestCase
{
	var id:String;
	var source:String;

	public function new(sourceId:String):Void
	{
		id = sourceId;
		super();
	}

	override function setup():Void
	{
		source = haxe.Resource.getString(id);
	}

	function testInitial()
	{
		var result = KernelCompiler.build(source);
		assertTrue(result != null);
		assertTrue(result.errors != null);

		for(k in result.errors.keys())
			trace('ERROR: $k - "${err3str(result.errors.get(k))}"');
	}

	function err3str(err:ExprError):String return Type.enumConstructor(err) + switch(err)
	{
		case UnknownBlock(block): block != null ? '[${block.att.type} ${block.att.id}]' : 'null';
		case InvalidDataType(message): message;
		case EmptyBlockStatment(block): block != null ? '[${block.att.type} ${block.att.id}]' : 'null';

		case InvalidField(block): block != null ? '[${block.att.type} ${block.att.id}]' : 'null';
		case InvalidInput(block): block != null ? '[${block.att.type} ${block.att.id}]' : 'null';
		case ComboError(errors): [for(e in errors) err3str(e)].join(", ");

		case InvalidCall(block): block != null ? '[${block.att.type} ${block.att.id}]' : 'null';
		case NotImplementedFeature(block, message): (block != null ? '[${block.att.type} ${block.att.id}]' : 'null');
	}
}
