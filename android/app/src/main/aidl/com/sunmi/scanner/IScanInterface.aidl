package com.sunmi.scanner;

import android.view.KeyEvent;

interface IScanInterface {
    /**
     * 触发开始与停止扫码
     * key.getAction()==KeyEvent.ACTION_UP 触发开始扫码
     * key.getAction()==KeyEvent.ACTION_DOWN 触发停止扫码
     */
    void sendKeyEvent(in KeyEvent key);
    /**
     * 触发开始扫码
     */
    void scan();
    /**
     * 触发停止扫码
     */
    void stop();
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
    int getScannerModel();
    void setScannerModel(in int Model);
    void sendCommand(in String cmd);
}
