package lib.core.util
{
import lib.core.util.log.Logger;

import flash.display.DisplayObjectContainer;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextLineMetrics;

public class TextFieldUtil
{
	/**
	 * Проверяет, есть ли фонт поля среди заембежженых
	 */
	public static function hasEmbedFonts(tf:TextField):Boolean
	{
		if(!tf)
			return false;

		var format:TextFormat = tf.defaultTextFormat;
		var font:String = format.font;
		var bold:Boolean = Boolean(format.bold);

		return FontUtil.hasEmbed(font, bold);
	}

	/**
	 * Удаляет поле и заменяет клоном, созданным программно с теми же свойствами
	 */
	public static function replaceTextField(tf:TextField, target:TextField = null, forceBold:Boolean = false):TextField
	{
		if (!tf)
			return target;

		//клонируем текстфилд
		var newTf:TextField = cloneTextField(tf, target, forceBold);
		//заменяем старый текстфилд новым
		var parent:DisplayObjectContainer = tf.parent;
		if(parent)
		{
			parent.addChildAt(newTf, parent.getChildIndex(tf));
			parent.removeChild(tf);
		}
		newTf.name = tf.name;

		return newTf;
	}

	/**
	 * Делает копию текстового поля со всеми свойствами оригинала
	 *
	 * @param tf
	 * @param target
	 * @param forceBold форсирует включение Bold в клон текстового поля. Этот параметр приходится указывать снаружи, т.к. при использовании трекинга
	 * и автокернинга Flash IDE сбрасывает bold в false и клон будет нежирным
	 * @return
	 *
	 */
	public static function cloneTextField (tf:TextField, target:TextField = null, forceBold:Boolean = false):TextField
	{
		if (!tf)
			return target;

		var clone:TextField = target ? target : new TextField();

		var copyTextFormat:TextFormat;
		if (tf.length <= 0) {
			copyTextFormat = tf.defaultTextFormat;
		} else {
			copyTextFormat = tf.getTextFormat() ? tf.getTextFormat() : tf.defaultTextFormat;
		}
		if(forceBold)
			copyTextFormat.bold = true;

		var format:TextFormat = ObjectUtil.copy(copyTextFormat) as TextFormat;
		clone.defaultTextFormat = format;

		clone.transform = tf.transform;
		clone.x = tf.x;
		clone.y = tf.y;
		clone.scaleX = tf.scaleX;
		clone.scaleY = tf.scaleY;
		clone.autoSize = tf.autoSize;
		clone.multiline = tf.multiline;
		clone.wordWrap = tf.wordWrap;
		clone.width = tf.width;
		clone.height = tf.height;
		clone.rotation = tf.rotation;
		clone.alpha = tf.alpha;
		clone.filters = tf.filters;
		clone.blendMode = tf.blendMode;
		clone.condenseWhite = tf.condenseWhite;
		clone.sharpness = tf.sharpness;
		clone.thickness = tf.thickness;
		clone.gridFitType = tf.gridFitType;
		clone.antiAliasType = tf.antiAliasType;
		clone.styleSheet = tf.styleSheet;
		clone.textColor = tf.textColor;
		clone.type = tf.type;
		clone.visible = tf.visible;
		clone.selectable = tf.selectable;
		clone.embedFonts = tf.embedFonts;
		clone.background = tf.background;
		clone.backgroundColor = tf.backgroundColor;
		clone.border = tf.border;
		clone.borderColor = tf.borderColor;
		clone.text = tf.text;
		clone.htmlText = tf.htmlText;

		return clone;
	}

	/**
	 * Укорачивает текст, добавляя "..." или переданную строку, чотбы текст влезал в размеры переданного TextField
	 * Работает только с sinle line текстовыми полями.
	 *
	 * @param tf
	 * @param truncateStr
	 * @return true, если текст был укорочен, false если остался без изменения
	 *
	 */
	public static function truncateToFit (tf:TextField, truncateStr:String = '...'):Boolean
	{
		//заглушка для текстового поля нулевой ширины или без текста
		if (!tf.text || tf.width <= 4) return false;

		var text:String = tf.text;
		var cached:String = text;
		var x:int = int(tf.defaultTextFormat.leftMargin) + 2; //x координата левого символа в строке
		
		while ((tf.textWidth + x) > tf.width && text.length > 0)
		{
			text = text.substring(0, text.length-1);
			tf.text = text+truncateStr;
		}

		return text != cached;
	}
	
//	public static function truncateToFit2 (tf:TextField, truncateStr:String = '...'):Boolean
//	{
//		//заглушка для текстового поля нулевой ширины или без текста
//		if (!tf.text || tf.width <= 4) return false;
//		
//		var text:String = tf.text;
//		var cached:String = text;
//		var lineMetric:TextLineMetrics = tf.getLineMetrics(0);
//		while ((lineMetric.width + lineMetric.x) > tf.width && text.length > 0)
//		{
//			text = text.substring(0, text.length-1);
//			tf.text = text+truncateStr;
//			lineMetric = tf.getLineMetrics(0);
//		}
//		
//		return text != cached;
//	}

	/**
	 * Подгоняет размер шрифта под размеры текстового поля, чтобы влазил текст
	 * @param tf
	 * @return
	 *
	 */
	public static function fitTextSize (tf:TextField, fitHeight:Boolean = false):Boolean
	{
		//заглушка для текстового поля нулевой ширины или без текста
		if (!tf.text || tf.width <= 4) return false;

		var format:TextFormat = tf.defaultTextFormat;

		var maxSteps:int = 100;
		var step:int = 0;
		while(fitHeight ? tf.textHeight+4 > tf.height : tf.textWidth+4 > tf.width)
		{
			format.size = int(format.size) - 1;
			tf.defaultTextFormat = format;
			tf.setTextFormat(format);

			// Код, чтобы цикл прерывался и не приводил к зависанию FlashPlayer
			step++;
			if(step >= maxSteps)
			{
				Logger.error("TextFieldUtil.fitTextSize", "ERROR! Max steps count!");
				break;
			}
		}

		return true;
	}
}
}