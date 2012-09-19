package lib.core.ui.controls
{
import lib.core.ui.list.ISelectable;
import lib.core.util.Graph;

import flash.display.DisplayObject;
import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.utils.Timer;

/**
 * Кнопка, может работать в toggle режиме. Основная особенность - широкая поддержка скинования:
 *
 * setState - любое из состояний отдельно
 * setSimpleState - скин (3 состояния + hit облать) задется кнопкой SimpleButton
 * setSelectedState - то же, что setSimpleState но для трех выделенных состоний
 *
 * setClipState - все 8 состояний (3 обычных, 3 выделенных, hit и disabled) через 8 кадровый MovieClip
 *
 * Одновременно можно использовать только [setState, setSimpleState, setSelectedState] или [setClipState]
 *
 */
[Event (name="select", type="flash.events.Event")]
public class ToggleButton extends Sprite implements ISelectable
{
	public static const UP:int = 1;
	public static const OVER:int = 2;
	public static const DOWN:int = 3;
	[Depracated("use hitArea property instead")]
	public static const HIT:int = 4;
	public static const DISABLED:int = 5;
	public static const SELECTED_UP:int = 6;
	public static const SELECTED_OVER:int = 7;
	public static const SELECTED_DOWN:int = 8;

	public static const ALL_SELECTED:String = 'allSelected';
	public static const ALL_UNSELECTED:String = 'allUnSelected';

	private var _showBorder:Boolean;
	public function set showBorder (value:Boolean):void
	{
		if(showBorder != value)
		{
			_showBorder = value;
			drawBorder();
		}
	}

	public function get showBorder ():Boolean
	{
		return _showBorder;
	}

	public var borderStyle:Object = {corner:5, borderThickness:1, borderColor:0x666666, borderAlpha:1, fillColor:0xCCCCCC, fillAlpha:0};
	/**
	 * выставить true для анимированных состояний кнопки, при этом
	 * саму анимацию делать в одном общем таймлайне по меткам
	 * state1, state2, ..., state8
	 */
	protected var _animStates:Boolean = false;

	/**
	 * максимальное заданое состояние в скине. Для неанимиронного клипа в качестве этого параметра используется
	 * общее количество кадров, для анимированного вычисляется при парсинге скина.
	 */
	protected var _maxClipSkinState:int = 0;

	/**
	 *	карта скинов для select состояния.
	 *  Если скин не задан, пытаемся использовать альтернативный скин из unselect состояния
	 */
	protected var selectSkinMap:Object;

	//используется когда в качестве скина передан MovieClip
	protected var _clip:MovieClip;
	
	/**
	 * По умолчанию кнопка растягивает скины всех состояний под один размер.
	 * Для сложных скинов, когда разные состояния имеют разные размеры и это не надо менять,
	 * выставить флаг в false, чтобы кнопка не меняла размер скина
	 */
	public var autoSizeSkin:Boolean = true;

	private var _selected:Boolean = false;
	private var _toggle:Boolean = false;

	protected var mouseState:String = MouseEvent.ROLL_OUT;

	protected var statesContent:Sprite;
	protected var statesMap:Array = [];

	protected var _data:Object;

	/**
	 * Если нужно, чтобы в кнопке работал 9скейлгрид правильно, нужно использовать враппер
	 * типа ScaleWrapper, который передавать сюда и соответственно при изменении размера
	 * меняться будут размеры через враппер
	 */
	public var clipSizeProxy:Object;

	/**
	 * фильтры (один фильтр или массив) для состояний
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
	public var filtersState:Array = [];

	public function ToggleButton ()
	{
		initInternal();
	}

	protected function initInternal():void
	{
		buttonMode = true;
		useHandCursor = true;

		statesContent = new Sprite();
		addChild(statesContent);

		initListeners();
		//updateState();

		//enabled = _enabled;
		_width = super.width;
		_height = super.height;

		mouseChildren = false;

		selectSkinMap = {};
		selectSkinMap[SELECTED_UP] = DOWN;
		selectSkinMap[SELECTED_OVER] = OVER;
		selectSkinMap[SELECTED_DOWN] = DOWN;
	}

	public function arrange():void
	{
		arrangeContent();
	}

	protected function arrangeLater():void
	{
		//arrangeContent();
		addEventListener(Event.ENTER_FRAME, onEnterFrameArrange);
	}

	protected function onEnterFrameArrange(event:Event):void
	{
		arrangeContent();
	}

	protected function arrangeContent():void
	{
		removeEventListener(Event.ENTER_FRAME, onEnterFrameArrange);

		if(autoSizeSkin)
		{
			var w:uint = _explicitWidth ? _explicitWidth : _width;
			var h:uint = _explicitHeight ? _explicitHeight : _height;

			if (clipSizeProxy)
			{
				clipSizeProxy.width = w;
				clipSizeProxy.height = h;
			}
			else if(_clip)
			{
				_clip.width = w;
				_clip.height = h;
			}else
			{
				var child:DisplayObject;
				for(var ii:uint = 0; ii<statesContent.numChildren; ii++)
				{
					child = statesContent.getChildAt(ii);
					child.width = w;
					child.height = h;
				}
			}
		}

		drawBorder();
	}

	protected function drawBorder():void
	{
		graphics.clear();

		if(!showBorder || !borderStyle)
		{
			return;
		}

		var r:int = borderStyle.corner;
		var bc:int = borderStyle.borderColor;
		var ba:Number = borderStyle.borderAlpha;
		var fc:int = borderStyle.fillColor;
		var fa:Number = borderStyle.fillAlpha;
		var bs:int = borderStyle.borderThickness;
		Graph.drawRoundRectAsFill(graphics, 0, 0, width, height, r, bc, fc, bs, ba, fa);
	}

	private function initListeners():void
	{
		addEventListener(MouseEvent.MOUSE_DOWN, onMouse, false, 1, true);
		addEventListener(MouseEvent.ROLL_OVER, onMouse, false, 1, true);
		addEventListener(MouseEvent.ROLL_OUT, onMouse, false, 1, true);
		addEventListener(MouseEvent.MOUSE_UP, onMouse, false, 1, true);

		addEventListener(MouseEvent.CLICK, onClick, false, 1, true);
	}

	private function removeListeners():void
	{
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouse, false);
		removeEventListener(MouseEvent.ROLL_OVER, onMouse, false);
		removeEventListener(MouseEvent.ROLL_OUT, onMouse, false);
		removeEventListener(MouseEvent.MOUSE_UP, onMouse, false);

		removeEventListener(MouseEvent.CLICK, onClick, false);
	}

	private function onClick(event:MouseEvent):void
	{
		if(!_enabled)
			event.stopImmediatePropagation();
		//trace("onClick");

		if(toggle)
			selected = !selected;
	}

	private function onMouse(event:MouseEvent):void
	{
		//trace("onMouse ::",event.type);
		mouseState = event.type;

		if(!_enabled)
			return;

		updateState();
	}

	protected function internalSetState(state:*, scale9grid:Rectangle = null):DisplayObject
	{
		var sprite:DisplayObject = state is Class ? new state() : state;
//		sprite.x = 0;
//		sprite.y = 0;
		sprite.visible = false;

		//if(!statesContent.contains(sprite))
			statesContent.addChild(sprite);
		if(scale9grid)
			sprite.scale9Grid = scale9grid;

		_width = Math.max(_width, sprite.width);
		_height = Math.max(_height, sprite.height);

		return sprite;
	}

	/**
	 *
	 * @param skin
	 * @param posToClip переместить кнопку в координаты клипа (часто бывает нужно)
	 *
	 */
	public function setClipState(skin:MovieClip, posToClip:Boolean = false):void
	{
		if (statesContent && _clip && statesContent.contains(_clip))
			statesContent.removeChild(_clip);

		clearSkins();

		if(skin)
		{
			_clip = skin as MovieClip;
			_clip.stop();
			if(posToClip)
			{
				x = _clip.x;
				y = _clip.y;
			}
			_clip.x = 0;
			_clip.y = 0;
			if(!animStates)
				_maxClipSkinState = _clip.totalFrames;
			else
				commitAnimState();

			statesContent.addChild(_clip);

			_width = clipSizeProxy ? clipSizeProxy.width : _clip.width;
			_height = clipSizeProxy ? clipSizeProxy.height : _clip.height;
		}

		updateState();
//		commitAnimState();
	}

	/**
	 * unselected state by simple button or 3-5 frame movie clip
	 * @param button
	 *
	 */
	public function setSimpleState(skin:SimpleButton):void
	{
		if(!skin)
			return;

		statesMap[DOWN] = internalSetState(skin.downState);
		statesMap[OVER] = internalSetState(skin.overState);
		statesMap[UP] = internalSetState(skin.upState);
//		statesMap[HIT] = internalSetState(skin.hitTestState);
//		statesMap[HIT].alpha = 0;

		updateState();
	}

	/**
	 * selected state by simple button or 3-5 frame movie clip
	 * @param button
	 *
	 */
	public function setSelectedState(skin:SimpleButton):void
	{
		statesMap[SELECTED_DOWN] = internalSetState(skin.downState);
		statesMap[SELECTED_OVER] = internalSetState(skin.overState);
		statesMap[SELECTED_UP] = internalSetState(skin.upState);

		updateState();
	}

	protected function clearSkins():void
	{
		if(statesContent && contains(statesContent))
		{
			statesContent = new Sprite();
			addChildAt(statesContent, 0);
		}
	}

	/**
	 *
	 * @param type тип состояния из констант
	 * @param state
	 * @param scale9grid
	 *
	 */
	public function setState(type:Object, state:*, scale9grid:Rectangle = null):void
	{
		if(!state)
			return;

		if(type == ALL_SELECTED)
		{
			statesMap[SELECTED_DOWN] = internalSetState(state, scale9grid);
			statesMap[SELECTED_OVER] = internalSetState(state, scale9grid);
			statesMap[SELECTED_UP] = internalSetState(state, scale9grid);
		}else if(type == ALL_UNSELECTED)
		{
			statesMap[DISABLED] = internalSetState(state, scale9grid);
			statesMap[DOWN] = internalSetState(state, scale9grid);
			statesMap[OVER] = internalSetState(state, scale9grid);
			statesMap[UP] = internalSetState(state, scale9grid);
//			statesMap[HIT] = internalSetState(state, scale9grid);
//			statesMap[HIT].alpha = 0;
		}else
		{
			statesMap[type] = internalSetState(state, scale9grid);
		}

		updateState();
	}

	protected var prevStateSprite:DisplayObject;
	protected var _currentState:int;
	/**
	 * Выставляем скин для состояния
	 * @param state
	 *
	 */
	protected function setCurrentState(state:int):void
	{
		if(prevStateSprite)
			prevStateSprite.visible = false;

		if(_clip)
		{
			if(animStates)
			{
				if(!enabled)
				{
					_clip.gotoAndStop("state"+state);
					_endAnim = false;
					_animating = false;
				}
				else
				{
					if(skipOverAnimOnDown && _animating)
					{
						//проверяем что сейчас играется анимация наведения, а надо перейти в down
						if(state - _stateAnim == 1)
							_animating = false;
					}
//					Logger.debug(this, "setCurrentState: ",state, "_animating = ",_animating, "prevState = ",_currentState+", _endAnim = "+_endAnim, ", _maxState=",_maxClipSkinState);
					if(!_animating)
					{
						//если предыдущее состояние имеет анимацию завершения играем ее, иначе играем анимацию нового стейта
						if(_endAnim)
						{
							_animating = true;
							_clip.play();
							_endAnim = false;
						}else if(animatedStates[state-1])
						{
							_animating = true;
							_clip.gotoAndPlay("state"+state);
							_stateAnim = state;
						}else
						{
							_clip.gotoAndStop("state"+state);
						}
					}
				}
			}else
			{
				_clip.gotoAndStop(state)
			}
		}
		else if(statesMap[state])
		{
			statesMap[state].visible = true;
			prevStateSprite = statesMap[state];
		}

		_currentState = state;
	}

	protected function updateState():void
	{
		var state:int = getCurrentState();

		//trace("updateState, state = ",state);

		//выставляем фильтры
		var flts:Object = filtersState && filtersState.length >= state ? filtersState[state-1] : [];
		if (!flts && filtersState.length == 1)
			flts = filtersState[0];
		if(!flts && selected)
			flts = filtersState[selectSkinMap[state]-1];

		//trace("filter = ",filter," selected = ",selected, "state = ",state, "selectSkinMap = ",selectSkinMap[state]);
		statesContent.filters = flts ? (flts is Array ? flts as Array : [flts]) : [];

		//проверяем на наличие скина
		if(_clip)
		{
			state = _maxClipSkinState >= state ? state : selectSkinMap[state];
		}else
		{
			state = statesMap[state] ? state : statesMap[selectSkinMap[state]] ? selectSkinMap[state] : UP;
		}

		if(state)
		{
			//alpha = 1;
			setCurrentState(state);
		}else if(!enabled)
		{
			//в дизаблед состояни если нет скина устанавливаем скин UP
			setCurrentState(selected ? selectSkinMap[UP] : UP);
			//alpha = .7;
		}

		arrangeContent();
	}

	protected function getCurrentState():int
	{
		var state:int = UP;

		if(!enabled)
		{
			state = DISABLED;
		}else
		{
			switch(mouseState)
			{
				case MouseEvent.ROLL_OVER:
					state = selected ? SELECTED_OVER : OVER;
					break;
				case MouseEvent.ROLL_OUT:
					state = selected ? SELECTED_UP : UP;
					break;
				case MouseEvent.MOUSE_DOWN:
					state = selected ? SELECTED_DOWN : DOWN;
					break;
				case MouseEvent.MOUSE_UP:
					state = selected ? SELECTED_UP : OVER;
					break;
			}
		}

		return state;
	}

	/**
	 *
	 * @param value
	 *
	 */
	public function set toggle(value:Boolean):void
	{
		_toggle = value;
		if(!_toggle)
			selected = false;
	}

	public function get toggle():Boolean
	{
		return _toggle;
	}

	public function set selected(value:Boolean):void
	{
		if(_selected != value)
		{
			_selected = value;
			updateState();

			dispatchEvent(new Event(Event.SELECT));
		}
	}

	public function get selected():Boolean
	{
		return _selected;
	}

    /**
     *  @private
     *  Storage for the width property.
     */
    protected var _width:Number;
    protected var _explicitWidth:Number;

    override public function get width():Number
    {
        return _explicitWidth ? _explicitWidth : _width;
    }

    /**
     *  @private
     */
    override public function set width(value:Number):void
    {
        _explicitWidth = value;
        if (_width != value)
        {
            _width = value;

            dispatchEvent(new Event("widthChanged"));
            arrangeContent();
        }
    }

    /**
     *  @private
     *  Storage for the height property.
     */
    protected var _height:Number;
    protected var _explicitHeight:Number;

    override public function get height():Number
    {
        return _explicitHeight ? _explicitHeight : _height;
    }

    /**
     *  @private
     */
    override public function set height(value:Number):void
    {
        _explicitHeight = value;
        if (_height != value)
        {
            _height = value;

            dispatchEvent(new Event("heightChanged"));
            arrangeContent();
        }
    }


	private var _enabled:Boolean = true;
	public function set enabled (value:Boolean):void
	{
		if(_enabled != value)
		{
			_enabled = value;
			buttonMode = value;
			//mouseEnabled = value;
			useHandCursor = value;

			/*if(_enabled)
				initListeners();
			else
				removeListeners();*/

			updateState();
		}
	}

	public function get enabled ():Boolean
	{
		return _enabled;
	}

	public function get data():Object
	{
		return _data;
	}

	public function set data(value:Object):void
	{
		if (value != _data)
		{
			_data = value;
			commitData();
		}
	};

	protected function commitData():void
	{
	}

	/*
	 *
	 Мигание по таймеру
	 */
	private var blinkTimer:Timer = new Timer(200);
	public var blinkTime:int = 200;

	private var _blink:Boolean = false;
	public function set blink(value:Boolean):void
	{
		if(_blink != value)
		{
			_blink = value;
			if(_blink)
			{
				blinkTimer.addEventListener(TimerEvent.TIMER, onBlickTimer);
				blinkTimer.delay = blinkTime;
				blinkTimer.start();
			}else
			{
				blinkTimer.removeEventListener(TimerEvent.TIMER, onBlickTimer);
				blinkTimer.stop();
				updateState()
//				setCurrentState(UP);
			}
		}
	}

	public function get blink():Boolean{
		return _blink;
	}

	private function onBlickTimer(event:TimerEvent):void
	{
		if(enabled && !selected && mouseState == MouseEvent.ROLL_OUT)
		{
			var state:int = blinkTimer.currentCount%2 ? OVER : UP;
			setCurrentState(state);
		}
	}

	/*
	 *
	 Анимация перехода по состояиям
	 */

	/**
	 * 	Cписок анимируемых состояний. Можно назначить массив снаружи, это оптимизирует кнопку, не будут обрабатываться состояния
	 *	в которых заведомо нет анимации, т.к. сама кнопка не может определить, есть анимация в состоянии или нет.
	 */
	public var animatedStates:Array = [1, 1, 1, 0, 0, 1, 1, 1];
	//играет анимация состояния
	protected var _animating:Boolean = false;

	//текущее анимируемое состояние
	protected var _stateAnim:int;

	//есть ли завершающая анимация для текущего анимируемого состояния
	protected var _endAnim:Boolean;
	 /**
	  * храним флаги состояний в которых есть анимация
	  */
	 protected var _animStatesEndMap:Object = {};

	 /**
	  * Конпка играет анимацию состояний.
	  * Выставить в true, чтобы включить анимацию так же необходимо назначить анимированный скин - setClipState с клипом в специально формате:
	  * анимация состояний проигрывается по меткам state1, state1, ..., state8 в таймлайне скина.
	  * Так же каждому состоянию можно (опционально) назначить анимацию входа в состояни и выхода из состояния, для
	  * этого надо после метки анимации stateN добавить метку stateNend - метка завершения анимации входа и начала анимации выхода.
	  * Кнопка проиграет анимацию и оставновится на метке stateNend, при смене состояни сначала завершится анимация выхода, потом начнется
	  * анимация следующего состояния.
	  * @param value
	  *
	  */
	 public function set animStates(value:Boolean):void
	 {
	 	if(_animStates != value)
	 	{
	 		_animStates = value;

	 		commitAnimState();
	 	}
	 }

	 public function get animStates():Boolean
	 {
	 	return _animStates;
	 }

	 /**
	  * Пропускать анимацию наведения при down мыши по кнопке.
	  * Флаг бывает полезен в ряде случаев, чтобы не было задержки на анимацию наведения при клике
	  * по кнопке.
	  */
	 public var skipOverAnimOnDown:Boolean = false;

	 /**
	  * парсим анимированный скин
	  *
	  */
	 protected function commitAnimState():void
	 {
	 	if(!_clip)
	 		return;

	 	if(animStates)
	 	{
	 		//вешаем скрипт на каждый кадр с меткой stateNend
	 		var frames:Array = [];
	 		var framesEnd:Array = [];
	 		var labels:Array = _clip.currentLabels;
	 		var frame:int;
	 		_animStatesEndMap = {};
	 		_maxClipSkinState = 0;

	 		//смотрим все метки в скине и помечаем номера кадров с метками, чтобы потом повесить на эти кадры скрип
	 		for each(var lbl:FrameLabel in labels)
	 		{
	 			frame = parseInt(lbl.name.substring(5, 6));
	 			if(lbl.name.indexOf("end") >= 0)
	 			{
	 				_animStatesEndMap[frame] = true;
	 				framesEnd[frame] = lbl.frame;
	 			}
	 			else
	 				frames[frame] = lbl.frame;
	 		}

			var i:int;
	 		//вешаем на кадры с метками скрипты onAnimStateEnd (завершение анимации входа в состояние, если есть)
	 		//и onAnimStateComplete (завершение анимации состояния)
	 		for(i = 1; i<=8; i++)
	 		{
	 			if(int(framesEnd[i]) > 1)
	 				_clip.addFrameScript(int(framesEnd[i])-2, onAnimStateEnd);
	 			if(int(frames[i]) > 1)
	 				_clip.addFrameScript(int(frames[i])-2, onAnimStateComplete);
	 		}

			//считаем последнее заданное состояние в скине, чтобы потом делать проверку, задан ли стейт  прежде, чем в него переходитб
			for(i = 8; i>=1; i--)
			{
				if(frames[i])
				{
					_maxClipSkinState = i;
					break;
				}
			}


	 		if(!_maxClipSkinState)
	 			_maxClipSkinState = 8;

	 		//отдельно вешаем скрит на последний кадр
	 		_clip.addFrameScript(_clip.totalFrames-1, onAnimStateComplete);

//			Logger.debug(this, "commitAnimState, _maxState = ", _maxClipSkinState);
	 	}
	 }


	 /**
	  * Завершение анимации входа в состояние.
	  */
	 protected function onAnimStateEnd():void
	 {
	 	//пока игралась анимация входа, состояние сменилось - запускаем анимацию выхода
	 	if(_stateAnim != _currentState)
	 	{
	 		_clip.play();
	 	}
	 	//состояние не изменилось, стопим анимацию входа, анимацию выхода запустим позже при смене состояния
	 	else
	 	{
	 		_endAnim = true;
		 	_animating = false;
		 	_clip.stop();
	 	}

//	 	Logger.debug(this, "onAnimStateEnd, _currentState = "+_currentState+", stateAnim = "+_stateAnim);
	 }

	 /**
	  * завершение анимации состояния (не важно, есть анимация выхода или нет, этот обработчик сработает  на последнем кадре
	  * анимации состояния)
	  *
	  */
	 protected function onAnimStateComplete():void
	 {
	 	_animating = false;
	 	_clip.stop();

//	 	Logger.debug(this, "onAnimStateComplete, mouseState = "+mouseState+", stateAnim = " + _stateAnim+", _currentState = "+_currentState);
	 	if(_stateAnim != _currentState)
	 	{
	 		_stateAnim = _currentState;
	 		setCurrentState(_currentState);
	 	}
	 }

	 /**
	  * остановить текущую анимацию
	  */
	 public function stopAnim():void
	 {
		 onAnimStateComplete();
	 }
	 
	 public function get selectable():Boolean{return true;}
	 public function set selectable(value:Boolean):void{}
}
}
