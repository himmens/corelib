package lib.core.util.log
{
import flash.display.DisplayObjectContainer;
import flash.events.ContextMenuEvent;
import flash.events.EventDispatcher;
import flash.events.KeyboardEvent;
import flash.system.System;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import flash.ui.Keyboard;


public class ClipboardTarget extends AbstractLoggerTarget implements ILoggerTarget
{
	public var checkShift:Boolean = false;
	public var keyCodes:Array;

	public function ClipboardTarget(kbDispatcher:EventDispatcher, keyCodes:Array = null, contextTarget:DisplayObjectContainer = null)
	{
		kbDispatcher.addEventListener(KeyboardEvent.KEY_UP, onKeyboard);
		this.keyCodes = keyCodes || [Keyboard.F12, Keyboard.F9];
		
		initContextMenu(contextTarget);
	}

	private function initContextMenu(contextTarget:DisplayObjectContainer):void
	{
		if (contextTarget)
		{
			try
			{
				var contextMenu:ContextMenu = new ContextMenu();
				contextMenu.hideBuiltInItems();
				
				var item:ContextMenuItem = new ContextMenuItem("Copy log");
				item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectHandler);
				contextMenu.customItems.push(item);
				
				contextTarget.contextMenu = contextMenu;
			}
			catch(e:Error)
			{
				Logger.debug(this, e);
			}
		}
	}
	
	override public function internalLog(message:String, level:int):void
	{
//		if(active)
//			trace(message);
	}

	private function onKeyboard (event:KeyboardEvent):void
	{
		if(!active)
			return;

		var keyOk:Boolean = keyCodes.indexOf(event.keyCode) >= 0;
		var shiftOk:Boolean = checkShift ? event.shiftKey : true;

		if(keyOk && shiftOk)
		{
			System.setClipboard(Logger.log);
		}
	}

	private function menuItemSelectHandler(event:ContextMenuEvent):void 
	{
		try
		{
			System.setClipboard(Logger.log);
		}
		catch(e:Error)
		{
			Logger.debug(e);
		}
	}
}
}