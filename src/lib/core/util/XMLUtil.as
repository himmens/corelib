package lib.core.util
{
public class XMLUtil
{
	/**
	 * Преобразует xml в объект, где аттрибуты - поля объекта
	 */
	public static function toObject(xml:XML):Object
	{
		var object:Object = {};
		//Аттрибуты преобразуем в свойства объекта
		for each (var attr:XML in xml.@*)
		{
			var attrName:String = attr.name();
			var attrValue:String = attr.toString();
			object[attrName] = attrValue;
		}
		return object;
	}
}
}