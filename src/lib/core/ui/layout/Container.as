package lib.core.ui.layout
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	
	
	/**
	 * простая реализация Контейнера
	 */
	public class Container extends Sprite
	{
		protected var _layout : ILayout;
		protected var _userHeight : Number;
		protected var _userWidth : Number;
		/**
		 * Индексированный список детей дисплейлиста.
		 * НЕЛЬЗЯ изменять этот массив вручную (НО, можно просто менять местами элементы)!
		 */
		public var children:Array = [];
		
		/**
		 * Кидать ли событие при изменении размеров
		 */
		public var dispatchResizeEvent:Boolean = true;
		
		public function Container(l : ILayout, userwidth:Number=0, userheight:Number=0)
		{
			_layout = l;
			_userWidth = userwidth;
			_userHeight = userheight;
		}
		/**
		 * Добавляем элемент в лейаут.
		 *
		 * Если элемент есть в контейнере, то он помещается на указанное место в лейауте.
		 * Если элемента нет в контейнере, добавляется в контейнер.
		 */
		public function add (o:DisplayObject, index:int=int.MAX_VALUE):DisplayObject
		{
			if (o)
			{
				var lastIndex:int = children.indexOf(o);
				
				if (index <= numChildren)
				{
					if (lastIndex > -1)
					{
						if (index != lastIndex)
						{
							children.splice(lastIndex, 1);
							children.splice(index, 0, o);
						}
					}
					else
					{
						children.splice(index, 0, o);
						super.addChildAt(o, index);
					}
				}
				else
				{
					if (lastIndex > -1)
					{
						if (lastIndex != children.length-1)
						{
							children.splice(lastIndex, 1);
							children.push(o);
						}
					}
					else
					{
						children.push(o);
						super.addChild(o);
					}
				}
				
				return o;
			}
			
			return null;
		}
		/**
		 * Убираем элемент из лейаута
		 */
		public function remove (o:DisplayObject):DisplayObject
		{
			if (o)
			{
				var index:int = children.indexOf(o);
				if (index > -1)
				{
					children.splice(index, 1);
				}
				
				if (contains(o))
				{
					super.removeChild(o);
				}
				
				return o;
			}
			return null;
		}
		/**
		 * Убираем элемент из лейаута по индексу
		 */
		public function removeAt (index:int):DisplayObject
		{
			return remove(children[index]);
		}
		/**
		 * Чистим контейнер.
		 * Удаляются все элементы дисплей-листа.
		 */
		public function removeAll ():void
		{
			children = [];
			
			while(numChildren > 0)
			{
				removeChildAt(numChildren-1);
			}
		}
		/**
		 * @return число детей, участвующих в лейауте
		 */
		public function get length ():int
		{
			return children.length;
		}
		
		public function set layout(l : ILayout) : void
		{
			_layout = l;
			_layout.arrange(this);
		}
		
		public function get layout() : ILayout
		{
			return _layout;
		}
		/**
		 * Вызывать для применения лейаутов
		 */
		public function arrange () : void
		{
			var prevWidth:Number = width;
			var prevHeight:Number = height;
			
			_layout.arrange(this);
			
			if (dispatchResizeEvent && (width != prevWidth || height != prevHeight))
				dispatchEvent(new Event(Event.RESIZE));
		}
		
		public function set userWidth(n : Number) : void
		{
			_userWidth = n;
		}
		public function get userWidth() : Number
		{
			return _userWidth;
		}
		public function set userHeight(n : Number) : void
		{
			_userHeight = n;
		}
		public function get userHeight() : Number
		{
			return _userHeight;
		}
		/**
		 * Переопределяем получение размеров.
		 * Размеры считаются в ILayout в зависимости от его реализации и настроек.
		 */
		override public function get width():Number
		{
			return _layout.width;
		}
		override public function get height():Number
		{
			return _layout.height;
		}
		
		// Хак: выставляем контйнер по целым координатам
		//		иначе возможны дерганья текста и растра
		override public function set x (value:Number):void
		{
			super.x = Math.round(value);
		}
		override public function set y (value:Number):void
		{
			super.y = Math.round(value);
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			return remove(child);
		}
		override public function removeChildAt(index:int):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			return remove(child);
		}
		
	}
	
}

