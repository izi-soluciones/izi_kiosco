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

                    AutoReplyPrint.INSTANCE.CP_Pos_PrintTextInUTF8(h, new WString(text));
                    
                    // Reset styles
                    AutoReplyPrint.INSTANCE.CP_Pos_SetTextScale(h, 0, 0);
                    AutoReplyPrint.INSTANCE.CP_Pos_SetTextBold(h, 0);
                    AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Left);

                } else if ("row".equals(type)) {
                     List<Map<String, Object>> columns = (List<Map<String, Object>>) item.get("cols");
                     int paperWidth = 576; // Assuming 80mm
                     int currentPos = 0;
                     
                     // Reset to start
                     AutoReplyPrint.INSTANCE.CP_Pos_SetHorizontalAbsolutePrintPosition(h, 0);

                     for(Map<String, Object> col : columns) {
                         String text = (String) col.get("text");
                         int widthPercent = (Integer) col.get("width");
                         String align = (String) col.get("align");
                         
                         // Determine start position for this column
                         // Actually, we should set position *before* printing the text?
                         // Or use ColumnMaker style? AutoReplyPrint doesn't seem to have high level column API.
                         // We will just print at absolute positions.
                         
                         int colWidth = (paperWidth * widthPercent) / 100;
                         
                         // Set position. 
                         // Note: If we align RIGHT within the column, we might need to adjust currentPos.
                         // Simple approach: Set pos to `currentPos`, check align? 
                         // AutoReplyPrint alignment is global or paragraph based. 
                         // Setting alignment might cause a newline or not. 
                         // Safe bet: Default LEFT, calculate position manually.
                         
                         AutoReplyPrint.INSTANCE.CP_Pos_SetHorizontalAbsolutePrintPosition(h, currentPos);
                         
                         // If center/right within the column, we'd need to measure text width? 
                         // Too complex for basic implementations without font metrics. 
                         // We will just align LEFT at the column start for now, or trust simple alignment commands if they don't break line.
                         // But changing alignment usually affects the whole line buffer.
                         
                         // Let's just print text at the position.
                         AutoReplyPrint.INSTANCE.CP_Pos_PrintTextInUTF8(h, new WString(text));
                         
                         currentPos += colWidth;
                     }
                     AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(h, 1);
                     
                } else if ("qrcode".equals(type)) {
                    String content = (String) item.get("content");
                    int size = (Integer) item.get("size");
                    AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_HCenter);
                    AutoReplyPrint.INSTANCE.CP_Pos_PrintQRCode(h, 0, AutoReplyPrint.CP_QRCodeECC_L, content);
                    AutoReplyPrint.INSTANCE.CP_Pos_SetAlignment(h, AutoReplyPrint.CP_Pos_Alignment_Left);
                } else if ("cut".equals(type)) {
                    AutoReplyPrint.INSTANCE.CP_Pos_FeedAndHalfCutPaper(h);
                } else if ("line".equals(type)) {
                     boolean dotted = (Boolean) item.get("dotted");
                     if (dotted) {
                        AutoReplyPrint.INSTANCE.CP_Pos_PrintHorizontalLineSpecifyThickness(h, 0, 576, 1); // Dotted not directly supported by command usually, just thin line? 
                        // Or iterate printing dashes?
                        // Let's just print a standard line for now or dashes if requested.
                        AutoReplyPrint.INSTANCE.CP_Pos_PrintTextInUTF8(h, new WString(new String(new char[32]).replace("\0", "- ") + "\r\n"));
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
