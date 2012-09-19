package lib.core.util
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

/**
 * утилитные методы для работы с DisplayObject, MovieClip, Sprite
 */
public class DisplayUtil
{


	/**
	 * Останавливает все анимации в заданном клипе
	 *
	 * @param	target клип.
	 * @param	self нужно ли останавливать главный переданный клип.
	 * @param	isGoToAndStopFirstFrame нужно ли переводить каретку проигрывания в 1-й кадр.
	 *
	 * @return	получилось ли остановить проигрывание.
	 */
	public static function stopAll(
		//target:DisplayObjectContainer,
		target:DisplayObject,
		self:Boolean = true,
		isGoToAndStopFirstFrame:Boolean = false):void
	{
		if (!target)
			return;

		var t:int = getTimer();
		var targetMovieClip:MovieClip = (target as MovieClip);
		if (self && targetMovieClip)
		{
			if(isGoToAndStopFirstFrame)
			{
				targetMovieClip.gotoAndStop(1);
			}else
			{
				targetMovieClip.stop();
			}
		}

		// Если переданный объект является контейнером, то пробегаемся по списку его детей
		var targetContainer:DisplayObjectContainer = (target as DisplayObjectContainer);
		if(targetContainer)
		{
			//for (var i:int=0; i<target.numChildren; i++)
			for (var i:int=0; i<targetContainer.numChildren; i++)
			{
				//var child:DisplayObjectContainer = target.getChildAt(i) as DisplayObjectContainer;
				//var child:DisplayObjectContainer = targetContainer.getChildAt(i) as DisplayObjectContainer;
				var child:DisplayObject = targetContainer.getChildAt(i);
				if (child)
				{
					stopAll(child, true, isGoToAndStopFirstFrame);
				}
			}
		}

		// Если переданный объект является SimpleButton, то пробегаемся по его состояниям
		var targetSimpleButton:SimpleButton = (target as SimpleButton);
		if(targetSimpleButton)
		{
			stopAll(targetSimpleButton.overState, true, isGoToAndStopFirstFrame);
			stopAll(targetSimpleButton.upState, true, isGoToAndStopFirstFrame);
			stopAll(targetSimpleButton.downState, true, isGoToAndStopFirstFrame);
			stopAll(targetSimpleButton.hitTestState, true, isGoToAndStopFirstFrame);
		}

//		Logger.debug("DisplayUtil::stopAll, time = "+ (getTimer() - t)+ " ms");

		return;
	}

	/**
	 * Запускает все анимации в заданном клипе
	 *
	 * @param target
	 * @param self
	 *
	 */
	//public static function playAll(target:DisplayObjectContainer, self:Boolean = true):void
	public static function playAll(target:DisplayObject, self:Boolean = true, isGoToAndPlayFirstFrame:Boolean = false):void
	{
		if (!target)
			return;

		var t:int = getTimer();
		var targetMovieClip:MovieClip = (target as MovieClip);
		if (self && targetMovieClip)
		{
			isGoToAndPlayFirstFrame ? targetMovieClip.gotoAndPlay(1) : targetMovieClip.play();
		}

		// Если переданный объект является контейнером, то пробегаемся по списку его детей
		var targetContainer:DisplayObjectContainer = (target as DisplayObjectContainer);
		if(targetContainer)
		{
			//for (var i:int=0; i<target.numChildren; i++)
			for (var i:int=0; i<targetContainer.numChildren; i++)
			{
				//var child:DisplayObjectContainer = target.getChildAt(i) as DisplayObjectContainer;
				var child:DisplayObjectContainer = targetContainer.getChildAt(i) as DisplayObjectContainer;
				if (child)
				{
					playAll(child, true, isGoToAndPlayFirstFrame);
				}
			}
		}

		// Если переданный объект является SimpleButton, то пробегаемся по его состояниям
		var targetSimpleButton:SimpleButton = (target as SimpleButton);
		if(targetSimpleButton)
		{
			playAll(targetSimpleButton.overState, true, isGoToAndPlayFirstFrame);
			playAll(targetSimpleButton.upState, true, isGoToAndPlayFirstFrame);
			playAll(targetSimpleButton.downState, true, isGoToAndPlayFirstFrame);
			playAll(targetSimpleButton.hitTestState, true, isGoToAndPlayFirstFrame);
		}

//		Logger.debug("DisplayUtil::playAll, time = "+ (getTimer() - t)+ " ms");

		return;
	}

