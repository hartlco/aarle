var MyExtensionJavaScriptClass = function() {};

MyExtensionJavaScriptClass.prototype = {
    run: function(arguments) {
    // Pass the baseURI of the webpage to the extension.
        arguments.completionFunction({
            "baseURI": document.baseURI,
            "title": document.title
        });
    },

// Note that the finalize function is only available in iOS.
    finalize: function(arguments) {
    }
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new MyExtensionJavaScriptClass;
