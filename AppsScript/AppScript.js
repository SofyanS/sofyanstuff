function onOpen(e) {
  //Create menu
  SpreadsheetApp.getUi()
      .createAddonMenu()
      .addItem('Create Proposal', 'proposalAutomation')
      .addToUi();
}

function proposalAutomation() {
  //Calculate Discount Pricing
  var sheet = SpreadsheetApp.getActiveSheet();
  var data = sheet.getDataRange().getValues();
  for (var i = 0; i < data.length; i++) {
    Logger.log('Product name: ' + data[i][0]);
    Logger.log('Product number: ' + data[i][1]);
  }
}