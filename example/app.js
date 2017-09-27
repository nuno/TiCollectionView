var TiCollectionView = require('ti.collectionview');

var win = Ti.UI.createWindow({
	backgroundColor: 'white'
});

// Create a custom template that displays an image on the left, 
// then a title next to it with a subtitle below it.
var myTemplate = {
    childTemplates: [
        {                            // Title 
            type: 'Ti.UI.Label',     // Use a label for the title 
            bindId: 'info',          // Maps to a custom info property of the item data
            properties: {            // Sets the label properties
                font: { fontSize: 20, fontWeight:'bold' },
                top: 10,
            }
        }, {                            // Subtitle
            type: 'Ti.UI.Label',     // Use a label for the subtitle
            bindId: 'es_info',       // Maps to a custom es_info property of the item data
            properties: {            // Sets the label properties
                color: 'gray',
                font: { fontSize: 14 },
                top: 40,
            }
        }
    ]
};

var collectionView = TiCollectionView.createCollectionView({
    backgroundColor: 'white',
    // Maps myTemplate dictionary to 'template' string
    templates: { 'template': myTemplate },
    // Use 'template', that is, the myTemplate dict created earlier
    // for all items as long as the template property is not defined for an item.
    defaultItemTemplate: 'template',

    // ANDROID ONLY
    columnWidth: 150,
    verticalSpacing: 10,
    horizontalSpacing: 10
});

collectionView.addEventListener('itemclick', function(e) {
    alert('Tapped cell at section = ' + e.sectionIndex + ', item = ' + e.itemIndex);
});

var sections = [];

var fruitSection = TiCollectionView.createCollectionSection({ headerTitle: 'Fruits / Frutas' });
var fruitDataSet = [
    // the text property of info maps to the text property of the title label
    // the text property of es_info maps to text property of the subtitle label
    // the image property of pic maps to the image property of the image view
    { info: { text: 'Apple 1' }, es_info: { text: 'Manzana 1' }, properties: { height: 150, width: 150 } },
    { info: { text: 'Apple 2' }, es_info: { text: 'Manzana 2' }, properties: { height: 150, width: 150 } },
    { info: { text: 'Apple 3' }, es_info: { text: 'Manzana 3' }, properties: { height: 150, width: 150 } },
    { info: { text: 'Apple 4' }, es_info: { text: 'Manzana 4' }, properties: { height: 150, width: 150 } },
    { info: { text: 'Apple 5' }, es_info: { text: 'Manzana 5' }, properties: { height: 150, width: 150 } },
    { info: { text: 'Apple 6' }, es_info: { text: 'Manzana 6' }, properties: { height: 150, width: 150 } },
];

fruitSection.setItems(fruitDataSet);
sections.push(fruitSection);

collectionView.setSections(sections);

win.add(collectionView);
win.open();
