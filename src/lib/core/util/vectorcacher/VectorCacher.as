package lib.core.util.vectorcacher
{
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.PixelSnapping;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.getQualifiedClassName;

/**
 * Менеджер кеширования векторной графики. Хранит кеш векторных по ключу.
 *  - Простые векторные объекты (Sprite, Shape, 1 кадровыне MovieClip переводит в Bitmap (или Shape с
 * битмап заливкой)
 *  - Анимации переводит в MovieClipCacher объекты
 */
public class VectorCacher
{
	/**
	 * значение для параметра Bitmap.pixelSnapping при растеризации вектора
	 */
	public var pixelSnapping:String = PixelSnapping.NEVER;

	/**
	 * заливать прозрачность белым для проверки, что кеширование работает
	 */
	public static var debugFill:Boolean = false;

	/**
	 * карта закешированных растровых изображений по ключу в двух вариантах:
	 * Либо DisplayObject либо массив DisplaObject-ов, если по ключу лежит анимация
	 */
	protected var _lib:Object;

	private static var _instance:VectorCacher;

	public static function get instance():VectorCacher
	{
		return _instance;
	}

	public function VectorCacher()
	{
		if(!_instance)
		{
			_instance = this;
			init();
		}
		else
		{
			throw(new Error("Only one instance of VectorCacher is allowed"));
		}
	}

	protected function init():void
	{
		_lib = {};
	}

	/**
	 * Основной метод кеширования - растеризация векторного объекта в BitmapData.
	 * Объект обрезается по своим визуальным границам (getBounds). В возвращаемом объекте
	 * так же есть координаты картинки, по ним можно будет выставить координаты.
	 *
	 * @param target
	 * @return объект в виде:
	 * {
	 * 	bd:BitmapData - растровый скрин векторного объекта
	 * 	x:int - x координата картинки (прямоугольника getBounds)
	 * 	y:int - y координата картинки (прямоугольника getBounds)
	 * 	scaleX - масштаб scaleX векторного объекта перед тем как его заскринили
	 * 	scaleY - масштаб scaleY векторного объекта перед тем как его заскринили
	 * }
	 *
	 */
	public static function makeSnapshot(target:DisplayObject, rect:Rectangle = null, fill:uint = 0x00FFFFFF, drawColorTransform:Boolean = false):Object
	{
		if(!target)
			return null;

		var bd:BitmapData;

		var absScaleX:Number = Math.abs(target.scaleX);
		var absScaleY:Number = Math.abs(target.scaleY);
//		var absScaleX:Number = 2;
//		var absScaleY:Number = 2;

		if(!rect)
		{
			rect = target.getBounds(target);
			rect.width *= absScaleX;
			rect.height *= absScaleY;
			rect.x *= absScaleX;
			rect.y *= absScaleY;
		}

		//округляем область скрина, чотбы вектор не засмусился
		rect.x = Math.floor(rect.x);
		rect.y = Math.floor(rect.y);
		rect.width = Math.ceil(rect.width) || 1;
		rect.height = Math.ceil(rect.height) || 1;

		//cropped
		fill = debugFill ? 0xFFFFFFFF : fill;
		bd = new BitmapData(rect.width, rect.height, true, fill);

		bd.draw(target,
			new Matrix(absScaleX, 0, 0, absScaleY, -rect.x, -rect.y),
			drawColorTransform ? target.transform.colorTransform : null,
			null, null, true);

		return {x:rect.x, y:rect.y, bd:bd, scaleX:absScaleX, scaleY:absScaleY, drawColorTransform:drawColorTransform};
	}

	/**
	 * Добавить объект в кеш, можно передать ключ снаружи, можно положить на автозаполнение по имени класса,
	 * для этого у любого кешируемого векторного объекта необходимо прописать свое имя класса во fla-шнике
	 * @param vector
	 * @param name
	 * @param swap - посдтавить вместо оригина закешированный растр
	 * @param localCache - использовать переданный снаружи локальный кеш вместо глобального. Кеш будет дополнен если надо переданным объектом
	 * @param forceStatic - сделать 1 кадровый кеш, без учета анимации даже для многокадровых клипов
	 * @param clipRect - область снятия скриншота (например scrollRect родителя или маска). Если не указан снимается getBounds объекта
	 * @param drawColorTransform - оптимизация. Применить colorTransform при отрисовке битпамы, а не назначением новому объекту. Такой способ работает быстрее, однако
	 * 								при этом в кеше остается епрекрашенный объект и при кешировании другого вектора того же класса получим перекрашенную битпаму из кеша, поэтому
	 * 								флаг надо использовать только если уверены, что все экземпляры имеют один и тот же трансформ.
	 * @return
	 *
	 */
	public function cacheVector(vector:DisplayObject, name:String = null, swap:Boolean = false, localCache:Object = null, forceStatic:Boolean = false, clipRect:Rectangle = null, drawColorTransform:Boolean = false):DisplayObject
	{
		var cached:DisplayObject;
		
		if(!(vector is MovieClipCacher))
		{
			if(!name)
				name = getKey(vector);
			if(!name)
				return null;
	
			var cacheLib:Object = localCache || _lib;
	
			var cache:Object = cacheLib[name];
	
			if(!cache)
			{
				var isSimple:Boolean =
					forceStatic ||
					vector is Shape ||
					vector is Bitmap ||
					(vector is MovieClip && MovieClip(vector).totalFrames == 1) ||
					(vector is Sprite && !(vector is MovieClip))
	
				//для простого однокадрового вектора делаем растровый битмап
				if(isSimple)
				{
					cache = VectorCacher.makeSnapshot(vector, clipRect, 0x00FFFFFF, drawColorTransform);
				}
				//для многокадрового клипа делаем MovieClipCacher объект
				else if(vector is MovieClip)
				{
					var mc:MovieClip = vector as MovieClip;
					mc.stop();
					var frames:Array = new Array(mc.totalFrames);
					cache = {source:mc, bd:frames, x:0, y:0, scaleX:Math.abs(vector.scaleX), scaleY:Math.abs(vector.scaleY)};
				}
			}
	
			cacheLib[name] = cache;
	
			cached = createCached(name, cacheLib);
			transformCached(cached, cache, vector.transform.matrix);
			copyVectorProps(cached, vector);
	
			if(!drawColorTransform)
				cached.transform.colorTransform = vector.transform.colorTransform;
			else if(cached is MovieClipCacher)
				MovieClipCacher(cached).drawColorTransform = true;
			
			if(swap)
				swapChildren(vector, cached);
			
		}else
		{
			cached = vector;
		}


		return cached;
	}

	/**
	 * Создает картинку из кеша, если там такая есть
	 * @param name
	 * @param scale - какого масштаба нужен кеш
	 * @return
	 *
	 */
	public function getCached(name:String, scaleX:Number = 1, scaleY:Number = 1):DisplayObject
	{
		var bitmap:DisplayObject = createCached(name, _lib);
		if(bitmap)
		{
			transformCached(bitmap, _lib[name], new Matrix(scaleX, 0, 0, scaleY));
		}

		return bitmap;
	}

	protected function createCached(name:String, cacheLib:Object):DisplayObject
	{
		var bitmap:DisplayObject;
		var cache:Object = cacheLib[name];
		if(cache)
		{
			if(cache.bd is Array)
			{
				var mc:MovieClipCacher = new MovieClipCacher();
				bitmap = mc;
				mc.cache = cache.bd as Array;
				mc.source = cache.source;
			}else
			{
				bitmap = createBitmap(cache);
			}
		}

		return bitmap;
	}

	/**
	 * Очищает память от кеша
	 * @param name
	 *
	 */
	public function clearCache(name:String = null):void
	{
		if(name)
		{
			if(_lib[name])
				BitmapData(_lib[name].bd).dispose();
			delete _lib[name];
		}
		else
		{
			for each(var obj:Object in _lib)
				BitmapData(obj.bd).dispose();
			_lib = {};
		}
	}

	protected function swapChildren(vector:DisplayObject, bitmap:DisplayObject):void
	{
		var cont:DisplayObjectContainer = vector.parent;
		if(cont)
		{
			var index:int = cont.getChildIndex(vector);
			cont.addChildAt(bitmap, index);
//			cont.removeChildAt(index);
			cont.removeChild(vector);

//			bitmap.x = vector.x;
//			bitmap.y = vector.y;
		}
	}

	public function hasCached(name:String):Boolean
	{
		return _lib[name] != null;
	}

//	protected function getCached(name:String):DisplayObject
//	{
//		var obj:Object = _lib[name];
//		if(obj)
//		{
//			createBitmap(obj);
//		}
//
//		return null;
//	}

	protected function createBitmap(cache:Object):DisplayObject
	{
		var bd:BitmapData = cache.bd;
		//Bitmap работает быстрее шейпа по ЦП, используем его
		var bitmap:Bitmap = new Bitmap(bd, pixelSnapping, true);

//		var bitmap:Shape = new Shape();
//		bitmap.graphics.beginBitmapFill(bd, null, false, true);
//		bitmap.graphics.drawRect(0, 0, bd.width, bd.height);
		return bitmap;
	}

	/**
	 * Подгонка размеров битмапы под переданный вектор:
	 * 1. Если передан вектор, битмапа на выходе будет по размерам совпадать с ним (ширина, высота)
	 * 2. Если не передан вектор, битпама заскейлится в размер, соответвующий scaleX = scaleY = 1 исходного вектора, с которого ее сняли
	 * @param bitmap
	 * @param vector
	 * @param cache
	 * @return
	 *
	 */
	protected function transformCached(bitmap:DisplayObject, cache:Object, matrix:Matrix):void
	{
		if(cache)
		{
			var shiftX:int = cache.x;
			var shiftY:int = cache.y;

			shiftX*=(matrix.a/cache.scaleX);
			shiftY*=(matrix.d/cache.scaleY);

			matrix.tx += shiftX;
			matrix.ty += shiftY;
			matrix.a /= cache.scaleX;
			matrix.d /= cache.scaleY;

		}

		//используем параметр трансформ, т.к. при создании объектов на сцене знак + или - задается именно в нем
		bitmap.transform.matrix = matrix;
	}

	protected function copyVectorProps(bitmap:DisplayObject, vector:DisplayObject):void
	{
		if(vector)
		{
			bitmap.filters = vector.filters;
		}
	}

//	public function addCache(cache:DisplayObject, name:String):void
//	{
//		_lib[name] = cache;
//	}

	/**
	 * Переводит векторный символ в ключ по которому он будет храниться в кеше. По умолчанию - имя класса.
	 * @param symbol
	 * @return
	 *
	 */
	internal static function getKey(symbol:DisplayObject):String
	{
		if(symbol is Shape)
			return "shape_"+symbol.width+"_"+symbol.height;
//		var name:String = describeType(symbol).@name;
		var key:String = getQualifiedClassName(symbol);
		return key;
		var name:String = String(symbol["constructor"]);
//		return symbol["constructor"];
		return name;
	}
}
}