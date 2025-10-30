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

package com.zebra.android.devdemo;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;

import androidx.appcompat.app.AppCompatActivity;

public abstract class ConnectionScreenSecondary extends AppCompatActivity {

    protected Button testButton;
    protected Button secondTestButton;
    private RadioButton btRadioButton;
    private EditText macAddress;
    private EditText ipAddress;
    private EditText printingPortNumber;
    protected EditText statusPortNumber;
    protected LinearLayout portLayout;
    protected LinearLayout statusPortLayout;

    public static final String bluetoothAddressKey = "ZEBRA_DEMO_BLUETOOTH_ADDRESS";
    public static final String tcpAddressKey = "ZEBRA_DEMO_TCP_ADDRESS";
    public static final String tcpPortKey = "ZEBRA_DEMO_TCP_PORT";
    public static final String tcpStatusPortKey = "ZEBRA_DEMO_TCP_STATUS_PORT";
    public static final String PREFS_NAME = "OurSavedAddress";

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.connection_screen_secondary);

        SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);

        ipAddress = findViewById(R.id.ipAddressInput);
        String ip = settings.getString(tcpAddressKey, "");
        ipAddress.setText(ip);

        printingPortNumber = findViewById(R.id.portInput);
        String port = settings.getString(tcpPortKey, "");
        printingPortNumber.setText(port);
        toggleEditField(printingPortNumber, shouldAllowPortNumberEditing());

        statusPortNumber = findViewById(R.id.statusPortInput);
        String statusPort = settings.getString(tcpStatusPortKey, "");
        statusPortNumber.setText(statusPort);
        toggleEditField(statusPortNumber, shouldAllowPortNumberEditing());

        portLayout = findViewById(R.id.portLayout);
        statusPortLayout = findViewById(R.id.statusPortLayout);

        macAddress = findViewById(R.id.macInput);
        String mac = settings.getString(bluetoothAddressKey, "");
        macAddress.setText(mac);

        btRadioButton = findViewById(R.id.bluetoothRadio);

        testButton = findViewById(R.id.testButton);
        testButton.setOnClickListener(v -> performTest());

        secondTestButton = findViewById(R.id.secondTestButton);
        secondTestButton.setOnClickListener(v -> performSecondTest());
        secondTestButton.setVisibility(View.INVISIBLE);

        RadioGroup radioGroup = findViewById(R.id.radioGroup);
        radioGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.bluetoothRadio) {
                toggleEditField(macAddress, true);
                toggleEditField(printingPortNumber, false);
                toggleEditField(statusPortNumber, false);
                toggleEditField(ipAddress, false);
                secondTestButton.setVisibility(desiredVisibilityForSecondTestButton());
            } else {
                toggleEditField(printingPortNumber, shouldAllowPortNumberEditing());
                toggleEditField(statusPortNumber, shouldAllowPortNumberEditing());
                toggleEditField(ipAddress, true);
                toggleEditField(macAddress, false);
                secondTestButton.setVisibility(View.INVISIBLE);
            }
        });
    }

    protected int desiredVisibilityForSecondTestButton() {
        return View.INVISIBLE;
    }

    protected boolean shouldAllowPortNumberEditing() {
        return true;
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

    protected boolean isBluetoothSelected() {
        return btRadioButton.isChecked();
    }

    protected String getMacAddressFieldText() {
        return macAddress.getText().toString();
    }

    protected String getTcpAddress() {
        return ipAddress.getText().toString();
    }

    protected String getTcpPortNumber() {
        return printingPortNumber.getText().toString();
    }

    protected String getTcpStatusPortNumber() {
        return statusPortNumber.getText().toString();
    }

    protected void disablePortEditBox() {
        toggleEditField(printingPortNumber, false);
    }

    public abstract void performTest();

    public void performSecondTest() {

    }
}
