package lib.core.ui.controls
{
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

/**
 */
public class LabelButton extends ToggleButton
{
	//метка сделана DisplayObject, чтобы в наследниках можно было задать более сложный компонет для рендеринга текста, чем просто TextField
	protected var _labelField:Object;
	public function get labelField():TextField{return _labelField as TextField;};

	/**
	 *
	 */
	public var autoSize:Boolean = true;

	public var align:String = "center";
	public var valign:String = "middle";

	/**
	 * фильтры (один фильтр или массив) на текст по состояниям
	 * [
	 *  UP фильтры,
	 *  OVER || SELECTED_OVER фильтры,
	 *  DOWN || SELECTED_UP || SELECTED_DOWN фильтры,
	 *  null,
	 *  DISABLED фильтры,
	 *  SELECTED_UP фильтры,
	 *  SELECTED_OVER фильтры,
	 *  SELECTED_DOWN фильтры,
	 * ]
	 */

	public var filtersLabel:Array = [];

	protected var userFiltersLabel:Boolean = false;

	public function LabelButton ()
	{
		createContent();
	}

	protected function createContent():void
	{
		_labelField = new TextField();
		_labelField.autoSize = TextFieldAutoSize.LEFT;
		_labelField.selectable = false;
		_labelField.mouseEnabled = false;
//		_labelField.border = true;
		addChild(_labelField as TextField);
	}

	protected override function arrangeContent():void
	{
		if(_labelField && label)
		{
			_labelField.multiline = _labelField.wordWrap = multiline;
			if(multiline)
			{
				_labelField.width = width - paddingLeft - paddingRight;
			}

			if(autoSize)
			{
				_width = _explicitWidth ? _explicitWidth : _labelField.width + paddingLeft + paddingRight;
				_height = _explicitHeight ? _explicitHeight : _labelField.height + paddingTop + paddingBottom;

				_width = Math.max(minWidth, _width);
				_height = Math.max(minHeight, _height);

				_width = Math.min(maxWidth, _width);
				_height = Math.min(maxHeight, _height);
			}

			if(align == "center")
			{
				_labelField.x = int(_width/2 - _labelField.width/2);
			}else if(align == "right")
			{
				_labelField.x = int(_width - _labelField.width - paddingRight);
			}else if(align == "left")
			{
				_labelField.x = int(paddingLeft);
			}

			if(valign == "top")
			{
				_labelField.y = paddingTop;
			}else if(valign == "middle")
			{
				_labelField.y = int(_height/2 - _labelField.height/2);
			}else if(valign == "bottom")
			{
				_labelField.y = int(_height - _labelField.height - paddingBottom);
			}
		}

//		Logger.debug('arrangeContent : wxh='+width,'x',height, this);
		super.arrangeContent();
	}

//	protected override function updateState():void
//	{
//		var anim:Boolean = _animating;
//
//		super.updateState();
//
//		if(!anim)
//			updateStateFormat();
//	}

	protected override function setCurrentState(state:int):void
	{
		var cachedAnim:Boolean = _animating;

		super.setCurrentState(state);

		if(!cachedAnim || !enabled)
			updateStateFormat();
	}

	protected function updateStateFormat(arrangeLaterFlag:Boolean = false):void
	{
		var format:TextFormat;

		if(!enabled)
		{
			format = labelDisabledFormat;
		}else
		{
			format = getMouseStateFormat(mouseState);
		}

		if(format)
		{
			_labelField.defaultTextFormat = format;
			_labelField.setTextFormat(format);
			arrangeLaterFlag ? arrangeLater() : arrangeContent();
		}

		//выставляем фильтры, только если они явно заданы
		if(filtersLabel && filtersLabel.length > 0)
		{
			var state:int = getCurrentState();
			var flts:Object = filtersLabel && filtersLabel.length >= state ? filtersLabel[state-1] : null;
			if (!flts && filtersLabel.length == 1)
				flts = filtersLabel[0];
			if(!flts && selected)
				flts = filtersLabel[selectSkinMap[state]-1];

			//trace("filter = ",filter," selected = ",selected, "state = ",state, "selectSkinMap = ",selectSkinMap[state]);
			_labelField.filters = flts ? (flts is Array ? flts as Array : [flts]) : [];
		}
	}
	
	protected function getMouseStateFormat(mouseState:String):TextFormat
	{
		var format:TextFormat;
		switch(mouseState)
		{
			case MouseEvent.ROLL_OVER:
				format = labelOverFormat || labelFormat;
				break;
			case MouseEvent.ROLL_OUT:
				format = selected ? labelDownFormat : labelFormat;
				break;
			case MouseEvent.MOUSE_DOWN:
				format = labelDownFormat || labelFormat;
				break;
			case MouseEvent.MOUSE_UP:
				format = labelOverFormat || labelFormat;
				break;
		}
		return format;
	}

	/**
	* embedFonts
	*/
	public function set embedFonts(value:Boolean):void
	{
		_labelField.embedFonts = value;
		arrangeContent();
	}
	
	override protected function updateState():void
	{
		commitLabel();
		
		super.updateState();
	}

	/**
	* label
	*/
	private var _label:String;
	public function set label(value:String):void
	{
		if(_label != value)
		{
			_label = value;
			commitLabel();
		}
	}

	public function get label():String
	{
		return _label ? _label : _labelField ? _labelField.text : null;
	}
	
	private var _selectedLabel:String;
	public function set selectedLabel(value:String):void
	{
		if (_selectedLabel != value)
		{
			_selectedLabel = value;
			commitLabel();
		}
	}
	
	public function get selectedLabel():String
	{
		return _selectedLabel ? _selectedLabel : label;
	}

	protected function commitLabel():void
	{
		if (labelField)
		{
			labelField.text = (selected && selectedLabel ? selectedLabel : label);
			arrangeLater();
		}
	}
	
	/**
	* label format
	*/
	private var _labelFormat:TextFormat;
	public function set labelFormat(value:TextFormat):void
	{
		_labelFormat = value;
		_labelField.defaultTextFormat = value;

		updateStateFormat(true);
	}

	public function get labelFormat():TextFormat
	{
		return _labelFormat;
	}

	/**
	* label mouse over format
	*/
	private var _labelOverFormat:TextFormat;
	public function set labelOverFormat(value:TextFormat):void
	{
		_labelOverFormat = value;

		updateStateFormat(true);
	}

	public function get labelOverFormat():TextFormat
	{
		return _labelOverFormat;
	}

	/**
	* label mouse down format
	*/
	private var _labelDownFormat:TextFormat;
	public function set labelDownFormat(value:TextFormat):void
	{
		_labelDownFormat = value;

		updateStateFormat(true);
	}

	public function get labelDownFormat():TextFormat
	{
		return _labelDownFormat;
	}

	/**
	* label disabled format
	*/
	private var _labelDisabledFormat:TextFormat;
	public function set labelDisabledFormat(value:TextFormat):void
	{
		_labelDisabledFormat = value;

		updateStateFormat(true);
	}

	public function get labelDisabledFormat():TextFormat
	{
		return _labelDisabledFormat;
	}

	/**
	* vertical padding
	*/
	private var _paddingV:Number = 3;
	public function set paddingV(value:Number):void
	{
		if(_paddingV != value)
		{
			_paddingV = value;
			_paddingTop = _paddingBottom = value;
			arrangeLater();
		}
	}
	public function get paddingV():Number
	{
		return _paddingV;
	}

	/**
	 * top padding
	 */
	private var _paddingTop:Number = 3;
	public function set paddingTop(value:Number):void
	{
		if(_paddingTop != value)
		{
			_paddingTop = value;
			arrangeLater();
		}
	}
	public function get paddingTop():Number
	{
		return _paddingTop;
	}

	/**
	 * bottom padding
	 */
	private var _paddingBottom:Number = 3;
	public function set paddingBottom(value:Number):void
	{
		if(_paddingBottom != value)
		{
			_paddingBottom = value;
			arrangeLater();
		}
	}
	public function get paddingBottom():Number
	{
		return _paddingBottom;
	}

	/**
	* vertical padding
	*/
	private var _paddingH:Number = 8;
	public function set paddingH(value:Number):void
	{
		if(_paddingH != value)
		{
			_paddingH = value;
			_paddingLeft = _paddingRight = value;
			arrangeLater();
		}
	}
	public function get paddingH():Number
	{
		return _paddingH;
	}

	/**
	 * left padding
	 */
	private var _paddingLeft:Number = 8;
	public function set paddingLeft(value:Number):void
	{
		if(_paddingLeft != value)
		{
			_paddingLeft = value;
			arrangeLater();
		}
	}
	public function get paddingLeft():Number
	{
		return _paddingLeft;
	}

	/**
	 * right padding
	 */
	private var _paddingRight:Number = 8;
	public function set paddingRight(value:Number):void
	{
		if(_paddingRight != value)
		{
			_paddingRight = value;
			arrangeLater();
		}
	}
	public function get paddingRight():Number
	{
		return _paddingRight;
	}

	protected var _minWidth:Number = 0;
	public function get minWidth():Number {return _minWidth;}
	public function set minWidth(value:Number):void {_minWidth = value;}

	protected var _minHeight:Number = 0;
	public function get minHeight():Number {return _minHeight;}
	public function set minHeight(value:Number):void {_minHeight = value;}

	protected var _maxWidth:Number = 1000;
	public function get maxWidth():Number {return _maxWidth;}
	public function set maxWidth(value:Number):void {_maxWidth = value;}

	protected var _maxHeight:Number = 1000;
	public function get maxHeight():Number {return _maxHeight;}
	public function set maxHeight(value:Number):void {_maxHeight = value;}

	protected var _multiline:Boolean = false;
	public function get multiline():Boolean {return _multiline;}
	/**
	 * мультилайновое текстовое поле.
	 * Ширина поля будет равняться ширине кнопки (минус педдинги)
	 * autoSize кнопки в этом случае будет работать только по высоте
	 * @param value
	 *
	 */
	public function set multiline(value:Boolean):void {_multiline = value; arrangeLater();}
}

}