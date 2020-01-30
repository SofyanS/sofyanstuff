function onOpen(e) {
  //Create menu
  SpreadsheetApp.getUi()
      .createAddonMenu()
      .addSubMenu(SpreadsheetApp.getUi().createMenu('Proposal Automation')
                  .addItem('Create Proposal', 'proposalAutomation'))
      .addToUi();
}

function proposalAutomation() {
   
}

function logProductInfo() {
  var sheet = SpreadsheetApp.getActiveSheet();
  var data = sheet.getDataRange().getValues();
  for (var i = 0; i < data.length; i++) {
    Logger.log('Product name: ' + data[i][0]);
    Logger.log('Product number: ' + data[i][1]);
  }
}