	/**
	 * Делает глобальную (видимую на экране) картинку, снятую с объекта с учетом всех вложенных трансформаций.
	 *
	 * @param target Объект на сцене
	 * @return объект в виде:
	 * {
	 * 	bitmapData:BitmapData - растровый скрин векторного объекта
	 * 	x:int - x координата картинки
	 * 	y:int - y координата картинки
	 * }
	 */
	public static function getGlobalImage(target:DisplayObject):Object
	{
		if (!target || !target.stage)
			return null;

		var globalBounds:Rectangle = target.getBounds(target.stage);
		//Если нет видимых размеров ничего не рисуем
		if (globalBounds.width == 0 || globalBounds.height == 0)
		{
			return null;
		}

		var globalPosition:Point = new Point(0, 0);
		globalPosition = target.localToGlobal(globalPosition);

		var matrix:Matrix = getGlobalTransformMatrix(target);
		//смещения для матрицы, чтобы отрисовать все картинку в пределах границ объекта
		matrix.tx = globalPosition.x - globalBounds.x;
		matrix.ty = globalPosition.y - globalBounds.y;

		var bitmapData:BitmapData = new BitmapData(globalBounds.width || 1, globalBounds.height || 1, true, 0x00000000);
		bitmapData.draw(target, matrix);

		return {x:globalBounds.x, y:globalBounds.y, bitmapData:bitmapData};
	}

	/**
	 * Получить глобальные границы видимой области векторного объекта - все прозрачные области или под маской обрезаются
	 * @param target Объект на сцене
	 */
	public static function getGlobalVisibleBounds(target:DisplayObject):Rectangle
	{
		var rect:Rectangle;

		var image:Object = getGlobalImage(target);
		if (image)
		{
			var bitmapData:BitmapData = image.bitmapData;
			if (bitmapData)
			{
				rect = bitmapData.getColorBoundsRect(0xff000000, 0x000000, false);
				bitmapData.dispose();

				rect.x += image.x;
				rect.y += image.y;
			}
		}
		return rect;
	}

	/**
	 * Получить глобальные границы видимой области векторного объекта - все прозрачные области или под маской обрезаются
	 * @param target Объект на сцене
	 */
	public static function getLocalVisibleBounds(target:DisplayObject, mask:uint = 0xFF000000, color:uint = 0x000000, findColor:Boolean = false):Rectangle
	{
		var rect:Rectangle;

		if(target)
		{
			var bitmapData:BitmapData = new BitmapData(target.width || 1, target.height || 1, true, 0x00000000);
			bitmapData.draw(target);
			bitmapData.lock();
			rect = bitmapData.getColorBoundsRect(mask, color, findColor);
			bitmapData.unlock();
			bitmapData.dispose();
		}

		return rect;
	}

	/**
	 * Получить суммарную матрицу трансформации объекта с учетом трансформации всех его родителей
	 * @param target Объект на сцене
	 */
	public static function getGlobalTransformMatrix(target:DisplayObject):Matrix
	{
		var matrix:Matrix;
		if (target && target.transform)
		{
			matrix = target.transform.matrix;
			if (target.parent && matrix)
				matrix.concat(getGlobalTransformMatrix(target.parent));
		}
		return matrix;
	}


	/**
	 * Функции для работы с дочерними клипами.
	 */

	/**
	 * Удаление всех дочерних клипов внутри какого-то родительского клипа.
	 *
	 * @param	parentClip ссылка на клип, внутри которого нужно будет удалить все дочерние клипы.
	 */
	static public function removeAllChildren(parentClip:DisplayObjectContainer):void
	{
		if(!parentClip)
			return;

		// Пока в клипе есть хотя бы 1 дочерний клип, удаляем клип на самом нижнем слое
		while(parentClip.numChildren > 0)
		{
			parentClip.removeChildAt(parentClip.numChildren - 1);
		}
	}

	/**
	 * Удаление дочерним клипом самого себя из родительского клипа.
	 *
	 * @param	child ссылка на дочерний клип.
	 */
	static public function removeChildFromParent(child:DisplayObject):DisplayObject
	{
		if (child && child.parent && child.parent.contains(child))
		{
			child.parent.removeChild(child);
		}

		return child;
	}


