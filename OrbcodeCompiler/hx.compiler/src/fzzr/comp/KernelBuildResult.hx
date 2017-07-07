package fzzr.comp;


@:structInit
@:keep class KernelBuildResult
{
  public var src:String;
  // n: line number, n+1: uuid
  // public var lines:Array<EitherType<Int, String>>;
  public var lines:Array<String>;
  // n: uuid, n+1: error
  public var errors:Array<String>;

  // contains uuid only
  public var ignores:Array<String>;
  public var cerrors:Array<String>;
  public var cinfos:Array<String>;
}
