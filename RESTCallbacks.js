// Generic ajax GETs with callback parameter
function CallMethod(url, successCallback, data) {
	var q = new Queue(true).add(function () {
	  data = data?"/"+data:"";
	  successCallback = successCallback || "";
      
		$.ajax({
			beforeSend: function(request) {
        // Where we set the custom header. The value doesn't matter. In the future we want to set this and verify the values matches the servers'
			  request.setRequestHeader("Grandmas-Cookies", Math.random());
			},
	    url:serverURL+url+data,
			type: "GET",
			async: true,
		  contentType: "application/json",
		  dataType: "text",
			error: function(response) { 
		    console.log(response);
		  },
		  success: successCallback
	  });
	});
}

// API queue management for all rest calls
var Queue = (function () {
    Queue.prototype.autorun = true;
    Queue.prototype.running = false;
    Queue.prototype.queue = [];
    function Queue(autorun) {
        if (typeof autorun !== "undefined") {
            this.autorun = autorun;
        }
        this.queue = []; //initialize the queue
    };
    Queue.prototype.add = function (callback) {
        var _this = this;
        //add callback to the queue
        this.queue.push(function () {
            var finished = callback();
            if (typeof finished === "undefined" || finished) {
                //  if callback returns `false`, then you have to 
                //  call `next` somewhere in the callback
                _this.dequeue();
            }
        });
        if (this.autorun && !this.running) {
            // if nothing is running, then start the engines!
            this.dequeue();
        }
        return this; // for chaining fun!
    };
    Queue.prototype.dequeue = function () {
        this.running = false;
        //get the first element off the queue
        var shift = this.queue.shift();
        if (shift) {
            this.running = true;
            shift();
        }
        return shift;
    };
    Queue.prototype.next = Queue.prototype.dequeue;
    return Queue;
})();
