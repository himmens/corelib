package lib.core.ui.skins
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Rectangle;

import lib.core.util.Graph;
import lib.core.util.vectorcacher.VectorCacher;

[Event(name="change", type="flash.events.Event")]
/**
 * Универсальная оболочка для скинуемого объекта.
 *
 * После выставления размеров (даже если нет реального ресурса), кеширует и возвращает их.
 * Если размеры не выставлялись - возвр размеры ресурса.
 */
public class Skin extends Sprite
{
	protected var _id:String;

	protected var dimension:Rectangle = new Rectangle();

	protected var _content:DisplayObject;
	public function get content():DisplayObject{return _content;}

	public function get contentObj():Object{return _content;}

	protected var skinsManager:SkinsManager;
	protected var vectorCacher:VectorCacher;

	public function get hasSkin():Boolean{return _content != null;}
	public var scaleContent:Boolean = true;

	/**
	 * рисовать прозрачный бордер или нет по размерам скина
	 */
	public var drawBorder:Boolean = true;

	/**
	 * Принудительная растеризация контента.
	 *  - поддежривается скейлинг через параметры scaleX и scaleY. Но скейлинг должен выставляться до назначения id скина
	 */
	public var cacheContent:Boolean = false;

	/**
	 * форсировать кеширование контента как 1 кадровый битмап.
	 */
	public var cacheContentForceShape:Boolean = false;

	/**
	 * использовать исходный вектор (если он есть) в качестве hitArea
	 * Флаг надо использовать в связке с cacheContent
	 *
	 * Поддерживается только для однокадровых векторов (Shape, Sprite, MovieClip с одним кадром)
	 */
	public var useVectorHitArea:Boolean = false;

	/**
	 * Область растеризации, когда надо обрезать лишние векторные куски
	 */
	public var cacheClipRect:Rectangle = null;

	public function Skin (id:String = null, width:Number = 0, height:Number = 0)
	{
		skinsManager = SkinsManager.instance;
		vectorCacher = VectorCacher.instance;
		this.width = width;
		this.height = height;

		_id = id;
		if (skinId)
		{
			updateSkin();
		}

		//draw();
	}

	protected function draw():void
	{
		graphics.clear();
		Graph.drawFillRec(graphics, 0, 0, width, height, 0x000000, .0);
	}

	/**
	 * Меняем линкейдж ресурса на лету
	 */
	public function set id (value:String):void
	{
		if(id != value)
		{
			_id = value;
			updateSkin();
		}
	}

	public function get id ():String
	{
		return _id;
	}

	public function removeSkin ():void
	{
		if (_content && contains(_content))
		{
			removeChild(_content);
			_content = null;
		}
	}

	protected function updateSkin ():void
	{
		if(!skinId)
		{
			setSkin(null);
			return;
		}

		var skin:DisplayObject = createSkin(skinId);
		setSkin(skin);
	}

	protected function createSkin(id:String):DisplayObject
	{
		var cached:Boolean = cacheContent && vectorCacher && vectorCacher.hasCached(id);
		return cached ? vectorCacher.getCached(id, scaleX, scaleY) : skinsManager.getSkin(id);
	}

	protected function setSkin(skin:DisplayObject):void
	{
		if(cacheContent && vectorCacher && skin && skinId)
		{
			var vectorHitArea:DisplayObject;
			//ниже важная работа с скейлингом в случае растеризации контента
			if(!vectorCacher.hasCached(skinId))
			{
				vectorHitArea = skin;

				//если контент растеризуется и задан, назнаем скейл контенту, чтобы получить битмапу в нужном масштабе
				//важно, что скейл надо назначить до назначения скина
				//скейлинг делаем через матрицу, т.к. через scaleX, scaleY будет ошибка в округлении, например если назначить
				//scaleX = 1.123 в matrix.a окажется 1.23299995, а VectorCacher работает именно с матрицей
				var matrix:Matrix = skin.transform.matrix;
				matrix.scale(scaleX, scaleY);
				skin.transform.matrix = matrix;
				skin = vectorCacher.cacheVector(skin, skinId, false, null, cacheContentForceShape, scaleRect(cacheClipRect));
			}

			if(useVectorHitArea)
				setVectorHitArea(vectorHitArea);

			//свой скейлинг должен быть 1, т.к. при растеризации контента скейлингом управляет VectorCacher,
			//он возвращает битмапу в нужном масштабе
			super.scaleX = 1;
			super.scaleY = 1;
			super.scrollRect = scaleRect(_scrollRect);
		}

		if (_content && contains(_content))
		{
			removeChild(_content);
			_content = null;
		}

		if (skin)
		{
			_content = skin;
			addChildAt(_content, 0);

			if (_explicitWidth > 0)
			{
				if(scaleContent)
					_content.width = _explicitWidth;
			}

			if (_explicitHeight > 0)
			{
				if(scaleContent)
					_content.height = _explicitHeight;
			}
		}

		measure();

		dispatchEvent(new Event(Event.CHANGE));
	}

