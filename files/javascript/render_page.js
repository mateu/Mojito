// A central place to store variables
var mojito = {};
	
$(document).ready(function() {
	// $('#content').each(function() {
	// this.focus();
	// })
	prettyPrint();
	$('#content').keyup(function() {
		fetchPreview.only_every(on_change_refresh_rate);
		oneshot_preview(fetchPreview, oneshot_pause);
	});
	$('#submit_create').click(function() {
		// if no content : no submit
		return got_content();
	});
	$('#submit_save').click(function() {
		fetchPreview('save');
		return false;
	});
	$('#page_delete').click(function() {
		alert("Are you sure?");
		return false;
	});
});

function got_content() {
	var content = $('textarea#content').val();
	if (!content || content.match(/^\s+$/)) {
		return false;
	}
	else {
		return true;
	}
}

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

var fetchPreview = function(extra_action) {
	var content = $('textarea#content').val();
	var mongo_id = $('#mongo_id').val();
	data = { 
			 content: content,
			 mongo_id: mongo_id,
			 extra_action: extra_action
		   };
	// Don't submit ajax request if we have trivial content
	if (!content || content.match(/^\s+$/)) {
		return false;
	}

	var ajaxOptions = {
		type : 'POST',
		url  : mojito.preview_url,
		data : data,
		success : function(response, status) {
			$('#view_area').html(response.rendered_content);
			prettyPrint();
	    },
		error : function(XMLHttpRequest, textStatus, errorThrown) {
			alert("Error: " + textStatus + " thrown: " + errorThrown); 
		},
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
