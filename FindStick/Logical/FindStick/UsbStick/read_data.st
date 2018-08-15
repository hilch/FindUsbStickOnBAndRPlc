(********************************************************************
 * COPYRIGHT -- Bernecker + Rainer
 ********************************************************************
 * Program: read_data
 * File: read_data.st
 * Author: Bernecker & Rainer
 * Created: April 20, 2009
 ********************************************************************
 * Implementation of program read_data
 ********************************************************************)

PROGRAM _INIT


	step := WAIT;  
	tonSearchUSBStick.PT := T#5s;
 	g_usbStickConnected := FALSE;
	DirRead_0;
	DirInfo_0;
	device_data;
	DIRECTORY_INFO;
	FINISH;
	DIRECTORY_READ;
END_PROGRAM


PROGRAM _CYCLIC

tonSearchUSBStick( IN:= TRUE );
IF tonSearchUSBStick.Q THEN
	start_reading_usb_data := TRUE;	
END_IF

CASE step OF
 	
	WAIT:
		
		IF start_reading_usb_data = TRUE THEN
			start_reading_usb_data := FALSE;
			step := CREATE_NODE_ID_LIST;  (*start FUBs below*)
		ELSE
			step := WAIT;
		END_IF;
				
							

	CREATE_NODE_ID_LIST:  (*Library AsUSB - Functionblock USBNodeListGet()*)
	
		UsbNodeListGet_0.enable := 1;
		UsbNodeListGet_0.pBuffer := ADR(node_id_buffer);  (*pointer to buffer - UDINT array is assigned*)
		UsbNodeListGet_0.bufferSize := SIZEOF(node_id_buffer);  (*size of node-id-buffer-array*)
		UsbNodeListGet_0.filterInterfaceClass := asusb_CLASS_MASS_STORAGE;  (*filter on mass storage devices is set*)
		UsbNodeListGet_0.filterInterfaceSubClass := asusb_SUBCLASS_SCSI_COMMAND_SET;  (*USB Stick*)
		UsbNodeListGet_0;
								
		IF UsbNodeListGet_0.status = 0 THEN
        	step := READ_DEVICE_DATA;  (*FUB worked correctly => next step*)	
		ELSIF UsbNodeListGet_0.status = ERR_FUB_BUSY THEN
			step := CREATE_NODE_ID_LIST;  (*FUB work asynchron => called until status isn't BUSY*)
		ELSIF UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND THEN
			brsmemset( ADR(usb_data_buffer), 0, SIZEOF(usb_data_buffer) );
			brsmemset( ADR(device_descriptor), 0, SIZEOF(device_descriptor) );
			g_usbStickConnected := FALSE;
			tonSearchUSBStick( IN:= FALSE ); (* Timer neu starten *)
			step := WAIT;
		ELSE
			errorStep := step;
			step := ERROR_CASE;  (*error occured*)
		END_IF;



	READ_DEVICE_DATA:  (*Library AsUSB - Functionblock USBNodeGet()*)
						
		UsbNodeGet_0.enable := 1;
		UsbNodeGet_0.nodeId := node_id_buffer[node];  (*specific node is read out of node_id_buffer*)
		UsbNodeGet_0.pBuffer := ADR(usb_data_buffer[node]);  (*data of specific node get stored in usb_data_buffer*)
		UsbNodeGet_0.bufferSize := SIZEOF (usb_data_buffer[node]);  (*size of specific node is read out usb_data_buffer*)
		UsbNodeGet_0;
	
		IF UsbNodeGet_0.status = 0 THEN  (*FUB worked correctly*)	
			node := node + 1;  (*next node to be read out of buffer*)
			IF node = UsbNodeListGet_0.listNodes THEN  (*last existing node is reached*)
				node := 0;
				step := GET_DESCRIPTOR;  (*all nodes are read out of buffer*)
			END_IF;
		
		ELSIF UsbNodeGet_0.status = ERR_FUB_BUSY THEN
			step := READ_DEVICE_DATA;  (*FUB work asynchron => called until status isn't BUSY*)
		ELSE
			errorStep := step;
			step := ERROR_CASE;  (*error occured*)
		END_IF;
			
															

	GET_DESCRIPTOR:  (*Library AsUSB - Functionblock USBDescriptorGet()*)
					
		UsbDescriptorGet_0.enable := 1;
		UsbDescriptorGet_0.nodeId := node_id_buffer[node];  (*specific node is read out of node_id_buffer*) 
		UsbDescriptorGet_0.requestType := 0;  (*Request for device*)
        UsbDescriptorGet_0.descriptorType := 1;  (*Determines the device descriptor*)
		UsbDescriptorGet_0.languageId := 0;  (*for device and configuration descriptors*)
		UsbDescriptorGet_0.pBuffer := ADR(device_descriptor[node]);  (*descriptor-data of specific node get stored in device_descriptor-buffer*) 
		UsbDescriptorGet_0.bufferSize := SIZEOF(device_descriptor[node]);  (*size of specific node is read out device_descriptor-buffer*)
		UsbDescriptorGet_0;
	
		IF UsbDescriptorGet_0.status = 0 THEN  (*FUB worked correctly*)	
			node := node + 1;  (*next node to be read out of buffer*)
			IF node = UsbNodeListGet_0.listNodes THEN  (*last existing node is reached*)
				node := 0;
				IF NOT(g_usbStickConnected) THEN
					g_usbStickConnected := TRUE;
					step := CREATE_FILE_DEVICE;  (*all nodes are read out of buffer*)
				ELSE
					tonSearchUSBStick( IN:= FALSE );  (* Timer neu starten *)
					step := WAIT;				
				END_IF
			END_IF;
	
		ELSIF UsbDescriptorGet_0.status = ERR_FUB_BUSY THEN
			step := GET_DESCRIPTOR;  (*FUB work asynchron => called until status isn't BUSY*)
		ELSIF UsbDescriptorGet_0.status = asusbERR_USB_NOTFOUND THEN
				g_usbStickConnected := FALSE;
				tonSearchUSBStick( IN:= FALSE );  (* Timer neu starten *)
				step := WAIT;
		ELSE
			errorStep := step;
			step := ERROR_CASE;  (*error occured*)
		END_IF;



	CREATE_FILE_DEVICE:  (*Library FileIO - Functionblock DevLink() - create file out of data just from 1. USB*)
						
		brsstrcpy(ADR(device_name), ADR('USBStick'));  (*fixed Device-Name get copied to device_name-Variable*)															
		brsstrcpy(ADR(device_param), ADR('/DEVICE='));  (*first part of parameter get copied to device_param-Variable*)		
		brsstrcat(ADR(device_param), ADR(usb_data_buffer[0].ifName));  (*second part get added to device_param-Variable*) 																												
	
		DevLink_0.enable := 1;
		DevLink_0.pDevice := ADR(device_name);  (*Devicename is assigned*)
		DevLink_0.pParam := ADR(device_param);  (*the path of the Device is assigned*)
		DevLink_0;
	
		IF DevLink_0.status = 0 THEN
			tonSearchUSBStick( IN:= FALSE );  (* Timer neu starten *)
			step := WAIT;						
//			step := DIRECTORY_INFO;  (*FUB worked correctly => next step*)	
		ELSIF DevLink_0.status = ERR_FUB_BUSY THEN
			step := CREATE_FILE_DEVICE;  (*FUB work asynchron => called until status isn't BUSY*) 
		ELSIF DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
			step := UNLINK_DEVICE;
		ELSE
			errorStep := step;
			step := ERROR_CASE;  (*error occured*)
		END_IF;
					

	UNLINK_DEVICE:  (*Library FileIO - Functionblock DevUnlink()*)
					
		DevUnlink_0.enable := 1;
		DevUnlink_0.handle := DevLink_0.handle;  (*handle from DevLink is assigned to cut the connection to specific file-device*)
		DevUnlink_0;

		IF DevUnlink_0.status = ERR_FUB_BUSY THEN
			step := UNLINK_DEVICE;  (*FUB work asynchron => called until status isn't BUSY*)
		ELSE
			step := CREATE_FILE_DEVICE;
		END_IF;

											
					
END_CASE;

END_PROGRAM
