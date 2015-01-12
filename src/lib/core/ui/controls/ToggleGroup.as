package lib.core.ui.controls
{
import lib.core.ui.list.ISelectable;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;

[Event (name="select", type="flash.events.Event")]
public class ToggleGroup extends EventDispatcher
{
	//используем Dictionary для мягкой связки на объекты
	private var buttons:Array = [];

	private var _selected:ISelectable;

	/**
	 * Флаг, кидать или нет событие, при повторных кликах на одну и ту же кнопку.
	 */
	public var dispatchTheSameState:Boolean = false;

	/**
	 * Флаг, могут ли все кнопки быть невыденными.
	 */
	public var canBeUnselected:Boolean = false;

	public function ToggleGroup()
	{
	}

	public function add(btn:ISelectable):void
	{
		if(!btn)
			return;
		
		if(buttons.indexOf(btn) == -1)
		{
			buttons[buttons.length] = btn;
			if(btn is ToggleButton)
				ToggleButton(btn).toggle = false;
			btn.selected = false;

			btn.addEventListener(MouseEvent.CLICK, onBtnSelect, false, 0 , true);

			if(!selected && !canBeUnselected)
				setSelected(btn);
		}
	}

	public function remove(btn:ISelectable, checkSelection:Boolean = true):void
	{
		var index:int = buttons.indexOf(btn);
		if (index == -1)
			return;
		
		buttons.splice(buttons.indexOf(btn), 1);

		if(_selected == btn)
		{
			if(checkSelection && !canBeUnselected && buttons.length > 0)
				setSelected(buttons[0]);
			else
			{
				setSelected(null);
			}
		}

		if(btn)
			btn.removeEventListener(MouseEvent.CLICK, onBtnSelect);
	}

	public function removeAll():void
	{
		if(_selected)
		{
			_selected.selected = false;
			_selected = null;
		}

		for each(var btn:ISelectable in buttons)
		{
			btn.removeEventListener(MouseEvent.CLICK, onBtnSelect);
		}

		buttons = [];
	}

	protected function onBtnSelect(event:Event):void
	{
		var btn:ISelectable = event.target as ISelectable;
		setSelected(btn, true);
	}

	public function set selected(btn:ISelectable):void
	{
		setSelected(btn);
	}

	public function get selected():ISelectable
	{
		return _selected;
	}
	
	public function get selectedData():Object
	{
		return selected && ("data" in selected) ? selected["data"] : null;
	}
	
	public var selectedProperty:String;
	protected var _selectedValue:*;
	public function set selectedValue(value:*):void
	{
		if(selectedValue != value)
		{
			_selectedValue = value;
			if(selectedProperty)
			{
				var data:Object;
				for each(var btn:ISelectable in buttons)
				{
					if(!("data" in btn))
						continue;
					
					data = btn["data"];
					if(data[selectedProperty] == value)
					{
						selected = btn;
						break;
					}
				}
					
			}
		}
	}
	
	public function get selectedValue():*
	{
		return _selectedValue;
	}

	protected function setSelected(btn:ISelectable, clicked:Boolean = false):void
	{
		//пытаемся выделить кнопку, которая не добавлена
		if(btn && buttons.indexOf(btn) == -1)
			return;

		//пытаемся снять выделение с флагом canBeUnselected=false, когда еще есть кнопки в запасе
		if(!btn && !canBeUnselected && buttons.length > 0)
			return;

		//if(btn && !btn.selected)
		//	return;

		var selectedChanged:Boolean = _selected != btn;

		//делаем доп проверку что данные также равны
		if(_selected && btn && !selectedChanged && ("data" in btn) && ("data" in _selected))
			selectedChanged = _selected["data"] != btn["data"];

		if(selectedChanged)
		{
			if(_selected)
				_selected.selected = false;

			_selected = btn;
			if(_selected)
				_selected.selected = true;
		}else if(_selected && canBeUnselected)
		{
			_selected.selected = false;
			_selected = null;
			selectedChanged = true;
		}

		_selectedValue = selected && ("data" in selected) ? selected["data"] : null;
		
		if(selectedChanged || dispatchTheSameState)
			dispatchEvent(new ToggleGroupEvent(ToggleGroupEvent.SELECT, clicked));
	}
}
}