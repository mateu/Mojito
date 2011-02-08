$(document).ready(function() {
	// $('#content').each(function() {
		// this.focus();
		// })
		prettyPrint();
		$('#content').keyup(function() {
			fetchPreview.only_every(on_change_refresh_rate);
			oneshot_preview(fetchPreview, oneshot_pause);
		});

		$('#editForm').submit(function() {
			fetchPreview();
			return false;
		});
	});

// Based on
// http://www.germanforblack.com/javascript-sleeping-keypress-delays-and-bashing-bad-articles
Function.prototype.only_every = function(millisecond_delay) {
	if (!window.only_every_func) {
		var function_object = this;
		window.only_every_func = setTimeout(function() {
			function_object();
			window.only_every_func = null
		}, millisecond_delay);
	}
};

var fetchPreview = function() {
	var content = $('textarea#content').val();
	// Don't submit ajax request if we have trivial content
	if (!content || content.match(/^\s+$/)) {
		return false;
	}

	var ajaxOptions = {
		type : 'POST',
		// url : "http://localhost/cgi-bin/render_page.cgi",
		url : "http://10.0.0.2:5000/page",
		// url : "http://localhost/cgi-bin/hola.cgi/page",
		data : {
			content : content
		},
		success : function(response, status) {
			// alert("Success response status: " + status + " state: " +
		// response.state);
		// console.log("Success response status: " + status + " state: " +
		// response.state);
		$('#preview_area').html(response.rendered_content);
		prettyPrint();
	},
	error : function(XMLHttpRequest, textStatus, errorThrown) {
		alert("Error: " + textStatus + " thrown: " + errorThrown);
	},
	type : 'POST',
	dataType : 'json'
	};

	$.ajax(ajaxOptions);
}

function oneshot() {
	var timer;
	return function(fun, time) {
		clearTimeout(timer);
		timer = setTimeout(fun, time);
	};
}
var oneshot_preview = oneshot();
var oneshot_pause = 1000; // Time in milliseconds.
var on_change_refresh_rate = 10000;
