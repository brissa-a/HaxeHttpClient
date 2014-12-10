package haxe.http ;

import haxe.http.HttpRequest;
import haxe.http.Url;
import php.Lib;
import php.Web;

class Main 
{

    public static var callbacks = {
        onData: function (data : String) {
            trace("On data called !");
            trace(data);
        },
        onError: function (error : String, ?data : String) {
            trace(error);
        },
        onStatus: function (code : Int) {
            trace("Status " + code);
        }
    }
    
    static function main() 
    {
        Web.setHeader("Content-Type", "text/plain");
        testPostRequest();
        trace("----NEXT----");
        testGetRequest();
        trace("----NEXT----");
        testHttpRequest();
    }
    
    static function testGetRequest() {
        var request = HttpRequest.createGetRequest("http://http.localhost.com/hello.txt");
        trace("request sended !");
        request.send(callbacks);
    }
    
    static function testGetRequest() {
        var request = HttpRequest.createGetRequest("http://http.localhost.com/hello.txt");
        trace("request sended !");
        request.send(callbacks);
    }

    static function testPostRequest() {
        var request = HttpRequest.createPostRequest("http://http.localhost.com/hello.txt");
        trace("request sended !");
        request.send(callbacks);
    }
    
    static function testHttpRequest() {
        var request = new HttpRequest();
        request.method = "GET";
        request.url = new Url("http://http.localhost.com/hello.txt");
        trace("request sended !");
        request.send(callbacks);
    }

}