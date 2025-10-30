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

package com.zebra.android.devdemo.status;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.OnBackPressedDispatcher;
import androidx.appcompat.app.AppCompatActivity;

import com.zebra.android.devdemo.ConnectionScreenPrimary;
import com.zebra.android.devdemo.R;
import com.zebra.android.devdemo.util.DemoSleeper;
import com.zebra.android.devdemo.util.SettingsHelper;
import com.zebra.android.devdemo.util.UIHelper;
import com.zebra.sdk.btleComm.BluetoothLeConnection;
import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.comm.TcpConnection;
import com.zebra.sdk.printer.PrinterStatus;
import com.zebra.sdk.printer.PrinterStatusMessages;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.ZebraPrinterLanguageUnknownException;
import com.zebra.sdk.printer.ZebraPrinterLinkOs;

public class PrinterStatusScreen extends AppCompatActivity {

    private boolean bluetoothSelected;
    private boolean bleSelected;
    private String macAddress;
    private String tcpAddress;
    private String tcpPort;
    private Connection Connection;
    private ZebraPrinter printer;
    private ArrayAdapter<String> statusListAdapter;
    private List<String> statusMessageList = new ArrayList<String>();
    private UIHelper helper = new UIHelper(this);
    private boolean activityIsActive;
    private Handler statusHandler;
    private Runnable statusRunnable;
    OnBackPressedDispatcher onBackPressedDispatcher = getOnBackPressedDispatcher();
    boolean backPressed = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        activityIsActive = true;
        setContentView(R.layout.print_status_activity);
        Bundle b = getIntent().getExtras();
        bluetoothSelected = b.getBoolean("bluetooth selected");
        bleSelected = b.getBoolean("ble selected");
        macAddress = b.getString("mac address");
        tcpAddress = b.getString("tcp address");
        tcpPort = b.getString("tcp port");
        statusListAdapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, statusMessageList);
        ListView statusList = findViewById(R.id.statusList);
        statusList.setAdapter(statusListAdapter);
        new Thread(() -> {
            saveSettings();
            Looper.prepare();
            pollForStatus();
            Looper.myLooper().quit();
        }).start();

        onBackPressedDispatcher.addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                // Set the backPressed flag to stop status polling
                backPressed = true;

                // Remove any pending callbacks for status polling
                if (statusHandler != null && statusRunnable != null) {
                    statusHandler.removeCallbacks(statusRunnable);
                }

                if (Connection != null && Connection.isConnected()) {
                    helper.showLoadingDialog("Closing ...");

                    // Use a background thread to close the connection
                    new Thread(() -> {
                        try {
                            if (Connection != null) {
                                Connection.close();
                            }
                        } catch (ConnectionException e) {
                            e.printStackTrace();
                        }

                        runOnUiThread(() -> {
                            new Handler().postDelayed(() -> {
                                helper.dismissLoadingDialog();
                                remove();
                                onBackPressedDispatcher.onBackPressed();
                            }, 2000);
                        });
                    }).start();
                } else {
                    remove();
                    onBackPressedDispatcher.onBackPressed();
                }
            }
        });
    }

    @Override
    protected void onPause() {
        super.onPause();
        activityIsActive = false;
        if (Connection != null && Connection.isConnected()) {
            disconnect();
        }
        if (helper.isDialogActive()) {
            helper.dismissLoadingDialog();
        }
    }

    public ZebraPrinter connect() {
        helper.showLoadingDialog("Updating Status...");

        if (bluetoothSelected || bleSelected) {
            pairBT();
        } else {
            connectToTcp();
        }

        ZebraPrinter printer = null;

        if (Connection != null && Connection.isConnected()) {
            try {
                printer = ZebraPrinterFactory.getInstance(Connection);
                printer.getPrinterControlLanguage();
            } catch (ConnectionException e) {
                displayConnectionError(e.getMessage());
                printer = null;
                disconnect();
            } catch (ZebraPrinterLanguageUnknownException e) {
                displayConnectionError(e.getMessage());
                printer = null;
                disconnect();
            }
        }
        helper.dismissLoadingDialog(2000);
        return printer;
    }

    public void disconnect() {
        try {
            if (Connection != null) {
                Connection.close();
            }
        } catch (ConnectionException e) {
        }
    }

    private void pairBT() {
        try {
            if(bleSelected){
                Connection = new BluetoothLeConnection(macAddress, this);
            } else {
                Connection = new BluetoothConnection(macAddress);
            }
            Connection.open();
            setStoredString(ConnectionScreenPrimary.bluetoothAddressKey, macAddress);
        } catch (ConnectionException e) {
            displayConnectionError(e.getMessage());
            disconnect();
        }
    }

    private void connectToTcp() {
        if (Connection != null && Connection.isConnected() == true) {
            return;
        }
        tryTcpConnect();
    }

    private void tryTcpConnect() {
        try {
            Connection = new TcpConnection(tcpAddress, Integer.parseInt(tcpPort));
            Connection.open();
            setStoredString(ConnectionScreenPrimary.tcpAddressKey, tcpAddress);
            setStoredString(ConnectionScreenPrimary.tcpPortKey, tcpPort);
        } catch (ConnectionException e) {
            displayConnectionError(e.getMessage());
            disconnect();
        } catch (NumberFormatException e) {
            displayConnectionError("Invalid port number");
        }
    }

    private void displayConnectionError(final String message) {
        if (activityIsActive == true) {
            runOnUiThread(new Runnable() {
                public void run() {
                    new AlertDialog.Builder(PrinterStatusScreen.this).setMessage(message).setTitle("Error").setPositiveButton("OK", new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int which) {
                            finish();
                        }
                    }).create().show();
                }
            });
        }
    }

    private void pollForStatus() {
        printer = connect();  // Attempt to connect to the printer

        // Initialize the Handler
        statusHandler = new Handler(Looper.getMainLooper());

        // Create a Runnable to update printer status periodically
        statusRunnable = new Runnable() {
            @Override
            public void run() {
                if (!backPressed && Connection != null && Connection.isConnected()) {
                    try {
                        updatePrinterStatus();
                    } catch (ConnectionException e) {
                        displayConnectionError(e.getMessage());
                        e.printStackTrace();
                    }
                    // Schedule the next status update after 3 seconds
                    statusHandler.postDelayed(this, 3000);
                }
            }
        };

        // Start the first status update
        statusHandler.post(statusRunnable);
    }
    
    private void updatePrinterStatus() throws ConnectionException {
        new Thread(() -> {
            try{
                if (Connection != null && Connection.isConnected()) {

                    ZebraPrinterLinkOs linkOsPrinter = ZebraPrinterFactory.createLinkOsPrinter(printer);

                    PrinterStatus printerStatus = (linkOsPrinter != null) ? linkOsPrinter.getCurrentStatus() : printer.getCurrentStatus();

                    final String[] printerStatusString = new PrinterStatusMessages(printerStatus).getStatusMessage();
                    final String[] printerStatusPrefix = getPrinterStatusPrefix(printerStatus);
                    runOnUiThread(() -> {
                        statusListAdapter.clear();
                        statusMessageList.clear();
                        statusMessageList.addAll(Arrays.asList(printerStatusPrefix));
                        statusMessageList.addAll(Arrays.asList(printerStatusString));
                        statusListAdapter.notifyDataSetChanged();
                    });
                } else {
                    displayConnectionError("No printer connection");
                }
            } catch (ConnectionException e) {
                displayConnectionError(e.getMessage());
                disconnect();
            }
        }).start();  // Start background thread
    }

    private void setStoredString(String key, String value) {
        SharedPreferences settings = getSharedPreferences(ConnectionScreenPrimary.PREFS_NAME, 0);
        SharedPreferences.Editor editor = settings.edit();
        editor.putString(key, value);
        editor.commit();
    }

    private String[] getPrinterStatusPrefix(PrinterStatus printerStatus) {
        boolean ready = printerStatus != null ? printerStatus.isReadyToPrint : false;
        String readyString = "Printer " + (ready ? "ready" : "not ready");
        String labelsInBatch = "Labels in batch: " + String.valueOf(printerStatus.labelsRemainingInBatch);
        String labelsInRecvBuffer = "Labels in buffer: " + String.valueOf(printerStatus.numberOfFormatsInReceiveBuffer);
        return new String[] { readyString, labelsInBatch, labelsInRecvBuffer };
    }

    private void saveSettings() {
        SettingsHelper.saveBluetoothAddress(PrinterStatusScreen.this, macAddress);
        SettingsHelper.saveIp(PrinterStatusScreen.this, tcpAddress);
        SettingsHelper.savePort(PrinterStatusScreen.this, tcpPort);
    }

}
