package lib.core.ui.controls
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import lib.core.ui.skins.Skin;
	import lib.core.util.CryptoUtil;

	/**
	 * Текстовое поле с иконками в тексте.
	 * Позиция иконки определяется по соответствующим идентификаторам в тексте, которые заменяются пробелами.
	 *
	 * Необходимо задать карту идентификаторов iconsMap.
	 * Пример:
	 * iconsMap["{money}"] = "moneySkinId";
	 *
	 * Тогда при нахождении в тексте строки {money}, она заменится пробелом и на ее место вставится скин с id == "moneySkinId"
	 */
	public class IconsTextField extends TextField
	{
		/**
		 * \u202F - символ вставляется после каждой иконки. чтобы корректно работало выравнивание иконок в формате
		 */
		private static const REPLACE_STRING:String = "<span class='classId'> </span>\u202F";

		/**
		 * Родитель для контейнера с иконками (в него добавляем контейнер)
		 */
		public var iconsParent:DisplayObjectContainer;

		public var scaleIcons:Boolean = false;

		//для оптимизации если в тексте заведомо нет иконок лучше отключить поиск иконок, лишняя регулярка жрет до 1 мс проца
		//если таких полей много могут начаниться просяды
		public var disableIcons:Boolean = false;
		/**
		 * Массив иконок с позициями для конечного расположения
		 */
		private var icons:Array = [];

		/**
		 * данные о размерах иконок по id
		 */
		private var iconsData:Object = {};

		/**
		 * регулярка для разделения строки на части
		 */
		private var splitRegexp:RegExp = /(\{.*?\})/;
//		public function get splitRegexp():RegExp
//		{
//			return _splitRegexp;
//		}

		/**
		 * Карта соответствия скина идентификатору иконки.
		 */
		private var _iconsMap:Object = {};
		public function get iconsMap():Object
		{
			return _iconsMap;
		}
		public function set iconsMap(value:Object):void
		{
			_iconsMap = value;
			initIcons();
		}

		private function initIcons():void
		{
//			var iconsIds:Array = [];
//			for (var id:String in _iconsMap)
//			{
//				iconsIds.push("("+id+")");
//			}
//			_splitRegexp = new RegExp(iconsIds.join("|"));
		}

		/**
		 * StyleSheet для поля с html текстом
		 */
		private var css:StyleSheet = new StyleSheet();

		//контейнер с иконками
		protected var iconsContainer:Sprite = new Sprite();

		//флаг, присутствуют иконки в тексте
		protected var hasIcons:Boolean;

		//исходный текст
		protected var sourceText:String;

		public function IconsTextField(iconsParent:DisplayObjectContainer = null)
		{
			super();
			this.iconsParent = iconsParent;
			css = new StyleSheet();

			addEventListener(Event.ADDED_TO_STAGE, onStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onStage);
		}

		protected function onShow():void
		{
			if (!iconsParent)
				iconsParent = this.parent;

			//Добавляем контейнер иконок на сцену
			if (iconsParent && !iconsParent.contains(iconsContainer))
			{
				iconsParent.addChild(iconsContainer);
			}
		}

		protected function onHide():void
		{
			//Удаляем контейнер иконок со сцены
			if (iconsContainer.parent && iconsContainer.parent.contains(iconsContainer))
			{
				iconsContainer.parent.removeChild(iconsContainer);
			}
		}

		/**
		 * Метод создания иконки по идентификатору
		 */
		protected function createIcon(id:String):DisplayObject
		{
			var skinId:String = iconsMap ? iconsMap[id] : null;
			if (!skinId)
				return null;

			var skin:Skin = new Skin(skinId);
			skin.mouseEnabled = false;
			return skin;
		}

		/**
		 * Возвращает CSS класс по идентификатору иконки
		 */
		protected function getCssClassByIconId(id:String):String
		{
			return CryptoUtil.md5(id);
		}

		/**
		 * Обновляем стиль для пробела-заменителя иконки по id иконки
		 */
		public function updateCssClassByIconId(id:String, value:Number):void
		{
			updateCssClass(getCssClassByIconId(id), value);
		}

		/**
		 * Обновляем стиль для пробела-заменителя иконки (чтобы соответсвовал ширине иконки)
		 */
		protected function updateCssClass(classId:String, value:Number):void
		{
			css.setStyle("."+classId, {letterSpacing:value});
			if (!styleSheet)
				styleSheet = css;
		}

		/**
		 * Метод добавления иконки по идентификатору с автозаменой текста, обозначающего иконку
		 */
		protected function replaceTextById(id:String):void
		{
			var html:String = super.htmlText;
			var text:String = super.text;

			//определим индекс символа начала иконки
			var textIndex:int = text.indexOf(id);
			var htmlIndex:int = html.indexOf(id);

			var icon:DisplayObject = createIcon(id);
			if (icon)
			{
				iconsContainer.addChild(icon);
				if(scaleIcons)
				{
					icon.height = getLineMetrics(0).height;
					icon.scaleX = icon.scaleY;
				}
			}

			updateCssClassByIconId(id, getSpaceWidth(id, icon));

			//заменяем идентификатор иконки следующей строкой:
			var replaceString:String = getReplaceString(id);
			var replacedText:String = html.substr(0, htmlIndex) + replaceString + html.substring(htmlIndex + id.length);

			applyHtmlText(replacedText);

			//сохраняем индекс символа начала иконки
			icons.push({id:id, index:textIndex, icon:icon});
		}

		/**
		 * Удаляем иконки из родителя
		 */
		protected function clear():void
		{
			while (iconsContainer.numChildren > 0)
			{
				iconsContainer.removeChildAt(0);
			}
			icons = [];
		}

		/**
		 * Возвращает ширину пробела для иконки-заменителя.
		 */
		protected function getSpaceWidth(iconId:String, icon:DisplayObject):Number
		{
			return icon ? icon.width - 4 : 0;
		}

		protected function getReplaceString(id:String):String
		{
			var classId:String = getCssClassByIconId(id);
			return REPLACE_STRING.split("classId").join(classId);
		}

		/**
		 * Метод перерисовки.
		 * Пересоздаем все иконки и заменяем текст.
		 */
		protected function update():void
		{
			clear();

			if(disableIcons)
			{
				styleSheet = null;
				applyHtmlText(sourceText || "");
			}else
			{
				if (!iconsMap || !sourceText)
				{
					applyHtmlText("");
					return;
				}

				var textParts:Array = sourceText.split(splitRegexp);

				hasIcons = textParts.length > 1;

				//если есть иконки, назначаем стиль, иначе нет, чтобы не ломался defaultTextFormat
				styleSheet = hasIcons ? css : null;

				applyHtmlText(sourceText);

				if (hasIcons)
				{
					for each (var part:String in textParts)
					{
						//если встретили идентификатор иконки, то вставляем иконку и заменяем текст пробелом нужной длины
						if (iconsMap[part] != null)
						{
							replaceTextById(part);
						}
					}
					arrangeIcons();
				}
			}
		}

		/**
		 * Расставляет иконки в нужные координаты, в зависимости от индекса в тексте
		 */
		public function arrangeIcons():void
		{
			//Не удалять!!! Баг TextField, если не дернуть геттер, не работает getCharBoundaries()
			x;

			for each (var obj:Object in icons)
			{
				var id:String = obj.id;
				var index:int = obj.index;
				var icon:DisplayObject = obj.icon;
				if (icon)
				{
					var bounds:Rectangle = getCharBoundaries(index);
					if (bounds)
					{
						icon.x = bounds.x;
						icon.y = bounds.y + ((bounds.height - icon.height) >> 1);
					}
				}
			}
		}

		protected var _text:String;
		override public function set text(value:String):void
		{
			if (_text != value)
			{
				_text = value;
				setHtmlText(value);
			}
		}

		protected var _htmlText:String;
		override public function set htmlText(value:String):void
		{
			if (_htmlText != value)
			{
				_htmlText = value;
				setHtmlText(value);
			}
		}

		protected function setHtmlText(value:String):void
		{
			sourceText = value ? value : "";
			// При наличии \r, \n неправильно работает getCharBoundaries() => заменяем на <br/>
			sourceText = sourceText.split("\n").join("<br/>");
			sourceText = sourceText.split("\r").join("<br/>");

			update();
		}

		protected function applyHtmlText(value:String):void
		{
			super.htmlText = value;
		}

		//--------------------------------------------------------------------------
		//
		//  Overridden methods for updating
		//
		//--------------------------------------------------------------------------

		override public function set x(value:Number):void
		{
			super.x = value;
			iconsContainer.x = value;
		}

		override public function set y(value:Number):void
		{
			super.y = value;
			iconsContainer.y = value;
		}

		override public function set width(value:Number):void
		{
			super.width = value;
			update();
		}

		override public function set height(value:Number):void
		{
			super.height = value;
			update();
		}

		override public function set autoSize(value:String):void
		{
			super.autoSize = value;
			update();
		}

		override public function set defaultTextFormat(value:TextFormat):void
		{
			if (styleSheet)
				styleSheet = null;
			super.defaultTextFormat = value;
			update();
		}

		override public function set multiline(value:Boolean):void
		{
			super.multiline = value;
			update();
		}

		override public function set wordWrap(value:Boolean):void
		{
			super.wordWrap = value;
			update();
		}

		override public function setTextFormat(value:TextFormat, beginIndex:int=-1, endIndex:int=-1):void
		{
			if (styleSheet)
				styleSheet = null;
			super.setTextFormat(value, beginIndex, endIndex);
			update();
		}

		override public function set visible(value:Boolean):void
		{
			super.visible = value;
			iconsContainer.visible = value;
		}

		private function onStage(event:Event):void
		{
			if(event.type == Event.ADDED_TO_STAGE)
				onShow();
			else
				onHide();
		}
	}
}