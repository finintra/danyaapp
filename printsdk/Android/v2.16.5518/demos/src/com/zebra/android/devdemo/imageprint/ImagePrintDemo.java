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

package com.zebra.android.devdemo.imageprint;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.provider.MediaStore.Images.Media;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;

import com.zebra.android.devdemo.R;
import com.zebra.android.devdemo.util.SettingsHelper;
import com.zebra.android.devdemo.util.UIHelper;
import com.zebra.sdk.btleComm.BluetoothLeConnection;
import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.comm.TcpConnection;
import com.zebra.sdk.device.ZebraIllegalArgumentException;
import com.zebra.sdk.graphics.internal.ZebraImageAndroid;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.ZebraPrinterLanguageUnknownException;

import java.io.File;
import java.io.IOException;

public class ImagePrintDemo extends AppCompatActivity {

    private RadioButton btRadioButton;
    private RadioButton bleRadioButton;
    private EditText macAddressEditText;
    private EditText ipAddressEditText;
    private EditText portNumberEditText;
    private EditText printStoragePath;
    private static final String bluetoothAddressKey = "ZEBRA_DEMO_BLUETOOTH_ADDRESS";
    private static final String tcpAddressKey = "ZEBRA_DEMO_TCP_ADDRESS";
    private static final String tcpPortKey = "ZEBRA_DEMO_TCP_PORT";
    private static final String PREFS_NAME = "OurSavedAddress";
    private UIHelper helper = new UIHelper(this);
    private static int TAKE_PICTURE = 1;
    private static int PICTURE_FROM_GALLERY = 2;
    private static File file = null;
    private static final int REQUEST_CAMERA_PERMISSION = 200;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.image_print_demo);
        SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);

        ipAddressEditText = this.findViewById(R.id.ipAddressInput);
        String ip = settings.getString(tcpAddressKey, "");
        ipAddressEditText.setText(ip);

        portNumberEditText = this.findViewById(R.id.portInput);
        String port = settings.getString(tcpPortKey, "");
        portNumberEditText.setText(port);

        macAddressEditText = this.findViewById(R.id.macInput);
        String mac = settings.getString(bluetoothAddressKey, "");
        macAddressEditText.setText(mac);

        printStoragePath = findViewById(R.id.printerStorePath);

        CheckBox cb = findViewById(R.id.checkBox);
        cb.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                printStoragePath.setVisibility(View.VISIBLE);
            } else {
                printStoragePath.setVisibility(View.INVISIBLE);
            }
        });

        btRadioButton = this.findViewById(R.id.bluetoothRadio);
        bleRadioButton = findViewById(R.id.bleRadio);

        Button cameraButton = this.findViewById(R.id.testButton);
        cameraButton.setOnClickListener(v -> getPhotoFromCamera());

        Button galleryButton = this.findViewById(R.id.galleryButton);
        galleryButton.setOnClickListener(v -> getPhotosFromGallery());

        RadioGroup radioGroup = this.findViewById(R.id.radioGroup);
        radioGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.bluetoothRadio) {
                toggleEditField(macAddressEditText, true);
                toggleEditField(portNumberEditText, false);
                toggleEditField(ipAddressEditText, false);
            } else if (checkedId == R.id.bleRadio){
                toggleEditField(macAddressEditText, true);
                toggleEditField(portNumberEditText, false);
                toggleEditField(ipAddressEditText, false);
            } else {
                toggleEditField(portNumberEditText, true);
                toggleEditField(ipAddressEditText, true);
                toggleEditField(macAddressEditText, false);
            }
        });
    }

    private void getPhotosFromGallery() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(intent, PICTURE_FROM_GALLERY);
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

    private boolean isBluetoothSelected() {
        return btRadioButton.isChecked();
    }

    private String getMacAddressFieldText() {
        return macAddressEditText.getText().toString();
    }

    private String getTcpAddress() {
        return ipAddressEditText.getText().toString();
    }

    private String getTcpPortNumber() {
        return portNumberEditText.getText().toString();
    }

    private boolean isBleSelected() {
        return bleRadioButton.isChecked();
    }

    private void getPhotoFromCamera() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            // Request camera and storage permissions
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE}, REQUEST_CAMERA_PERMISSION);
        } else {
            // Permissions already granted, proceed to open camera
            openCamera();
        }
    }

    private void openCamera() {
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        file = new File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "tempPic.jpg");
        Uri photoURI = FileProvider.getUriForFile(this, getApplicationContext().getPackageName() + ".fileprovider", file);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION); // Grant URI permission
        startActivityForResult(intent, TAKE_PICTURE);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permissions granted, proceed to open camera
                openCamera();
            } else {
                // Permissions denied, show a message to the user
                Toast.makeText(this, "Camera permission required to proceed", Toast.LENGTH_SHORT).show();
            }
        }
    }

    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == Activity.RESULT_OK) {
            if (requestCode == TAKE_PICTURE) {
                printPhotoFromExternal(BitmapFactory.decodeFile(file.getAbsolutePath()));
            }
            if (requestCode == PICTURE_FROM_GALLERY) {
                Uri imgPath = data.getData();
                Bitmap myBitmap = null;
                try {
                    myBitmap = Media.getBitmap(getContentResolver(), imgPath);
                } catch (IOException e) {
                    helper.showErrorDialog(e.getMessage());
                }
                printPhotoFromExternal(myBitmap);
            }
        }
    }

    private void printPhotoFromExternal(final Bitmap bitmap) {
        helper.showLoadingDialog("Sending image to printer");
        new Thread(() -> {
            try {
                getAndSaveSettings();

                Looper.prepare();
                Connection connection = getZebraPrinterConn();
                connection.open();
                ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);

                if (((CheckBox) findViewById(R.id.checkBox)).isChecked()) {
                    printer.storeImage(printStoragePath.getText().toString(), new ZebraImageAndroid(bitmap), 550, 412);
                } else {
                    printer.printImage(new ZebraImageAndroid(bitmap), 0, 0, 550, 412, false);
                }

                connection.close();
                if (file != null) {
                    file.delete();
                    file = null;
                }
            } catch (ConnectionException | ZebraPrinterLanguageUnknownException |
                     ZebraIllegalArgumentException e) {
                helper.showErrorDialogOnGuiThread(e.getMessage());
            } finally {
                bitmap.recycle();
                helper.dismissLoadingDialog(2000);
                Looper.myLooper().quit();
            }
        }).start();
    }

    private Connection getZebraPrinterConn() {
        String macAddress = getMacAddressFieldText();
        int portNumber = parseTcpPortNumber();

        if (isBleSelected()) {
            return new BluetoothLeConnection(macAddress,this);
        } else if (isBluetoothSelected()) {
            return new BluetoothConnection(macAddress);
        } else {
            return new TcpConnection(getTcpAddress(), portNumber);
        }
    }

    private int parseTcpPortNumber() {
        try {
            return Integer.parseInt(getTcpPortNumber());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private void getAndSaveSettings() {
        SettingsHelper.saveBluetoothAddress(ImagePrintDemo.this, getMacAddressFieldText());
        SettingsHelper.saveIp(ImagePrintDemo.this, getTcpAddress());
        SettingsHelper.savePort(ImagePrintDemo.this, getTcpPortNumber());
    }

}
