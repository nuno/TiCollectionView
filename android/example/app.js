var collectionView = require("de.marcelpociot.collectionview");

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
                color: 'black',
                font: { fontFamily:'Arial', fontSize: '20dp', fontWeight:'bold' },
                left: '60dp', top: 0,
            }
        },
        {                            // Subtitle
            type: 'Ti.UI.Label',     // Use a label for the subtitle
            bindId: 'es_info',       // Maps to a custom es_info property of the item data
            properties: {            // Sets the label properties
                color: 'gray',
                font: { fontFamily:'Arial', fontSize: '14dp' },
                left: '60dp', top: '25dp',
            }
        }
    ]
};

var listView = require("CollectionView").createCollectionView({
    backgroundColor: "white",
    top: 0,
    left: 0,
    width: Ti.UI.FILL,
    height: Ti.UI.FILL,
    // Maps myTemplate dictionary to 'template' string
    templates: { 'template': myTemplate },
    // Use 'template', that is, the myTemplate dict created earlier
    // for all items as long as the template property is not defined for an item.
    defaultItemTemplate: 'template',

    // Context menu options
    showContextMenu : true,
    contextMenuStrokeColor : "red",
    contextMenuItems : [
        {
            tintColor: "red",
            selected: "/images/UploadIconSelected.png",
            unselected:"/images/UploadIcon.png",
        },
        {
            tintColor: "red",
            selected: "/images/TrashIconSelected.png",
            unselected:"/images/TrashIcon.png",
        }
    ],

    // ANDROID ONLY
    columnWidth: 150,
    verticalSpacing: 10,
    horizontalSpacing: 10
});

listView.addEventListener("contextMenuClick", function(e)
{
    alert( "You clicked on menu item " + e.index + " - CollectionView item " + e.itemIndex );
});

var sections = [];

var fruitSection = collectionView.createCollectionSection({ headerTitle: 'Fruits / Frutas'});
var fruitDataSet = [
    // the text property of info maps to the text property of the title label
    // the text property of es_info maps to text property of the subtitle label
    // the image property of pic maps to the image property of the image view
    { info: {text: 'Apple'}, es_info: {text: 'Manzana'}, properties: {height:150,width:150}},
    { info: {text: 'Apple'}, es_info: {text: 'Manzana'}, properties: {height:150,width:150}},
];
fruitSection.setItems(fruitDataSet);
sections.push(fruitSection);

listView.setSections(sections);
win.add(listView);


win.open();