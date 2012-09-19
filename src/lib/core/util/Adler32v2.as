/*

The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at

http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the License.

The Original Code is ASGard Framework.

The Initial Developer of the Original Code is
ALCARAZ Marc (aka eKameleon)  <ekameleon@gmail.com>.
Portions created by the Initial Developer are Copyright (C) 2004-2009
the Initial Developer. All Rights Reserved.

Contributor(s) :

*/

  /**
 *http://code.google.com/p/as-gard/source/browse/trunk/AS3/trunk/src/libraries/hash/Adler32.as?r=177 
 */
package lib.core.util
{
	
import flash.utils.ByteArray;

/**
 * Adler-32 is a modification of the Fletcher checksum.
 * The <a href="http://en.wikipedia.org/wiki/Adler-32">Adler-32</a> checksum is part of the widely-used zlib compression library, as both were developed by Mark Adler.  
 * A "rolling checksum" version of Adler-32 is used in the rsync utility.
 */
public final class Adler32v2
{
	/**
	 * Adds the complete byte array to the data checksum.
	 * @param buffer the buffer ByteArray object which contains the datas.
	 * @param index The index to begin the buffering (default 0).
	 * @param len The length value to limit the buffering.
	 */
	public static function checkSum( buffer:ByteArray , index:uint = 0 , length:uint = 0 ):uint
	{
		if (index >= buffer.length )
		{
			index = buffer.length ;
		}
		
		if( length == 0 )
		{
			length = buffer.length - index ;
		}
		
		if( ( length + index ) > buffer.length )
		{
			length = buffer.length - index;
		}
		
		var tlen:uint ;
		var i:uint = index ;
		var a:uint = 1;
		var b:uint = 0;
		
		while ( length )
		{
			tlen    = ( length  > NMAX ) ? NMAX : length ;
			length -= tlen;
			do
			{
				a += buffer[i++] ;
				b += a ;
			}
			while ( --tlen ) ;
			
			a = (a & 0xFFFF) + (a >> 16) * 15 ;
			b = (b & 0xFFFF) + (b >> 16) * 15 ;
		}
		
		if (a >= BASE)
		{
			a -= BASE ;
		}
		
		b = (b & 0xFFFF) + (b >> 16) * 15;
		
		if (b >= BASE)
		{
			b -= BASE ;
		}
		
		return (b << 16) | a;
	}
	
	/**
	 * The largest prime smaller than 65536.
	 */
	public static const BASE:int = 65521 ;
	
	/**
	 * NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1
	 */
	public static const NMAX:int = 5552 ;
}
}