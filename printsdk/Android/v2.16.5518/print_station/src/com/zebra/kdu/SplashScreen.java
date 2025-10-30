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
package com.zebra.kdu;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.view.ContextThemeWrapper;
import android.view.KeyEvent;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.multidex.BuildConfig;

import com.zebra.kdu.util.UIHelper;

@RequiresApi(api = Build.VERSION_CODES.TIRAMISU)
public class SplashScreen extends Activity {
    public static final int MULTIPLE_PERMISSION = 1001;
    private static final int splashTime = 2000;
    private final String[] permissionList = new String[]{
            Manifest.permission.CAMERA,
            Manifest.permission.BLUETOOTH_SCAN,
            android.Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.WRITE_EXTERNAL_STORAGE};
    private final String[] permissionList_33 = new String[]{
            Manifest.permission.CAMERA,
            Manifest.permission.BLUETOOTH_SCAN,
            android.Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION,
    };
    private UIHelper uiHelper;

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        boolean bluetoothPermission = false;
        boolean locationPermission = false;
        boolean storagePermission = false;
        if (requestCode == MULTIPLE_PERMISSION) {
            for (String p : permissions) {
                switch (p) {
                    case Manifest.permission.BLUETOOTH_SCAN:
                        bluetoothPermission = this.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED;
                        break;
                    case Manifest.permission.ACCESS_FINE_LOCATION:
                        locationPermission = this.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED;
                        break;
                    case Manifest.permission.WRITE_EXTERNAL_STORAGE:
                        storagePermission = this.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED;
                        break;
                    default:
                        break;
                }
            }
            if ((Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !bluetoothPermission) || !locationPermission || (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU && !storagePermission)) {
                showDialogToGrantPermissionFromSettings(getString(R.string.permission_required_title), getString(R.string.bluetooth_permission_required_message));
            } else {
                navigateToChooseFormatScreen();
            }
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.splash_screen);
        if (Permissions.hasPermissions(this, Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ? permissionList_33 : permissionList)) {
            navigateToChooseFormatScreen();
        } else {
            requestPermission();
        }
    }

    private void requestPermission() {
        ActivityCompat.requestPermissions(this,  Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ? permissionList_33 : permissionList, MULTIPLE_PERMISSION);
    }

    void navigateToChooseFormatScreen() {
        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {
                try {
                    Thread.sleep(splashTime);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                return null;
            }

            protected void onPostExecute(Void result) {
                Intent i = new Intent(SplashScreen.this, ChooseFormatScreen.class);
                startActivity(i);
                overridePendingTransition(android.R.anim.fade_in, R.anim.slide_out_left);
                finish();
            }
        }.execute((Void) null);
    }

    public void showDialogToGrantPermissionFromSettings(String title, String messsage) {
        runOnUiThread(() -> {
            new AlertDialog.Builder(new ContextThemeWrapper(SplashScreen.this, R.style.AppStyleDialog))
                    .setMessage(messsage).setTitle(title)
                    .setCancelable(true)
                    .setOnCancelListener(dialog -> navigateToChooseFormatScreen())
                    .setPositiveButton("Open Settings", (dialog, which) -> {

                        Intent intent = new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:" + BuildConfig.APPLICATION_ID));
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                        startActivity(intent);
                    })
                    .setNegativeButton("Cancel", (dialog, which) -> navigateToChooseFormatScreen())
                    .create()
                    .show();
        });
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        navigateToChooseFormatScreen();
    }
}