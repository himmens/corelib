package lib.core.util
{
import flash.display.DisplayObjectContainer;
import flash.events.ContextMenuEvent;
import flash.events.Event;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;

/**
 * Утилитные методы для работы с ContextMenu
 */
public class ContextMenuUtil
{
	/**
	 * Добавляет в контекстное меню элемента новый пункт
	 * @param target - контейнер относительно которого создаем контекстное меню
	 * @param caption - текст элемента меню
	 * @param handler - обработчик нажатия
	 * @return
	 */
	public static function addItem(target:DisplayObjectContainer, caption:String, handler:Function = null):void
	{
		if (!target || !caption)
			return;
		
		var onAddedToStage:Function = function(event:Event):void
		{
			var contextMenu:ContextMenu = target.contextMenu || new ContextMenu();
			contextMenu.hideBuiltInItems();
			
			var enabled:Boolean = handler != null;
			var item:ContextMenuItem = new ContextMenuItem(caption, enabled, enabled);
			if (handler != null)
				item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void { handler(); } );
			contextMenu.customItems.push(item);
			target.contextMenu = contextMenu;
		}
		if (!target.stage)
			target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		else
			onAddedToStage(null);
	}
	
	/**
	 * Удаляет элемент из контекстного меню элемента
	 * @param target - контейнер относительно которого создаем контекстное меню
	 * @param caption - текст элемента меню
	 * @return
	 */
	public static function removeItem(target:DisplayObjectContainer, caption:String):void
	{
		if (!target || !caption)
			return;
		
		var contextMenu:ContextMenu = target.contextMenu;
		var items:Array = contextMenu ? contextMenu.customItems : [];
		var index:int = -1;
		for (var i:int=0; i<items.length; i++)
		{
			var item:ContextMenuItem = ContextMenuItem(items[i]);
			if (item.caption == caption)
			{
				index = i;
				break;
			}
		}
		if (index >= 0)
			contextMenu.customItems.splice(index, 1);
		
		target.contextMenu = contextMenu;
	}
}
}