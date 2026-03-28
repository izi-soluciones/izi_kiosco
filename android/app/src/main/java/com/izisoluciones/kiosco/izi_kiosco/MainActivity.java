package com.izisoluciones.kiosco.izi_kiosco;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.List;
import java.util.Map;
import com.caysn.autoreplyprint.AutoReplyPrint;
import com.sun.jna.Pointer;
import com.sun.jna.WString;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.izisoluciones.kiosco/print";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("print")) {
                                List<Map<String, Object>> items = call.argument("items");
                                if (items != null) {
                                    new Thread(() -> {
                                        boolean success = printWithAutoReply(items);
                                        runOnUiThread(() -> {
                                            if (success) {
                                                result.success(true);
                                            } else {
                                                result.error("PRINT_ERROR", "Failed to print", null);
                                            }
                                        });
                                    }).start();
                                } else {
                                    result.error("INVALID_ARGUMENT", "Items are null", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private boolean printWithAutoReply(List<Map<String, Object>> items) {
        Pointer h = Pointer.NULL;
        try {
            // 1. Enumerate and Open USB Port (Simplistic approach: Try first found)
            String[] usbPaths = AutoReplyPrint.CP_Port_EnumUsb_Helper.EnumUsb();
            if (usbPaths == null || usbPaths.length == 0) {
                System.out.println("No USB printers found.");
                return false;
            }

            String targetPort = usbPaths[0]; // Take the first one
            h = AutoReplyPrint.INSTANCE.CP_Port_OpenUsb(targetPort, 1);

            if (h == Pointer.NULL) {
                 System.out.println("Failed to open port: " + targetPort);
                 return false;
            }

            // 2. Initialize
            AutoReplyPrint.INSTANCE.CP_Pos_ResetPrinter(h);
            AutoReplyPrint.INSTANCE.CP_Pos_SetMultiByteMode(h);
            AutoReplyPrint.INSTANCE.CP_Pos_SetMultiByteEncoding(h, AutoReplyPrint.CP_MultiByteEncoding_UTF8);
            
            // 3. Process Items
            for (Map<String, Object> item : items) {
                String type = (String) item.get("type");
                if ("text".equals(type)) {
                    String text = (String) item.get("text");
                    String align = (String) item.get("align");
                    boolean bold = (Boolean) item.get("bold");
                    int size = (Integer) item.get("size"); // mapped to font size enum/int

                    // Alignment
                    if ("center".equals(align)) {
                        AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_HCenter);
                    } else if ("right".equals(align)) {
                        AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Right);
                    } else {
                        AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Left);
                    }

                    // Bold
                    AutoReplyPrint.INSTANCE.CP_Pos_SetTextBold(h, bold ? 1 : 0);

                    // Size (Simplification, mapped from 0-5 roughly)
                    // AutoReplyPrint has SetTextScale(h, w, h)
                    int scale = size > 3 ? 1 : 0; // rough mapping
                    AutoReplyPrint.INSTANCE.CP_Pos_SetTextScale(h, scale, scale);

                    // Handle newlines manually. CP_Pos_PrintTextInUTF8 does not auto-feed.
                    // We split by newline and ensure a FeedLine occurs after each segment.
                    // This solves two problems:
                    // 1. Internal \n in string are respected.
                    // 2. The Text item itself acts as a block element (ending with a newline).
                    String[] lines = text.split("\n", -1);
                    for (String line : lines) {
                         if (line.length() > 0) {
                             AutoReplyPrint.INSTANCE.CP_Pos_PrintTextInUTF8(h, new WString(line));
                         }
                         // Always feed after a line segment to advance paper
                         AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(h, 1);
                    }
                    
                    // Reset styles
                    AutoReplyPrint.INSTANCE.CP_Pos_SetTextScale(h, 0, 0);
                    AutoReplyPrint.INSTANCE.CP_Pos_SetTextBold(h, 0);
                    AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Left);

                } else if ("row".equals(type)) {
                     List<Map<String, Object>> columns = (List<Map<String, Object>>) item.get("cols");
                     
                     int totalWidthUnits = 0;
                     for(Map<String, Object> col : columns) {
                         totalWidthUnits += (Integer) col.get("width");
                     }
                     if (totalWidthUnits == 0) totalWidthUnits = 1;

                     int charsPerLine = 48; // Standard Font A on 80mm
                     int size = (item.containsKey("size") && item.get("size") != null) ? (Integer) item.get("size") : 0;
                     int scale = size > 3 ? 1 : 0;
                     if (scale == 1) charsPerLine = 24;
                     
                     StringBuilder rowBuilder = new StringBuilder();
                     int remainingChars = charsPerLine;

                     for(int j = 0; j < columns.size(); j++) {
                         Map<String, Object> col = columns.get(j);
                         String text = (String) col.get("text");
                         if (text == null) text = "";
                         int widthUnit = (Integer) col.get("width");
                         String align = (String) col.get("align");
                         
                         int colChars;
                         if (j == columns.size() - 1) {
                             colChars = remainingChars; 
                             if (colChars < 0) colChars = 0;
                         } else {
                             colChars = (charsPerLine * widthUnit) / totalWidthUnits; 
                             remainingChars -= colChars;
                         }
                         
                         if (text.length() > colChars && colChars > 0) {
                             text = text.substring(0, colChars);
                         }
                         
                         int spacesToPad = colChars - text.length();
                         if (spacesToPad < 0) spacesToPad = 0;
                         
                         String paddedText;
                         if ("center".equals(align)) {
                             int leftPad = spacesToPad / 2;
                             int rightPad = spacesToPad - leftPad;
                             paddedText = new String(new char[leftPad]).replace('\0', ' ') + text + new String(new char[rightPad]).replace('\0', ' ');
                         } else if ("right".equals(align)) {
                             paddedText = new String(new char[spacesToPad]).replace('\0', ' ') + text;
                         } else { // default left
                             paddedText = text + new String(new char[spacesToPad]).replace('\0', ' ');
                         }
                         rowBuilder.append(paddedText);
                     }
                     
                     boolean bold = (item.containsKey("bold") && item.get("bold") != null) ? (Boolean) item.get("bold") : false;
                     AutoReplyPrint.INSTANCE.CP_Pos_SetTextBold(h, bold ? 1 : 0);
                     AutoReplyPrint.INSTANCE.CP_Pos_SetTextScale(h, scale, scale);
                     
                     AutoReplyPrint.INSTANCE.CP_Pos_PrintTextInUTF8(h, new WString(rowBuilder.toString()));
                     AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(h, 1);
                     
                     // Reset styles
                     AutoReplyPrint.INSTANCE.CP_Pos_SetTextScale(h, 0, 0);
                     AutoReplyPrint.INSTANCE.CP_Pos_SetTextBold(h, 0);
                     
                } else if ("qrcode".equals(type)) {
                    String content = (String) item.get("content");
                    int size = (Integer) item.get("size");
                    AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_HCenter);
                    AutoReplyPrint.INSTANCE.CP_Pos_PrintQRCode(h, 0, AutoReplyPrint.CP_QRCodeECC_L, content);
                    AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Left);
                } else if ("cut".equals(type)) {
                    // Explicitly feed lines before cutting. 
                    // Some printers ignore cut commands if the paper hasn't advanced past the print head.
                    AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(h, 4);
                    AutoReplyPrint.INSTANCE.CP_Pos_FeedAndHalfCutPaper(h);
                } else if ("line".equals(type)) {
                     boolean dotted = (Boolean) item.get("dotted");
                     if (dotted) {
                        // Use a thin line for "dotted" request, as not all printers support native dotted lines via this API
                        AutoReplyPrint.INSTANCE.CP_Pos_PrintHorizontalLineSpecifyThickness(h, 0, 576, 1);
                     } else {
                        AutoReplyPrint.INSTANCE.CP_Pos_PrintHorizontalLine(h, 0, 576);
                     }
                } else if ("feed".equals(type)) {
                     int lines = (Integer) item.get("lines");
                     AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(h, lines);
                } else if ("image".equals(type)) {
                     byte[] imgData = (byte[]) item.get("data"); 
                     if (imgData != null) {
                        android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeByteArray(imgData, 0, imgData.length);
                         if (bitmap != null) {
                            int size = (Integer) item.get("size"); // maybe scale?
                            AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_HCenter);
                             AutoReplyPrint.CP_Pos_PrintRasterImageFromData_Helper.PrintRasterImageFromBitmap(
                                 h, 
                                 bitmap.getWidth(), 
                                 bitmap.getHeight(), 
                                 bitmap, 
                                 AutoReplyPrint.CP_ImageBinarizationMethod_Thresholding, 
                                 AutoReplyPrint.CP_ImageCompressionMethod_None
                             );
                             AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Left);
                         }
                     }
                }
            }
            
            // Finalize
            // AutoReplyPrint.INSTANCE.CP_Pos_FeedAndHalfCutPaper(h); // Already in items?
            
            AutoReplyPrint.INSTANCE.CP_Port_Close(h);
            return true;

        } catch (Throwable e) {
            e.printStackTrace();
            if (h != Pointer.NULL) {
                AutoReplyPrint.INSTANCE.CP_Port_Close(h);
            }
            return false;
        }
    }
}