	protected function setVectorHitArea(source:DisplayObject = null):void
	{
		if(!source)
		{
			source = skinsManager.getSkin(skinId);
			if(source)
				source.transform.matrix = new Matrix(scaleX, 0, 0, scaleY);
		}

		if(hitArea && contains(hitArea)) removeChild(hitArea);

		hitArea = source as Sprite;
		if(hitArea)
		{
			addChild(hitArea);
			hitArea.visible = false;
		}
	}

	//вынесено в отдельный геттер, чтобы можно было добавить некую логику в наследениках
	//например добавять что-то к id для генерации контента
	protected function get skinId():String{return id;}

	// скейлим scrollRect для растеризованного контента вручную (для векторного флеш плеер делает это сам)
	protected function scaleRect(rect:Rectangle):Rectangle
	{
		if(rect)
		{
			//приводим к целым координатам как нам надо, а не как это делает автоматом флеш плеер
			//здесь к целым приводится из расчета на макс область (x,y округляются вниз, ширина,высота - вверх)
			//чотбы при использовании флага cacheAsBitmap ничего не обрезалось
			rect = rect.clone();
			rect.width = Math.ceil(rect.width *scaleX);
			rect.height = Math.ceil(rect.height *scaleY);
			rect.x = int(rect.x * scaleX);
			rect.y = int(rect.y * scaleY);
		}
		return rect;
	}

	/**
	 * @param name идентификатор дочернего объекта скина
	 */
	public function getChild (chain:Object):DisplayObject
	{
		// дергаем через getChildByName, чтобы не было эксепшена ReferenceError: Error #1069: Property ... not found on ...
		// а возвращался null
		if (_content is DisplayObjectContainer)
		{
			var arr:Array = chain is Array ? chain as Array : [String(chain)];
			var parent:DisplayObject = _content;
			for each(var name:String in arr)
				if(parent is DisplayObjectContainer)
					parent = DisplayObjectContainer(parent).getChildByName(name);
				else
					return null;

			return parent;
		}
		return null;
	}

	protected function measure():void
	{
		_measuredWidth = _content ? _content.width * Math.abs(scaleX) : 0;
		_measuredHeight = _content ? _content.height * Math.abs(scaleY) : 0;
		_measuredScaleX = _content ? _content.scaleX : 1;
		_measuredScaleY = _content ? _content.scaleY : 1;
	}

	protected var _explicitWidth:Number = 0;
	protected var _measuredWidth:Number = 0;
	override public function set width (value:Number):void
	{
		_explicitWidth = value;
		if(_content && scaleContent)
		{
			_content.width = value;
			_scaleX = _content.scaleX;
		}
		if (drawBorder)
			draw();
	}

	protected var _explicitHeight:Number = 0;
	protected var _measuredHeight:Number = 0;
	override public function set height(value:Number):void
	{
		_explicitHeight = value;
		if(_content && scaleContent)
		{
			_content.height = value;
			_scaleY = _content.scaleY;
		}
		if (drawBorder)
			draw();
	}

	override public function get width():Number
	{
		measure();
		return _explicitWidth || _measuredWidth;
	}

	override public function get height():Number
	{
		measure();
		return _explicitHeight || _measuredHeight;
	}

	protected var _scaleX:Number = 0;
	protected var _measuredScaleX:Number = 1;
	override public function set scaleX(value:Number):void
	{
		if(_scaleX != value)
		{
			_scaleX = value;
			super.scaleX = value;
			measure();
		}
	}
	override public function get scaleX():Number{return _scaleX || _measuredScaleX}

	protected var _scaleY:Number = 0;
	protected var _measuredScaleY:Number = 1;
	override public function set scaleY(value:Number):void
	{
		if(_scaleY != value)
		{
			_scaleY = value;
			super.scaleY = value;
			measure();
		}
	}
	override public function get scaleY():Number{return _scaleY || _measuredScaleY}

	protected var _scrollRect:Rectangle;
	override public function set scrollRect(value:Rectangle):void
	{
		_scrollRect = value;
		super.scrollRect = value;
	}

}
}