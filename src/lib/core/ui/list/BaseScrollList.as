package lib.core.ui.list
{
import lib.core.data.ItemSet;
import lib.core.data.ItemSetEvent;
import lib.core.ui.controls.SimpleList;
import lib.core.ui.layout.ColumnLayout;
import lib.core.ui.layout.ILayout;
import lib.core.ui.layout.ITableLayout;
import lib.core.ui.scroll.ScrollPane;
import lib.core.util.FunctionUtil;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;

/**
 * Базовый лист с прокруткой.
 *
 * Оптимизирует количество отображаемых данных в переделах видимости по индексам.
 * Показывает только количество countLines*countInLines.
 *
 * Есть возможность выделения элементов. (Если задано selectable == true).
 * Выделение элемента происходит по событию MouseEvent.CLICK.
 * (Элемент должен имплементировать интерфейс ISelectable)
 *
 * Usage:
 * 		var list:BaseScrollList = new BaseScrollList();
 * 		list.width = 400;
 * 		list.height = 80;
 * 		list.countLines = 6;
 * 		list.countInLine = 1;
 * 		list.itemRenderer = MyItemRenderer;
 * 		list.dataProvider = [{id:1, label:1}, {id2:label2}]
 */

[Event (name="scrollIndexChanged", type="flash.events.Event")]
[Event (name="select", type="flash.events.Event")]

public class BaseScrollList extends ScrollPane
{
	public static const EVENT_SCROLL_INDEX_CHANGED:String = "scrollIndexChanged";

	//автоматически сбрасывать прокрутки при изменении данных
	public var autoScrollOnDataChanged:Boolean = true;

	//автоматически определять величину разовой прокрутки
	public var autoScrollSize:Boolean = true;

	//автоматически вычислять величины countLines и countInLine
	public var autoMeasureCounts:Boolean = true;

	//делать цикличным дата провайдер
	public var cyclic:Boolean = false;

	//хранилище для выделенных индексов
	protected var selectedData:Object = {};

	//флаг инициализации контента
	protected var contentInited:Boolean;

	public function BaseScrollList(layout:ILayout = null, direction:String = DIRECTION_VERTICAL)
	{
		super(direction);
		autoCheckSize = false;
		this.layout = layout || new ColumnLayout();
	}

	override protected function init():void
	{
		super.init();

		_list = createList(layout);
		if (itemRenderer)
			_list.itemRenderer = itemRenderer;
		_content = _list;
		contentClip.addChild(_content);

		if (scrollBar)
			scrollBar.autoScrollAfterDrop = true;
	}

	protected function createList(layout:ILayout):SimpleList
	{
		return new SimpleList(layout);
	}
	protected var _list:SimpleList;
	protected function get list():SimpleList {
		return _list;
	}

	public function set itemProperties(value:Object):void {
		if (list)
			list.itemProperties = value;
	}

	/**
	 * Данные - Array или ItemSet
	 * @param value
	 */
	protected var dataProviderChanged:Boolean;
	protected var _dataProvider:*;
	protected var dataArray:Array = [];
	public function get dataProvider ():*
	{
		return _dataProvider;
	}
	public function set dataProvider (value:*):void
	{
		if (dataProvider && (dataProvider is ItemSet)) {
			ItemSet(dataProvider).removeEventListener(ItemSetEvent.ADD, onItemSetEvent);
			ItemSet(dataProvider).removeEventListener(ItemSetEvent.REMOVE, onItemSetEvent);
			ItemSet(dataProvider).removeEventListener(ItemSetEvent.UPDATE, onItemSetEvent);
			ItemSet(dataProvider).removeEventListener(ItemSetEvent.REFRESH, onItemSetEvent);
		}

		if (value is ItemSet)
		{
			ItemSet(value).addEventListener(ItemSetEvent.ADD, onItemSetEvent, false, 0, true);
			ItemSet(value).addEventListener(ItemSetEvent.REMOVE, onItemSetEvent, false, 0, true);
			ItemSet(value).addEventListener(ItemSetEvent.UPDATE, onItemSetEvent, false, 0, true);
			ItemSet(value).addEventListener(ItemSetEvent.REFRESH, onItemSetEvent, false, 0, true);
		}

		_dataProvider = value;
		dataArray = value is ItemSet ? ItemSet(value).toArray() : value;
		dataProviderChanged = true;
		updateLater();
	}

	/**
	 * Получить данные элемента по его индексу
	 */
	public function getItemDataAt(index:int):Object
	{
		return dataArray ? dataArray[index] : null;
	}

	/**
	 * Получить индекс элемента по его данным
	 */
	public function getItemIndexByData(data:Object):int
	{
		return dataArray ? dataArray.indexOf(data) : -1;
	}

	protected var itemRendererChanged:Boolean;
	protected var _itemRenderer:Class;
	public function get itemRenderer():Class
	{
		return _itemRenderer;
	}
	public function set itemRenderer(value:Class):void
	{
		if(_itemRenderer == value)
			return;
		_itemRenderer = value;
		measuredChildCached = null;
		itemRendererChanged = true;
		updateLater();
	}

	protected var layoutChanged:Boolean;
	protected var _layout:ILayout;
	public function get layout():ILayout
	{
		return _layout;
	}
	/**
	 * Layout объект для расположения элементов
	 * Не рекомендуется использовать ненулевые paddings в лейаутах, т.к. при этом не получится полностью прокрутить весь список
	 * за целое число прокруток (в конце всегда придется докручивать).
	 * @param value
	 */
	public function set layout(value:ILayout):void
	{
		if(_layout == value)
			return;
		_layout = value;
		layoutChanged = true;
		updateLater();
	}

	protected var countLinesChanged:Boolean;
	protected var _countLines:int = 1;
	/**
	 * Количество отображаемых групп прокрутки на экране, для однострочных леэаутов (например
	 * список друзей) этот параметр совпадает с видимым числом элементов в списке.
	 *
	 */
	public function get countLines():int
    {
        return _countLines;
    }
    public function set countLines(value:int):void
    {
    	if (_countLines == value)
    		return;
    	_countLines = value;
    	countLinesChanged = true;
		autoMeasureCounts = false;
		updateLater();
    }

    protected var countInLineChanged:Boolean;
	protected var _countInLine:int = 1;
	/**
	 * Количество элементов в группе прокрутки, т.е. число элементов, которые прокручиваются
	 * при единичной прокрутке (при клике на первую кнопку).
	 * Этот параметр отличен от 1 только в случае мультистрочных лейаутов, когда по клику на первую кнопку
	 * прокручивается не 1 элемент, а целая колонка.
	 */
	public function get countInLine():int
    {
        return _countInLine;
    }
    public function set countInLine(value:int):void
    {
    	if (_countInLine == value)
    		return;
    	_countInLine = value;
    	countInLineChanged = true;
		autoMeasureCounts = false;
		updateLater();
    }

    /**
    * Индекс прокрутки (количество проскролленных scrollSize'ов)
    */
	protected var scrollIndexChanged:Boolean;
	protected var _scrollIndex:int = 0;
	protected function set scrollIndex(value:int):void
	{
		if (_scrollIndex == value)
			return;

		_scrollIndex = value;
		//scrollIndexChanged = true;
		updateViewData();

		//если идет анимация не кидаем событие смены индекса. Событие кинется в конце анимаиции
		if(tween.paused)
			dispatchEvent(new Event(EVENT_SCROLL_INDEX_CHANGED));
	}
	protected function get scrollIndex():int {
		return _scrollIndex;
	}

	public function get children():Array {
		return list ? list.children : [];
	}

	/**
    * Флаг обновления для листа при изменении рендерера
    */
	protected var _autoRefreshWhenItemRendererChanged:Boolean;
	public function set autoRefreshWhenItemRendererChanged(value:Boolean):void
	{
		_autoRefreshWhenItemRendererChanged = value;
		if (list)
			list.autoRefreshWhenItemRendererChanged = value;
	}
	public function get autoRefreshWhenItemRendererChanged():Boolean {
		return _autoRefreshWhenItemRendererChanged;
	}

	override public function get maxScrollPosition():Number
	{
		return cyclic ? Number.MAX_VALUE : super.maxScrollPosition;
	}

	override public function get minScrollPosition():Number
	{
		return cyclic ? -Number.MAX_VALUE : super.minScrollPosition;
	}

	/**
	 * ширина контента списка
	 */
	protected function get contentWidth():Number
	{
		return width;
	}

	/**
	 * высота контента списка
	 */
	protected function get contentHeight():Number
	{
		return height;
	}

	/**
    * Позиция прокрутки
    */
	override protected function applyScrollPosition(value:Number):void
	{
		scrollIndex = Math.floor(value/scrollSize);
		super.applyScrollPosition(value);
	}

	/**
	 * Измерение величины прокрутки списка исходя из размера ребенка и паддингов
	 */
	protected function measureScrollSize():void
	{
		var child:DisplayObject = createMeasuredChild();
		if (layout && child)
		{
			if (isHorizontal)
				_scrollSize = child.width + layout.settings.hSpacing;
			else
				_scrollSize = child.height + layout.settings.vSpacing;
		}
	}

	/**
	 * Измерение числа отображаемых элементов
	 */
	protected function measureCounts():void
	{
		var child:DisplayObject = createMeasuredChild();
		if (child && layout is ITableLayout)
		{
			if (isHorizontal)
			{
				_countLines = Math.max(1, ITableLayout(layout).countColumns(list, child.width));
				_countInLine = Math.max(1, ITableLayout(layout).countRows(list, child.height));
			}
			else
			{
				_countLines = Math.max(1, ITableLayout(layout).countRows(list, child.height));
				_countInLine = Math.max(1, ITableLayout(layout).countColumns(list, child.width));
			}
		}
	}

	protected var measuredChildCached:DisplayObject;
	//создаем ребенка, чтобы измерить его размеры
	protected function createMeasuredChild():DisplayObject
	{
		if (measuredChildCached)
			return measuredChildCached;

		var child:DisplayObject;
		if (itemRenderer)
		{
			measuredChildCached = child = new itemRenderer();
			if(child.hasOwnProperty("data") && dataArray && dataArray[0])
				child["data"] = dataArray[0];
		}
		return child;
	}

	/**
	 * Обновить отображаемые данные в диапазоне видимых индексов
	 */
	protected function updateViewData():void
	{
		var dataProvider:Array = [];
		if (list)
		{
			if (dataArray)
			{
				if (cyclic) //если цикличный дата провайдер
				{
					var dataLength:int = dataArray.length;
				    for (var i:int=0; i<countLines+1; i++)
				    {
				    	var index:int = scrollIndex + Math.ceil(Math.abs(scrollIndex)/dataLength)*dataLength;
				    	dataProvider.push(dataArray[(index+i) % dataLength]);
				    }
				}
				else {
					var startIndex:int = scrollIndex*countInLine;
					var endIndex:int = (scrollIndex+countLines + 1)*countInLine;
					dataProvider = dataArray.slice(startIndex, endIndex);
				}
				list.dataProvider = dataProvider;
			}
			else
			{
				list.dataProvider = null;
			}
		}

		if (selectable)
			updateSelection();
	}

	/**
	 * Обновить прямоугольник маски отображения
	 */
	override protected function updateScrollRect():void
	{
		var position:Number = scrollPosition - scrollIndex*scrollSize;
		if (isHorizontal)
			contentScrollRect.x = position
		else
			contentScrollRect.y = position;
		if (contentClip)
			contentClip.scrollRect = contentScrollRect;
	}

	protected var scrollIndexTo:int = -1;
	protected var useTweenScrollIndexTo:Boolean;

	/**
	 * Скролить до элемента с индексом
	 *
	 * @param index - индекс до которого скролить
	 * @param useTween - использовать ли анимацию при скролировании
	 */
	public function scrollToIndex(index:int, useTween:Boolean = false):void
	{
		index = Math.max(index, 0);

		scrollIndexTo = index;
		useTweenScrollIndexTo = useTween;

		updateLater();
	}

	protected function commitScrollToIndex():void
	{
		if (!dataArray)
			return;

		scrollIndexTo = Math.max(0, Math.min(scrollIndexTo, dataArray.length - 1));

		var rowIndex:int = Math.floor(scrollIndexTo/countInLine);

		var listUseScrollTween:Boolean = this.useScrollTween;
		this.useScrollTween = useTweenScrollIndexTo;
		scrollPosition = rowIndex*scrollSize;
		this.useScrollTween = listUseScrollTween;

		scrollIndexTo = -1;
		useTweenScrollIndexTo = false;
	}

	/**
	 * Скролить до элемента
	 */
	[Depricated ("Use scrollToIndex instead")]
	public function scrollToItem(item:DisplayObject, useTween:Boolean = false):void
	{
		if (!item)
			return;

		var itemIndex:int = list.children.indexOf(item);
		scrollToIndex(itemIndex, useTween);
	}

	override protected function updateContent():void
	{
		if (!dataArray)
			return;

		if (autoScrollSize)
			measureScrollSize();

		if (autoMeasureCounts)
			measureCounts();

		commitScrollSize();

		var padding:Number = isHorizontal ? layout.settings.hPadding : layout.settings.vPadding;
		var spacing:Number = isHorizontal ? layout.settings.hSpacing : layout.settings.vSpacing;

		contentSize = Math.ceil(dataArray.length/countInLine)*scrollSize - spacing + 2*padding;

		updateScrollRect();

		if (scrollBar)
			updateScrollBar();
	}

	override protected function updateLayout():void
	{
		super.updateLayout();
		if (list) {
			list.userWidth = contentWidth;
			list.userHeight = contentHeight;
			list.arrange();
		}
	}

	protected function updateLater():void
	{
		FunctionUtil.callLater(update);
	}

	override protected function update():void
	{
		var sizeChanged:Boolean = this.sizeChanged;

		super.update();

		var needUpdateContent:Boolean;
		var needUpdateViewData:Boolean;

		if (sizeChanged) {
			needUpdateContent = true;
			needUpdateViewData = true;
		}

		if (layoutChanged) {
			layoutChanged = false;
			needUpdateContent = true;
			if (list)
				list.layout = layout;
		}

		if (itemRendererChanged) {
			itemRendererChanged = false;
			needUpdateContent = true;
			needUpdateViewData = true;
			if (list)
				list.itemRenderer = itemRenderer;
			reset();
		}

		if (dataProviderChanged) {
			dataProviderChanged = false;

			needUpdateContent = true;
			needUpdateViewData = true;

			if (autoScrollOnDataChanged)
				reset();

			//снимаем выдлеление при изменении данных, иначе выделятся новые элементы по старым индексам
			if(selectedIndeces.length > 0)
				selectAll(false);
		}

		if (countLinesChanged) {
			countLinesChanged = false;
			needUpdateViewData = true;
		}

		if (countInLineChanged) {
			countInLineChanged = false;
			needUpdateViewData = true;
		}

		if (scrollIndexChanged)
			needUpdateViewData = true;

		if (needUpdateContent) {
			updateContent();
		}

		if (scrollIndexTo != -1)
			commitScrollToIndex();

		if (needUpdateViewData)
			updateViewData();
	}

	/**
	 * Является ли лист выделяемым
	 */
	private var _selectable:Boolean;
	public function get selectable():Boolean
	{
		return _selectable;
	}
	public function set selectable(value:Boolean):void
	{
		_selectable = value;
		if (_selectable) {
			if (!hasEventListener(MouseEvent.CLICK))
				addEventListener(MouseEvent.CLICK, onClick);
		}
		else {
			if (hasEventListener(MouseEvent.CLICK))
				removeEventListener(MouseEvent.CLICK, onClick);
		}
	}

	/**
	 * Разрешать выделение нескольких элементов
	 */
	protected var _allowMultipleSelection:Boolean = false;
	public function get allowMultipleSelection():Boolean
	{
		return _allowMultipleSelection;
	}
	public function set allowMultipleSelection(value:Boolean):void
	{
		_allowMultipleSelection = value;
		if (value && maxSelectionCount == 1)
		{
			maxSelectionCount = uint.MAX_VALUE;
		}else if(!value && maxSelectionCount != 1)
		{
			maxSelectionCount = 1;
		}
	}

	/**
	 * Максимальное число элементов выделения.
	 */
	protected var _maxSelectionCount:uint = 1;
	public function get maxSelectionCount():uint
	{
		return _maxSelectionCount;
	}
	public function set maxSelectionCount(value:uint):void
	{
		_maxSelectionCount = value;
		if (value > 1)
			allowMultipleSelection = true;
	}

	/**
	 * Минимальное число элементов выделения.
	 */
	protected var _minSelectionCount:uint = 0;
	public function get minSelectionCount():uint
	{
		return _minSelectionCount;
	}
	public function set minSelectionCount(value:uint):void
	{
		_minSelectionCount = value;
	}

	/**
	 * Массив индексов выделенных элементов.
	 */
	protected var _selectedIndeces:Array = [];
    public function get selectedIndeces():Array
    {
        return _selectedIndeces;
    }
    public function set selectedIndeces(value:Array):void
    {
    	if (!selectable)
    		return;

        _selectedIndeces = value;
        for (var i:String in selectedData) {
        	selectedData[i] = value.indexOf(int(i)) != -1;
        }
        updateSelection();

        dispatchEvent(new Event(Event.SELECT));
    }

	/**
	 * Обновляем состояния выделенности детей по карте выделенных объектов
	 */
	protected function updateSelection():void
	{
		if (selectable) {
			for (var i:int=0; i<children.length; i++) {
				var index:int = i + scrollIndex*countInLine;
				var item:DisplayObject = children[i];
				if (item && item is ISelectable && ISelectable(item).selectable) {
					ISelectable(item).selected = selectedData[index] ? selectedData[index] : false;
				}
			}
		}
	}

	/**
	 * Выделение всех детей.
	 * @param value флаг выделить или сбросить выделение
	 * @param dispatch кидать событие о выделении
	 */
	public function selectAll(value:Boolean = true, dispatch:Boolean = true):void
	{
		if (!selectable || !dataArray)
			return;

		if (!allowMultipleSelection && value)
			return;

		_selectedIndeces = [];
		for (var i:int=0; i<dataArray.length; i++) {
			selectedData[i] = value;
			if (value)
				_selectedIndeces.push(i);
		}
		updateSelection();

		if (dispatch)
			dispatchEvent(new Event(Event.SELECT));
	}

	/**
	 * Выделение ребенка.
	 * @param value флаг выделить или сбросить выделение
	 * @param dispatch кидать событие о выделении
	 */
	public function selectItem(item:ISelectable, value:Boolean = true, dispatch:Boolean = true):void
	{
		if (!selectable || !item || !item.selectable)
			return;

		if (Object(item).hasOwnProperty("data")) {
			var itemIndex:int = dataArray.indexOf(item["data"]);
			selectItemByIndex(itemIndex, value, dispatch);
		}
	}

	/**
	 * Выделение ребенка по индексу.
	 * @param value флаг выделить или сбросить выделение
	 * @param dispatch кидать событие о выделении
	 */
	public function selectItemByIndex(index:int, value:Boolean = true, dispatch:Boolean = true):void
	{
		if (!selectable)
			return;

		if (index < 0 || index > dataArray.length - 1)
			return;

		if (!value) {
			//если при сбрасывании выделения число выделенных < минимально допустимого, ничего не делаем
			if (_selectedIndeces.length <= minSelectionCount)
				return;
			if (_selectedIndeces.indexOf(index) != -1)
				_selectedIndeces.splice(_selectedIndeces.indexOf(index), 1);
		}
		else {
			if (_selectedIndeces.indexOf(index) == -1)
				_selectedIndeces.push(index);
			//если достигнут предел выделенния, или множественный выбор запрещен сбрасываем у первого выделение
			if (_selectedIndeces.length > maxSelectionCount) {
				var prevIndex:int = _selectedIndeces.length > 0 ? _selectedIndeces[0] : -1;
				if (prevIndex != -1)
					selectItemByIndex(prevIndex, false, dispatch);
			}
		}

		selectedData[index] = value;

		var item:DisplayObject = getItemByIndex(index);
		if (item && item is ISelectable && ISelectable(item).selectable)
		{
			ISelectable(item).selected = value;
		}

		if (dispatch)
			dispatchEvent(new Event(Event.SELECT));
	}

	public function getItemByIndex(index:int):DisplayObject
	{
		var childIndex:int = index - scrollIndex*countInLine;
		if (childIndex >= 0 && childIndex < list.children.length)
			return children[childIndex];
		return null;
	}

	/**
	 * Поиск ребенка в указанных глобальных координатах.
	 */
	protected function getItemAtPoint(point:Point):DisplayObject
	{
		for each (var item:DisplayObject in children) {
			if (item.hitTestPoint(point.x, point.y, true)) {
				return item;
			}
		}
		return null;
	}

	/**
	 * запоминаем scrollIndex на старте твина, чтобы кинуть событие его изменения при окончании твина
	 */
	protected var _tempStartScrollIndex:int;
	override protected function startTweenScrollPosition(value:Number):void
	{
		if (tween && tween.paused)
			_tempStartScrollIndex = scrollIndex;
		super.startTweenScrollPosition(value);
	}

	//-------------------------------Event Handlers--------------------------------------

	protected function onClick(event:MouseEvent):void
	{
		var point:Point = new Point(mouseX, mouseY);
		point = localToGlobal(point);
		//ищем элемент в точке клика, если находим, выделяем
		var item:DisplayObject = getItemAtPoint(point);
		if (item && item is ISelectable && ISelectable(item).selectable) {
			selectItem(ISelectable(item), !ISelectable(item).selected);
		}
	}

	protected function onItemSetEvent(event:ItemSetEvent):void
	{
		var items:ItemSet = event.target as ItemSet;
		dataArray = items.toArray();
		dataProviderChanged = true;
		updateLater();
	}

	override protected function onTweenComplete(tween:Object = null):void
	{
		super.onTweenComplete(tween);
		if(_tempStartScrollIndex != scrollIndex)
		{
			_tempStartScrollIndex = scrollIndex;
			dispatchEvent(new Event(EVENT_SCROLL_INDEX_CHANGED));
		}
	}
}
}