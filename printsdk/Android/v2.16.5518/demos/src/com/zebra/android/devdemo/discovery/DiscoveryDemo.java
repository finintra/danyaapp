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

package com.zebra.android.devdemo.discovery;

import android.content.Intent;
import android.os.Bundle;
import android.widget.ListView;

import androidx.appcompat.app.AppCompatActivity;

import com.zebra.android.devdemo.R;

public class DiscoveryDemo extends AppCompatActivity {

    private static final int BLUETOOTH = 0;
    private static final int BLE = 1;
    private static final int LOCAL_BROADCAST = 2;
    private static final int DIRECTED_BROADCAST = 3;
    private static final int MULTICAST = 4;
    private static final int SUBNET_SEARCH = 5;
    private static final int FIND_PRINTERS = 6;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.discovery_methods);
        ListView listView = findViewById(R.id.listView);
        listView.setOnItemClickListener((parent, view, position, id) -> {
            Intent intent;
            switch (position) {
                case BLUETOOTH:
                    intent = new Intent(this, BluetoothDiscovery.class);
                    break;
                case BLE:
                    intent = new Intent(this, BluetoothLeDiscovery.class);
                    break;
                case LOCAL_BROADCAST:
                    intent = new Intent(this, LocalBroadcastDiscoveryResultList.class);
                    break;
                case MULTICAST:
                    intent = new Intent(this, MulticastDiscoveryParameters.class);
                    break;
                case DIRECTED_BROADCAST:
                    intent = new Intent(this, DirectedBroadcastParameters.class);
                    break;
                case SUBNET_SEARCH:
                    intent = new Intent(this, SubnetSearchParameters.class);
                    break;
                case FIND_PRINTERS:
                    intent = new Intent(this, FindPrintersDiscoveryResultList.class);
                    break;
                default:
                    return;// not possible
            }
            startActivity(intent);
        });
    }
}
