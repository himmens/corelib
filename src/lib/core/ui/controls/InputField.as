package lib.core.ui.controls
{
import lib.core.util.DataEvent;

import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Keyboard;

/**
 * Событие шлём по ENTER
 */
[Event(name="someData", type="lib.core.util.DataEvent")]
/**
 * Текстовое поле для ввода с подсказкой, например
 * "Текст поста", "Заголовок".
 *
 * Корректно работает с displayAsPassword = true, text
 * и htmlText.
 */
public class InputField extends TextField
{
	protected var _defaultUnfocusLabel:String;
	protected var _selectOnFocus:Boolean;
	protected var _displayAsPassword:Boolean;
	protected var focus:Boolean = false;
	
	private var _labelTextFormat:TextFormat;
	private var _defaultTextFormat:TextFormat;
	
	public function InputField(defaultUnfocusLabel:String = "", selectOnFocus:Boolean = true, displayAsPassword:Boolean = false)
	{
		super();
		
		init();
		
		this.defaultUnfocusLabel = defaultUnfocusLabel;
		this.selectOnFocus = selectOnFocus;
		this.displayAsPassword = displayAsPassword;
	}
	
	protected function init():void
	{
		type = TextFieldType.INPUT;
		
		addEventListener(FocusEvent.FOCUS_IN, onFocusIn, false,0,true);
		addEventListener(FocusEvent.FOCUS_OUT, onFocusOut, false,0,true);
		addEventListener(TextEvent.TEXT_INPUT, onTextInput, false,0,true);
		addEventListener(MouseEvent.CLICK, onMouse, false,0,true);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouse, false,0,true);
		
		addEventListener(KeyboardEvent.KEY_DOWN, onKeyboard, false,0,true);
	}
	
	override public function get text():String
	{
		if (super.text == _defaultUnfocusLabel)
			return "";
		
		return super.text;
	}
	
	override public function set text(value:String):void
	{
		super.text = value;
		update();
		
		dispatchEvent(new Event(Event.CHANGE));
	}
	
	override public function get htmlText():String
	{
		if (super.text == _defaultUnfocusLabel)
			return "";
		
		return super.htmlText;
	}
	
	override public function set htmlText(value:String):void
	{
		super.htmlText = value;
		update();
	}
	
	override public function get length():int
	{
		return text.length;
	}
	
	override public function set defaultTextFormat(format:TextFormat):void
	{
		_defaultTextFormat = format;
		super.defaultTextFormat = format;
		setTextFormat(format);
	}
	
	public function set labelTextFormat(value:TextFormat):void 
	{
		if(_labelTextFormat != value)
		{
			_labelTextFormat = value;
			update();
		}
	}
	
	public function get labelTextFormat():TextFormat 
	{
		return _labelTextFormat;
	}
	
	private function commitLabelTextFormat():void
	{
		// TODO Auto Generated method stub
		
	}
	
	override public function get displayAsPassword():Boolean
	{
		return _displayAsPassword;
	}
	
	override public function set displayAsPassword(value:Boolean):void
	{
		super.displayAsPassword = value;
		_displayAsPassword = value;
	}
	
	/**
	 * Флаг действия при фокусе.
	 * true - выделяем весь текст
	 * false - обычное поведение - стираем
	 */
	public function get selectOnFocus():Boolean
	{
		return _selectOnFocus;
	}
	
	public function set selectOnFocus(value:Boolean):void
	{
		_selectOnFocus = value;
	}
	
	/**
	 * Текст-подсказка для пользователя.
	 */
	public function get defaultUnfocusLabel():String
	{
		return _defaultUnfocusLabel;
	}
	
	public function set defaultUnfocusLabel(value:String):void
	{
		if (super.text == _defaultUnfocusLabel || _defaultUnfocusLabel == null)
			super.text = value;
		
		_defaultUnfocusLabel = value;
	}
	
	protected function selectDefault():void
	{
		super.displayAsPassword = false;
		// переопределяем текст для корректного выравнивания
		super.text = super.text;
		
		setSelection(0, _defaultUnfocusLabel.length);
		scrollH = 0;
	}
	
	protected function update():void
	{
		if (focus == true)
		{
			if (super.text == _defaultUnfocusLabel)
			{
				if (_selectOnFocus)
				{
					selectDefault();
				}
				else
				{
					super.displayAsPassword = _displayAsPassword;
					super.text = "";
				}
			}
		}
		else
		{
			if (super.text=="")
			{
				super.displayAsPassword = false;
				super.text = _defaultUnfocusLabel;
			}
		}
		
		var format:TextFormat = super.text == _defaultUnfocusLabel ? (labelTextFormat || _defaultTextFormat) : _defaultTextFormat;
		if(format && format != super.defaultTextFormat)
		{
			super.defaultTextFormat = format;
			setTextFormat(format);
		}
		
	}
	
	private function onMouse(event:Event):void
	{
		if (super.text == _defaultUnfocusLabel)
		{
			selectDefault();
		}
	}
	
	private function onKeyboard(e:KeyboardEvent):void
	{
		if (e.keyCode == Keyboard.ENTER)
		{
			dispatchEvent(new DataEvent(DataEvent.SOME_DATA, text));
		}
	}
	
	private function onTextInput(event:Event):void
	{
		// выставляем при вводе текста, для режима selectOnFocus
		super.displayAsPassword = _displayAsPassword;
	}
	
	private function onFocusIn(event:FocusEvent):void
	{
		focus = true;
		update();
	}
	
	private function onFocusOut(event:FocusEvent):void
	{
		focus = false;
		update();
	}
}
}