	/**
	 * Масштабирование объекта.
	 * 
	 * На данный момент метод работает только в сторону уменьшения,
	 * т.е. если объект по одной из сторон превышает максимальные размеры (maxWidth или maxHeight),
	 * то объект по этой стороне будет масштабироваться, а другая сторона будет подгоняться
	 * по масштабу к этой стороне (с сохранением пропорций). Если размеры объекта превышают
	 * максимальные размеры по двум сторонам, то объект будет масштабироваться по стороне,
	 * для которой требуется большее изменение масштаба.
	 * 
	 * Если какую-то из сторон не нужно учитывать при рассчитывании размеров,
	 * то для этого параметра нужно установить значение -1 (напр. maxWidth = -1, или maxHeight = -1).
	 * По умолчанию для обоих сторон установлено -1. Если для обоих сторон установлено -1, то объект не будет масштабироваться.
	 * 
	 * Примеры использования:
	 * 
	 * Допустим, есть testSprite с размерами width = 100, height = 50;
	 * 
	 * 1) scaleObject(testSprite, 50, 50) - в результате размеры объекта будут 50*25.
	 * 
	 * 2) scaleObject(testSprite, 100, 25) - в результате размеры объекта будут 50*25.
	 * 
	 * 3) scaleObject(testSprite, 50, 10) - в результате размеры объекта будут 20*10,
	 * так как в этом случае большее изменение необходимо для высоты (высоту нужно
	 * изменить в 5 раз, а ширину в 2 раза).
	 * 
	 *
	 * @param	object объект.
	 * @param	maxWidth максимальная ширина.
	 * @param	maxHeight максимальная высота.
	 */
	static public function fitObjectScale(object:DisplayObject, maxWidth:Number = -1, maxHeight:Number = -1):void
	{
		// Если размеры объекта не преывышают максимальных размеров, то прерываем функцию.
		// Если не нужно изменять ни высоту ни ширину (оба равны -1), то прерываем функцию.
		if (((object.width <= maxWidth || maxWidth == -1) && (object.height <= maxHeight || maxHeight == -1)) ||
			(maxWidth == -1 && maxHeight == -1))
		{
			return;
		}

		var maxDelta:Number = maxWidth / maxHeight;
		var objDelta:Number = object.width / object.height;

		// Если нужно изменять ширину (соотношения объекта и соотношения макс.размеров
		// показали, что минимальная сторона - ширина) или если не нужно изменять высоту
		if (objDelta > maxDelta || maxHeight == -1)
		{
			object.width = maxWidth;
			object.scaleY = object.scaleX;

		// Если нужно изменять высоту
		}else
		{
			object.height = maxHeight;
			object.scaleX = object.scaleY;
		}
	}

	/**
	 *
	 * Перемещение объекта в целочисленные пиксели с учётом глобальных координат.
	 *
	 * @param	object объект, который нужно переместить.
	 */
//	static public function moveObjectToIntGlobalPixels(object:DisplayObject):void
//	{
//		var globalPos:Point = object.localToGlobal(new Point());
//
//		object.x += Math.round(globalPos.x) - globalPos.x;
//		object.y += Math.round(globalPos.y) - globalPos.y;
//	}

	/**
	 * Заменяет один DisplayObject другим и назначает размеры/координаты/индекс исходника
	 * Метод удобен для парсинга скинов
	 * @param target
	 * @param source
	 * @param pos
	 * @param index
	 * @param size
	 *
	 */
	static public function replaceAndArrange(target:DisplayObject, source:DisplayObject, pos:Boolean = true, index:Boolean = true, size:Boolean = true, precisePos:Boolean = true):DisplayObject
	{
		if(!target || !source)
			return null;

		if(pos)
		{
			target.x = precisePos ? Math.round(source.x) : source.x;
			target.y = precisePos ? Math.round(source.y) : source.y;
		}

		if(size)
		{
			target.width = source.width;
			target.height = source.height;
		}

		var parent:DisplayObjectContainer = source.parent;
		if(parent && index)
		{
			var chIndex:int = parent.getChildIndex(source);
			parent.removeChild(source);
			parent.addChildAt(target, chIndex);
		}
		
		return target;
	}

	/**
	 * Копирует свойства DisplayObject из другого
	 * @param target
	 * @param source
	 *
	 */
//	static public function copyProps(target:DisplayObject, source:DisplayObject):void
//	{
//		if(!target || !source)
//			return;
//		
//		target.transform = source.transform;
//		target.filters = source.filters;
//	}

	/**
	 * Получение центральной координаты объекта.
	 *
	 * @param	object объект.
	 *
	 * @return	центральная координата объекта.
	 */
//	static public function getObjectCenterPos(object:DisplayObject):Point
//	{
//		var centerPos:Point = new Point();
//
//		var bounds:Rectangle = object.getBounds(object);
//		centerPos.x = object.x + (object.width >> 1) + bounds.x * object.scaleX;
//		centerPos.y = object.y + (object.height >> 1) + bounds.y * object.scaleY;
//
//		return centerPos;
//	}

	/**
	 * Перемещение центра объекта.
	 *
	 * @param	object объект.
	 * @param	position позиция, в которую нужно переместить центр объекта.
	 */
//	static public function moveObjectCenterTo(object:DisplayObject, position:Point):void
//	{
//		var bounds:Rectangle = object.getBounds(object);
//		object.x = position.x - (object.width >> 1) - bounds.x * object.scaleX;
//		object.y = position.y - (object.height >> 1) - bounds.y * object.scaleY;
//	}


