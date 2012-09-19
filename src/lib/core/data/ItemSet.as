package lib.core.data
{
import flash.events.Event;
import flash.events.EventDispatcher;

import lib.core.util.log.Logger;

/**
 * Базовая коллекция для хранения IItem-ов.
 * Функционал:
 * 	- события добавление/удаление элемента, изменение индекса элемента, обновление коллекции
 * 	- работа по уникальному id, коллекция гарантирует унильность элемента с данным id
 */
[Event(name="add", type="lib.core.data.ItemSetEvent")]
[Event(name="remove", type="lib.core.data.ItemSetEvent")]
[Event(name="update", type="lib.core.data.ItemSetEvent")]
[Event(name="refresh", type="lib.core.data.ItemSetEvent")]

public class ItemSet extends EventDispatcher
{
	/**
	 * не посылать никаких ItemSetEvent событий
	 */
	public var preventEvents:Boolean = false;

	protected var storage:Object = {};
	protected var array:Array = [];

	// ----------------------------------------------------------------------------------------------------
	// Getters and setters
	// ----------------------------------------------------------------------------------------------------

	/**
	 * Возвращает число адаптеров, хранимых в коллекции.
	 */
	[Bindable(event="add")]
	[Bindable(event="remove")]
	public function get length():uint
	{
		return array.length;
	}

	/**
	 * Возвращает ссылку на первый элемент в колллекции.
	 */
	public function get first():IItemVO
	{
		return array.length > 0 ? IItemVO(array[0]) : null;
	}

	/**
	 * Возвращает ссылку на последний элемент в колллекции.
	 */
	public function get last():IItemVO
	{
		return array.length > 0 ? IItemVO(array[length - 1]) : null;
	}

	// ----------------------------------------------------------------------------------------------------
	// Constructor
	// ----------------------------------------------------------------------------------------------------

	public function ItemSet(arr:Array = null)
	{
		if (arr)
		{
			updateByArray(arr);
		}
	}

	// ----------------------------------------------------------------------------------------------------
	// Public methods
	// ----------------------------------------------------------------------------------------------------

	public function add(item:IItemVO, index:int = int.MAX_VALUE):IItemVO
	{
		if (!item)
		{
			return null;
		}

		// если индекс выходит за границы массива - пишем
		if (index != int.MAX_VALUE && index > array.length)
		{
			Logger.debug("Set:: вышли за пределы массива:", index);
			index = array.length;
		}

		var he:IItemVO = find(item.id);
		//такой уже есть - меняем индекс или добавляем в конец массива
		if (he)
		{
			var oldIndex:int = array.indexOf(he);

			//если изменился индекс, двигаем по массиву
			if (index != int.MAX_VALUE && oldIndex != index)
			{
				array.splice(oldIndex, 1);
				array.splice(index, 0, item);

				//заменяем элемент в карте на новый
				storage[item.id] = item;

				// шлём событие по случаю изменения элемента или индекса
				dispatchEvent(new ItemSetEvent(ItemSetEvent.UPDATE, item, index, oldIndex));
			}
			else
			{
//				if(he != item)
//				{
					index = oldIndex;
					array[index] = item;

					//заменяем элемент в карте на новый
					storage[item.id] = item;

					// шлём событие по случаю изменения элемента
					dispatchEvent(new ItemSetEvent(ItemSetEvent.UPDATE, item, index, oldIndex));
//				}
			}
		}
		else
		{
			index = Math.min(index, array.length);

			array.splice(index, 0, item);

			//заменяем элемент в карте на новый
			storage[item.id] = item;

			dispatchEvent(new ItemSetEvent(ItemSetEvent.ADD, item, index));
		}

		return item;
	}

	public function remove(id:String):IItemVO
	{
		var obj:IItemVO = find(id);
		if (obj)
		{
			var index:int = array.indexOf(obj);

			array.splice(index, 1);
			delete storage[obj.id];

			dispatchEvent(new ItemSetEvent(ItemSetEvent.REMOVE, obj, index));
			return obj;
		}
		return null;
	}

	public function removeAt(index:int):IItemVO
	{
		var o:IItemVO = getAt(index);
		if (o)
			remove(o.id)
		return o;
	}

	public function has(o:IItemVO):Boolean
	{
		return Boolean(storage[o.id])
	}

	[Bindable(event="add")]
	[Bindable(event="remove")]
	public function find(id:String):IItemVO
	{
		var o:IItemVO = IItemVO(storage[id]);
		return o;
	}

	public function getAt(index:int):IItemVO
	{
		var o:IItemVO = IItemVO(array[index]);
		return o;
	}

	/**
	 * Фильтр.
	 * Возвращает новую коллекцию с отфильтрованными данными.
	 *	
	 * @param callback функция фильтрации
	 * function callback(item:*, index:int, array:Array):Boolean;
	 */
	public function filter(callback:Function):ItemSet
	{
		return new ItemSet(array.filter(callback));
	}

	/**
	 * Апдейт коллекции массивом адапретов
	 * @param arr массов объектов IItemVO
	 */
	public function updateByArray(arr:Array):void
	{
		this.array = arr || [];
		storage = {};
		for each (var item:IItemVO in array)
			storage[item.id] = item;

		dispatchEvent(new ItemSetEvent(ItemSetEvent.REFRESH));
	}

	/**
	 * Апдейт коллекции другим сетом
	 * @param arr массов объектов IItemVO
	 */
//	public function updateBySet (newset:ItemSet):void
//	{
//		var item:IItemVO;
//		var changed:Boolean=false;
//
//		for each (item in storage)
//		{
//			if (! newset.has(item))
//			{
//				remove(item.id);
//				changed=true;
//			}
//		}
//
//		var array:Array = newset.toArray();
//		for (var i:uint=0; i < array.length; i++)
//		{
//			item = IItemVO(array[i]);
//			add(item, i);
//			changed=true;
//		}
//	}

/* 	public function get myArray():Array
	{
		return array;
	} */

	/**
	 * Аналогичен методу sortOn в Array 
	 * @param fieldName
	 * @param options
	 * 
	 */
	public function sortOn(fieldName:Object, options:Object):Array
	{
		var result:Array = array.sortOn(fieldName, options);
		dispatchEvent(new ItemSetEvent(ItemSetEvent.REFRESH));
		return result;
	}
	/**
	 * Аналогичен методу sort в Array 
	 */
	public function sort(...params):Array
	{
		var result:Array = array.sort.apply(null, params);
		dispatchEvent(new ItemSetEvent(ItemSetEvent.REFRESH));
		return result;
	}
	/**
	 * Returns array of IItemVO
	 */
	public function toArray():Array
	{
		return array;
	}

	/**
	 * Returns index of IEntity within result of toArray() method.
	 */
	public function indexOf(item:IItemVO):int
	{
		return array.indexOf(item);
	}

	/**
	 * Чистим всё без событий.
	 * Для очистки с событием, использовать функцию updateByArray([])
	 */
	public function clear():void
	{
		storage = {};
		array = [];
	}
/**
 * Чистим всё с событиями
 */
//	public function flush ():void
//	{
//		updateByArray([]);
//	}

	override public function dispatchEvent(event:Event):Boolean
	{
		if(!preventEvents)
			return super.dispatchEvent(event);

		return false;
	}

	override public function toString():String
	{
		return super.toString() + "(" + array + ")";  
	}
}
}