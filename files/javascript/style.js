$(document).ready(function() {    
	// Make pretty buttons - via jQuery UI
	$("input:submit").button();
    $( "#wiki_language" ).buttonset();
    
    // Selectable - via jQuery UI
    $( "#selectable_page_list ul" ).selectable({
		stop: function() {
			var page_ids = [];
			$( ".ui-selected", this ).each(function() {
				page_ids.push($(this).attr('id'));
			});
			var page_ids_string = page_ids.join(',');
			$("#collected_page_ids").attr('value', page_ids_string);
		}
    });
});
