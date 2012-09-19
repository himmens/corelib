package lib.core.util.log
{
public interface ILoggerTarget
{
   function internalLog( message:String , level:int ):void
   
   function set active(value:Boolean):void;
   function get active():Boolean;
}
}