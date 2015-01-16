function createCollectionView(options) {
	if( OS_IOS )
	{
		return require("de.marcelpociot.collectionview").createCollectionView(options);
	}
	var templates = options.templates;
	for (var binding in templates) {
		var currentTemplate = templates[binding];
		//process template
		processTemplate(currentTemplate);
		//process child templates
		processChildTemplates(currentTemplate);
	}
	Ti.API.info( JSON.stringify(options) );
	var listView = require("de.marcelpociot.collectionview").createCollectionView(options);
	
	return listView;
}

//Create ListItemProxy, add events, then store it in 'tiProxy' property
function processTemplate(properties) {
   	var cellProxy = require("de.marcelpociot.collectionview").createCollectionItem();
	properties.tiProxy = cellProxy;
	var events = properties.events;
	addEventListeners(events, cellProxy);
}

//Recursive function that process childTemplates and append corresponding proxies to
//property 'tiProxy'. I.e: type: "Titanium.UI.Label" -> tiProxy: LabelProxy object
function processChildTemplates(properties) {
	if (!properties.hasOwnProperty('childTemplates')) return;
	
	var childProperties = properties.childTemplates;
	if (childProperties === void 0 || childProperties === null) return;
	
	for (var i = 0; i < childProperties.length; i++) {
		var child = childProperties[i];
		var proxyType = child.type;
		if (proxyType !== void 0) {
			var creationProperties = child.properties;
			var creationFunction = lookup(proxyType);
			var childProxy;
			//create the proxy
			if (creationProperties !== void 0) {
				childProxy = creationFunction(creationProperties);
			} else {
				childProxy = creationFunction();
			}
			//add event listeners
			var events = child.events;
			addEventListeners(events, childProxy);
			//append proxy to tiProxy property
			child.tiProxy = childProxy;
		}

		processChildTemplates(child);
		
	}
	
	
}

//add event listeners
function addEventListeners(events, proxy) {
	if (events !== void 0) {
		for (var eventName in events) {
			proxy.addEventListener(eventName, events[eventName]);
		}
	}
}

//convert name of UI elements into a constructor function.
//I.e: lookup("Titanium.UI.Label") returns Titanium.UI.createLabel function
function lookup(name) {
	var lastDotIndex = name.lastIndexOf('.');
	var proxy = eval(name.substring(0, lastDotIndex));
	if (typeof(proxy) == undefined) return;

	var proxyName = name.slice(lastDotIndex + 1);
	return proxy['create' + proxyName];
}

exports.createCollectionView = createCollectionView;