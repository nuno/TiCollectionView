


$.listView.addEventListener("pull", function(e){
	Ti.API.info(e);
});

$.listView.addEventListener("pullend", function(e){
	Ti.API.info(e);
});

function myRefresher(e) {
	
	Ti.API.info("myRefresher");
	
	// fake a remote fetch
    setTimeout(function(){
    	Ti.API.info("myRefresher callback");
    	e.hide();
    }, 3000);
}

// init
$.ptr.refresh();

$.win.open();