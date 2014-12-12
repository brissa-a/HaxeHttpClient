#HaxeHttpRequest

A simple http client based on standard [haxe.Http](https://github.com/HaxeFoundation/haxe/blob/development/std/haxe/Http.hx)
to handle Rest call.

Theoretically support all sys target, but was tested only in php.

##Usage Exemple

### Json POST Request
```haxe
  var request = new HttpRequest();
  request.method = "POST";
  request.url = new Url("http://localhost");
  request.headers.set("Content-Type", "application/json");
  request.data = "{test: 'Valeur'}";
  request.send({
    onData: function (data : String) {
        trace(data);
    },
    onError: function (error : String, ?data : String) {
        trace(error);
    },
    onStatus: function (code : Int) {
        trace("Status " + code);
    }
  });
```

### Html Post/Get

For convenience there is two utils function to create post and get with parameter

```haxe
    var request = HttpRequest.createGetRequest("http://http.localhost.com/hello.txt", {[
      {
        name: "param1",
        value: "value1",
      },
      {
        name: "param2",
        value: "value2",
      }
    ]);
    //If post request the data attribute is initilised with parameters
    //If get request the url is initialised with parameters
    request.send(callbacks);
```

##Todo

- Multipart
- Proxy
- Targe flash, js
