package lib.core.util
{
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.utils.ByteArray;
	
public class URLLoaderUtil
{
	private static const BOUNDARY:String = "boundary";
	
	/**
	 * Создает multipart запрос для аплоада картинки на сервер из bitmapData.
	 * @param url адрес загрузки
	 * @param bytes байты для загрузки
	 */ 
	public static function createMultiPartRequest(url:String, bytes:ByteArray, fileProp:String="file1", fileName:String="file1.png", params:Object=null):URLRequest
	{
		var request:URLRequest = new URLRequest(url);
		
		var uploadVars:URLVariables = new URLVariables();
		
		var header1:String = "\r\n--" + BOUNDARY + "\r\n" + 
			"Content-Disposition: form-data; name=\""+fileProp+"\"; filename=\""+fileName+"\"\r\n" + 
			"Content-Type: image/png\r\n" + "\r\n";
		var headerBytes1:ByteArray = new ByteArray();
		headerBytes1.writeMultiByte(header1, "ascii");
		var postData:ByteArray = new ByteArray();
		postData.writeBytes(headerBytes1, 0, headerBytes1.length);
		
		if(bytes)
			postData.writeBytes(bytes, 0, bytes.length);
		
		if (!params)
			params = {};
		if (!params.Upload)
			params.Upload = "Submit Query";
		for (var prop:String in params) {
			var header:String = "--" + BOUNDARY + "\r\n" + "Content-Disposition: form-data; name=\""+prop+"\"\r\n" + "\r\n" + params[prop]+"\r\n" + "--" + BOUNDARY + "--";
			var headerBytes:ByteArray = new ByteArray();
			headerBytes.writeMultiByte(header, "ascii");
			postData.writeBytes(headerBytes, 0, headerBytes.length);
		}
		request.data = postData;
		request.method = URLRequestMethod.POST;
		request.contentType = "multipart/form-data; boundary=" + BOUNDARY;
		
		return request;
	}
}
}