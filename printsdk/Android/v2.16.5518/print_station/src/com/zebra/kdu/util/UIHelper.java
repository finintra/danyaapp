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
package com.zebra.kdu.util;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;

import androidx.multidex.BuildConfig;


public class UIHelper {
    ProgressDialog loadingDialog;
    Activity activity;

    AlertDialog dialog;

    public UIHelper(Activity activity) {
        this.activity = activity;
    }

    public void showLoadingDialog(final String message) {
        if (activity != null && activity instanceof FinishInfo && ((FinishInfo) activity).isFinished() == true) {
            return;
        }
        if (activity != null) {
            activity.runOnUiThread(() -> loadingDialog = ProgressDialog.show(activity, "", message, true, false));
        }
    }

    public void updateLoadingDialog(final String message) {
        if (activity != null && activity instanceof FinishInfo && ((FinishInfo) activity).isFinished() == true) {
            return;
        }
        if (activity != null) {
            activity.runOnUiThread(() -> loadingDialog.setMessage(message));
        }
    }

    public boolean isDialogActive() {
        if (activity != null && activity instanceof FinishInfo && ((FinishInfo) activity).isFinished() == true) {
            return false;
        }
        if (loadingDialog != null) {
            return loadingDialog.isShowing();
        } else {
            return false;
        }
    }

    public void dismissLoadingDialog() {
        if (loadingDialog != null && loadingDialog.isShowing()) {
            loadingDialog.dismiss();
        }
    }

    public void dismissLoadingDialog(Dialog loadingDialog) {
        try{
            if (loadingDialog != null && loadingDialog.isShowing()) {
                loadingDialog.dismiss();
            }
        } catch (Exception e){

        }
    }

    public void showErrorDialog(String errorMessage) {
        if (activity != null && activity instanceof FinishInfo && ((FinishInfo) activity).isFinished() == true) {
            return;
        }
        new AlertDialog.Builder(activity).setMessage(errorMessage).setTitle("Error").setPositiveButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int id) {
                dialog.dismiss();
            }
        }).create().show();
    }

    public void showDialogToGrantPermissionFromSettings(String title, String messsage) {
        if (activity != null && activity instanceof FinishInfo && ((FinishInfo) activity).isFinished() ) {
            return;
        }
        new AlertDialog.Builder(activity).setMessage(messsage)
                .setTitle(title)
                .setPositiveButton("Open Settings", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        activity.startActivity(new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:" + BuildConfig.APPLICATION_ID)));
                    }
                }).
                setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.dismiss();
                    }
                }).create().show();
    }


    public void showErrorDialogOnGuiThread(final String errorMessage) {
        if (activity != null && activity instanceof FinishInfo && ((FinishInfo) activity).isFinished() == true) {
            return;
        }
        if (activity != null) {
            activity.runOnUiThread(new Runnable() {
                public void run() {
                    new AlertDialog.Builder(activity).setMessage(errorMessage).setTitle("Error").setPositiveButton("OK", new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int id) {
                            dialog.dismiss();
                            dismissLoadingDialog();
                        }
                    }).create().show();
                }
            });
        }
    }

}
