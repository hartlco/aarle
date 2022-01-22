var ExtensionClass = function() {};

ExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({
            "title": document.title,
            "hostname": document.location.hostname,
            "description": document.querySelector('meta[name="description"]').content,
            "baseURI": document.baseURI
        });
    }
};

var ExtensionPreprocessingJS = new ExtensionClass;
