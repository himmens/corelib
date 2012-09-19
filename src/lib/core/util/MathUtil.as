package lib.core.util
{
public class MathUtil
{
	// Коэфициент корректировки по-умолчанию
	static public const DEFAULT_CORRECT_KOEF:Number = 1;
	
	/**
	 * Функции для работы с углами.
	 */
	
	/**
	 * Перевод величины угла из градусов в радианы.
	 *
	 * @param	angle величина угла в градусах.
	 *
	 * @return	величина угла в радианах.
	 */
	static public function convertAngleToRadians(angle:Number):Number
	{
		var radians:Number = angle  / 180 * Math.PI;
		
		return radians;
	}
	
	/**
	 * Перевод величины угла из радианов в градусы.
	 *
	 * @param	radians величина угла в радианах.
	 *
	 * @return	величина угла в градусах.
	 */
	static public function convertRadiansToAngle(radians:Number):Number
	{
		var angle:Number = radians * 180 / Math.PI;
		
		return angle;
	}
	
	
	/**
	 * Функции для работы с тригонометрией.
	 */
	
	/**
	 * Получение «защищённого» синуса (осуществляется проверка на определённые значения угла).
	 * 
	 * @param	radians угол в радианах
	 * 
	 * @return	значение синуса.
	 */
	static public function getSafeSin(radians:Number):Number
	{
		var safeSin:Number = 0;
		
		// Если угол равен 0, PI, 2PI и т.п., то синус в этом случае должен быть равен 0
		if (radians % Math.PI != 0)
		{
			safeSin = Math.sin(radians);
		}
		
		return safeSin;
	}
	
	/**
	 * Получение «защищённого» косинуса (осуществляется проверка на определённые значения угла).
	 * 
	 * @param	radians угол в радианах
	 * 
	 * @return	значение косинуса.
	 */
	static public function getSafeCos(radians:Number):Number
	{
		var safeCos:Number = 0;
		
		// Если угол равен PI / 2, PI / 2 * 3, PI / 2 * 5 и т.п., то косинус в этом случае должен быть равен 0
		if (radians % Math.PI / 2 != 0 || radians % Math.PI == 0)
		{
			safeCos = Math.cos(radians);
		}
		
		return safeCos;
	}
	
	
	/**
	 * Функции для работы со случайными значениями.
	 */
	
	/**
	 * Возвращение случайного числа в заданных рамках.
	 *
	 * @param	minNum минимальное значение для случайного числа.
	 * @param	maxNum максимальное значение для случайного числа.
	 * @param	isNeedFloor нужно ли округлять к меньшему целому числу.
	 * @param	isNeedRound нужно ли округлять к ближайшему целому числу.
	 * @param	isNeedCeil нужно ли округлять к большему целому числу.
	 *
	 * @return	случайное число в заданных рамках.
	 */
	static public function getRandomNum(minNum:Number, maxNum:Number, isNeedFloor:Boolean = false, isNeedRound:Boolean = false, isNeedCeil:Boolean = false):Number
	{
		var randNum:Number = minNum + Math.random() * (maxNum - minNum);
		
		if (isNeedFloor)
		{
			randNum = Math.floor(randNum);
		}
		
		if (isNeedRound)
		{
			randNum = Math.round(randNum);
		}
		
		if (isNeedCeil)
		{
			randNum = Math.ceil(randNum);
		}
		
		return randNum;
	}
	
	
	/**
	 * Функции для работы с проверкой данных.
	 */
	
	/**
	 * Проверка значения.
	 * 
	 * @param	value значение, которое нужно проверить.
	 * @param	minValue минимальное значение.
	 * @param	maxValue максимальное значение.
	 * @param	correctKoef коэфициент корректировки
	 * 			(число будет умножаться на коэфициент при выходе за рамки).
	 * 
	 * @return	скорректированне значение.
	 */
	static public function correctValueWhenOver(
		value:Number,
		minValue:Number,
		maxValue:Number,
		correctKoef:Number = MathUtil.DEFAULT_CORRECT_KOEF):Number
	{
		if (value < minValue)
		{
			value = minValue;
			value *= correctKoef;
			
		}else if (value > maxValue)
		{
			value = maxValue;
			value *= correctKoef;
		}
		
		return value;
	}
	
	
	/**
	 * Получение знака числа.
	 * 
	 * @param	value число.
	 * 
	 * @return	знак числа (1 или -1), если число будет 0, то знак будет 1.
	 */
	static public function getValueSign(value:Number):int
	{
		var sign:int = 1;
		if (value < 0)
		{
			sign = -1;
		}
		
		return sign;
	}
	
	
	/**
	 * Увеличение числа до такого значения, чтобы оно не было дробным (через умножение на 10 в какой-то степенинаприм).
	 * Если в функцию передаётся 0.0234, а в качестве roundTo передаётся 1000, то в результате получится 
	 * 
	 * @param	number число.
	 * @param	roundTo до какого числа нужно будет округлить число.
	 * 
	 * @return	преобразованное число.
	 */
	static public function increaseNumberToNonFraciton(number:Number, roundTo:Number = 100):Number
	{
		number = MathUtil.roundNumberTo(number, roundTo);
		
		var numStr:String = String(number);
		var splittedNum:Array = numStr.split(".");
		
		// Если число вообще было дробным
		if (splittedNum.length > 1)
		{
			var fraction:String = splittedNum[1];
			number = number * Math.pow(10, fraction.length);
		}
		
		return number;
	}
	
	/**
	 * Округление числа до какого-то числа.
	 * 
	 * @param	number число.
	 * @param	roundTo число, к которому нужно округлить.
	 * 
	 * @return	полученное число.
	 */
	static public function roundNumberTo(number:Number, roundTo:Number = 10):Number
	{
		number = Math.round(number * roundTo) / roundTo;
		return number;
	}
}
}