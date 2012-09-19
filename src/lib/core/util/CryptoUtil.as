package lib.core.util
{
import by.blooddy.crypto.Base64;
import by.blooddy.crypto.CRC32;
import by.blooddy.crypto.MD5;

import lib.core.util.log.Logger;

import flash.utils.ByteArray;
import flash.utils.getDefinitionByName;

//JSON;

public class CryptoUtil
{
	public static function base64Encode(value:ByteArray):String
	{
		var res:String;
		try {
//			var encoder:Base64Encoder = new Base64Encoder();
//			encoder.encodeBytes(value);
//			res = encoder.flush();
			res = Base64.encode(value);
		}
		catch (e:Error) {
			Logger.debug("Base64Encoder Error: " + e);
		}
		return res;
	}

	public static function base64Decode(value:String):ByteArray
	{
		var res:ByteArray;
		try {
//			var decoder:Base64Decoder = new Base64Decoder();
//			decoder.decode(value);
//			res = decoder.flush();
			res = Base64.decode(value);
		}
		catch (e:Error) {
			Logger.debug("Base64Decoder Error: " + e);
		}
		return res;
	}

	public static function md5(value:String):String
	{
		return MD5.hash(value);
	}

	public static function JSONDecode(value:String):*
	{
		var res:Object;
		try
		{
			var decoder:Object;
			
			try
			{
				decoder = getDefinitionByName("JSON");
			}catch(err:Error){}
			
			
			if(decoder)
			{
				res = decoder.parse(value);
			}else
			{
				decoder = getDefinitionByName("com.adobe.serialization.json.JSON");
				res = decoder.decode(value);
			}
			
			return res;
			
		}
		catch (e:Error) {
			Logger.debug("JSONDecode Error: " + e, "value="+value);
		}
		return res;
	}

	public static function JSONEncode(value:Object):String
	{
		var res:String;
		try
		{
			var encoder:Object;
			
			try
			{
				encoder = getDefinitionByName("JSON");
			}catch(err:Error){}
			
			
			if(encoder)
			{
				res = encoder.stringify(value);
			}else
			{
				encoder = getDefinitionByName("com.adobe.serialization.json.JSON");
				res = encoder.encode(value);
			}
		}
		catch (e:Error) {
			Logger.debug("JSONEncode Error: " + e);
		}
		return res;
	}

	public static function crc32(value:ByteArray):uint
	{
		return CRC32.hash(value);
	}
	
	public static function adler32(value:ByteArray):uint
	{
//		return Adler32.hash(value);
		return Adler32v2.checkSum(value);
	}
}
}