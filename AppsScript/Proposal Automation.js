function onOpen(e) {
  //Create menu
  SpreadsheetApp.getUi()
      .createAddonMenu()
      .addItem('Create Proposal', 'proposalAutomation')
      .addToUi();
}

function proposalAutomation() {
  //Template Variables
  DOC_TEMPLATE_ID = "1QwXNuKA9oGWwDRnAt5TPEzFJ6kfkGPL2PKr1bq5Pi2E";
  FOLDER_ID = "1nLGDlJDfNtJd7r-B-vKfAUvPKOyux7NT";

  //Calculate Discount Pricing
  var sheet = SpreadsheetApp.getActiveSheet();
  var data = sheet.getDataRange().offset(1,0,26).getValues();
  for (var i = 0; i < data.length; i++) {
    custName = data[i][0];
    custEmail = data[i][1];
    plan = data[i][2];
    numSeats = data[i][3];
    discount = data[i][4];
    if (plan == "G Suite Basic"){
      grossAmt = numSeats * 6;
    }
    else if(plan == "G Suite Business"){
      grossAmt = numSeats * 12;
    }
    else if(plan == "G Suite Enterprise"){
      grossAmt = numSeats * 25;
    }
    netAmt = grossAmt * (1-discount);
    discountAmt = grossAmt - netAmt;
    sheet.getRange(2+i, 6).setValue(grossAmt);
    sheet.getRange(2+i, 7).setValue(netAmt);
    
    // Copy File
    var copyFile = DriveApp.getFileById(DOC_TEMPLATE_ID).makeCopy(),
      copyId = copyFile.getId(),
      copyDoc = DocumentApp.openById(copyId),
      body = copyDoc.getActiveSection();
    
    // Write to Google Doc
    body.replaceText('{Enter Customer Name}', custName);
    body.replaceText('{enter today’s date}', Utilities.formatDate(new Date(), "GMT+1", "MM/dd/yyyy"));
    body.replaceText('{enter G Suite plan}', plan);
    body.replaceText('{enter seats count}', numSeats);
    body.replaceText('{enter customer name}', custEmail);
    body.replaceText('{plan cost}', plan);
    body.replaceText('{enter total amount}', grossAmt);
    body.replaceText('{enter discount percentage}', discount);
    body.replaceText('{enter discount amount}', discountAmt);
    body.replaceText('{enter net amount}', netAmt);

    // Make PDF
    copyDoc.saveAndClose();
    var pdfFile = DriveApp.createFile(copyFile.getAs('application/pdf'))
    DriveApp.getFolderById(FOLDER_ID).addFile(pdfFile);
    pdfFile.setName("G Suite Proposal for " + custName);
    sheet.getRange(2+i, 8).setValue("Proposal Created Successfully");
    sheet.getRange(2+i, 8).setValue(pdfFile.getUrl());
    copyFile.setTrashed(true);
    
    // Create Gmail Draft
    GmailApp.createDraft(custEmail, "Quote for " + custName, 'Please see attached file for your GSuite Quote', {
    attachments: [pdfFile],
    name: 'Automatic Emailer Script'
    }); 
  }
}