package lib.core.ui.controls
{
import lib.core.ui.managers.KeyboardDispatcher;
import lib.core.ui.skins.SkinsManager;
import lib.core.util.Graph;
import lib.core.util.log.Logger;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.InteractiveObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Keyboard;

[Event(name="popupOk", type="lib.core.ui.controls.PopupEvent")]
[Event(name="popupCancel", type="com.kamagames.ui.view.controls.PopupEvent")]
[Event(name="popupHide", type="com.kamagames.ui.view.controls.PopupEvent")]

/**
 * Popup.
 *
 * <p>Popup is a container that is hidden (closed)
 * most of the time, but is brought visible in certain
 * situations. By default popups are modal, that means:
 * user can't access the other UI-components
 * before the popup is closed. </p>
 */
public class Popup extends Sprite
{
	public static var TITLE_FORMAT:TextFormat = new TextFormat("Arial", 20, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER);
	public static var BODY_FORMAT:TextFormat = new TextFormat("Arial", 16, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER);

	protected static const FIRST_NAME:String = 'firstButton';
	protected static const SECOND_NAME:String = 'secondButton';
	protected static const CLOSE_NAME:String = 'closeButton';

	public static const DEFAULT_WIDTH : Number = 290;

	protected var vPadding : Number = 10;
	protected var hPadding : Number = 10;
	
	protected var spacing : Number = 10;

	private var kbDispatcher:KeyboardDispatcher;

	protected static var _popupHolder:DisplayObjectContainer;

	public static var okButtonRenderer:Class = LabelButton;
	public static var cancelButtonRenderer:Class = LabelButton;

	public static var popupRenderer:Class = Popup;

	public static var popupInfoTitle:String = "Инфо: ";
	public static var popupErrorTitle:String = "Ошибка: ";
	public static var okLabel:String = "OK";
	public static var cancelLabel:String = "Отмена";
	public static var yesLabel:String = "Да";
	public static var noLabel:String = "Нет";

	public static var modalColor:uint = 0x000000;
	public static var modalAlpha:Number = 0;
	/**
	 * отступы при центрировании, если например центрировать надо не относительно центра
	 */
	protected var paddingV:int = 0;
	protected var paddingH:int = 0;

	private var _textField:TextField;
	/**
	 * Текстовое поле в теле попапа.
	 * @return
	 *
	 */
	public function get textField():TextField
	{
		return _textField;
	}
	private var _titleField:TextField;
	/**
	 * Текстовое поле заголовка попапа.
	 * @return
	 *
	 */
	public function get titleField():TextField
	{
		return _titleField;
	}

	protected var bkg:DisplayObject;
	protected var content:DisplayObject;

	public static function set popupHolder(value:DisplayObjectContainer):void
	{
		_popupHolder = value;
	}

	public static function get popupHolder():DisplayObjectContainer
	{
		return _popupHolder;
	};

	public static var stage:Stage;

	protected static var skinManager:SkinsManager;
	
	protected static var borderId:String = "windowBorder";

	protected var closeOnEsc:Boolean = false;

	protected var modal:Boolean;
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 */
	public function Popup(modal:Boolean = true)
	{
		super();

		this.modal = modal;
		width = DEFAULT_WIDTH;
		skinManager = SkinsManager.instance;

		addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);

		visible = false;

		//filters = [new DropShadowFilter()];
		focusRect = false;
	}

	protected function addedToStageHandler(event:Event):void
	{
		centerPopup();

		if(modal)
			makeModal();

//		addEventListener(KeyboardEvent.KEY_DOWN, onKeyboard, false, 1, true);
//		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboard, false, 1, true);
		stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);

		kbDispatcher = new KeyboardDispatcher(stage);
		kbDispatcher.addEventListener(KeyboardEvent.KEY_UP, onKeyboard);
	}

	public function addEventListeners (ok:Function=null, cancel:Function=null, hide:Function=null, priority:int=0):void
	{
		if (ok is Function)
		{
			addEventListener(PopupEvent.POPUP_OK, ok, false, priority, true);
		}
		if (cancel is Function)
		{
			addEventListener(PopupEvent.POPUP_CANCEL, cancel, false, priority, true);
		}
		if (hide is Function)
		{
			addEventListener(PopupEvent.POPUP_HIDE, hide, false, priority, true);
		}
	}

	public function removeEventListeners (ok:Function=null, cancel:Function=null, hide:Function=null):void
	{
		if (ok is Function)
		{
			removeEventListener(PopupEvent.POPUP_OK, ok, false);
		}
		if (cancel is Function)
		{
			removeEventListener(PopupEvent.POPUP_CANCEL, cancel, false);
		}
		if (hide is Function)
		{
			removeEventListener(PopupEvent.POPUP_HIDE, hide, false);
		}
	}

	//--------------------------------------------------------------------------
	//
	//  Static
	//
	//--------------------------------------------------------------------------

	/**
	 * Попап ошибки к кнопкой ok.
	 * @param msg
	 * @param title
	 * @param hideButtons
	 * @param btnlabel
	 *
	 */
	public static function error(msg:String, title:String = null, hideButtons:Boolean = false, btnlabel:String = null ):void
	{
		btnlabel = btnlabel == null ? okLabel : btnlabel;

		var popup:Popup = msgOneButtonDialog(title, msg, hideButtons? null : btnlabel);

		//var holder:DisplayObjectContainer = parent ? parent : popupHolder;
		var holder:DisplayObjectContainer = popupHolder;
		holder.addChild(popup);
		popup.show();

		Logger.error("Popup::error", title, msg);
	}

	/**
	 *
	 * @param msg
	 * @param hideButtons
	 * @param btnlabel
	 *
	 */
	public static function msg(msg:String, hideButtons:Boolean = false, btnlabel:String = null ):Popup
	{
		btnlabel = btnlabel == null ? okLabel : btnlabel;

		var popup:Popup = msgOneButtonDialog(null, msg, hideButtons ? null : btnlabel);

		//var holder:DisplayObjectContainer = parent ? parent : popupHolder;
		var holder:DisplayObjectContainer = popupHolder;
		holder.addChild(popup);
		popup.show();

		Logger.debug("Popup::msg", msg);
		
		return popup;
	}

	/**
	 * Popup some content, add standart border, buttons, title and closeButton
	 * @param content
	 * @param title
	 * @param label1
	 * @param label2
	 * @param closeBtn whether show close button
	 * @return
	 *
	 */
	public static function popup(content:DisplayObject, title:String = null, label1:String = null, label2:String = null, closeBtn:Boolean = false):Popup
	{
		label1 = label1 == null ? okLabel : label1;

		var popup:Popup = label2 ?
			msgTwoButtonDialog(null, title, label1, label2, content, closeBtn) :
			msgOneButtonDialog (title, null, label1, content, closeBtn);

		//var holder:DisplayObjectContainer = parent ? parent : popupHolder;
		var holder:DisplayObjectContainer = popupHolder;
		if(holder)
			holder.addChild(popup);
		popup.show();
		return popup;
	}


	/**
	 * Shows info message with OK button.
	 *
	 * @param msg message for user in popup.
	 */
	public static function info(msg:String, title:String = null, hideButtons:Boolean = false, btnlabel:String = null, closeBtn:Boolean = false, action:Function = null, content:DisplayObject = null):Popup
	{
		btnlabel = btnlabel == null ? okLabel : btnlabel;

		//title = title == null ? popupInfoTitle : title;

		var popup:Popup = msgOneButtonDialog (title, msg, hideButtons? null : btnlabel, content, closeBtn);

		//var holder:DisplayObjectContainer = parent ? parent : popupHolder;
		var holder:DisplayObjectContainer = popupHolder;
		if(holder)
			holder.addChild(popup);

		if (action != null)
			popup.addEventListener(PopupEvent.POPUP_OK, action, false, 0, true);

		popup.show();
		return popup;
	}

	/**
	 * Shows confirm dialog
	 * with action for OK button.
	 * Action calls with button event object in it.
	 *
	 * @param msg text in popup.
	 * @param action action called when click on button "OK".
	 * @param data additional data, will be attached to event object
	 * @param parent
	 * @param buttonMode indicates which buttons will be in popup.
	 */
	public static function confirm(msg:String, action:Function = null, data:* = null, title:String = null, label1:String = null, label2:String = null, closeBtn:Boolean = false, content:DisplayObject = null):Popup
	{
		label1 = label1 == null ? yesLabel : label1;
		label2 = label2 == null ? noLabel : label2;

		var popup:Popup = msgTwoButtonDialog(msg, title, label1, label2, content, closeBtn);
		popup.data = data;

		if(action is Function)
		{
			popup.addEventListener(PopupEvent.POPUP_OK, action, false, 0, true);
			popup.addEventListener(PopupEvent.POPUP_CANCEL, action, false, 0, true);
			popup.addEventListener(PopupEvent.POPUP_HIDE, action, false, 0, true);
		}

		popup.show();
		return popup;
	}

	/**
	 * Shows prompt dialog with input area and OK and Cancel buttons.
	 * OK button calls action function with button event object and
	 * typed message as input parameters.
	 *
	 * @param msg message in popup
	 * @param action action called when click on button "OK"
	 * @param parent
	 * @param allowEmptyAnswer indicates whether
	 * is empty string in input area allowed.
	 */
	public static function prompt (msg:String, action:Function, parent:DisplayObject = null, allowEmptyAnswer:Boolean = false):void
	{

	}

	//--------------------------------------------------------------------------
	//
	//  Private
	//
	//--------------------------------------------------------------------------

	/**
	 * Show dialog message with OK button and message string in it.
	 * It may be info or error dialog
	 *
	 * @param title title of popup window
	 * @param msg message for user
	 * @param parent
	 */
	protected static function msgOneButtonDialog(title:String, msg:String, label:String, content:DisplayObject = null, closeBtn:Boolean = false):Popup
	{
		var popup:Popup = new popupRenderer();
		popup.createOneButtonDialog(title, msg, label, content, closeBtn);
		return popup;
	}

	/**
	 * метод создания окна с заголовком, текстом/кастомным контентом, кнопкой закрыть, одной кнопкой
	 * можно переопределить в наследниках
	 * @param title
	 * @param msg
	 * @param label
	 * @param content
	 * @param closeBtn
	 *
	 */
	protected function createOneButtonDialog(title:String, msg:String, label:String, content:DisplayObject = null, closeBtn:Boolean = false):void
	{
		//bkg
		bkg = createBkg();
		addChildAt(bkg, 0);

		if(title == '')
			title = null;
		var titleField:TextField = createText(TITLE_FORMAT);
		titleField.width = width - 2*hPadding;
		titleField.x = hPadding;
		titleField.y = vPadding;

		titleField.text = title ? title : '';
		addChild(titleField);
		_titleField = titleField;

		if(msg)
		{
			var msgField:TextField = createText(BODY_FORMAT);
			msgField.text = msg;
			if(msgField.height > 400)
			{
				msgField.autoSize = TextFieldAutoSize.NONE;
				msgField.height = 400;
			}
			msgField.width = width - 2*hPadding;

			_textField = msgField;

			content = msgField;
		}
		else if(content)
		{
			width = Math.max(content.width, titleField.width) + 2*hPadding;
		}
		if(!content)
			content = new Shape();

		if(closeBtn)
		{
			var closeButton:DisplayObject = createCloseButton();
			if(closeButton)
			{
				addChild(closeButton);
				closeButton.x = width - closeButton.width - hPadding;
				closeButton.y = vPadding;
				closeButton.name = CLOSE_NAME;
			}

			titleField.width -= (closeButton.width + 5);
		}

		this.content = content;
		content.x = width/2 - content.width/2;
		content.y = title ? titleField.y + titleField.height + spacing : closeButton ? (closeButton.y + closeButton.height) : vPadding;
		addChild(content);

		var h:int = vPadding + content.y + content.height;

		if(label)
		{
			var ok:DisplayObject;
			var popupH:Number =  2*vPadding + spacing + titleField.height + content.height;
			//ok button
			ok =  addChild(createButton(label, okButtonRenderer));
			ok.x = int(width/2 - ok.width/2);
			ok.addEventListener(MouseEvent.CLICK, okHandler, false, 0, true);
			ok.y = int(content.y + content.height + spacing);
			ok.name = FIRST_NAME;
		}

		if(ok)
			h+=ok.height+spacing;

		height= h;
	}
	
	protected function createBkg():DisplayObject
	{
		var skin:Sprite = skinManager.getSkin(borderId) as Sprite;
		return skin ? skin : defaultBkg();
	}
	
	protected static function msgTwoButtonDialog(msg:String, title:String, label1:String, label2:String, content:DisplayObject = null, closeBtn:Boolean = false):Popup
	{
		var popup:Popup = new popupRenderer();
		popup.createTwoButtonDialog(title, msg, label1, label2, content, closeBtn);

		return popup;
	}

	protected function createTwoButtonDialog(title:String, msg:String, label1:String, label2:String, content:DisplayObject = null, closeBtn:Boolean = false):void
	{
		createOneButtonDialog(title, msg, label1, content, closeBtn);

		var first:LabelButton = LabelButton(getChildByName(FIRST_NAME));
		var second:Sprite;

		//ok button
		first.x = hPadding;

		//cancel button
		second = Sprite(addChild(createButton(label2, cancelButtonRenderer)));
		var sumWidth:int = first.width + second.width + hPadding;
		first.x = (width - sumWidth) >> 1;
		second.x = int(first.x + first.width + hPadding);
		second.addEventListener(MouseEvent.CLICK, cancelHandler, false, 0, true);
		second.y = int(first.y);
		second.name = SECOND_NAME;
	}

	protected function createText(format:TextFormat = null):TextField
	{
		var tf:TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		if(format)
		{
			tf.defaultTextFormat = format;
		}

		tf.multiline = true;
		tf.wordWrap = true;

		return tf;
	}

	protected function createButton(text:String, buttonRenderer:Class):Sprite
	{
		var btn:LabelButton;
		try{
			btn = new buttonRenderer();
			btn.label = text;
			btn.arrange();
		}catch(err:Error){

		}
		return btn;
	}

	protected function createCloseButton():DisplayObject
	{
		var btn:DisplayObject = skinManager.getSkin("CloseWinBtn");
		if (btn)
		{
			btn.addEventListener(MouseEvent.CLICK, closeHandler);
			if(btn is DisplayObjectContainer) DisplayObjectContainer(btn).mouseChildren = false;
		}
		return btn;
	}

	protected function defaultBkg():DisplayObject
	{
		var bkg:Sprite = new Sprite();
		Graph.drawRoundRectAsFill(bkg.graphics, 0, 0, 60, 60, 15, 0x000000, 0x666666, 0, .8, .8);
		bkg.scale9Grid = new Rectangle(15, 15, 30, 30);
		return bkg;
	}

	protected var _data:Object;
	public function set data(value:Object):void
	{
		_data = value;
	}

	public function get data():Object
	{
		return _data;
	}

	protected function okHandler(event:Event, popup:Popup = null):void
	{
		var popupEvent:PopupEvent = new PopupEvent(PopupEvent.POPUP_OK);
		popupEvent.data = data;
		dispatchEvent(popupEvent);
		hide();
	}

	protected function cancelHandler(event:Event):void
	{
		var popupEvent:PopupEvent = new PopupEvent(PopupEvent.POPUP_CANCEL);
		popupEvent.data = data;
		dispatchEvent(popupEvent);
		hide();
	}

	protected function closeHandler(event:Event, popup:Popup = null):void
	{
		var popupEvent:PopupEvent = new PopupEvent(PopupEvent.POPUP_HIDE);
		popupEvent.data = data;
		dispatchEvent(popupEvent);
		hide();
	}

	protected function centerPopup(event:Event = null):void
	{
		var holder:DisplayObject = Popup.stage ? Popup.stage : parent;
		var stg:Stage = holder as Stage || stage;
		
		if(stg)
		{
			x = int(stg.stageWidth/2 - width/2 - paddingH);
			y = int(stg.stageHeight/2 - height/2 - paddingV);
		}
		else if (holder)
		{
			x = int(holder.width/2 - width/2);
			y = int(holder.height/2 - height/2);
		}
	}

	protected var modalHolder:Sprite;
	protected function makeModal(event:Event = null):void
	{
		if(!stage)
			return;

		if(!modalHolder)
		{
			modalHolder = new Sprite();
			addChildAt(modalHolder, 0);
		}
		modalHolder.graphics.clear();
		Graph.drawFillRec(modalHolder.graphics, 0, 0, stage.stageWidth, stage.stageHeight, modalColor, modalAlpha);
//		modalHolder.filters = [new BlurFilter()];
		modalHolder.mouseEnabled = false;

		var p:Point = new Point(-x, -y);
		p = stage.localToGlobal(p);
		modalHolder.x = p.x;
		modalHolder.y = p.y;
	}

	//--------------------------------------------------------------------------
	//
	//  Event handlers
	//
	//--------------------------------------------------------------------------
	/**
	 * Method closes popup window.
	 */
	public function hide():void
	{
		if(stage && prevFocus)
		{
			//TODO: прячем желтую обводку
			//prevFocus.focusRect = false;
			//stage.focus = prevFocus;
		}

		if(parent)
			parent.removeChild(this);

		kbDispatcher.removeEventListener(KeyboardEvent.KEY_UP, onKeyboard);
	}

	private function onStageResize(event:Event):void
	{
		centerPopup();

		makeModal();
	}

	private function onKeyboard(event:KeyboardEvent):void
	{
		var hasOkBtn:Boolean = getChildByName(FIRST_NAME) != null;
		if(event.keyCode == Keyboard.ESCAPE && (closeOnEsc || hasOkBtn))
			cancelHandler(event);
		else if(event.keyCode == Keyboard.ENTER)
		{
			//close if one button mode
			if(hasOkBtn && !getChildByName(SECOND_NAME))
				okHandler(event, this);
		}
	}

	protected var prevFocus:InteractiveObject;
	/**
	 * Method shows popup window.
	 */
	public function show():void
	{
		var holder:DisplayObjectContainer = popupHolder;
		if(holder)
			holder.addChild(this);

		visible = true;

		if(stage)
		{
			//переводим фокус на попап, чтобы фокус на оставался где-то в фоне, плюс чтобы слушать клаву
			//prevFocus = stage.focus;
			//stage.focus = this;
		}
	}

	protected function arrange():void
	{
		if (bkg)
		{
			bkg.width = width;
			bkg.height = height;
		}
	}

	protected var _width:Number;
	override public function set width (value:Number):void
	{
		_width = value;
		arrange();
	}
	override public function get width():Number
	{
		return isNaN(_width) ? super.width : _width;
	}

	protected var _height:Number;
	override public function set height(value:Number):void
	{
		_height = value;
		arrange();
	}
	override public function get height():Number
	{
		return isNaN(_height) ? super.height : _height;
	}

}
}