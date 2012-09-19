package lib.core.util
{

public class ArrayUtils
{
	// Строка, которая будет использоваться для разделения массивов на строки и собирания из строк массива
	static private const SPLIT_TEXT:String = "!--my-split-code--!";
	// Константа, которая будет использоваться, когда нужно будет удалить все элементы массива
	static private const REMOVE_COUNT_ALL:int = -1;


	/**
	 * Индексируем массив объектов по уникальному полю uniqueKeyProperty.
	 * Если значение uniqueKeyProperty совпадают, индекс получится хуевый (проверок нет)
	 *
	 * @param array
	 * @param uniqueKeyProperty
	 * @param valueProperty если передать в значение впишется свойство объекта вместо самого объекта
	 * @return hash по uniqueKeyProperty
	 */
	public static function map (array:Array, uniqueKeyProperty:String, valueProperty:String = null):Object
	{
		var res:Object = {};
		for each (var o:Object in array)
		{
			if (o.hasOwnProperty(uniqueKeyProperty))
				res[o[uniqueKeyProperty]] = valueProperty && valueProperty in o ? o[valueProperty] : o;
		}
		return res;
	}

	/**
	 * картируем массив объектов по полю keyProperty.
	 * на каждыйключ создается массив объектов
	 *
	 * @param array
	 * @param uniqueKeyProperty
	 * @return hash по uniqueKeyProperty
	 *
	 */
	public static function multiMap (array:Array, keyProperty:String):Object
	{
		var res:Object = {};
		var arr:Array;
		for each (var o:Object in array)
		{
			if (o.hasOwnProperty(keyProperty)) {
				arr = res[o[keyProperty]];
				if(!arr)
					arr = res[o[keyProperty]] = [];
				arr.push(o);
			}
		}

		return res;
	}

	/**
	 * Объединяет два массива с определенного индекса.
	 * Пример:
	 * 	source = [1, 2, 3]
	 * 	startIndex = 1
	 * 	insArray = ["a", "b", "c"]
	 *
	 * return = [1, "a", "b", "c", 2, 3]
	 *
	 * @param source
	 * @param startIndex
	 * @param insArray
	 * @return
	 *
	 */
	public static function spliceArrays(source:Array, startIndex:int, insArray:Array):Array
	{
		for each(var obj:Object in insArray)
		{
			source.splice(startIndex++, 0, obj);
		}

		return source;
	}

	/**
	 * Ищем индекс элемента в коллеции по id.
	 * @param source
	 * @param id
	 * @param idName - имя поля ключа, default "id"
	 * @return
	 *
	 */
	public static function getIndexById(source:Array, id:String, idName:String = "id"):int
	{
		if(!source)
			return -1;

		var item:Object;
		for (var i:int=0; i<source.length; i++)
		{
			item = source[i];
			if(item.hasOwnProperty(idName) && item[idName] == id)
				return i;
		}

		return -1;
	}

	/**
	 * Ищем индекс элемента в коллеции по значению указанного свойства.
	 * @param source
	 * @param property
	 * @param propertyValue
	 * @return
	 *
	 */
	public static function getIndexByPropertyValue(source:Array, property:String, propertyValue:Object):int
	{
		if(!source)
			return -1;

		var item:Object;
		for (var i:int=0; i<source.length; i++)
		{
			item = source[i];
			if(item.hasOwnProperty(property) && item[property] == propertyValue)
				return i;
		}

		return -1;
	}

	/**
	 * Ищем элемент в коллеции по значению указанного свойства.
	 * @param source
	 * @param property
	 * @param propertyValue
	 * @return
	 *
	 */
	public static function getElementByPropertyValue(source:Array, property:String, propertyValue:Object):Object
	{
		if(!source)
			return null;

		var res:Object;
		for (var i:int=0; i<source.length; i++)
		{
			var item:Object = source[i];
			if((property in item) && item[property] == propertyValue) {
				res = item;
				break;
			}
		}
		return res;
	}

	/**
	 * Сравнивает два массива по id объектов - есть ли разные обьекты.
	 *
	 * @param arr1
	 * @param arr2
	 * @param keyProperty
	 * @return true если разница есть, false если оба массива состоят из объектов с одинаковыми id,
	 * без проверки индексов в массиве.
	 *
	 */
	public static function compare(arr1:Array, arr2:Array, keyProperty:String):Boolean
	{
		//оба массива null
		if(arr1 == null && arr2 == null)
			return false;

		//Один из массивов null
		if(! (arr1 && arr2))
			return true;

		//проверяем, что массив изменился
		var diff:Boolean = arr1.length != arr2.length;

		if(!diff)
		{
			var obj:Object;
			var keys:Array = [];
			for each(obj in arr1)
			{
				keys[keys.length] = obj[keyProperty];
			}

			for each(obj in arr2)
			{
				if(keys.indexOf(obj[keyProperty]) == -1)
				{
					diff = true;
					break;
				}
			}
		}

		return diff;
	}

	/**
	 * Выборка случайных элементов из массива
	 *
	 * @param arr Исходный массив
	 * @param number Количество выбираемых элементов
	 * @param except Массив элементов, которые не выбираем из исходного массива
	 * @param unique Выборка уникальных элементов из исходного массива
	 */
	public static function getRandomItems(arr:Array, number:uint, except:Array=null, unique:Boolean=true) : Array
	{
		var res:Array = [];
		var arrCopy:Array = arr.slice();

		var i:int = 0;
		if (except)
		{
			for(i=0; i<except.length; i++)
			{
				var index:int = arrCopy.indexOf(except[i]);
				if (index != -1)
					arrCopy.splice(index, 1);
			}
		}

		while (res.length < number && arrCopy.length > 0)
		{
			i = Math.floor(arrCopy.length*Math.random());
			res.push(arrCopy[i]);
			if (unique)
				arrCopy.splice(i, 1);
		}

		return res;
	}

	/**
	 * Вернуть случайный элемент массива
	 * @param arr
	 * @param number
	 * @return
	 */
	public static function getRandomItem(arr:Array,  except:Array=null) : Object
	{
		if(!arr) return null;
		var arrCopy:Array = arr.slice();

		var i:int = 0, index:int;
		if (except)
		{
			for(i=0; i<except.length; i++)
			{
				index = arrCopy.indexOf(except[i]);
				if (index != -1)
					arrCopy.splice(index, 1);
			}
		}

		index = Math.floor(arrCopy.length*Math.random());

		return arrCopy[index];
	}
	
	/**
	 * Вернуть случайный элемент массива с заданной вероятностью
	 * @param arr массив объектов
	 * @param prop свойства объекта для вероятности
	 * @return 
	 */
	public static function getRandomItemByProbability(arr:Array,  prop:String="probability") : Object
	{
		var arrCopy:Array = arr.slice();
		arrCopy.sortOn(prop, Array.NUMERIC);
		
		var i:int=0;
		var obj:Object;
		var probabilitySum:Number = 0;
		
		var position:Number = 0;
		var positions:Array = [];
		
		for(i=0; i<arrCopy.length; i++)		
		{
			obj = arrCopy[i];
			if (obj.hasOwnProperty(prop))
			{
				var probability:Number = obj[prop]; 
				probabilitySum += probability;
				
				position += probability;
				positions[positions.length] = position;
			}
		}
		
		var rnd:Number = Math.random()*probabilitySum;				
		for(i=0; i<arrCopy.length; i++)
		{			
			if(rnd <= positions[i])
				return arrCopy[i];
		}
		return arrCopy[i];
	}

	/**
	 * Проверка наличия элемента в массиве
	 *
	 * @param arr Массив
	 * @param element Элемент, который ищем
	 */
	public static function contains(arr:Array, element:*):Boolean
	{
		return arr.indexOf(element) != -1;
	}

	/**
	 * Перемешавает массив на основе Math.random
	 * @param arr
	 *
	 */
	public static function shuffle(arr : Array):void
	{
       var t : Object;
       var ind2 : int;
       var len:int = arr.length;

       for(var i : int = 0; i < len; i++)
       {
           ind2 = int(Math.random() * len);
           t = arr[i];
           arr[i] = arr[ind2];
           arr[ind2] = t;
       }
	}

	/**
	 * Получение массива на основе типизированного массива.
	 *
	 * @param	sourceVec исходный типизированный массив, который нужно конвертировать в обычный массив.
	 *
	 * @return	массив, полученный на основе типизированного массива.
	 */
	public static function convertVectorToArray(sourceVec:*):Array
	{
/*		var array:Array = sourceVec.join(ArrayUtils.SPLIT_TEXT).split(ArrayUtils.SPLIT_TEXT);
		return array;*/

		var count:int = sourceVec.length;
		var array:Array = new Array(count);
		for (var index:int = 0; index < count; index++)
		{
			array[index] = sourceVec[index];
		}

		return array;
	}


	/**
	 * Функции для удаления объектов из массивов.
	 */

	/**
	 * Удаление всех ссылок на объекты из массива.
	 *
	 * @param	array исходный массив.
	 * @param	item объект, который нужно удалить.
	 * @param	needRemoveCount количество удалений объекта (если передано -1, то удалятся все объекты).
	 */
	public static function removeItemFromArray(array:Array, item:*, needRemoveCount:int = ArrayUtils.REMOVE_COUNT_ALL):void
	{
		if (needRemoveCount == ArrayUtils.REMOVE_COUNT_ALL)
		{
			needRemoveCount = array.length;
		}

		var totalRemovedCount:int = 0;
		var itemIndex:int  = array.indexOf(item);
		while (itemIndex != -1 && totalRemovedCount < needRemoveCount)
		{
			array.splice(itemIndex, 1);

			itemIndex = array.indexOf(item, itemIndex);
			totalRemovedCount++;
		}
	}

	/**
	 * Удаление всех ссылок на объекты из типизированного массива.
	 *
	 * @param	vec исходный типизированный массив.
	 * @param	item объект, который нужно удалить.
	 * @param	needRemoveCount количество удалений объекта (если передано -1, то удалятся все объекты).
	 */
	public static function removeItemFromVector(vec:*, item:*, needRemoveCount:int = ArrayUtils.REMOVE_COUNT_ALL):void
	{
		if (needRemoveCount == ArrayUtils.REMOVE_COUNT_ALL)
		{
			needRemoveCount = vec.length;
		}

		var totalRemovedCount:int = 0;
		var itemIndex:int  = vec.indexOf(item);
		while (itemIndex != -1 && totalRemovedCount < needRemoveCount)
		{
			vec.splice(itemIndex, 1);

			itemIndex = vec.indexOf(item, itemIndex);
			totalRemovedCount++;
		}
	}
}
}