	/**
	 * Проверка того, находится ли дочерний объект в DisplayList родителського объекта.
	 *
	 * @param	child дочерний объект.
	 * @param	checkedParent проверяемый родительский объект.
	 * @param	isNeedCheckItself нужно ли проверять сам дочерний объект (является ли дочерний одновременно и родительским).
	 *
	 * @return	флаг, который показывает, находится ли дочерний объект в DisplayList родительского.
	 */
//	static public function checkIsObjectInDisplayList(
//		child:DisplayObject,
//		checkedParent:DisplayObjectContainer,
//		isNeedCheckItself:Boolean = true):Boolean
//	{
//		var isInList:Boolean = false;
//
//		// Если дочерний клип, одновременно, является родительским клипом, то запоминаем,
//		// что клип находиться в DisplayList этого объекта (если на это было установлено разрешение isNeedCheckItself)
//		if (isNeedCheckItself && child == checkedParent)
//		{
//			isInList = true;
//
//		// Если проверяемый родительский объект не является проверяемым дочерним объектом,
//		// или если на такую проверку не было дано разрешение, то перебираем весь список
//		// родительских объектов и проверяем их
//		}else
//		{
//			var tempParent:DisplayObjectContainer = child.parent;
//			while (tempParent)
//			{
//				if (tempParent == checkedParent)
//				{
//					isInList = true;
//					break;
//				}else
//				{
//					tempParent = tempParent.parent;
//				}
//			}
//		}
//
//		return isInList;
//	}

	/**
	 * Поиск клипа нужного класса в DisplayList дочернего клипа.
	 *
	 * @param	child родительский клип.
	 * @param	checkedClass проверяемый класс.
	 * @param	isNeedCheckItself нужно ли проверять сам дочерний объект (является ли дочерний одновременно и родительским).
	 *
	 * @return	найденный клип нужного класса. Если объект не будет найден, вернётся null.
	 */
//	static public function findObjectInDisplayListByClass(
//		child:DisplayObject,
//		checkedClass:Class,
//		isNeedCheckItself:Boolean = true):DisplayObject
//	{
//		var findedClip:DisplayObject = null;
//
//		// Если дочерний клип, одновременно, является родительским клипом, то запоминаем,
//		// что клип находиться в DisplayList этого объекта (если на это было установлено разрешение isNeedCheckItself)
//		if (isNeedCheckItself && (child is checkedClass))
//		{
//			findedClip = child;
//
//		// Если проверяемый родительский объект не является проверяемым дочерним объектом,
//		// или если на такую проверку не было дано разрешение, то перебираем весь список
//		// родительских объектов и проверяем их
//		}else
//		{
//			var tempParent:DisplayObjectContainer = child.parent;
//			while (tempParent)
//			{
//				if (tempParent is checkedClass)
//				{
//					findedClip = tempParent;
//					break;
//				}else
//				{
//					tempParent = tempParent.parent;
//				}
//			}
//		}
//
//		return findedClip;
//	}

	/**
	 * Функция, которая будет проверять, находится мышка внутри клипа или нет.
	 *
	 * @param	checkedClip ссылка на клип.
	 * @return	флаг, который говорит, находится мышки внутри клипа или нет.
	 */
	static public function checkIsMouseInBounds(checkedClip:DisplayObject):Boolean
	{
		var isMouseInBounds:Boolean = false;

		if(checkedClip.parent)
		{
			/*var bounds:Rectangle = checkedClip.getRect(checkedClip.parent);
			isMouseInBounds = bounds.contains(checkedClip.parent.mouseX, checkedClip.parent.mouseY);*/
			isMouseInBounds = checkedClip.hitTestPoint(checkedClip.parent.mouseX, checkedClip.parent.mouseY, true);
		}



		return isMouseInBounds;
	}

	static public function randomizeColorTransform(clip:DisplayObject, randomFactor:Number = 0.1, alpha:Boolean = true):void
	{
		clip.transform.colorTransform = new ColorTransform(
			1 - randomFactor + Math.random()*randomFactor, //red
			1 - randomFactor + Math.random()*randomFactor, //Green
			1 - randomFactor + Math.random()*randomFactor, // blue
			alpha ? 1 - randomFactor + Math.random()*randomFactor:1);
	}

	/**
	 * Вернуть список фильров, которые применены к объекту, по всему display tree.
	 * Метод удобен для проверки (например при отладке) есть ли на объекте какие-то фильтры
	 * @param clip
	 * @return
	 *
	 */
	static public function getAllFilters(obj:DisplayObject):Array
	{
		if(!obj)
			return null;

		var arr:Array = obj.filters;
		var parent:DisplayObjectContainer = obj.parent;
		while(parent)
		{
			arr = arr.concat(parent.filters);
			parent = parent.parent;
		}

		return arr;
	}
}
}