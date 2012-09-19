package lib.core.data
{

import flash.utils.Dictionary;

/**
 * Спикос с дополнительным функцоналом фильтрации и сортировки с последующей синхронизацей отфильтрованного 
 * ItemSet-а с собой.
 */
public class ItemSetAdvanced extends ItemSet
{
	/**
	 * 
	 */
	protected var sets:Dictionary = new Dictionary(false);
	
	public function ItemSetAdvanced(arr:Array=null)
	{
		super(arr);
	}
	
	/**
	 * Создает дочерний ItemSet с фильтрацией и сортировкой 
	 * @param filter стандартная функция фильтрации массива, например:
	 *	 filterItems(item:IItemVO, index:int, arr:Array):Boolean
	 * @param sort стандартная функция сортировки массива, например:
	 *	 sortItems(item1:IItemVO, item2:IItemVO):int
	 * @param descending сортировать в порядке убывания
	 * @return 
	 * 
	 */
	public function getChild(filter:Function, sort:Function = null, descending:Boolean = false, advancedChildren:Boolean = false):ItemSet
	{
		var filtered:ItemSet;
		
		if(sets[filter])
		{
			filtered = sets[filter].sett as ItemSet;
			filtered.updateByArray(super.filter(filter).toArray());
		}else
		{ 
			var filteredArray:Array = array.filter(filter);
			filtered = advancedChildren ? new ItemSetAdvanced(filteredArray) : new ItemSet(filteredArray);
		}
		
		if(sort is Function)
			filtered.toArray().sort(sort, descending ? Array.NUMERIC | Array.DESCENDING : Array.NUMERIC);
		
		sets[filter] = {sett:filtered, filter:filter, sort:sort, descending:descending};
		return filtered;
	}
	
	/**
	 * Удаляет дочерний ItemSet на заданный фильтр
	 * @param filter
	 * @return 
	 * 
	 */
	public function removeChild(filter:Function):ItemSet
	{
		var sett:ItemSet = sets[filter];
		delete sets[filter];
		return sett;
	}
	
	override public function add(item:IItemVO, index:int=int.MAX_VALUE):IItemVO
	{
		var item:IItemVO = super.add(item, index);
		
		if(item)
		{
			var filter:Function;
			var sort:Function;
			var sett:ItemSet;
			var index:int = array.indexOf(item);
			
			for each(var obj:Object in sets)
			{
				filter = obj.filter;
				sort = obj.sort;
				sett = obj.sett;
				if(filter(item, index, array))
				{
					//TODO: пока добавялем в конец, подключить сортировку
					index = sort is Function ? findIndex(sett.toArray(), item, sort, obj.descending) : int.MAX_VALUE;
					sett.add(item, index);
				}
			}
		}
		
		return item;
	}
	
	override public function remove(id:String):IItemVO
	{
		var item:IItemVO = super.remove(id);
		
		for each(var obj:Object in sets)
		{
			obj.sett.remove(id);
		}
		
		return item;
	}
	
	protected function findIndex(arr:Array, item:IItemVO, sort:Function, descending:Boolean):int
	{
		var index:int = 0;
		var i:int = 0;
		//считаем, что массив уже отсортирован и выходим из цикла при нахождении первого удачного индекса - когда текущий 
		//элемент больше или равен элементу в списке по этому индексу
		
		//для сортировки по убыванию идем с начала списка
		if(descending)
		{
			for(i = 0; i< arr.length; i++)
				if(sort(item, arr[i]) >= 0)
				{
					index = i;
					break;
				}
		}
		//для сортировки по возрастанию идем с конца списка
		else
		{
			for(i = arr.length-1; i >= 0; i--)
				if(sort(item, arr[i]) >= 0)
				{
					index = i+1;
					break;
				}
		}
		return index;
	}
}
}