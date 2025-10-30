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
import android.app.Dialog;
import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.Configuration;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.nfc.NdefMessage;
import android.nfc.NfcAdapter;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Parcelable;
import android.view.ContextMenu;
import android.view.ContextMenu.ContextMenuInfo;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.BaseAdapter;
import android.widget.ImageButton;
import android.widget.ListView;
import android.widget.SimpleAdapter;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.zebra.kdu.chooseprinter.DiscoveredPrinterListAdapter;
import com.zebra.kdu.util.FinishInfo;
import com.zebra.kdu.util.FormatRefresher;
import com.zebra.kdu.util.SavedFormatProvider;
import com.zebra.kdu.util.SelectedPrinterManager;
import com.zebra.kdu.util.UIHelper;
import com.zebra.kdu.util.UsbHelper;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.ZebraPrinterLanguageUnknownException;
import com.zebra.sdk.printer.discovery.BluetoothDiscoverer;
import com.zebra.sdk.printer.discovery.DiscoveredPrinter;
import com.zebra.sdk.printer.discovery.DiscoveredPrinterBluetooth;
import com.zebra.sdk.printer.discovery.DiscoveredPrinterNetwork;
import com.zebra.sdk.printer.discovery.DiscoveredPrinterUsb;
import com.zebra.sdk.printer.discovery.DiscoveryException;
import com.zebra.sdk.printer.discovery.DiscoveryHandler;
import com.zebra.sdk.printer.discovery.NetworkDiscoverer;
import com.zebra.sdk.printer.discovery.UrlPrinterDiscoverer;
import com.zebra.sdk.printer.discovery.UsbDiscoverer;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ChooseFormatScreen extends ListActivity implements FinishInfo {
    public static final String APP_PREFERENCES_KEY = "PrintStationPreferences";
    public static final int DIALOG_DISCOVERY = 0;
    public static final int DIALOG_ABOUT = 1;
    public static final int DIALOG_PEMISSION_ERROR = 2;
    public static final int MULTIPLE_PERMISSION = 1004;
    private final String[] permissionList = new String[]{
            Manifest.permission.BLUETOOTH_SCAN,
            android.Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION};


    private Dialog dialog;
    public static final int REQUEST_ENABLE_BT = 0;
    private final List<Map<String, String>> formatsList = new ArrayList<Map<String, String>>();
    private final UIHelper uiHelper = new UIHelper(this);
    private final List<Map<String, String>> storedPrintersList = new ArrayList<Map<String, String>>();
    String[] attributeKeys = new String[]{"drive_letter", "format_name", "extension", "source_image", "format_details"};
    int[] attributeIds = new int[]{R.id.formatDrive, R.id.formatFilename, R.id.formatExtension, R.id.formatSourceImage, R.id.formatDetails};
    String[] storedPrinterAttributeKeys = new String[]{"printer_name", "printer_address"};
    int[] storedPrinterAttributeIds = new int[]{R.id.storedPrinterName, R.id.storedPrinterAddress};
    private BaseAdapter statusListAdapter;
    private BaseAdapter spinnerAdapter;
    private final UsbHelper usbHelper = new UsbHelper(this) {

        @Override
        public void usbDisconnected(UsbDevice device) {
            uiHelper.dismissLoadingDialog();
            removeDisconnectedUsbPrinterFromHistory(device);
        }

        private void removeDisconnectedUsbPrinterFromHistory(UsbDevice device) {
            DiscoveredPrinter[] printers = SelectedPrinterManager.getPrinterHistory();
            for (int i = 0; i < printers.length; i++) {
                DiscoveredPrinter printer = printers[i];
                if (isPrinterToRemove(device, printer)) {
                    SelectedPrinterManager.removeHistoryItemAtIndex(i);
                    spinnerAdapter.notifyDataSetChanged();

                    if (SelectedPrinterManager.getSelectedPrinter() == null) {
                        showDialog(DIALOG_DISCOVERY);
                    } else {
                        if (i == 0) {
                            uiHelper.dismissLoadingDialog();
                            FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
                        }
                    }
                    return;
                }
            }
        }

        private boolean isPrinterToRemove(UsbDevice device, DiscoveredPrinter printer) {
            if (printer instanceof DiscoveredPrinterUsb) {
                DiscoveredPrinterUsb usbPrinter = (DiscoveredPrinterUsb) printer;
                return device.getDeviceName().equals(usbPrinter.device.getDeviceName());
            }
            return false;
        }

        @Override
        public void usbConnectedAndPermissionGranted(UsbDevice device) {
            UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            SelectedPrinterManager.setSelectedPrinter(new DiscoveredPrinterUsb(device.getDeviceName(), usbManager, device));
            if (spinnerAdapter != null) {
                spinnerAdapter.notifyDataSetChanged();
            }
            uiHelper.dismissLoadingDialog(dialog);
            FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
        }
    };
    private DiscoveredPrinterListAdapter discoveredPrinterListAdapter;
    private DiscoveredPrinter formatPrinter;
    private volatile boolean usbDiscoveryComplete = false;
    private volatile boolean bluetoothDiscoveryComplete = false;
    private volatile boolean networkDiscoveryComplete = false;
    private volatile boolean isFinished = false;

    String payload;
    boolean isPermissionRequested = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.stored_format_screen);
        statusListAdapter = new SimpleAdapter(this, formatsList, R.layout.format_list_item, attributeKeys, attributeIds);

        ListView listView = findViewById(android.R.id.list);
        listView.setDividerHeight(3);
        findViewById(R.id.emptyFormat).setVisibility(View.INVISIBLE);
        listView.setEmptyView(findViewById(R.id.emptyFormat));
        ImageButton refreshButton = findViewById(R.id.refreshFormatsButton);
        refreshButton.setOnClickListener(v -> FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter));

        registerForContextMenu(listView);

        setListAdapter(statusListAdapter);

        SelectedPrinterManager.populatePrinterHistoryFromPreferences(this);

        usbHelper.onCreate(getIntent());

        DiscoveredPrinter selectedPrinter = SelectedPrinterManager.getSelectedPrinter();
        boolean isNFC = getIntent() != null && NfcAdapter.ACTION_NDEF_DISCOVERED.equals(getIntent().getAction());
        if (selectedPrinter != null && selectedPrinter instanceof DiscoveredPrinterUsb == false && !isNFC) {
            FormatRefresher.execute(this, uiHelper, attributeKeys, formatsList, statusListAdapter);
        }
    }

    @Override
    public void onCreateContextMenu(ContextMenu menu, View v, ContextMenuInfo info) {
        super.onCreateContextMenu(menu, v, info);
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.format_menu, menu);

        Map<String, String> selectedFormat = formatsList.get(((AdapterContextMenuInfo) info).position);
        String formatSource = selectedFormat.get(FormatRefresher.FORMAT_SOURCE_KEY);

        menu.findItem(R.id.menu_save).setVisible(formatSource.equals(FormatRefresher.FORMAT_SOURCE_PRINTER));
        menu.findItem(R.id.menu_delete).setVisible(formatSource.equals(FormatRefresher.FORMAT_SOURCE_DATABASE));
    }

    @Override
    public boolean onContextItemSelected(MenuItem item) {
        AdapterContextMenuInfo info = (AdapterContextMenuInfo) item.getMenuInfo();

        final SavedFormatProvider formatStorageHandler = new SavedFormatProvider(this);
        Map<String, String> selectedFormat = formatsList.get(info.position);
        final String formatDrive = selectedFormat.get(attributeKeys[0]);
        final String formatName = selectedFormat.get(attributeKeys[1]);
        final String formatExtension = selectedFormat.get(attributeKeys[2]);
        final String sourcePrinterName = SelectedPrinterManager.getSelectedPrinter().address;

        switch (item.getItemId()) {
            case R.id.menu_save:
                new AsyncTask<Void, Void, Void>() {
                    String formatText = null;

                    @Override
                    protected Void doInBackground(Void... params) {
                        uiHelper.showLoadingDialog("Retrieving format...");
                        Connection connection = SelectedPrinterManager.getPrinterConnection();

                        if (connection != null) {
                            try {
                                connection.open();
                                ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);

                                byte[] formatContents = printer.retrieveFormatFromPrinter(formatDrive + formatName + formatExtension);
                                formatText = new String(formatContents, StandardCharsets.UTF_8);

                            } catch (ConnectionException e) {
                                uiHelper.showErrorDialogOnGuiThread(e.getMessage());
                            } catch (ZebraPrinterLanguageUnknownException e) {
                                uiHelper.showErrorDialogOnGuiThread(e.getMessage());
                            } finally {
                                try {
                                    connection.close();
                                } catch (ConnectionException e) {
                                    uiHelper.showErrorDialogOnGuiThread(e.getMessage());
                                }
                            }
                        }
                        uiHelper.dismissLoadingDialog();
                        return null;
                    }

                    protected void onPostExecute(Void result) {
                        if (formatText != null) {
                            long id = formatStorageHandler.insert(formatDrive, formatName, formatExtension, sourcePrinterName, formatText);
                            if (id >= 0) {
                                Map<String, String> listEntry = new HashMap<String, String>();
                                listEntry.put(attributeKeys[0], "");
                                listEntry.put(attributeKeys[1], formatName);
                                listEntry.put(attributeKeys[2], formatExtension);
                                listEntry.put(attributeKeys[3], Integer.toString(R.drawable.btn_star_big_on));
                                listEntry.put(attributeKeys[4], "Retrieved from: " + sourcePrinterName + " on " + formatStorageHandler.getTimestampOfFormat(id));
                                listEntry.put(FormatRefresher.FORMAT_SOURCE_KEY, FormatRefresher.FORMAT_SOURCE_DATABASE);
                                listEntry.put(FormatRefresher.FORMAT_LOCATION_KEY, Long.toString(id));

                                formatsList.add(formatStorageHandler.getNumberOfStoredFormats() - 1, listEntry);
                                statusListAdapter.notifyDataSetChanged();
                            }
                        }
                    }

                }.execute((Void) null);
                return true;
            case R.id.menu_delete:
                final String formatId = selectedFormat.get(FormatRefresher.FORMAT_LOCATION_KEY);
                if (formatStorageHandler.delete(formatId) == true) {
                    formatsList.remove(info.position);
                    statusListAdapter.notifyDataSetChanged();
                }

                return true;
            default:
                return super.onContextItemSelected(item);
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        usbHelper.onNewIntent(intent);
        processNfcScan(intent);
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onStop() {
        super.onStop();
        usbHelper.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();

        removeDisconnectedUsbPrintersFromList();
        processNfcScan(getIntent());

        DiscoveredPrinter selectedPrinter = SelectedPrinterManager.getSelectedPrinter();
        if (selectedPrinter == null && !isPermissionRequested) {
            uiHelper.dismissLoadingDialog(dialog);
            showDialog(DIALOG_DISCOVERY);
        } else if (formatPrinter != null && formatPrinter.address.equals(selectedPrinter.address) == false) {
            FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        usbHelper.onResume();
    }

    private void processNfcScan(Intent intent) {
        Parcelable[] scannedTags = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES);
        if (scannedTags != null && scannedTags.length > 0) {
            NdefMessage msg = (NdefMessage) scannedTags[0];
            payload = new String(msg.getRecords()[0].getPayload());
            if (Permissions.hasPermissions(this, permissionList)) {
                findNfcAsyncTask();
            } else {
                isPermissionRequested = true;
                requestPermission();
            }
            intent.removeExtra(NfcAdapter.EXTRA_NDEF_MESSAGES);
        }
    }

    private void findNfcAsyncTask() {
        if (!isFinishing() && !isDestroyed()) {
            AsyncTask<String, Void, Void> findNfcTask = new AsyncTask<String, Void, Void>() {

                ProgressDialog dialog;
                private volatile boolean discoveryComplete = false;
                private volatile boolean printerFound = false;

                @Override
                protected void onPreExecute() {
                    super.onPreExecute();
                    dialog = new ProgressDialog(ChooseFormatScreen.this, ProgressDialog.STYLE_SPINNER);
                    dialog.setMessage("Processing NFC Scan");
                    dialog.show();
                    try {
                        ChooseFormatScreen.this.dismissDialog(DIALOG_DISCOVERY);
                    } catch (IllegalArgumentException e) {
                    }
                }

                @Override
                protected Void doInBackground(String... params) {
                    try {
                        UrlPrinterDiscoverer.findPrinters(params[0], new DiscoveryHandler() {
                            @Override
                            public void foundPrinter(DiscoveredPrinter printer) {
                                if (printerFound == false) {
                                    printerFound = true;
                                    SelectedPrinterManager.setSelectedPrinter(printer);
                                    SelectedPrinterManager.storePrinterHistoryInPreferences(ChooseFormatScreen.this);
                                }
                            }

                            @Override
                            public void discoveryFinished() {
                                discoveryComplete = true;
                            }

                            @Override
                            public void discoveryError(String message) {
                                discoveryComplete = true;
                            }
                        });
                    } catch (DiscoveryException e) {
                        e.printStackTrace();
                        discoveryComplete = true;
                    } catch (SecurityException e) {
                        e.printStackTrace();
                        discoveryComplete = true;
                    }

                    while (discoveryComplete == false && printerFound == false) {
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException e) {
                        }
                    }
                    return null;
                }

                @Override
                protected void onPostExecute(Void result) {
                    super.onPostExecute(result);
                    uiHelper.dismissLoadingDialog(dialog);
                    try {
                        ChooseFormatScreen.this.dismissDialog(DIALOG_DISCOVERY);
                    } catch (IllegalArgumentException e) {
                    }

                    if (spinnerAdapter != null) {
                        spinnerAdapter.notifyDataSetChanged();
                    }
                    if (printerFound == true) {
                        FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
                    }

                    if (printerFound == false) {
                        Toast.makeText(ChooseFormatScreen.this, "Unable to find specified NFC printer", Toast.LENGTH_SHORT).show();
                    }

                    if (SelectedPrinterManager.getSelectedPrinter() == null) {
                        showDialog(DIALOG_DISCOVERY);
                    }
                }
            };
            findNfcTask.execute(payload);
        }
    }

    private void requestPermission() {
        ActivityCompat.requestPermissions(this, permissionList, MULTIPLE_PERMISSION);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        isPermissionRequested = false;
        findNfcAsyncTask();
    }

    private void removeDisconnectedUsbPrintersFromList() {
        UsbManager usbService = (UsbManager) this.getSystemService(Context.USB_SERVICE);
        HashMap<String, UsbDevice> deviceList = usbService.getDeviceList();


        DiscoveredPrinter[] history = SelectedPrinterManager.getPrinterHistory();
        for (int i = 0; i < history.length; i++) {
            DiscoveredPrinter historyPrinter = history[i];
            if (historyPrinter instanceof DiscoveredPrinterUsb && deviceList.containsKey(historyPrinter.address) == false) {
                SelectedPrinterManager.removeHistoryItemAtIndex(i);
                i--;
                history = SelectedPrinterManager.getPrinterHistory();
            }
        }

        if (spinnerAdapter != null) {
            spinnerAdapter.notifyDataSetChanged();
        }
    }

    @Override
    protected void onListItemClick(ListView l, View v, int position, long id) {
        super.onListItemClick(l, v, position, id);

        formatPrinter = SelectedPrinterManager.getSelectedPrinter();

        Intent intent;
        intent = new Intent(this, VariablesScreen.class);
        Map<String, String> listItem = (Map<String, String>) l.getItemAtPosition(position);
        String formatName = listItem.get(attributeKeys[0]) + listItem.get(attributeKeys[1]) + listItem.get(attributeKeys[2]);
        intent.putExtra(FormatRefresher.FORMAT_NAME, formatName);
        intent.putExtra(FormatRefresher.FORMAT_SOURCE_KEY, listItem.get(FormatRefresher.FORMAT_SOURCE_KEY));
        intent.putExtra(FormatRefresher.FORMAT_LOCATION_KEY, listItem.get(FormatRefresher.FORMAT_LOCATION_KEY));

        startActivity(intent);
        overridePendingTransition(R.anim.slide_in_right, android.R.anim.fade_out);
    }

    @Override
    protected Dialog onCreateDialog(int id) {
        switch (id) {
            case DIALOG_DISCOVERY:
                dialog = new Dialog(this);

                dialog.setContentView(R.layout.discovery_dialog);
                dialog.setTitle("Select a Printer");
                dialog.setCancelable(true);

                dialog.setOnCancelListener(dialog -> {
                    if (SelectedPrinterManager.getSelectedPrinter() == null) {
                        finish();
                    }
                });

                ListView discoveryList = dialog.findViewById(R.id.discoveryList);
                discoveryList.setEmptyView(dialog.findViewById(R.id.emptyDiscoveryLayout));

                discoveredPrinterListAdapter = new DiscoveredPrinterListAdapter(this);

                discoveryList.setAdapter(discoveredPrinterListAdapter);

                discoveryList.setOnItemClickListener((arg0, arg1, position, id1) -> {
                    DiscoveredPrinter printer = discoveredPrinterListAdapter.getPrinter(position);
                    uiHelper.dismissLoadingDialog(dialog);

                    if (printer instanceof DiscoveredPrinterUsb) {
                        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
                        UsbDevice device = ((DiscoveredPrinterUsb) printer).device;
                        if (!usbManager.hasPermission(device)) {
                            usbHelper.requestUsbPermission(usbManager, device);
                            return;
                        }
                    }
                    SelectedPrinterManager.setSelectedPrinter(printer);
                    spinnerAdapter.notifyDataSetChanged();
                    SelectedPrinterManager.storePrinterHistoryInPreferences(ChooseFormatScreen.this);
                    FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
                });
                break;
            case DIALOG_ABOUT:
                final String version = getVersionInfo();
                Dialog aboutDialog = new Dialog(this) {
                    @Override
                    protected void onCreate(Bundle savedInstanceState) {
                        super.onCreate(savedInstanceState);
                        ((TextView) findViewById(R.id.textView2)).setText(version);
                    }
                };
                aboutDialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                aboutDialog.setContentView(R.layout.about_dialog);
                aboutDialog.setCancelable(true);
                return aboutDialog;
            default:
//                dialog = super.onCreateDialog(id);
        }
        return dialog;
    }

    private String getVersionInfo() {
        try {
            PackageInfo packageInfo = this.getApplication().getPackageManager().getPackageInfo("com.zebra.kdu", 0);
            return "Version " + packageInfo.versionName;
        } catch (NameNotFoundException e) {
            e.printStackTrace();
            return null;
        }
    }

    @Override
    protected void onPrepareDialog(int id, final Dialog dialog) {
        switch (id) {
            case DIALOG_DISCOVERY:
                dialog.findViewById(R.id.refreshPrintersButton).setOnClickListener(v -> doDiscovery(dialog));

                doDiscovery(dialog);
        }

        super.onPrepareDialog(id, dialog);
    }

    private void doDiscovery(final Dialog dialog) {
        discoveredPrinterListAdapter.clearPrinters();
        discoveredPrinterListAdapter.notifyDataSetChanged();

        ((TextView) dialog.findViewById(R.id.emptyDiscovery)).setText("Searching...");
        dialog.findViewById(R.id.searchingSpinner).setVisibility(View.VISIBLE);
        dialog.findViewById(R.id.refreshPrintersButton).setVisibility(View.INVISIBLE);

        usbDiscoveryComplete = false;
        bluetoothDiscoveryComplete = false;
        networkDiscoveryComplete = false;

        UsbDiscoverer.findPrinters(this, new DiscoveryHandler() {
            public void foundPrinter(final DiscoveredPrinter printer) {
                ChooseFormatScreen.this.runOnUiThread(() -> discoveredPrinterListAdapter.addPrinter(printer));
            }

            public void discoveryFinished() {
                usbDiscoveryComplete = true;
            }

            public void discoveryError(String message) {
                usbDiscoveryComplete = true;
            }
        });

        int permissionCheck = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION);
        try {
            BluetoothDiscoverer.findPrinters(this, new DiscoveryHandler() {

                public void foundPrinter(final DiscoveredPrinter printer) {
                    ChooseFormatScreen.this.runOnUiThread(() -> discoveredPrinterListAdapter.addPrinter(printer));
                }

                public void discoveryFinished() {
                    bluetoothDiscoveryComplete = true;
                }

                public void discoveryError(String message) {
                    bluetoothDiscoveryComplete = true;
                }
            });
        } catch (ConnectionException | SecurityException e) {
            bluetoothDiscoveryComplete = true;
        }

        try {
            NetworkDiscoverer.findPrinters(new DiscoveryHandler() {

                public void foundPrinter(final DiscoveredPrinter printer) {
                    ChooseFormatScreen.this.runOnUiThread(() -> discoveredPrinterListAdapter.addPrinter(printer));
                }

                public void discoveryFinished() {
                    networkDiscoveryComplete = true;
                }

                public void discoveryError(String message) {
                    networkDiscoveryComplete = true;
                }
            });
        } catch (DiscoveryException e) {
            networkDiscoveryComplete = true;
        }

        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {
                while (usbDiscoveryComplete == false || bluetoothDiscoveryComplete == false || networkDiscoveryComplete == false) {
                    try {
                        Thread.sleep(250);
                    } catch (InterruptedException e) {
                    }
                }
                return null;
            }

            @Override
            protected void onPostExecute(Void result) {
                dialog.findViewById(R.id.searchingSpinner).setVisibility(View.INVISIBLE);
                dialog.findViewById(R.id.refreshPrintersButton).setVisibility(View.VISIBLE);
                ((TextView) dialog.findViewById(R.id.emptyDiscovery)).setText("No Printers Found");
                super.onPostExecute(result);
            }
        }.

                execute((Void) null);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        MenuItem item = menu.getItem(0);
        final Spinner printerSpinner = item.getActionView().findViewById(R.id.actionBarSpinner);

        spinnerAdapter = new SimpleAdapter(this, storedPrintersList, R.layout.stored_printer_entry, storedPrinterAttributeKeys, storedPrinterAttributeIds) {
            @Override
            public void notifyDataSetChanged() {
                DiscoveredPrinter[] printerList = SelectedPrinterManager.getPrinterHistory();
                storedPrintersList.clear();
                for (DiscoveredPrinter selectedPrinter : printerList) {
                    Map<String, String> printerAttributes = new HashMap<String, String>();
                    if (selectedPrinter instanceof DiscoveredPrinterNetwork) {
                        printerAttributes.put(storedPrinterAttributeKeys[0], selectedPrinter.getDiscoveryDataMap().get("DNS_NAME"));
                    } else if (selectedPrinter instanceof DiscoveredPrinterBluetooth) {
                        printerAttributes.put(storedPrinterAttributeKeys[0], ((DiscoveredPrinterBluetooth) selectedPrinter).friendlyName);
                    } else if (selectedPrinter instanceof DiscoveredPrinterUsb) {
                        printerAttributes.put(storedPrinterAttributeKeys[0], "USB Printer");
                    }
                    printerAttributes.put(storedPrinterAttributeKeys[1], selectedPrinter.address);
                    storedPrintersList.add(storedPrintersList.size(), printerAttributes);
                }

                Map<String, String> findPrintersEntry = new HashMap<String, String>();
                findPrintersEntry.put(storedPrinterAttributeKeys[0], "Find Printer...");
                findPrintersEntry.put(storedPrinterAttributeKeys[1], "");
                storedPrintersList.add(storedPrintersList.size(), findPrintersEntry);
                super.notifyDataSetChanged();
            }
        };

        if (!isPermissionRequested)
            spinnerAdapter.notifyDataSetChanged();

        ((SimpleAdapter) spinnerAdapter).setDropDownViewResource(R.layout.stored_printer_entry);
        printerSpinner.setAdapter(spinnerAdapter);
        printerSpinner.setOnItemSelectedListener(new OnItemSelectedListener() {
            public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
                DiscoveredPrinter[] history = SelectedPrinterManager.getPrinterHistory();

                if (arg2 == history.length) {
                    showDialog(DIALOG_DISCOVERY);
                    ((Spinner) findViewById(R.id.actionBarSpinner)).setSelection(0);
                    return;
                } else if (arg2 == 0) {
                    return;
                }

                SelectedPrinterManager.removeHistoryItemAtIndex(arg2);
                SelectedPrinterManager.setSelectedPrinter(history[arg2]);
                spinnerAdapter.notifyDataSetChanged();
                ((Spinner) findViewById(R.id.actionBarSpinner)).setSelection(0);
                SelectedPrinterManager.storePrinterHistoryInPreferences(ChooseFormatScreen.this);
                FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
            }

            public void onNothingSelected(AdapterView<?> arg0) {
            }
        });

        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.menu_refresh:
                FormatRefresher.execute(ChooseFormatScreen.this, uiHelper, attributeKeys, formatsList, statusListAdapter);
                break;
            case R.id.menu_about:
                showDialog(DIALOG_ABOUT);
                break;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void finish() {
        isFinished = true;
        super.finish();
    }

    public boolean isFinished() {
        return isFinished;
    }
}
