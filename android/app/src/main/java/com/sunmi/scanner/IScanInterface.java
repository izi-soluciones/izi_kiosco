/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.sunmi.scanner;
// Declare any non-default types here with import statements

public interface IScanInterface extends android.os.IInterface
{
  /** Default implementation for IScanInterface. */
  public static class Default implements com.sunmi.scanner.IScanInterface
  {
    /**
         * 触发开始与停止扫码
         * key.getAction()==KeyEvent.ACTION_UP 触发开始扫码
         * key.getAction()==KeyEvent.ACTION_DWON 触发停止扫码
         */
    @Override public void sendKeyEvent(android.view.KeyEvent key) throws android.os.RemoteException
    {
    }
    /**
         * 触发开始扫码
         */
    @Override public void scan() throws android.os.RemoteException
    {
    }
    /**
         * 触发停止扫码
         */
    @Override public void stop() throws android.os.RemoteException
    {
    }
    /**
         * 获取扫码头类型
         * 100: NONE
         * 101: super_n1365_y1825
         * 102: newland-2096
         * 103: zebra-4710
         * 104: honeywell-3601
         * 105: honeywell-6603
         * 106: zebra-4750
         * 107: zebra-1350
         * 108: honeywell-6703
         * 109: honeywell-3603
         * 110: newland-cm47
         * 111: newland-3108
         * 112: zebra_965
         * 113: sm_ss_1100
         * 114: newland-cm30
         * 115: honeywell-4603
         * 116: zebra_4770
         * 117: newland_2596
         * 118: sm_ss_1103
         * 119: sm_ss_1101
         * 120: honeywell_5703
         * 121: sm_ss_1100_2
         * 122: sm_ss_1104
         */
    @Override public int getScannerModel() throws android.os.RemoteException
    {
      return 0;
    }
    // 内部调用,不暴露给外部使用
    /**
         * 设置扫码头类型（谨慎调用，可能引起扫码服务不可用，若设置错误，在未重启前修改，若已重启，请清除app Cache后重启重新设置）
         * 100: NONE
         * 101: super_n1365_y1825
         * 102: newland-2096
         * 103: zebra-4710
         * 104: honeywell-3601
         * 105: honeywell-6603
         * 106: zebra-4750
         * 107: zebra-1350
         * 108: honeywell-6703
         * 109: honeywell-3603
         * 110: newland-cm47
         * 111: newland-3108
         * 112: zebra_965
         * 113: sm_ss_1100
         * 114: newland-cm30
         * 115: honeywell-4603
         * 116: zebra_4770
         * 117: newland_2596
         * 118: sm_ss_1103
         * 119: sm_ss_1101
         * 120: honeywell_5703
         * 121: sm_ss_1100_2
         * 122: sm_ss_1104
         */
    @Override public void setScannerModel(int Model) throws android.os.RemoteException
    {
    }
    /**
         * 设置命令
         */
    @Override public void sendCommand(java.lang.String cmd) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.sunmi.scanner.IScanInterface
  {
    private static final java.lang.String DESCRIPTOR = "com.sunmi.scanner.IScanInterface";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.sunmi.scanner.IScanInterface interface,
     * generating a proxy if needed.
     */
    public static com.sunmi.scanner.IScanInterface asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.sunmi.scanner.IScanInterface))) {
        return ((com.sunmi.scanner.IScanInterface)iin);
      }
      return new com.sunmi.scanner.IScanInterface.Stub.Proxy(obj);
    }
    @Override public android.os.IBinder asBinder()
    {
      return this;
    }
    @Override public boolean onTransact(int code, android.os.Parcel data, android.os.Parcel reply, int flags) throws android.os.RemoteException
    {
      java.lang.String descriptor = DESCRIPTOR;
      switch (code)
      {
        case INTERFACE_TRANSACTION:
        {
          reply.writeString(descriptor);
          return true;
        }
        case TRANSACTION_sendKeyEvent:
        {
          data.enforceInterface(descriptor);
          android.view.KeyEvent _arg0;
          if ((0!=data.readInt())) {
            _arg0 = android.view.KeyEvent.CREATOR.createFromParcel(data);
          }
          else {
            _arg0 = null;
          }
          this.sendKeyEvent(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_scan:
        {
          data.enforceInterface(descriptor);
          this.scan();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_stop:
        {
          data.enforceInterface(descriptor);
          this.stop();
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_getScannerModel:
        {
          data.enforceInterface(descriptor);
          int _result = this.getScannerModel();
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        case TRANSACTION_setScannerModel:
        {
          data.enforceInterface(descriptor);
          int _arg0;
          _arg0 = data.readInt();
          this.setScannerModel(_arg0);
          reply.writeNoException();
          return true;
        }
        case TRANSACTION_sendCommand:
        {
          data.enforceInterface(descriptor);
          java.lang.String _arg0;
          _arg0 = data.readString();
          this.sendCommand(_arg0);
          reply.writeNoException();
          return true;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
    }
    private static class Proxy implements com.sunmi.scanner.IScanInterface
    {
      private android.os.IBinder mRemote;
      Proxy(android.os.IBinder remote)
      {
        mRemote = remote;
      }
      @Override public android.os.IBinder asBinder()
      {
        return mRemote;
      }
      public java.lang.String getInterfaceDescriptor()
      {
        return DESCRIPTOR;
      }
      /**
           * 触发开始与停止扫码
           * key.getAction()==KeyEvent.ACTION_UP 触发开始扫码
           * key.getAction()==KeyEvent.ACTION_DWON 触发停止扫码
           */
      @Override public void sendKeyEvent(android.view.KeyEvent key) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          if ((key!=null)) {
            _data.writeInt(1);
            key.writeToParcel(_data, 0);
          }
          else {
            _data.writeInt(0);
          }
          boolean _status = mRemote.transact(Stub.TRANSACTION_sendKeyEvent, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().sendKeyEvent(key);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
           * 触发开始扫码
           */
      @Override public void scan() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_scan, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().scan();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
           * 触发停止扫码
           */
      @Override public void stop() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_stop, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().stop();
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
           * 获取扫码头类型
           * 100: NONE
           * 101: super_n1365_y1825
           * 102: newland-2096
           * 103: zebra-4710
           * 104: honeywell-3601
           * 105: honeywell-6603
           * 106: zebra-4750
           * 107: zebra-1350
           * 108: honeywell-6703
           * 109: honeywell-3603
           * 110: newland-cm47
           * 111: newland-3108
           * 112: zebra_965
           * 113: sm_ss_1100
           * 114: newland-cm30
           * 115: honeywell-4603
           * 116: zebra_4770
           * 117: newland_2596
           * 118: sm_ss_1103
           * 119: sm_ss_1101
           * 120: honeywell_5703
           * 121: sm_ss_1100_2
           * 122: sm_ss_1104
           */
      @Override public int getScannerModel() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getScannerModel, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            return getDefaultImpl().getScannerModel();
          }
          _reply.readException();
          _result = _reply.readInt();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      // 内部调用,不暴露给外部使用
      /**
           * 设置扫码头类型（谨慎调用，可能引起扫码服务不可用，若设置错误，在未重启前修改，若已重启，请清除app Cache后重启重新设置）
           * 100: NONE
           * 101: super_n1365_y1825
           * 102: newland-2096
           * 103: zebra-4710
           * 104: honeywell-3601
           * 105: honeywell-6603
           * 106: zebra-4750
           * 107: zebra-1350
           * 108: honeywell-6703
           * 109: honeywell-3603
           * 110: newland-cm47
           * 111: newland-3108
           * 112: zebra_965
           * 113: sm_ss_1100
           * 114: newland-cm30
           * 115: honeywell-4603
           * 116: zebra_4770
           * 117: newland_2596
           * 118: sm_ss_1103
           * 119: sm_ss_1101
           * 120: honeywell_5703
           * 121: sm_ss_1100_2
           * 122: sm_ss_1104
           */
      @Override public void setScannerModel(int Model) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(Model);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setScannerModel, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().setScannerModel(Model);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      /**
           * 设置命令
           */
      @Override public void sendCommand(java.lang.String cmd) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeString(cmd);
          boolean _status = mRemote.transact(Stub.TRANSACTION_sendCommand, _data, _reply, 0);
          if (!_status && getDefaultImpl() != null) {
            getDefaultImpl().sendCommand(cmd);
            return;
          }
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      public static com.sunmi.scanner.IScanInterface sDefaultImpl;
    }
    static final int TRANSACTION_sendKeyEvent = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_scan = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_stop = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_getScannerModel = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_setScannerModel = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_sendCommand = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
    public static boolean setDefaultImpl(com.sunmi.scanner.IScanInterface impl) {
      // Only one user of this interface can use this function
      // at a time. This is a heuristic to detect if two different
      // users in the same process use this function.
      if (Stub.Proxy.sDefaultImpl != null) {
        throw new IllegalStateException("setDefaultImpl() called twice");
      }
      if (impl != null) {
        Stub.Proxy.sDefaultImpl = impl;
        return true;
      }
      return false;
    }
    public static com.sunmi.scanner.IScanInterface getDefaultImpl() {
      return Stub.Proxy.sDefaultImpl;
    }
  }
  /**
       * 触发开始与停止扫码
       * key.getAction()==KeyEvent.ACTION_UP 触发开始扫码
       * key.getAction()==KeyEvent.ACTION_DWON 触发停止扫码
       */
  public void sendKeyEvent(android.view.KeyEvent key) throws android.os.RemoteException;
  /**
       * 触发开始扫码
       */
  public void scan() throws android.os.RemoteException;
  /**
       * 触发停止扫码
       */
  public void stop() throws android.os.RemoteException;
  /**
       * 获取扫码头类型
       * 100: NONE
       * 101: super_n1365_y1825
       * 102: newland-2096
       * 103: zebra-4710
       * 104: honeywell-3601
       * 105: honeywell-6603
       * 106: zebra-4750
       * 107: zebra-1350
       * 108: honeywell-6703
       * 109: honeywell-3603
       * 110: newland-cm47
       * 111: newland-3108
       * 112: zebra_965
       * 113: sm_ss_1100
       * 114: newland-cm30
       * 115: honeywell-4603
       * 116: zebra_4770
       * 117: newland_2596
       * 118: sm_ss_1103
       * 119: sm_ss_1101
       * 120: honeywell_5703
       * 121: sm_ss_1100_2
       * 122: sm_ss_1104
       */
  public int getScannerModel() throws android.os.RemoteException;
  // 内部调用,不暴露给外部使用
  /**
       * 设置扫码头类型（谨慎调用，可能引起扫码服务不可用，若设置错误，在未重启前修改，若已重启，请清除app Cache后重启重新设置）
       * 100: NONE
       * 101: super_n1365_y1825
       * 102: newland-2096
       * 103: zebra-4710
       * 104: honeywell-3601
       * 105: honeywell-6603
       * 106: zebra-4750
       * 107: zebra-1350
       * 108: honeywell-6703
       * 109: honeywell-3603
       * 110: newland-cm47
       * 111: newland-3108
       * 112: zebra_965
       * 113: sm_ss_1100
       * 114: newland-cm30
       * 115: honeywell-4603
       * 116: zebra_4770
       * 117: newland_2596
       * 118: sm_ss_1103
       * 119: sm_ss_1101
       * 120: honeywell_5703
       * 121: sm_ss_1100_2
       * 122: sm_ss_1104
       */
  public void setScannerModel(int Model) throws android.os.RemoteException;
  /**
       * 设置命令
       */
  public void sendCommand(java.lang.String cmd) throws android.os.RemoteException;
}
