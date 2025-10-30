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
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Build;

import com.zebra.sdk.printer.discovery.UsbDiscoverer;

public abstract class UsbHelper {

	private BroadcastReceiver usbDisconnectReceiver;
	private BroadcastReceiver usbPermissionReceiver;
	private Activity parentActivity;

	public static final String DISCONNECT_INTENT = "com.zebra.kdu.usbDisconnected";
	public static final String USB_PERMISSION_GRANTED_ACTION = "com.zebra.kdu.usbPermissionGranted";

	public UsbHelper(Activity parentActivity) {
		this.parentActivity = parentActivity;
	}

	public void onCreate(Intent intent) {

        UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
		if (device != null && UsbDiscoverer.isZebraUsbDevice(device)) {
			usbConnectedAndPermissionGranted(device);
		}
		usbDisconnectReceiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				final String action = intent.getAction(); 

				if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
					UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
					if (device != null && UsbDiscoverer.isZebraUsbDevice(device)) {
						usbDisconnected(device);
					}
				}
			}
		};
		
		usbPermissionReceiver = new BroadcastReceiver() {
			
			@Override
			public void onReceive(Context context, Intent intent) {
				final String action = intent.getAction(); 

				if (USB_PERMISSION_GRANTED_ACTION.equals(action)) {
					synchronized (this) {
						UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
						boolean permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);
						if (device != null && permissionGranted && UsbDiscoverer.isZebraUsbDevice(device)) {
							usbConnectedAndPermissionGranted(device);
						}
					}
				}				
			}
		};
		
		IntentFilter filter = new IntentFilter();
		filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
		parentActivity.registerReceiver(usbDisconnectReceiver, filter);
		
		filter = new IntentFilter();
		filter.addAction(USB_PERMISSION_GRANTED_ACTION);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			parentActivity.registerReceiver(usbPermissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
		} else{
			parentActivity.registerReceiver(usbPermissionReceiver, filter);
		}
	}
	
	public void onResume() {
		IntentFilter filter = new IntentFilter();
		filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
		parentActivity.registerReceiver(usbDisconnectReceiver, filter);
		
		filter = new IntentFilter();
		filter.addAction(USB_PERMISSION_GRANTED_ACTION);
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			parentActivity.registerReceiver(usbPermissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
		} else{
			parentActivity.registerReceiver(usbPermissionReceiver, filter);
		}
	}
	
	public void onPause() {
		parentActivity.unregisterReceiver(usbDisconnectReceiver);
		parentActivity.unregisterReceiver(usbPermissionReceiver);
	}

	public void onNewIntent(Intent intent) {
        UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
		if (device != null) {
			usbConnectedAndPermissionGranted(device);
		}
	}
	
	public void requestUsbPermission(final UsbManager manager, final UsbDevice device) {
		Intent intent = new Intent(USB_PERMISSION_GRANTED_ACTION);
		intent.setPackage(parentActivity.getPackageName());
		PendingIntent permissionIntent = PendingIntent.getBroadcast(parentActivity, 0, intent, PendingIntent.FLAG_MUTABLE);
		manager.requestPermission(device, permissionIntent);
	}
	
	public abstract void usbConnectedAndPermissionGranted(UsbDevice device) ;
	public abstract void usbDisconnected(UsbDevice device);


	

}
