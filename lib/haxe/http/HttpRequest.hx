package haxe.http ;


/*
public static function get(url : String, ?param : Map<String, String>, ?headers : Map<String, String>) {
    send("GET", url += param, headers, null);
}

public static function post(param : {url : String, param : Map<String, String>, ?headers : Map<String, String>, ?callback}) {
    headers.set("Content-Type","application/x-www-form-urlencoded");
    send("POST", url, headers, param.form-urlencoded);
}
*/

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Output;
import sys.net.Host;
import sys.net.Socket;

private typedef AbstractSocket = {
    var input(default,null) : haxe.io.Input;
    var output(default,null) : haxe.io.Output;
    function connect( host : Host, port : Int ) : Void;
    function setTimeout( t : Float ) : Void;
    function write( str : String ) : Void;
    function close() : Void;
    function shutdown( read : Bool, write : Bool ) : Void;
}

typedef HttpRequestCallback = {
    ?onError : String -> ?String -> Void,
    ?onData : String -> Void,
    ?onStatus : Int -> Void
}

typedef HttpResponse = {
    raw : BytesOutput,
    headers : Map<String, String>
}

class HttpRequest
{

    public var method : String;
    public var url : Url;
    public var headers = new Map<String, String>();
    public var data : String;

    public function new()
    {
        
    }

    private static function urlEncode(params : Array<{name:String, value:String}>) {
        var encoded : String = null;
        for( p in params ) {
            if( encoded == null )
                encoded = "";
            else
                encoded += "&";
            encoded += StringTools.urlEncode(p.name)+"="+StringTools.urlEncode(p.value);
        }
        return encoded;
    }
    
    public static function createGetRequest(url : String, ?params : Array<{name:String, value:String}>) {
        var rq = new HttpRequest();
        rq.method = "GET";
        rq.url = new Url(url);
        if (params != null) {
            rq.url = new Url(rq.url + "?" + urlEncode(params));
        }
        return rq;
    }
    
    public static function createPostRequest(url : String, ?params : Array<{name:String, value:String}>) {
        var rq = new HttpRequest();
        rq.method = "POST";
        rq.headers.set("Content-Type", "application/x-www-form-urlencoded");
        rq.url = new Url(url);
        if (params != null) {
            rq.data = urlEncode(params);
        }
        return rq;
    }

    public function send(callbacks : HttpRequestCallback, timeout = 35.0) {
        if(!url.valid) {
            callbacks.onError("Invalid URL");
            return;
        }
        var sock : AbstractSocket;
        if( url.secure ) {
            sock = getSslSocket();
        } else {
            sock = new Socket();
        }

        var b = new StringBuf();
        b.add(method);
        b.add(" ");
        b.add(url.request);
        b.add(" HTTP/1.1\r\n");
        b.add("Host: " + url.host + "\r\n");
        for( key in headers.keys() ) {
            b.add(key);
            b.add(": ");
            b.add(headers[key]);
            b.add("\r\n");
        }
        if (data != null) {
            b.add("Content-Length: " + data.length + "\r\n");
            b.add("\r\n");
            b.add(data);
        }
        b.add("\r\n");
        var response = {
            raw: new BytesOutput(),
            headers: new Map<String, String>()
        }
        try {
            sock.connect(new Host(url.host), url.port);
            Sys.println(b.toString());
            sock.write(b.toString());
            readHttpResponse(response, sock, callbacks, timeout);
            callbacks.onData(toString(response.raw));
        } catch( e : Dynamic ) {
            try sock.close() catch( e : Dynamic ) { };
            callbacks.onError(Std.string(e), toString(response.raw));
        }
    }
    
    private static function getSslSocket() {
        #if php
        return new php.net.SslSocket();
        #elseif java
        return new java.net.SslSocket();
        #elseif hxssl
        return new neko.tls.Socket();
        #else
        throw "Https is only supported with -lib hxssl";
        #end
    }
    
    private static function toString(o : BytesOutput) {
        #if neko
            return neko.Lib.stringReference(o.getBytes());
        #else
            return o.getBytes().toString();
        #end
    }
    
