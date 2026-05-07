package com.printsdk.usbsdk;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.util.Log;

public class UsbDriver {
    public static final int BAUD9600 = 9600;
    public static final int BAUD19200 = 19200;
    public static final int BAUD38400 = 38400;
    public static final int BAUD57600 = 57600;
    public static final int BAUD115200 = 115200;
    private UsbManager a;
    private PendingIntent b;
    private int[] c = new int[4];
    private UsbDevice[] d = new UsbDevice[2];
    private UsbInterface[] e = new UsbInterface[2];
    private UsbDeviceConnection[] f = new UsbDeviceConnection[2];
    private int g = -1;
    private UsbEndpoint[] h = new UsbEndpoint[2];
    private UsbEndpoint[] i = new UsbEndpoint[2];
    public boolean PID2013 = false;
    public boolean PID2015 = false;
    public boolean PID2017 = false;

    public UsbDriver(UsbManager usbManager, Context context) {
        this.a = usbManager;
        int n = 0;
        while (n < 4) {
            this.c[n] = 8;
            ++n;
        }
    }

    public void setPermissionIntent(PendingIntent pendingIntent) {
        this.b = pendingIntent;
    }

    public boolean usbAttached(Intent intent) {
        UsbDevice device = (UsbDevice)intent.getParcelableExtra("device");
        return this.usbAttached(device);
    }

    public boolean usbAttached(UsbDevice usbDevice) {
        this.g = UsbDriver.a(usbDevice);
        this.d[this.g] = usbDevice;
        if (this.g < 0) {
            Log.i((String)"UsbDriver", (String)("Not support device : " + usbDevice.toString()));
            return false;
        }
        if (this.a.hasPermission(this.d[this.g])) {
            return true;
        }
        this.a.requestPermission(this.d[this.g], this.b);
        return false;
    }

    public boolean openUsbDevice() {
        if (this.g < 0) {
            for (UsbDevice usbDevice : this.a.getDeviceList().values()) {
                Log.i((String)"UsbDriver", (String)("Devices : " + usbDevice.toString()));
                this.g = UsbDriver.a(usbDevice);
                if (this.g < 0) continue;
                this.d[this.g] = usbDevice;
                break;
            }
        }
        if (this.g < 0) {
            return false;
        }
        return this.openUsbDevice(this.d[this.g]);
    }

    public boolean openUsbDevice(UsbDevice usbDevice) {
        this.g = UsbDriver.a(usbDevice);
        if (this.g < 0) {
            return false;
        }
        int n = this.d[this.g].getInterfaceCount();
        Log.i((String)"UsbDriver", (String)(" m_Device[m_UsbDevIdx].getInterfaceCount():" + n));
        if (n == 0) {
            return false;
        }
        if (n > 0) {
            this.e[this.g] = this.d[this.g].getInterface(0);
        }
        if (this.e[this.g].getEndpoint(1) != null) {
            this.i[this.g] = this.e[this.g].getEndpoint(1);
        }
        if (this.e[this.g].getEndpoint(0) != null) {
            this.h[this.g] = this.e[this.g].getEndpoint(0);
        }
        this.f[this.g] = this.a.openDevice(this.d[this.g]);
        if (this.f[this.g] == null) {
            return false;
        }
        if (this.f[this.g].claimInterface(this.e[this.g], true)) {
            return true;
        }
        this.f[this.g].close();
        return false;
    }

    public void closeUsbDevice() {
        if (this.g < 0) {
            return;
        }
        this.closeUsbDevice(this.d[this.g]);
    }

    public boolean closeUsbDevice(UsbDevice usbDevice) {
        block4: {
            this.g = UsbDriver.a(usbDevice);
            if (this.g >= 0) break block4;
            return false;
        }
        try {
            if (this.f[this.g] != null && this.e[this.g] != null) {
                this.f[this.g].releaseInterface(this.e[this.g]);
                this.e[this.g] = null;
                this.f[this.g].close();
                this.f[this.g] = null;
                this.d[this.g] = null;
                this.h[this.g] = null;
                this.i[this.g] = null;
            }
        }
        catch (Exception exception) {
            Log.i((String)"UsbDriver", (String)("closeUsbDevice exception: " + exception.getMessage().toString()));
        }
        return true;
    }

    public boolean usbDetached(Intent intent) {
        UsbDevice device = (UsbDevice)intent.getParcelableExtra("device");
        return this.closeUsbDevice(device);
    }

    public int write(byte[] byArray) {
        return this.write(byArray, byArray.length);
    }

    public int write(byte[] byArray, int n) {
        if (this.g < 0) {
            return -1;
        }
        return this.write(byArray, byArray.length, this.d[this.g]);
    }

    public int read(byte[] byArray, byte[] byArray2) {
        if (this.g < 0) {
            return -1;
        }
        return this.read(byArray, byArray2, this.d[this.g]);
    }

    public int write(byte[] byArray, UsbDevice usbDevice) {
        return this.write(byArray, byArray.length, usbDevice);
    }

    public int write(byte[] byArray, int n, UsbDevice usbDevice) {
        this.g = UsbDriver.a(usbDevice);
        if (this.g < 0) {
            return -1;
        }
        int n2 = 0;
        byte[] byArray2 = new byte[4096];
        while (n2 < n) {
            int n3 = 4096;
            if (n2 + 4096 > n) {
                n3 = n - n2;
            }
            System.arraycopy(byArray, n2, byArray2, 0, n3);
            n3 = this.f[this.g].bulkTransfer(this.h[this.g], byArray2, n3, 3000);
            Log.i((String)"UsbDriver", (String)("-----Length--------" + String.valueOf(n3)));
            if (n3 < 0) {
                return -1;
            }
            n2 += n3;
        }
        return n2;
    }

    public int read(byte[] byArray, byte[] byArray2, UsbDevice usbDevice) {
        if (this.write(byArray2, byArray2.length, usbDevice) < 0) {
            return -1;
        }
        int n = this.f[this.g].bulkTransfer(this.i[this.g], byArray, byArray.length, 100);
        Log.i((String)"UsbDriver", (String)("mFTDIEndpointOUT:" + n));
        return n;
    }

    private static int a(UsbDevice usbDevice) {
        block5: {
            if (usbDevice == null) {
                return -1;
            }
            if (usbDevice.getProductId() != 8211 || usbDevice.getVendorId() != 1305) break block5;
            return 0;
        }
        try {
            if (usbDevice.getProductId() == 8213 && usbDevice.getVendorId() == 1305 || usbDevice.getProductId() == 8215 && usbDevice.getVendorId() == 1305) {
                return 1;
            }
        }
        catch (Exception exception) {
            Log.i((String)"UsbDriver", (String)("getUsbDevIndex exception: " + exception.getMessage().toString()));
        }
        Log.i((String)"UsbDriver", (String)("Not support device : " + usbDevice.toString()));
        return -1;
    }

    public boolean isUsbPermission() {
        boolean bl;
        block4: {
            bl = false;
            try {
                if (this.g >= 0) break block4;
                return false;
            }
            catch (Exception exception) {}
        }
        if (this.a != null) {
            bl = this.a.hasPermission(this.d[this.g]);
        }
        return bl;
    }

    public boolean isConnected() {
        if (this.g < 0) {
            return false;
        }
        return this.d[this.g] != null && this.h[this.g] != null && this.i[this.g] != null;
    }
}
