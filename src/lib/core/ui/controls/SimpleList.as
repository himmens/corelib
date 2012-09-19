package lib.core.ui.controls
{
import lib.core.data.ItemSet;
import lib.core.data.ItemSetEvent;
import lib.core.ui.layout.ColumnLayout;
import lib.core.ui.layout.Container;
import lib.core.ui.layout.ILayout;

import flash.display.DisplayObject;

/**
* Простой список элементов:
 * 1. itemRenderer (опционально с полями set/get data)
 * 2. layout - любой лайаут (вертикальный, горизонтальный, таблицей и т.п.)
 * 3. dataProvider - массив или ItemSet.
*/
public class SimpleList extends Container
{
	/**
	 * Пересоздавать детей автоматом при смене itemRenderer
	 */
	public var autoRefreshWhenItemRendererChanged:Boolean = true;

	public function SimpleList(layout:ILayout = null)
	{
		super(layout || new ColumnLayout());
	}

	protected function commitProperties():void
	{
		if(dataProviderChanged)
		{
			dataProviderChanged = false;

			//if(!dataProvider)
			//	return;

			var dataArray:Object = dataProvider is ItemSet ? ItemSet(dataProvider).toArray() : dataProvider;
			if(!dataArray)
				dataArray = [];

			//удаляем лишних детей
			while(children.length > dataArray.length)
				removeAt(children.length-1);

			//заполняем детей новыми данными
			var child:DisplayObject;
			var data:Object;
			for (var i:int=0; i<dataArray.length; i++)
			{
				data = dataArray[i];

				//если рендерер уже есть используем его, иначе создаем новый
				if(i < children.length)
				{
					child = children[i] as DisplayObject;
				}
				else
				{
					child = createItemRenderer(data);
					if(child)
					{
						add(child);
					}
				}

				//данные назначаем после добавления
				setChildData(child, data);
			}

			arrange();
		}
	}

	override public function add(o:DisplayObject, index:int=int.MAX_VALUE):DisplayObject
	{
		o = super.add(o, index);
		setItemProperties(o);

		return o;
	}

	private var _itemRenderer:Class;

	public function set itemRenderer(value:Class):void
	{
		if(_itemRenderer != value)
		{
			removeAll();
			_itemRenderer = value;

			if(autoRefreshWhenItemRendererChanged && dataProvider)
			{
				dataProviderChanged = true;
				commitProperties();
			}
		}
	}

	public function get itemRenderer():Class
	{
		return _itemRenderer;
	}

	/**
	 * @param data данные передаются чтобы иметь возмонжость в наследниках не создавать детей под определнный тип данных
	 * @return
	 *
	 */
	protected function createItemRenderer(data:Object):DisplayObject
	{
		if(!itemRenderer)
			return null;

		try
		{
			var child:DisplayObject = new itemRenderer() as DisplayObject;
			return child as DisplayObject;
		}catch(error:Error)
		{
			trace(error.getStackTrace());
		}

		return null;
	}

	protected function setChildData(child:DisplayObject, data:Object = null):void
	{
		if(child && child.hasOwnProperty("data"))
			child["data"] = data;
	}

	protected var dataProviderChanged:Boolean = false;
	protected var _dataProvider:*;
	/**
	 * В качестве датапровайдера только массив.
	 *
	 **/
	public function set dataProvider(value:*):void
	{
		if (value is ItemSet)
		{
			if (dataProvider && (dataProvider is ItemSet)) {
				ItemSet(dataProvider).removeEventListener(ItemSetEvent.ADD, onItemSetEvent);
				ItemSet(dataProvider).removeEventListener(ItemSetEvent.REMOVE, onItemSetEvent);
				ItemSet(dataProvider).removeEventListener(ItemSetEvent.UPDATE, onItemSetEvent);
				ItemSet(dataProvider).removeEventListener(ItemSetEvent.REFRESH, onItemSetEvent);
			}
			ItemSet(value).addEventListener(ItemSetEvent.ADD, onItemSetEvent, false, 0, true);
			ItemSet(value).addEventListener(ItemSetEvent.REMOVE, onItemSetEvent, false, 0, true);
			ItemSet(value).addEventListener(ItemSetEvent.UPDATE, onItemSetEvent, false, 0, true);
			ItemSet(value).addEventListener(ItemSetEvent.REFRESH, onItemSetEvent, false, 0, true);
		}

		_dataProvider = value;
		dataProviderChanged = true;
		commitProperties();
	}

	public function get dataProvider():*
	{
		return _dataProvider;
	}

	protected function onItemSetEvent(event:ItemSetEvent):void
	{
		var data:Object = event.item;
		var child:DisplayObject;
		var index:int = event.index;
		var oldIndex:int = event.oldIndex;

		switch (event.type)
		{
			case ItemSetEvent.ADD :
				child = createItemRenderer(data);
				if(child)
				{
					add(child, index);
					setChildData(child, data);
				}
				arrange();
				break;

			case ItemSetEvent.REMOVE :
				removeAt(index);
				arrange();
				break;

			case ItemSetEvent.UPDATE :
				child = oldIndex != -1 ? children[oldIndex] : children[index];
				if(child)
				{
					setChildData(child, data);

					//если индексы не равны, перемещаем
					if (oldIndex != -1 && index != oldIndex) {
						removeAt(oldIndex);
						add(child, index);
						arrange();
					}
				}
				break;

			case ItemSetEvent.REFRESH :
				dataProviderChanged = true;
				commitProperties();
				break;
		}
	}

	private var _itemProperties:Object;
	/**
	 * Дополнительный объект инициализации для itemRenderer-ов, все свойста объекта назначатся уже созданным рендерарам
	 * и будут применяться к вновь добавленным.
	 * @param value
	 *
	 */
	public function set itemProperties(value:Object):void
	{
		_itemProperties = value;
		commitItemProperties();
	}

	public function get itemProperties():Object
	{
		return _itemProperties;
	}

	protected function commitItemProperties():void
	{
		if(numChildren == 0)
			return;

		for(var i:int=0; i<numChildren; i++)
			setItemProperties(getChildAt(i));
	}

	protected function setItemProperties(item:Object):void
	{
		if(!item)
			return;

		for(var propName:String in itemProperties)
		{
			if(item.hasOwnProperty(propName))
				item[propName] = itemProperties[propName]
		}
	}
	
	public function setItemProperty(propName:String, propValue:*):void
	{
		if(!_itemProperties)
			_itemProperties = {};
		
		_itemProperties[propName] = propValue;
		
		var item:Object;
		for(var i:int=0; i<numChildren; i++)
		{
			item = getChildAt(i);
			if(item.hasOwnProperty(propName))
				item[propName] = propValue;
		}
	}
}
}