    function readHttpResponse( out_reponse : HttpResponse, sock : AbstractSocket, callbacks : HttpRequestCallback, timeout ) {
        // READ the HTTP header (until \r\n\r\n)
        var b = new haxe.io.BytesBuffer();
        var k = 4;
        var s = haxe.io.Bytes.alloc(4);
        sock.setTimeout(timeout);
        while ( true ) {
            var p = sock.input.readBytes(s,0,k);
            while( p != k )
                p += sock.input.readBytes(s,p,k - p);
            b.addBytes(s,0,k);
            switch( k ) {
            case 1:
                var c = s.get(0);
                if( c == 10 )
                    break;
                if( c == 13 )
                    k = 3;
                else
                    k = 4;
            case 2:
                var c = s.get(1);
                if( c == 10 ) {
                    if( s.get(0) == 13 )
                        break;
                    k = 4;
                } else if( c == 13 )
                    k = 3;
                else
                    k = 4;
            case 3:
                var c = s.get(2);
                if( c == 10 ) {
                    if( s.get(1) != 13 )
                        k = 4;
                    else if( s.get(0) != 10 )
                        k = 2;
                    else
                        break;
                } else if( c == 13 ) {
                    if( s.get(1) != 10 || s.get(0) != 13 )
                        k = 1;
                    else
                        k = 3;
                } else
                    k = 4;
            case 4:
                var c = s.get(3);
                if( c == 10 ) {
                    if( s.get(2) != 13 )
                        continue;
                    else if( s.get(1) != 10 || s.get(0) != 13 )
                        k = 2;
                    else
                        break;
                } else if( c == 13 ) {
                    if( s.get(2) != 10 || s.get(1) != 13 )
                        k = 3;
                    else
                        k = 1;
                }
            }
        }
        #if neko
        var headers = neko.Lib.stringReference(b.getBytes()).split("\r\n");
        #else
        var headers = b.getBytes().toString().split("\r\n");
        #end
        var response = headers.shift();
        var rp = response.split(" ");
        var status = Std.parseInt(rp[1]);
        if( status == 0 || status == null )
            throw "Response status error";

        // remove the two lasts \r\n\r\n
        headers.pop();
        headers.pop();
        out_reponse.headers = new haxe.ds.StringMap();
        var size = null;
        var chunked = false;
        for( hline in headers ) {
            var a = hline.split(": ");
            var hname = a.shift();
            var hval = if( a.length == 1 ) a[0] else a.join(": ");
            hval = StringTools.ltrim( StringTools.rtrim( hval ) );
            out_reponse.headers.set(hname, hval);
            switch(hname.toLowerCase())
            {
                case "content-length":
                    size = Std.parseInt(hval);
                case "transfer-encoding":
                    chunked = (hval.toLowerCase() == "chunked");
            }
        }

        callbacks.onStatus(status);

        var chunk_re = ~/^([0-9A-Fa-f]+)[ ]*\r\n/m;
        var chunk_size = null;
        var chunk_buf = null;

        var bufsize = 1024;
        var buf = haxe.io.Bytes.alloc(bufsize);
        if( size == null ) {
            sock.shutdown(false,true);
            try {
                while( true ) {
                    var len = sock.input.readBytes(buf,0,bufsize);
                    if( chunked ) {
                        if( !readChunk(chunk_re,out_reponse.raw,buf,len, chunk_size, chunk_buf, callbacks) )
                            break;
                    } else
                        out_reponse.raw.writeBytes(buf,0,len);
                }
            } catch( e : haxe.io.Eof ) {
            }
        } else {
            out_reponse.raw.prepare(size);
            try {
                while( size > 0 ) {
                    var len = sock.input.readBytes(buf,0,if( size > bufsize ) bufsize else size);
                    if( chunked ) {
                        if( !readChunk(chunk_re,out_reponse.raw,buf,len, chunk_size, chunk_buf, callbacks) )
                            break;
                    } else
                        out_reponse.raw.writeBytes(buf,0,len);
                    size -= len;
                }
            } catch( e : haxe.io.Eof ) {
                throw "Transfer aborted";
            }
        }
        if( chunked && (chunk_size != null || chunk_buf != null) )
            throw "Invalid chunk";
        if( status < 200 || status >= 400 )
            throw "Http Error #"+status;
        out_reponse.raw.close();
    }

    function readChunk(chunk_re : EReg, api : haxe.io.BytesOutput, buf : haxe.io.Bytes, len, chunk_size, chunk_buf, callbacks) {
        if( chunk_size == null ) {
            if( chunk_buf != null ) {
                var b = new haxe.io.BytesBuffer();
                b.add(chunk_buf);
                b.addBytes(buf,0,len);
                buf = b.getBytes();
                len += chunk_buf.length;
                chunk_buf = null;
            }
            #if neko
            if( chunk_re.match(neko.Lib.stringReference(buf)) ) {
            #else
            if( chunk_re.match(buf.toString()) ) {
            #end
                var p = chunk_re.matchedPos();
                if( p.len <= len ) {
                    var cstr = chunk_re.matched(1);
                    chunk_size = Std.parseInt("0x"+cstr);
                    if( cstr == "0" ) {
                        chunk_size = null;
                        chunk_buf = null;
                        return false;
                    }
                    len -= p.len;
                    return readChunk(chunk_re,api,buf.sub(p.len,len),len, chunk_size, chunk_buf, callbacks);
                }
            }
            // prevent buffer accumulation
            if( len > 10 ) {
                callbacks.onError("Invalid chunk", toString(api));
                return false;
            }
            chunk_buf = buf.sub(0,len);
            return true;
        }
        if( chunk_size > len ) {
            chunk_size -= len;
            api.writeBytes(buf,0,len);
            return true;
        }
        var end = chunk_size + 2;
        if( len >= end ) {
            if( chunk_size > 0 )
                api.writeBytes(buf,0,chunk_size);
            len -= end;
            chunk_size = null;
            if( len == 0 )
                return true;
            return readChunk(chunk_re,api,buf.sub(end,len),len, chunk_size, chunk_buf, callbacks);
        }
        if( chunk_size > 0 )
            api.writeBytes(buf,0,chunk_size);
        chunk_size -= len;
        return true;
    }

    
}