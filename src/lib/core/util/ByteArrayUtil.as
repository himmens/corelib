package lib.core.util
{
import flash.utils.ByteArray;


public class ByteArrayUtil
{
//	public static function getBits(bytes:ByteArray, radix:int = 16):String
//	{
//		var output:String = "";
//		var cachedPos:int = bytes.position;
//		bytes.position = 0;
//
//		var hex:String;
//		for (var i:uint = 0; i < bytes.length; i++ ) {
//			var tempInt:int = bytes.readUnsignedByte();
//			if(radix == 2){
//				output += (tempInt & 128) > 0 ? '1':'0';
//				output += (tempInt & 64)  > 0 ? '1':'0';
//				output += (tempInt & 32)  > 0 ? '1':'0';
//				output += (tempInt & 16)  > 0 ? '1':'0';
//				output += (tempInt & 8)   > 0 ? '1':'0';
//				output += (tempInt & 4)   > 0 ? '1':'0';
//				output += (tempInt & 2)   > 0 ? '1':'0';
//				output += (tempInt & 1)   > 0 ? '1':'0';
//				output += " ";
//			}else
//				hex = tempInt.toString(radix).toUpperCase();
//				if (hex.length&1==1) hex="0"+hex;
//				output += hex+ " ";
//		}
//		bytes.position = cachedPos;
//		return output;
//	}

	public static function getBytesString(array:ByteArray, colons:Boolean=false, position:int = 0):String {
		var s:String = "";
		for (var i:int=position;i<array.length;i++) {
			s+=("0"+array[i].toString(16)).substr(-2,2).toUpperCase();
			if (i<array.length-1) s+= colons ? ":" : " ";
		}
		return s;
	}
	
	public static function getAvailableBytesString(array:ByteArray, colons:Boolean=false):String {
		return getBytesString(array, colons, array.position);
	}

//	public static function getBytesString(arr:ByteArray):String
//	{
//		var str:String = "";
//		for (var i:int = 0; i<arr.length; i++)
//		{
//			str += arr[i];
//			if (i < arr.length - 1)
//				str += ",";
//		}
//		return str;
//	}

}
}