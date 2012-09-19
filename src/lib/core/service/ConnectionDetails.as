package lib.core.service
{

/**
 *
 */
public class ConnectionDetails
{
	public var host:String;
	public var port:int;
	public var policyPort:int;
	public var secure:Boolean;
	public var secureVer:String;

	public function ConnectionDetails(host:String, port:int = 0, policyPort:int = 0, secure:Boolean = false, secureVer:String = null)
	{
		this.host = host;
		this.port = port;
		this.policyPort = policyPort;
		this.secure = secure;
		this.secureVer = secureVer;
	}

	public function toString():String
	{
		var str:String = "[host= "+host+", port= "+port+", policyPort= "+policyPort+", secure= "+secure+", secureVer = "+secureVer+"]";
		return str;
	}

}
}