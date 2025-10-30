/***********************************************
 * CONFIDENTIAL AND PROPRIETARY
 *
 * The source code and other information contained herein is the confidential and the exclusive property of
 * ZIH Corp. and is subject to the terms and conditions in your end user license agreement.
 * This source code, and any other information contained herein, shall not be copied, reproduced, published,
 * displayed or distributed, in whole or in part, in any medium, by any means, for any purpose except as
 * expressly permitted under such license agreement.
 *
 * Copyright ZIH Corp. 2012
 *
 * ALL RIGHTS RESERVED
 ***********************************************/

package com.zebra.android.devdemo.statuschannel;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import com.zebra.android.devdemo.R;
import com.zebra.android.devdemo.util.SettingsHelper;
import com.zebra.android.devdemo.util.UIHelper;
import com.zebra.sdk.btleComm.BluetoothLeStatusConnection;
import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.BluetoothStatusConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.comm.TcpStatusConnection;
import com.zebra.sdk.printer.LinkOsInformation;
import com.zebra.sdk.printer.PrinterLanguage;
import com.zebra.sdk.printer.PrinterStatus;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.settings.SettingsRanges;
import com.zebra.sdk.util.internal.Sleeper;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import androidx.appcompat.app.AppCompatActivity;

public class StatusChannelScreen extends AppCompatActivity {
    private boolean bluetoothSelected;
    private boolean bleSelected;
    private String macAddress;
    private String tcpAddress;
    private String tcpStatusPort;
    private UIHelper helper = new UIHelper(this);
    private ArrayAdapter<String> statusListAdapter;
    private List<String> statusMessageList = new ArrayList<String>();
    private static final List<String> settingNames = Arrays.asList("media.type", "media.speed", "device.languages", "ezpl.media_type", "zpl.label_length", "ezpl.print_width", "zpl.print_orientation", "media.sense_mode", "ezpl.print_method", "media.printmode", "ezpl.head_close_action", "ezpl.power_up_action", "device.printhead.resolution", "print.tone_zpl");

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.status_channel_activity);
        Bundle b = getIntent().getExtras();
        bluetoothSelected = b.getBoolean("bluetooth selected");
        bleSelected = b.getBoolean("ble selected");
        macAddress = b.getString("mac address");
        tcpAddress = b.getString("tcp address");
        tcpStatusPort = b.getString("tcp status port");
        statusListAdapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, statusMessageList);
        ListView statusList = findViewById(R.id.statusListView);
        statusList.setAdapter(statusListAdapter);
        new Thread(() -> {
            saveSettings();
            if (bleSelected) {
                helper.showLoadingDialog("Getting settings over status channel");
                getBleStatus();
            } else {
                helper.showLoadingDialog("Getting printer status");
                getStatus();
            }
        }).start();

    }

    private void getStatus() {
        Connection connection = null;
        Connection connectionRaw = null;
        try {

            if (bluetoothSelected) {
                // Printer only broadcasts the status connection if a valid raw connection is open
                connectionRaw = new BluetoothConnection(macAddress);
                connection = new BluetoothStatusConnection(macAddress);

                connectionRaw.open();
                Sleeper.sleep(3000); // give the printer some time to start the status connection
            } else {
                connection = new TcpStatusConnection(tcpAddress, Integer.parseInt(tcpStatusPort));
            }

            connection.open();
            ZebraPrinter printer = ZebraPrinterFactory.getLinkOsPrinter(connection);

            final PrinterStatus myPrinterStatus = printer.getCurrentStatus();

            runOnUiThread(() -> {
                statusListAdapter.clear();
                statusMessageList.clear();
                statusMessageList.add("Is Printer Ready: " + myPrinterStatus.isReadyToPrint);
                statusMessageList.add("Is Head Open: " + myPrinterStatus.isHeadOpen);
                statusMessageList.add("Is Paper Out: " + myPrinterStatus.isPaperOut);
                statusMessageList.add("Is Printer Paused: " + myPrinterStatus.isPaused);
                statusMessageList.add("Batch Labels Remaining: " + myPrinterStatus.labelsRemainingInBatch);
                statusListAdapter.notifyDataSetChanged();
                helper.dismissLoadingDialog(1000);
            });
        } catch (Exception e) {
            helper.dismissLoadingDialog(500);
            helper.showErrorDialogOnGuiThread(e.getMessage());
        } finally {
            try {
                if (connection != null) {
                    connection.close();
                }
                if (connectionRaw != null) {
                    connectionRaw.close();
                }
            } catch (ConnectionException e) {
                helper.showErrorDialogOnGuiThread(e.getMessage());
            }
        }
    }

    private void getBleStatus() {
        Connection connection = new BluetoothLeStatusConnection(macAddress, this);
        try {
            connection.open();

            final Map<String, String> rangeMap = SettingsRanges.getRanges(settingNames, connection, PrinterLanguage.ZPL, new LinkOsInformation(3, 2));

            runOnUiThread(() -> {
                statusListAdapter.clear();
                statusMessageList.clear();
                if (!rangeMap.isEmpty()) {
                    for (String rangeKey : rangeMap.keySet()) {
                        statusMessageList.add(rangeKey + " range: " + (rangeMap.get(rangeKey)).replaceAll(",", ", "));
                    }
                } else {
                    statusMessageList.add("Response from requesting ranges did not return any data.");
                }
                helper.dismissLoadingDialog();
                statusListAdapter.notifyDataSetChanged();
            });

        } catch (Exception e) {
            helper.dismissLoadingDialog();
            helper.showErrorDialogOnGuiThread(e.getMessage());
        } finally {
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (ConnectionException e) {
                helper.showErrorDialogOnGuiThread(e.getMessage());
            }
        }
    }

    private void saveSettings() {
        SettingsHelper.saveBluetoothAddress(StatusChannelScreen.this, macAddress);
        SettingsHelper.saveIp(StatusChannelScreen.this, tcpAddress);
        SettingsHelper.saveStatusPort(StatusChannelScreen.this, tcpStatusPort);
    }

}
