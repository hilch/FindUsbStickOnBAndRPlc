[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Made For B&R](https://github.com/hilch/BandR-badges/blob/main/Made-For-BrAutomation.svg)](https://www.br-automation.com)

# FindUsbStickOnBAndRPlc
B&amp;R Automation Studio : Auto mount USB Stick connected to a B&amp;R PLC and use it as file device for FileIO - Library.

What is this about ?

You cannot assign a fixed [file device](https://help.br-automation.com/#/en/4/libraries%2Ffileio%2Fgen%2Ffiledevice.html) to a USB stick in Automation Runtime. This would not even make sense, as the USB stick can be removed at any time or plugged in anywhere in the USB network.

After plugging a USB stick into a PLC, you must therefore first search for it using the functions of the [AsUSB library](https://help.br-automation.com/#/en/4/libraries%2Fasusb%2Fasusb.html) and then dynamically create a [file device](https://help.br-automation.com/#/en/4/libraries%2Ffileio%2Fgen%2Ffiledevice.html) using the [AsFileIO library](https://help.br-automation.com/#/en/4/libraries%2Ffileio%2Ffileio.html).

How to do this is explained in an [example in the online help](https://help.br-automation.com/#/en/4/librarysamples%2Flibsamples%2Flibsamples_dataaccess_libasusb1_st.htm).

This project attempts to automate this process by cyclically searching for an inserted stick and then making it available as a file device.

There is a package which does the job and can be used in own projects.
It provides a global structure as an interface:
`gFindUsbStick.connected` signals whether a stick is present.
`gFindUsbStick.deviceName` shows the created file device for usage with FileIO's function blocks.

There is an example task that uses this interface to show the number of files on the stick.


