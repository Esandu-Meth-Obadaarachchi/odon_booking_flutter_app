import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> generateInvoice({
  required String guestName,
  required String checkIn,
  required String checkOut,
  required int numGuests,
  required String room,
  required String packageDetails,
  required String totalAmount,
  required String standardDiscount,
  required String additionalDiscount,
  required List<ExtraCharge> extraCharges,
  required String finalAmount,
  required String advanceAmount,
  required String balanceAmount,
  required Map<String, Map<String, dynamic>> priceBreakdown,
  String specialNotes = '',
}) async {
  final pdf = pw.Document();

  // Parse dates
  final DateTime checkInDate = DateTime.parse(checkIn);
  final DateTime checkOutDate = DateTime.parse(checkOut);
  final int stayDuration = checkOutDate.difference(checkInDate).inDays;

  // Use default fonts
  final defaultFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();
  final italicFont = pw.Font.helveticaOblique();

  // Format dates for display
  final dateFormat = DateFormat('dd MMM yyyy');
  final formattedCheckIn = dateFormat.format(checkInDate);
  final formattedCheckOut = dateFormat.format(checkOutDate);

  // Generate invoice number
  final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  final currentDate = dateFormat.format(DateTime.now());

  // Create a paid stamp if advance payment was made
  final paidStamp = double.parse(advanceAmount.replaceAll(',', '')) > 0;

  // Calculate total extra charges
  final totalExtraCharges = extraCharges.fold(0.0, (sum, charge) => sum + charge.amount);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "ODON HOTEL",
                      style: pw.TextStyle(font: boldFont, fontSize: 24),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "No.10, Ankara 25, Lollugaswewa, Watawandana Rd, Anuradhapura",
                      style: pw.TextStyle(font: defaultFont, fontSize: 10),
                    ),
                    pw.Text(
                      "Tel: +94 742828422 | Email: hoteltheodon@gmail.com",
                      style: pw.TextStyle(font: defaultFont, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "INVOICE",
                      style: pw.TextStyle(font: boldFont, fontSize: 20),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Invoice #: $invoiceNumber",
                      style: pw.TextStyle(font: defaultFont, fontSize: 10),
                    ),
                    pw.Text(
                      "Date: $currentDate",
                      style: pw.TextStyle(font: defaultFont, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Billing Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "BILL TO:",
                        style: pw.TextStyle(font: boldFont, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        guestName,
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "STAY INFORMATION:",
                        style: pw.TextStyle(font: boldFont, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Check-in: $formattedCheckIn",
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                      pw.Text(
                        "Check-out: $formattedCheckOut",
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                      pw.Text(
                        "Duration: $stayDuration night(s)",
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                      pw.Text(
                        "No. of Guests: $numGuests",
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                      pw.Text(
                        "Room(s): $room",
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                      pw.Text(
                        "Package: $packageDetails",
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Table Header
            pw.Container(
              color: PdfColors.grey300,
              padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      "DESCRIPTION",
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      "UNIT PRICE",
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      "QTY",
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      "NIGHTS",
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      "AMOUNT",
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Table Items - Room and packages
            ...priceBreakdown.entries.map((entry) {
              final String description = entry.key;
              final Map<String, dynamic> details = entry.value;

              return pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        description,
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        "LKR " + NumberFormat('#,##0.00').format(details['unitPrice']),
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        details['quantity'].toString(),
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        details['nights'].toString(),
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        "LKR " + NumberFormat('#,##0.00').format(details['totalPrice']),
                        style: pw.TextStyle(font: defaultFont, fontSize: 12),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Extra charges - Display multiple charges if applicable
            ...extraCharges.where((charge) => charge.reason.isNotEmpty && charge.amount > 0).map((charge) =>
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          "Extra: ${charge.reason}",
                          style: pw.TextStyle(font: defaultFont, fontSize: 12),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "LKR " + NumberFormat('#,##0.00').format(charge.amount),
                          style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          "1",
                          style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          "-",
                          style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "LKR " + NumberFormat('#,##0.00').format(charge.amount),
                          style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )
            ).toList(),

            pw.SizedBox(height: 20),

            // Summary and Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.SizedBox(
                      width: 200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Subtotal:",
                            style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          ),
                          pw.Text(
                            "LKR $totalAmount",
                            style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.SizedBox(
                      width: 200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Standard Discount:",
                            style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          ),
                          pw.Text(
                            "LKR $standardDiscount",
                            style: pw.TextStyle(font: defaultFont, fontSize: 12, color: PdfColors.red),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.SizedBox(
                      width: 200,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Additional Discount:",
                            style: pw.TextStyle(font: defaultFont, fontSize: 12),
                          ),
                          pw.Text(
                            "LKR $additionalDiscount",
                            style: pw.TextStyle(font: defaultFont, fontSize: 12, color: PdfColors.red),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (totalExtraCharges > 0)
                      pw.SizedBox(
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Extra Charges:",
                              style: pw.TextStyle(font: defaultFont, fontSize: 12),
                            ),
                            pw.Text(
                              "LKR " + NumberFormat('#,##0.00').format(totalExtraCharges),
                              style: pw.TextStyle(font: defaultFont, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 200,
                      padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.grey300),
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Total:",
                            style: pw.TextStyle(font: boldFont, fontSize: 14),
                          ),
                          pw.Text(
                            "LKR $finalAmount",
                            style: pw.TextStyle(font: boldFont, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (paidStamp)
                      pw.SizedBox(
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Advance Payment:",
                              style: pw.TextStyle(font: defaultFont, fontSize: 12, color: PdfColors.green),
                            ),
                            pw.Text(
                              "LKR $advanceAmount",
                              style: pw.TextStyle(font: defaultFont, fontSize: 12, color: PdfColors.green),
                            ),
                          ],
                        ),
                      ),
                    pw.SizedBox(height: 5),
                    if (paidStamp)
                      pw.SizedBox(
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Balance Due:",
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                            pw.Text(
                              "LKR $balanceAmount",
                              style: pw.TextStyle(font: boldFont, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Special Notes (if any)
            if (specialNotes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                "Special Notes:",
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  specialNotes,
                  style: pw.TextStyle(font: italicFont, fontSize: 10),
                ),
              ),
            ],

            pw.SizedBox(height: 30),

            // Paid stamp if advance payment was made
            if (paidStamp)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green, width: 2),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      "ADVANCE PAID",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 24,
                        color: PdfColors.green,
                      ),
                    ),
                  ),
                ],
              ),

            pw.Spacer(),

            // Footer
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Payment Methods",
                        style: pw.TextStyle(font: boldFont, fontSize: 10),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "Cash / Bank Transfer / Credit Card",
                        style: pw.TextStyle(font: defaultFont, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Thank You for Choosing Odon Hotel",
                        style: pw.TextStyle(font: boldFont, fontSize: 10),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "We hope to see you again soon!",
                        style: pw.TextStyle(font: italicFont, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Save the PDF to a file
  final output = await getTemporaryDirectory();
  final file = File("${output.path}/invoice_$invoiceNumber.pdf");
  await file.writeAsBytes(await pdf.save());

  // Open the PDF
  final downloads = await getExternalStorageDirectory();
  final downloadFile = File("${downloads!.path}/invoice_$invoiceNumber.pdf");
  await downloadFile.writeAsBytes(await pdf.save());

  await OpenFile.open(file.path);
}

// Class to handle extra charges
class ExtraCharge {
  final String reason;
  final double amount;

  ExtraCharge({required this.reason, required this.amount});
}