package lib.core.util
{
import flash.net.getClassByAlias;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.describeType;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

public class ObjectUtil
{

	/**
	 * Копирует свойста одного обеъкта в другой.
	 *
	 * @param object
	 * @param properties
	 * @param checkProperty
	 *
	 */
	public static function copyProps(object:Object, properties:Object, checkProperty:Boolean = false):Object
	{
		for (var i:String in properties)
		{
			if(checkProperty && !object.hasOwnProperty(i))
				continue;

			object[i] = properties[i];
		}
		return object;
	}

	/**
     *  Copies the specified Object and returns a reference to the copy.
     *  The copy is made using a native serialization technique.
     *  This means that custom serialization will be respected during the copy.
	 *
	 * @param value
	 * @return
	 *
	 */
	public static function copy(value:Object):Object
	{
		if (!value)
			return null;

		//регистрируем класс объекта копирования, чтобы работало приведение к классу объекта
		registerClassAlias(getQualifiedClassName(value), value.constructor);

		var buffer:ByteArray = new ByteArray();
		buffer.writeObject(value);
		buffer.position = 0;
		var result:Object = buffer.readObject();
		return result;
	}

	/**
	 * Конвертируем тип Object в тип Array, копируя все свойства.
	 * Метод нужен для отправки amf на C++ сервер, где не поддерживается тип Object (СЕРВЕР ПРИВЕД!)
	 * @param value
	 * @param recursive рекурсивно перевести в массивы
	 * @return
	 *
	 */
	public static function toArray(value:Object, recursive:Boolean = false):Array
	{
		var arr:Array = [];
		ObjectUtil.copyProps(arr, value, false);
		if(recursive)
			for (var name:String in arr)
			{
				//массив чего-то, проверяем каждый элемент массива
				if(arr[name] is Array)
				{
					for(var i:int=0; i<arr[name].length; i++)
						if(typeof arr[name][i] == "object")
							arr[name][i] = toArray(arr[name][i], true);
				}
				//объект, переводим в массив
				else if(!(arr[name] is Array) && (typeof arr[name] == "object"))
					arr[name] = toArray(value[name], true);

			}
		return arr;
	}
	
	/**
	 * Получение имени свойства по значению свойства. 
	 *  
	 * @param object объект, в котором будет происходить поиск.
	 * @param value значение свойства.
	 * 
	 * @return найденное имя свойства.
	 */	
	public static function getPropNameByValue(object:Object, value:*):String
	{
		var result:String = "";
		
		for (var propName:String in object)
		{
			if(object[propName] == value)
			{
				result = propName;
				break;
			}
		}
		
		return result;
	}
	
	/**
	 * Получение имени свойства по значению внутреннего свойства. 
	 *  
	 * @param object объект, в котором будет происходить поиск.
	 * @param insidePropName название внутреннего свойства.
	 * @param value значение свойства.
	 * 
	 * @return найденное имя свойства.
	 */	
	public static function getPropNameByInsidePropValue(object:Object, insidePropName:String, value:*):String
	{
		var result:String = "";
		
		var insideProp:Object;
		for (var propName:String in object)
		{
			insideProp = object[propName]; 
			if(insideProp && insideProp.hasOwnProperty(insidePropName) && insideProp[insidePropName] == value)
			{
				result = propName;
				break;
			}
		}
		
		return result;
	}

	/**
	 * возвращает размер объекта в байтах
	 * @param value
	 * @return
	 *
	 */
	public static function sizeOf(value:Object):int
	{
		if(!value)
			return 0;

		var bytes:ByteArray = new ByteArray();
		bytes.writeObject(value);
		var size:int = bytes.length;
		return size;
	}
	
	/**
	 * возвращает класс объекта
	 * @param target
	 */
	public static function getClass(target:Object):Class
	{
		return getDefinitionByName(getQualifiedClassName(target)) as Class;
	}

	/**
	 * Возвращает список имет свойст статического объекта использую as3 reflection api (describeType)
	 *  
	 * @param obj
	 * @param excludes список имен исключений
	 * @param sortOnPos сортировать в порядке, в котором свойства перечислены в коде
	 * @return 
	 * 
	 */
	public static function getPropertyList(obj:Object, excludes:Array = null, sortOnPos:Boolean = false):Array
	{
		var result:Array = [];
		var tmp:Array = [];
		
		var xml:XML = describeType(obj);
		var vars:XMLList = xml.variable;
		var name:String;
		
		var exclMap:Object = {};
		for each(name in excludes)
			exclMap[name] = true;
			
		for each(var node:XML in vars)
		{
			name = String(node.@name[0]);
			if(!exclMap[name])
			{
				sortOnPos ? 
					tmp.push({index:int(node.metadata.arg.(@key == "pos").@value[0]), name:name})
				:
				result.push(name);
			}
		}
		
		if(sortOnPos)
		{
			tmp.sortOn("index", Array.NUMERIC);
			for each(var obj:Object in tmp)
				result.push(obj.name);
		}
		
		return result;
	}
}

}