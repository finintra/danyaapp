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

package com.zebra.android.devdemo.connectivity;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.OnBackPressedDispatcher;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.zebra.android.devdemo.R;
import com.zebra.android.devdemo.util.DemoSleeper;
import com.zebra.android.devdemo.util.SettingsHelper;
import com.zebra.sdk.btleComm.BluetoothLeConnection;
import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.comm.TcpConnection;
import com.zebra.sdk.printer.PrinterLanguage;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.ZebraPrinterLanguageUnknownException;

public class ConnectivityDemo extends AppCompatActivity {

    private Connection printerConnection;
    private RadioButton btRadioButton;
    private RadioButton bleRadioButton;
    private ZebraPrinter printer;
    private TextView statusField;
    private EditText macAddress, ipDNSAddress, portNumber;
    private Button testButton;
    OnBackPressedDispatcher onBackPressedDispatcher = getOnBackPressedDispatcher();
    boolean backPressed = false;
    private boolean jobStarted = false;
    AlertDialog alert;

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.connection_screen_with_status);

        ipDNSAddress = findViewById(R.id.ipAddressInput);
        ipDNSAddress.setText(SettingsHelper.getIp(this));

        portNumber = findViewById(R.id.portInput);
        portNumber.setText(SettingsHelper.getPort(this));

        macAddress = findViewById(R.id.macInput);
        macAddress.setText(SettingsHelper.getBluetoothAddress(this));

        statusField = findViewById(R.id.statusText);
        btRadioButton = findViewById(R.id.bluetoothRadio);
        bleRadioButton = findViewById(R.id.bleRadio);

        testButton = findViewById(R.id.testButton);
        testButton.setOnClickListener(v -> {
            testAction();
        });

        RadioGroup radioGroup = findViewById(R.id.radioGroup);
        radioGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.bluetoothRadio) {
                toggleEditField(macAddress, true);
                toggleEditField(portNumber, false);
                toggleEditField(ipDNSAddress, false);
            } else if (checkedId == R.id.bleRadio){
                toggleEditField(macAddress, true);
                toggleEditField(portNumber, false);
                toggleEditField(ipDNSAddress, false);
            } else {
                toggleEditField(portNumber, true);
                toggleEditField(ipDNSAddress, true);
                toggleEditField(macAddress, false);
            }
        });
        onBackPressedDispatcher.addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                backPressed = true;
                if(jobStarted){
                    showAlert();
                } else {
                    remove();
                    onBackPressedDispatcher.onBackPressed();
                }
            }
        });
    }

    private void showAlert() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setMessage("Please wait, connection is not yet closed...")
                .setCancelable(false); // Prevents dismissing the dialog by clicking outside

        alert = builder.create();
        alert.show();
    }

    private void testAction() {
        new Thread(() -> {
            enableTestButton(false);
            Looper.prepare();
            doConnectionTest();
            Looper.loop();
            Looper.myLooper().quit();
        }).start();
    }

    private void toggleEditField(EditText editText, boolean set) {
        /*
         * Note: Disabled EditText fields may still get focus by some other means, and allow text input.
         *       See http://code.google.com/p/android/issues/detail?id=2771
         */
        editText.setEnabled(set);
        editText.setFocusable(set);
        editText.setFocusableInTouchMode(set);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (printerConnection != null && printerConnection.isConnected()) {
            disconnect();
        }
    }

    private void enableTestButton(final boolean enabled) {
        runOnUiThread(new Runnable() {
            public void run() {
                testButton.setEnabled(enabled);
            }
        });
    }

    private boolean isBluetoothSelected() {
        return btRadioButton.isChecked();
    }

    private boolean isBleSelected() {
        return bleRadioButton.isChecked();
    }

    public ZebraPrinter connect() {
        setStatus("Connecting...", Color.YELLOW);
        printerConnection = null;
        if (isBleSelected()) {
            printerConnection = new BluetoothLeConnection(getMacAddressFieldText(), this);
            SettingsHelper.saveBluetoothAddress(this, getMacAddressFieldText());
        } else if (isBluetoothSelected()) {
            printerConnection = new BluetoothConnection(getMacAddressFieldText());
            SettingsHelper.saveBluetoothAddress(this, getMacAddressFieldText());
        } else {
            try {
                int port = Integer.parseInt(getTcpPortNumber());
                printerConnection = new TcpConnection(getTcpAddress(), port);
                SettingsHelper.saveIp(this, getTcpAddress());
                SettingsHelper.savePort(this, getTcpPortNumber());
            } catch (NumberFormatException e) {
                setStatus("Port Number Is Invalid", Color.RED);
                return null;
            }
        }

        try {
            printerConnection.open();
            setStatus("Connected", Color.GREEN);
        } catch (ConnectionException e) {
            setStatus("Comm Error! Disconnecting", Color.RED);
            DemoSleeper.sleep(1000);
            disconnect();
        }

        ZebraPrinter printer = null;

        if (printerConnection.isConnected()) {
            try {
                printer = ZebraPrinterFactory.getInstance(printerConnection);
                setStatus("Determining Printer Language", Color.YELLOW);
                PrinterLanguage pl = printer.getPrinterControlLanguage();
                setStatus("Printer Language " + pl, Color.BLUE);
            } catch (ConnectionException e) {
                setStatus("Unknown Printer Language", Color.RED);
                printer = null;
                DemoSleeper.sleep(1000);
                disconnect();
            } catch (ZebraPrinterLanguageUnknownException e) {
                setStatus("Unknown Printer Language", Color.RED);
                printer = null;
                DemoSleeper.sleep(1000);
                disconnect();
            }
        }

        return printer;
    }

    public void disconnect() {
        try {
            setStatus("Disconnecting", Color.RED);
            if (printerConnection != null) {
                printerConnection.close();
            }
            setStatus("Not Connected", Color.RED);
        } catch (ConnectionException e) {
            setStatus("COMM Error! Disconnected", Color.RED);
        } finally {
            enableTestButton(true);
            if(backPressed){
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    // Dismiss the dialog when the condition is met
                    alert.dismiss();
                    onBackPressedDispatcher.onBackPressed();
                }, 3000);
            }
            jobStarted = false;
        }
    }

    private void setStatus(final String statusMessage, final int color) {
        runOnUiThread(() -> {
            statusField.setBackgroundColor(color);
            statusField.setText(statusMessage);
        });
        DemoSleeper.sleep(1000);
    }

    private String getMacAddressFieldText() {
        return macAddress.getText().toString();
    }

    private String getTcpAddress() {
        return ipDNSAddress.getText().toString();
    }

    private String getTcpPortNumber() {
        return portNumber.getText().toString();
    }

    private void doConnectionTest() {
        jobStarted = true;
        printer = connect();
        if (printer != null) {
            sendTestLabel();
        } else {
            disconnect();
        }
    }

    private void sendTestLabel() {
        try {
            byte[] configLabel = getConfigLabel();
            printerConnection.write(configLabel);
            setStatus("Sending Data", Color.BLUE);
            DemoSleeper.sleep(1500);
            if (printerConnection instanceof BluetoothConnection) {
                String friendlyName = ((BluetoothConnection) printerConnection).getFriendlyName();
                setStatus(friendlyName, Color.MAGENTA);
                DemoSleeper.sleep(500);
            }
        } catch (ConnectionException e) {
            setStatus(e.getMessage(), Color.RED);
        } finally {
            disconnect();
        }
    }

    /*
     * Returns the command for a test label depending on the printer control language
     * The test label is a box with the word "TEST" inside of it
     *
     * _________________________
     * |                       |
     * |                       |
     * |        TEST           |
     * |                       |
     * |                       |
     * |_______________________|
     *
     *
     */
    private byte[] getConfigLabel() {
        PrinterLanguage printerLanguage = printer.getPrinterControlLanguage();

        byte[] configLabel = null;
        if (printerLanguage == PrinterLanguage.ZPL) {
            configLabel = "^XA^FO17,16^GB379,371,8^FS^FT65,255^A0N,135,134^FDTEST^FS^XZ".getBytes();
        } else if ((printerLanguage == PrinterLanguage.CPCL)||(printerLanguage == PrinterLanguage.LINE_PRINT)) {
            String cpclConfigLabel = "! 0 200 200 406 1\r\n" + "ON-FEED IGNORE\r\n" + "BOX 20 20 380 380 8\r\n" + "T 0 6 137 177 TEST\r\n" + "PRINT\r\n";
            configLabel = cpclConfigLabel.getBytes();
        }
        return configLabel;
    }

}
