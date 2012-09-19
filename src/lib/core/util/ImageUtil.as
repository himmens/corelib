package lib.core.util
{
import by.blooddy.crypto.image.JPEGEncoder;
import by.blooddy.crypto.image.PNGEncoder;

import com.gskinner.geom.ColorMatrix;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.PixelSnapping;
import flash.filters.ColorMatrixFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import lib.core.util.log.Logger;

public class ImageUtil
{
	public static function jpgEncode(image:BitmapData, quality:Number = 85):ByteArray
	{
		var res:ByteArray;
		try {
			res = JPEGEncoder.encode(image, quality);
		}
		catch (e:Error) {
			Logger.debug("jpgEncode Error: " + e);
		}
		return res;
	}

	public static function pngEncode(image:BitmapData):ByteArray
	{
		var res:ByteArray;
		try {
			res = PNGEncoder.encode(image);
		}
		catch (e:Error) {
			Logger.debug("pngEncode Error: " + e);
		}
		return res;
	}


	/**
	 * Возвращает фильтр для изменения яркости.
	 * @param value значение для яркости
	 * @return ColorMatrixFilter
	 *
	 */
	public static function brightnessFilter (value:int):ColorMatrixFilter
	{
		var matrix:ColorMatrix = new ColorMatrix();
		matrix.adjustBrightness(value);
		var filter:ColorMatrixFilter = new ColorMatrixFilter (matrix);
		return filter;
	}

	/**
	 * Возвращает фильтр для изменения контраста.
	 * @param value значение для контраста
	 * @return ColorMatrixFilter
	 *
	 */
	public static function constrastFilter (value:int):ColorMatrixFilter
	{
		var matrix:ColorMatrix = new ColorMatrix();
		matrix.adjustContrast(value);
		var filter:ColorMatrixFilter = new ColorMatrixFilter (matrix);
		return filter;
	}

	/**
	 * Возвращает фильтр для изменения насыщенности цвета.
	 *
	 * @param value значение для насыщенности цвета.
	 *
	 * @return ColorMatrixFilter
	 */
	public static function saturationFilter (value:int):ColorMatrixFilter
	{
		var matrix:ColorMatrix = new ColorMatrix();
		matrix.adjustSaturation(value);
		var filter:ColorMatrixFilter = new ColorMatrixFilter (matrix.toArray());
		return filter;
	}
	
	/**
	 * Возвращает фильтр для изменения цвета парметрами HSV цветовой модели.
	 *
	 * @param hue цветовой тон.
	 * @param saturation насыщенность цвета.
	 * @param brightness яркость цвета.
	 * @param contrast контрастность цвета.
	 *
	 * @return ColorMatrixFilter
	 */
	public static function hsvFilter (hue:int, saturation:int, brightness:int, contrast:int = 0):ColorMatrixFilter
	{
		var matrix:ColorMatrix = new ColorMatrix();
		matrix.adjustHue(hue);
		matrix.adjustSaturation(saturation);
		matrix.adjustBrightness(brightness);
		matrix.adjustContrast(contrast);
		return new ColorMatrixFilter (matrix.toArray());
	}

	/**
	 * Получение фильтра для чёрно-белого изображения.
	 *
	 * @return	ColorMatrixFilter
	 */
	public static function blackAndWhiteFilter ():ColorMatrixFilter
	{
		var matrix:ColorMatrix = new ColorMatrix();
		matrix.adjustSaturation(-100);
		var filter:ColorMatrixFilter = new ColorMatrixFilter (matrix.toArray());
		return filter;
	}

	/**
	 * Получение сепия фильтра.
	 */
	public static const sepiaFilter:ColorMatrixFilter = function():ColorMatrixFilter
	{
		var sepia:ColorMatrixFilter = new ColorMatrixFilter();
		sepia.matrix = [
			0.3930000066757202, 0.7689999938011169,
			0.1889999955892563, 0, 0, 0.3490000069141388,
			0.6859999895095825, 0.1679999977350235, 0, 0,
			0.2720000147819519, 0.5339999794960022,
			0.1309999972581863, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1
		];

		return sepia;
	}();

	/**
	 *
	 * @param vector
	 * @param crop
	 * @param fill
	 * @return
	 *
	 * @see vectorToBitmapData
	 *
	 */
	public static function vectorToBitmap(vector:DisplayObject, crop:Boolean = true, fill:uint = 0x00FFFFFF):Bitmap
	{
		var bd:BitmapData = vectorToBitmapData(vector, crop, fill);

		var bitmap:Bitmap = new Bitmap(bd, PixelSnapping.AUTO, true);
		return bitmap;
	}

	/**
	 *
	 * @param vector
	 * @param crop обрезать границы картинки, получавшаяся картинка будет в координатах (0, 0) независимо от ее
	 * 		исходного положения внутри прозрачного векторного спрайта. Если указать false, то битмап будет полностью повторять
	 * 		положение контента как в векторе и зальет себя прозрачным цветом.
	 * @param fill цвет заливки, по умолчанию - прозрачный белый
	 * @param rect границы для картинки
	 * @return
	 *
	 */
	public static function vectorToBitmapData(vector:DisplayObject, crop:Boolean = true, fill:uint = 0x00FFFFFF, rect:Rectangle = null):BitmapData
	{
		var bd:BitmapData;

		var absScaleX:Number = Math.abs(vector.scaleX);
		var absScaleY:Number = Math.abs(vector.scaleY);

		if(!rect)
		{
			rect = vector.getBounds(vector);
			rect.width *= absScaleX;
			rect.height *= absScaleY;
			rect.x *= absScaleX;
			rect.y *= absScaleY;
		}

		//округляем область скрина, чотбы вектор не засмусился
		rect.x = int(rect.x);
		rect.y = int(rect.y);
		rect.width = Math.ceil(rect.width) || 1;
		rect.height = Math.ceil(rect.height) || 1;

		//cropped
		bd = new BitmapData(rect.width, rect.height, true, fill);
		bd.draw(vector, new Matrix(absScaleX, 0, 0, absScaleY, -rect.x, -rect.y), null, null, null, true);

		return bd;
	}

	/**
	 * Метод фитит битмапу в переданный размер в сохранением пропорций дозаливая нужным цветом "лишние" образовавшиеся зоны (если пропорции
	 * исходной битмапы не совпадают с переданным размером).
	 *
	 * @param fillToMaxSize можно выставить флаг чтобы на выходе была битпама переданного максимального размера - что удобно для соц сетей,
	 * которые часто тупо выставляют картинке ширину*высоту без сохранения пропорций.
	 *
	 * @param center цетнрирование исходной битмапы в сгенерированной. если размер исходной оказался меньше сгенерированной
	 *
	 * @param bd
	 * @return
	 *
	 */
	public static function scaleBitmap(bd:BitmapData, maxSize:Point = null, disposeSource:Boolean = true, fillColor:uint = 0x00FFFFFF, fillToMaxSize:Boolean = false, center:Boolean = true):BitmapData
	{
		if(!maxSize) maxSize = new Point(1000, 1000);

		var w:int = fillToMaxSize ? maxSize.x : Math.min(bd.width, maxSize.x);
		var h:int = fillToMaxSize ? maxSize.y : Math.min(bd.height, maxSize.y);

		var scale:Number = 1;
		if(w < bd.width || h < bd.height)
			scale = Math.min(w/bd.width, h/bd.height);

		var bds:BitmapData = new BitmapData(w, h, true, fillColor);

		//центрировение
		var shiftX:int = center ? (w - bd.width*scale)/2 : 0;
		var shiftY:int = center ? (h - bd.height*scale)/2 : 0;

		bds.draw(bd, new Matrix(scale, 0, 0, scale, shiftX, shiftY), null, null, null, true);
		if(disposeSource)
			bd.dispose();

		return bds;
	}
}
}