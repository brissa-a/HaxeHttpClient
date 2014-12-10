package haxe.http;

class Url
{

    private var regexp = ~/^(https?:\/\/)?([a-zA-Z\.0-9-]+)(:[0-9]+)?(.*)$/;

    public var url(default, null) : String;
    public var valid(default, null) : Bool;
    public var secure(default, null) : Bool;
    public var host(default, null) : String;
    public var port(default, null) : Int;
    public var request(default, null) : String;

    public function new (url : String) {
        this.url = url;
        this.valid = regexp.match(url);
        this.secure = regexp.matched(1) == "https://";
        this.host = regexp.matched(2);
        var portString = regexp.matched(3);
        this.port = if ( portString == null || portString == "" ) secure ? 443 : 80 else Std.parseInt(portString.substr(1, portString.length - 1));
        this.request = regexp.matched(4);
        if ( request == "" ) request = "/";
    }

    public function toString() {
        return url;
    }

}