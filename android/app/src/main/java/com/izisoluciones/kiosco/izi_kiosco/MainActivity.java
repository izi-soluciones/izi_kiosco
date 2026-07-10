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

import com.sun.jna.WString;
import android.hardware.usb.UsbManager;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbConstants;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.Context;
import com.printsdk.cmd.PrintCmd;
import com.printsdk.usbsdk.UsbDriver;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.izisoluciones.kiosco/print";

    // Masung/SAT kiosk printer (IP1000 family): VID 0x0519, PIDs 0x2013/0x2015/0x2017
    private static final int SAT_VID = 1305;
    private static final int[] SAT_PIDS = {8211, 8213, 8215};

    // The printer defaults to a Chinese (GBK) text mode. For Spanish receipts we
    // cancel Kanji mode (FS .) and select an ESC/POS Latin codepage (ESC t n),
    // encoding text with the matching Java charset ourselves instead of relying
    // on PrintCmd.PrintString (which mangles accented characters).
    private static final int SAT_CODEPAGE = 16; // ESC t 16 = Windows-1252
    private static final java.nio.charset.Charset SAT_CHARSET =
            java.nio.charset.Charset.forName("windows-1252");

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
                            } else if (call.method.equals("printSat")) {
                                List<Map<String, Object>> items = call.argument("items");
                                if (items != null) {
                                    new Thread(() -> {
                                        boolean success = printWithSat(items);
                                        runOnUiThread(() -> {
                                            if (success) {
                                                result.success(true);
                                            } else {
                                                result.error("PRINT_ERROR", "Failed to print on SAT", null);
                                            }
                                        });
                                    }).start();
                                } else {
                                    result.error("INVALID_ARGUMENT", "Items are null", null);
                                }
                            } else if (call.method.equals("hasSatPrinter")) {
                                // Exact VID/PID match only: used by Dart to auto-route to the SAT
                                // path without a backend flag. Kept strict so kiosks with other
                                // USB printers (e.g. AutoReply/Caysn) are not captured by mistake.
                                result.success(findSatDevice(false) != null);
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

    private boolean isSatVidPid(UsbDevice device) {
        if (device.getVendorId() != SAT_VID) return false;
        for (int pid : SAT_PIDS) {
            if (device.getProductId() == pid) return true;
        }
        return false;
    }

    private UsbDevice findSatDevice(boolean allowGenericPrinterClass) {
        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
        if (usbManager == null) return null;
        for (UsbDevice device : usbManager.getDeviceList().values()) {
            if (isSatVidPid(device)) {
                return device;
            }
        }
        if (allowGenericPrinterClass) {
            for (UsbDevice device : usbManager.getDeviceList().values()) {
                for (int i = 0; i < device.getInterfaceCount(); i++) {
                    if (device.getInterface(i).getInterfaceClass() == UsbConstants.USB_CLASS_PRINTER) {
                        return device;
                    }
                }
            }
        }
        return null;
    }

    // Encode and send text using the Latin codepage selected at print start.
    private void satWriteText(UsbDriver driver, String text, boolean appendNewline) {
        if (text != null && text.length() > 0) {
            driver.write(text.getBytes(SAT_CHARSET));
        }
        if (appendNewline) {
            driver.write(new byte[]{0x0A});
        }
    }

    // Print a bitmap as an ESC/POS raster image (GS v 0). targetWidth is in
    // printer dots (80mm head = 576 dots); the bitmap is scaled proportionally.
    private void satPrintBitmap(UsbDriver driver, android.graphics.Bitmap bitmap, int targetWidth) {
        if (targetWidth < 8) targetWidth = 8;
        if (targetWidth > 576) targetWidth = 576;
        int width = targetWidth & ~7; // multiple of 8
        int height = Math.max(1, bitmap.getHeight() * width / bitmap.getWidth());
        android.graphics.Bitmap scaled = android.graphics.Bitmap.createScaledBitmap(bitmap, width, height, true);

        int bytesPerRow = width / 8;
        byte[] raster = new byte[bytesPerRow * height];
        int[] pixels = new int[width * height];
        scaled.getPixels(pixels, 0, width, 0, 0, width, height);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int p = pixels[y * width + x];
                int alpha = (p >>> 24) & 0xFF;
                int r = (p >> 16) & 0xFF, g = (p >> 8) & 0xFF, b = p & 0xFF;
                int luminance = (r * 299 + g * 587 + b * 114) / 1000;
                boolean black = alpha > 127 && luminance < 128;
                if (black) {
                    raster[y * bytesPerRow + (x >> 3)] |= (byte) (0x80 >> (x & 7));
                }
            }
        }

        byte[] header = new byte[]{
                0x1D, 0x76, 0x30, 0x00,
                (byte) (bytesPerRow & 0xFF), (byte) ((bytesPerRow >> 8) & 0xFF),
                (byte) (height & 0xFF), (byte) ((height >> 8) & 0xFF)
        };
        byte[] payload = new byte[header.length + raster.length];
        System.arraycopy(header, 0, payload, 0, header.length);
        System.arraycopy(raster, 0, payload, header.length, raster.length);
        driver.write(payload);
    }

    private boolean printWithSat(List<Map<String, Object>> items) {
        UsbManager mUsbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
        UsbDriver mUsbDriver = new UsbDriver(mUsbManager, this);
        boolean isConnected = false;
        UsbDevice targetDevice = null;

        try {
            android.util.Log.i("MainActivity", "1. printWithSat started. Beginning device search...");
            targetDevice = findSatDevice(true);

            if (targetDevice == null) {
                android.util.Log.e("MainActivity", "No USB printer found. Aborting print.");
                return false;
            }

            android.util.Log.i("MainActivity", "3. Checking permissions for " + targetDevice.getDeviceName());
            if (!mUsbManager.hasPermission(targetDevice)) {
                android.util.Log.i("MainActivity", "-> Requesting permission explicitly...");
                int flags = PendingIntent.FLAG_UPDATE_CURRENT;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    flags |= PendingIntent.FLAG_IMMUTABLE;
                }
                PendingIntent mPermissionIntent = PendingIntent.getBroadcast(
                    MainActivity.this, 0, new Intent("com.izisoluciones.kiosco.USB_PERMISSION"), flags);
                mUsbManager.requestPermission(targetDevice, mPermissionIntent);
                int times = 0;
                while (!mUsbManager.hasPermission(targetDevice) && times < 4) {
                    times++;
                    android.util.Log.i("MainActivity", "-> Polling permission wait " + times);
                    Thread.sleep(1000);
                }
            }

            if (mUsbManager.hasPermission(targetDevice)) {
                android.util.Log.i("MainActivity", "4. Permission active. Attaching to device driver...");
                if (mUsbDriver.usbAttached(targetDevice)) {
                    android.util.Log.i("MainActivity", "-> Device driver attached successfully. Opening...");
                    if (mUsbDriver.openUsbDevice(targetDevice)) {
                        android.util.Log.i("MainActivity", "-> Device opened and channel secured!");
                        isConnected = true;
                    } else {
                        android.util.Log.e("MainActivity", "-> FAILED to open device connection.");
                    }
                } else {
                    android.util.Log.e("MainActivity", "-> FAILED to attach usb driver.");
                }
            } else {
                android.util.Log.w("MainActivity", "-> Permissions were REJECTED or timeout.");
            }

            if (!isConnected) {
                android.util.Log.e("MainActivity", "5. Print canceled: isConnected unresolved.");
                return false;
            }

            mUsbDriver.write(PrintCmd.SetClean());
            byte[] resetLineSpacing = new byte[]{0x1B, 0x32}; // ESC 2 (Default Line Spacing ~ 30 dots)
            mUsbDriver.write(resetLineSpacing);
            mUsbDriver.write(new byte[]{0x1C, 0x2E}); // FS . : cancel Chinese/Kanji mode
            mUsbDriver.write(new byte[]{0x1B, 0x74, (byte) SAT_CODEPAGE}); // ESC t : Latin codepage
            android.util.Log.d("MainActivity", "-> Payload Size: " + items.size() + " components received from Dart.");

            for (Map<String, Object> item : items) {
                try {
                    String type = (String) item.get("type");
                    android.util.Log.d("MainActivity", "Processing print element type: " + type);

                    if ("text".equals(type)) {
                        String text = (String) item.get("text");
                        String align = (String) item.get("align");
                        boolean bold = (Boolean) item.get("bold");
                        int size = (Integer) item.get("size");

                        if ("center".equals(align)) {
                            mUsbDriver.write(PrintCmd.SetAlignment(1));
                        } else if ("right".equals(align)) {
                            mUsbDriver.write(PrintCmd.SetAlignment(2));
                        } else {
                            mUsbDriver.write(PrintCmd.SetAlignment(0));
                        }

                        mUsbDriver.write(PrintCmd.SetBold(bold ? 1 : 0));
                        int scale = size > 3 ? 1 : 0;
                        mUsbDriver.write(PrintCmd.SetSizetext(scale, scale));

                        satWriteText(mUsbDriver, text, true);

                        mUsbDriver.write(PrintCmd.SetSizetext(0, 0));
                        mUsbDriver.write(PrintCmd.SetBold(0));
                        mUsbDriver.write(PrintCmd.SetAlignment(0));

                    } else if ("row".equals(type)) {
                        List<Map<String, Object>> columns = (List<Map<String, Object>>) item.get("cols");
                        int totalWidthUnits = 0;
                        for (Map<String, Object> col : columns) {
                            totalWidthUnits += (Integer) col.get("width");
                        }
                        if (totalWidthUnits == 0) totalWidthUnits = 1;

                        int charsPerLine = 48;
                        int size = (item.containsKey("size") && item.get("size") != null) ? (Integer) item.get("size") : 0;
                        int scale = size > 3 ? 1 : 0;
                        if (scale == 1) charsPerLine = 24;

                        StringBuilder rowBuilder = new StringBuilder();
                        int remainingChars = charsPerLine;

                        for (int j = 0; j < columns.size(); j++) {
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
                            } else { 
                                paddedText = text + new String(new char[spacesToPad]).replace('\0', ' ');
                            }
                            rowBuilder.append(paddedText);
                        }

                        boolean bold = (item.containsKey("bold") && item.get("bold") != null) ? (Boolean) item.get("bold") : false;
                        mUsbDriver.write(PrintCmd.SetBold(bold ? 1 : 0));
                        mUsbDriver.write(PrintCmd.SetSizetext(scale, scale));
                        satWriteText(mUsbDriver, rowBuilder.toString(), true);

                        mUsbDriver.write(PrintCmd.SetSizetext(0, 0));
                        mUsbDriver.write(PrintCmd.SetBold(0));

                    } else if ("qrcode".equals(type)) {
                        String content = (String) item.get("content");
                        mUsbDriver.write(PrintCmd.SetAlignment(1));
                        mUsbDriver.write(PrintCmd.PrintQrcode(content, 25, 6, 1));
                        mUsbDriver.write(PrintCmd.SetAlignment(0));

                    } else if ("cut".equals(type)) {
                        mUsbDriver.write(PrintCmd.PrintFeedline(7)); // Increased to safely clear mechanical blade
                        mUsbDriver.write(PrintCmd.PrintCutpaper(0));
                        try {
                            Thread.sleep(1500); // Pause bulk transfer to allow hardware mechanical cut
                        } catch (InterruptedException e) {}

                    } else if ("line".equals(type)) {
                        boolean dotted = (Boolean) item.get("dotted");
                        byte[] line = new byte[49];
                        // 0xC4 is the single horizontal box-drawing char in CP437
                        byte lineByte = dotted ? (byte) '-' : (byte) 0xC4;
                        for (int c = 0; c < 48; c++) line[c] = lineByte;
                        line[48] = 0x0A;
                        if (!dotted) mUsbDriver.write(new byte[]{0x1B, 0x74, 0x00}); // ESC t 0: CP437
                        mUsbDriver.write(line);
                        if (!dotted) mUsbDriver.write(new byte[]{0x1B, 0x74, (byte) SAT_CODEPAGE});

                    } else if ("feed".equals(type)) {
                        int lines = (Integer) item.get("lines");
                        mUsbDriver.write(PrintCmd.PrintFeedline(lines));

                    } else if ("image".equals(type)) {
                        byte[] imgData = (byte[]) item.get("data");
                        if (imgData != null) {
                            android.graphics.Bitmap bitmap =
                                    android.graphics.BitmapFactory.decodeByteArray(imgData, 0, imgData.length);
                            if (bitmap != null) {
                                String align = (String) item.get("align");
                                Integer size = (Integer) item.get("size");
                                // Dart sends 'size' as a nominal square dimension (~70 for logos);
                                // map it to printer dots with a 2x factor so logos stay readable.
                                int targetWidth = (size != null && size > 0) ? size * 2 : 240;
                                if ("center".equals(align)) {
                                    mUsbDriver.write(PrintCmd.SetAlignment(1));
                                } else if ("right".equals(align)) {
                                    mUsbDriver.write(PrintCmd.SetAlignment(2));
                                }
                                satPrintBitmap(mUsbDriver, bitmap, targetWidth);
                                mUsbDriver.write(PrintCmd.SetAlignment(0));
                            }
                        }
                    }
                } catch (Throwable innerException) {
                    android.util.Log.e("MainActivity", "Failed to print individual item: " + innerException.getMessage());
                }
            }
            
            mUsbDriver.closeUsbDevice();
            return true;

        } catch (Throwable e) {
            e.printStackTrace();
            if (isConnected) {
                mUsbDriver.closeUsbDevice();
            }
            return false;
        }
    }
}
