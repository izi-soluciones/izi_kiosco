package com.izisoluciones.kiosco.izi_kiosco;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Build;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;

import androidx.core.content.ContextCompat;

import com.sunmi.scanner.IScanInterface;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SunmiScannerHelper {
    public static final String TAG = "SunmiScannerHelper";
    public static final String ACTION_DATA_CODE_RECEIVED = "com.sunmi.scanner.ACTION_DATA_CODE_RECEIVED";
    public static final String DATA = "data";
    public static final String SOURCE = "source_byte";
    public static final int MODEL_NONE = 100;

    public interface ScanCallback {
        void onScanSuccess(String code, byte[] source);
        void onScanError(int errorCode, String message);
    }

    private final Context context;
    private IScanInterface scanInterface = null;
    private boolean isBound = false;
    private boolean isReceiverRegistered = false;
    private ScanCallback callback;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    private final BroadcastReceiver scannerReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent == null) return;
            String action = intent.getAction();
            if (ACTION_DATA_CODE_RECEIVED.equals(action)) {
                String code = intent.getStringExtra(DATA);
                byte[] source = intent.getByteArrayExtra(SOURCE);
                Log.d(TAG, "Sunmi Barcode received: " + code);
                if (code != null && !code.isEmpty() && callback != null) {
                    callback.onScanSuccess(code, source);
                }
            }
        }
    };

    private final ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            scanInterface = IScanInterface.Stub.asInterface(service);
            isBound = true;
            Log.i(TAG, "Sunmi Scanner Service Connected successfully!");
            try {
                int model = scanInterface.getScannerModel();
                Log.i(TAG, "Detected Sunmi Scanner Model ID: " + model);
            } catch (Exception e) {
                Log.w(TAG, "Could not query scanner model", e);
            }
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            Log.w(TAG, "Sunmi Scanner Service Disconnected!");
            scanInterface = null;
            isBound = false;
        }
    };

    public SunmiScannerHelper(Context context) {
        this.context = context.getApplicationContext();
    }

    public void setScanCallback(ScanCallback callback) {
        this.callback = callback;
    }

    public static boolean isSunmiDevice() {
        String manufacturer = Build.MANUFACTURER;
        String brand = Build.BRAND;
        return (manufacturer != null && manufacturer.equalsIgnoreCase("SUNMI")) ||
               (brand != null && brand.equalsIgnoreCase("SUNMI"));
    }

    public void init() {
        if (!isSunmiDevice()) {
            Log.d(TAG, "Device is not SUNMI (" + Build.MANUFACTURER + "/" + Build.BRAND + "). Scanner helper idle.");
            return;
        }
        registerReceiver();
        bindService();
    }

    public void registerReceiver() {
        if (isReceiverRegistered) return;
        try {
            IntentFilter filter = new IntentFilter(ACTION_DATA_CODE_RECEIVED);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(scannerReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                context.registerReceiver(scannerReceiver, filter);
            }
            isReceiverRegistered = true;
            Log.d(TAG, "Sunmi broadcast receiver registered.");
        } catch (Exception e) {
            Log.e(TAG, "Error registering Sunmi broadcast receiver", e);
        }
    }

    public void unregisterReceiver() {
        if (!isReceiverRegistered) return;
        try {
            context.unregisterReceiver(scannerReceiver);
            isReceiverRegistered = false;
            Log.d(TAG, "Sunmi broadcast receiver unregistered.");
        } catch (Exception e) {
            Log.e(TAG, "Error unregistering Sunmi broadcast receiver", e);
        }
    }

    public void bindService() {
        if (isBound && scanInterface != null) return;
        try {
            Intent intent = new Intent();
            intent.setPackage("com.sunmi.scanner");
            intent.setAction("com.sunmi.scanner.IScanInterface");
            boolean bound = context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
            Log.d(TAG, "Attempted to bind Sunmi scanner service, bindService returned: " + bound);
        } catch (Exception e) {
            Log.e(TAG, "Error binding Sunmi scanner service", e);
        }
    }

    public void unbindService() {
        if (!isBound) return;
        try {
            context.unbindService(serviceConnection);
            isBound = false;
            scanInterface = null;
            Log.d(TAG, "Sunmi scanner service unbound.");
        } catch (Exception e) {
            Log.e(TAG, "Error unbinding Sunmi scanner service", e);
        }
    }

    public boolean isConnected() {
        return isBound && scanInterface != null;
    }

    public int getScannerModel() {
        if (scanInterface != null) {
            try {
                return scanInterface.getScannerModel();
            } catch (RemoteException e) {
                Log.e(TAG, "Error getting scanner model", e);
            }
        }
        return MODEL_NONE;
    }

    public void startScan() {
        if (!isSunmiDevice()) return;
        executor.execute(() -> {
            try {
                if (scanInterface == null) {
                    bindService();
                    // Wait briefly if binding in progress
                    int retries = 0;
                    while (scanInterface == null && retries < 5) {
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException ignored) {}
                        retries++;
                    }
                }
                if (scanInterface != null) {
                    scanInterface.scan();
                    Log.d(TAG, "Sunmi scan() invoked.");
                } else {
                    Log.w(TAG, "Cannot startScan: scanner service is null.");
                }
            } catch (Exception e) {
                Log.e(TAG, "Exception during startScan()", e);
            }
        });
    }

    public void stopScan() {
        if (!isSunmiDevice()) return;
        executor.execute(() -> {
            try {
                if (scanInterface != null) {
                    scanInterface.stop();
                    Log.d(TAG, "Sunmi stop() invoked.");
                }
            } catch (Exception e) {
                Log.e(TAG, "Exception during stopScan()", e);
            }
        });
    }

    public void destroy() {
        stopScan();
        unregisterReceiver();
        unbindService();
        executor.shutdown();
    }
}
