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

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.widget.ListView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.zebra.android.devdemo.connectionbuilder.ConnectionBuilderDemo;
import com.zebra.android.devdemo.connectivity.ConnectivityDemo;
import com.zebra.android.devdemo.discovery.DiscoveryDemo;
import com.zebra.android.devdemo.imageprint.ImagePrintDemo;
import com.zebra.android.devdemo.listformats.ListFormatsDemo;
import com.zebra.android.devdemo.magcard.MagCardDemo;
import com.zebra.android.devdemo.multichannel.MultiChannelDemo;
import com.zebra.android.devdemo.receipt.ReceiptDemo;
import com.zebra.android.devdemo.sendfile.SendFileDemo;
import com.zebra.android.devdemo.sigcapture.SigCaptureDemo;
import com.zebra.android.devdemo.smartcard.SmartCardDemo;
import com.zebra.android.devdemo.status.PrintStatusDemo;
import com.zebra.android.devdemo.statuschannel.StatusChannelDemo;
import com.zebra.android.devdemo.storedformat.StoredFormatDemo;

public class LoadDevDemo extends AppCompatActivity {

    private static final int CONNECT_ID = 0;
    private static final int DISCO_ID = 1;
    private static final int IMGPRNT_ID = 2;
    private static final int LSTFORMATS_ID = 3;
    private static final int MAGCARD_ID = 4;
    private static final int PRNTSTATUS_ID = 5;
    private static final int SMRTCARD_ID = 6;
    private static final int SIGCAP_ID = 7;
    private static final int SNDFILE_ID = 8;
    private static final int STRDFRMT_ID = 9;
    private static final int STATUSCHANNEL_ID = 10;
    private static final int CONNECTIONBUILDER_ID = 11;
    private static final int RECEIPT_ID = 12;
    private static final int MULTICHANNEL_ID = 13;

    private int selectedPosition = -1;
    private static final int BLUETOOTH_REQUEST_CODE = 3000;
    private static final int LOCATION_REQUEST_CODE = 4000;

    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        ListView listView = findViewById(R.id.listView);
        listView.setOnItemClickListener((parent, view, position, id) -> {
            selectedPosition = position;
            positionBasedIntent();
        });
    }

    private void positionBasedIntent() {
        if(checkBluetoothPermission()){
            if(enableBluetooth()){
                Intent intent;
                switch (selectedPosition) {
                    case CONNECT_ID:
                        intent = new Intent(this, ConnectivityDemo.class);
                        break;
                    case DISCO_ID:
                        intent = new Intent(this, DiscoveryDemo.class);
                        break;
                    case IMGPRNT_ID:
                        intent = new Intent(this, ImagePrintDemo.class);
                        break;
                    case LSTFORMATS_ID:
                        intent = new Intent(this, ListFormatsDemo.class);
                        break;
                    case MAGCARD_ID:
                        intent = new Intent(this, MagCardDemo.class);
                        break;
                    case PRNTSTATUS_ID:
                        intent = new Intent(this, PrintStatusDemo.class);
                        break;
                    case SMRTCARD_ID:
                        intent = new Intent(this, SmartCardDemo.class);
                        break;
                    case SIGCAP_ID:
                        intent = new Intent(this, SigCaptureDemo.class);
                        break;
                    case SNDFILE_ID:
                        intent = new Intent(this, SendFileDemo.class);
                        break;
                    case STRDFRMT_ID:
                        intent = new Intent(this, StoredFormatDemo.class);
                        break;
                    case STATUSCHANNEL_ID:
                        intent = new Intent(this, StatusChannelDemo.class);
                        break;
                    case CONNECTIONBUILDER_ID:
                        intent = new Intent(this, ConnectionBuilderDemo.class);
                        break;
                    case RECEIPT_ID:
                        intent = new Intent(this, ReceiptDemo.class);
                        break;
                    case MULTICHANNEL_ID:
                        intent = new Intent(this, MultiChannelDemo.class);
                        break;
                    default:
                        return;// not possible
                }
                startActivity(intent);
            }
        }
    }

    private boolean checkBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_DENIED ||
                    ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_DENIED) {
                ActivityCompat.requestPermissions(this, new String[]{android.Manifest.permission.BLUETOOTH_CONNECT, android.Manifest.permission.BLUETOOTH_SCAN}, BLUETOOTH_REQUEST_CODE);
            } else {
                if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION)
                        != PackageManager.PERMISSION_GRANTED ||
                        ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION)
                                != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this,
                            new String[]{android.Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION},
                            LOCATION_REQUEST_CODE);
                } else {
                    return true;
                }
            }
        } else {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED ||
                    ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION)
                            != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                        new String[]{android.Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION},
                        LOCATION_REQUEST_CODE);
            } else {
                return true;
            }
        }
        return false;
    }

    private boolean enableBluetooth() {
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetoothAdapter != null) {
            if (!bluetoothAdapter.isEnabled()) {
                Toast.makeText(this, "Please switch on the bluetooth", Toast.LENGTH_SHORT).show();
            } else {
                return true;
            }
        } else {
            // Device does not support Bluetooth
            Toast.makeText(this, "Bluetooth not supported", Toast.LENGTH_SHORT).show();
        }
        return false;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == BLUETOOTH_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                positionBasedIntent();
            } else {
                // Location permission denied, show a message or handle accordingly
                Toast.makeText(this, "Location permission required for Bluetooth scanning", Toast.LENGTH_SHORT).show();
            }
        } else if (requestCode == LOCATION_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                positionBasedIntent();
            } else {
                // Location permission denied, show a message or handle accordingly
                Toast.makeText(this, "Location permission required for Bluetooth scanning", Toast.LENGTH_SHORT).show();
            }
        }
    }

}
