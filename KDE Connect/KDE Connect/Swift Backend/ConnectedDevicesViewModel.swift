/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  ConnectedDevicesViewModel.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-09.
//

import SwiftUI
import UIKit
import AVFoundation
import CryptoKit

@objc class ConnectedDevicesViewModel : NSObject {
    var devicesView: DevicesView? = nil
    var currDeviceDetailsView: DevicesDetailView? = nil
    
    var connectedDevices: [String : String] = [:]
    var visibleDevices: [String : String] = [:]
    var savedDevices: [String : String] = [:]
    
    var lastLocalClipboardUpdateTimestamp: Int = 0
        
    @objc func onPairRequest(_ deviceId: String!) -> Void {
        if (devicesView != nil) {
            devicesView!.onPairRequestInsideView(deviceId)
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform onPairRequest in ConnectedDevicesViewModel")
        }
    }
    
    @objc func onPairTimeout(_ deviceId: String!) -> Void{
        if (devicesView != nil) {
            devicesView!.onPairTimeoutInsideView(deviceId)
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform onPairTimeout in ConnectedDevicesViewModel")
        }
    }
    
    @objc func onPairSuccess(_ deviceId: String!) -> Void {
        if (devicesView != nil) {
            if (certificateService.tempRemoteCerts[deviceId] != nil) {
                let status: Bool = certificateService.saveRemoteDeviceCertToKeychain(cert: certificateService.tempRemoteCerts[deviceId]!, deviceId: deviceId)
                print("Remote certificate saved into local Keychain with status \(status)")
                (backgroundService._devices[deviceId as Any] as! Device)._SHA256HashFormatted = certificateService.SHA256HashDividedAndFormatted(hashDescription: SHA256.hash(data: SecCertificateCopyData(certificateService.tempRemoteCerts[deviceId]!) as Data).description)
                devicesView!.onPairSuccessInsideView(deviceId)
            } else {
                AudioServicesPlaySystemSound(soundAudioError)
                print("Pairing failed")
            }
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform onPairTimeout in ConnectedDevicesViewModel")
        }
    }
    
    @objc func onPairRejected(_ deviceId: String!) -> Void {
        if (devicesView != nil) {
            devicesView!.onPairRejectedInsideView(deviceId)
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform onPairRejected in ConnectedDevicesViewModel")
        }
    }
    
    // Recalculate AND rerender the lists
    @objc func onDeviceListRefreshed() -> Void {
        if (devicesView != nil) {
            let devicesListsMap = backgroundService.getDevicesLists() //[String : [String : Device]]
            connectedDevices = devicesListsMap?["connected"] as! [String : String]
            visibleDevices = devicesListsMap?["visible"] as! [String : String]
            savedDevices = devicesListsMap?["remembered"] as! [String : String]
            devicesView!.onDeviceListRefreshedInsideView(vm: self)
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform onDeviceListRefreshed in ConnectedDevicesViewModel")
        }
    }
    
    // Refresh Discovery, Recalculate AND rerender the lists
    @objc func refreshDiscoveryAndListInsideView() -> Void {
        if (devicesView != nil) {
            devicesView!.refreshDiscoveryAndList()
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform refreshDiscoveryAndListInsideView in ConnectedDevicesViewModel")
        }
    }
    
    @objc func reRenderDeviceView() -> Void {
        if (devicesView != nil) {
            withAnimation { // do we want animation for battery updates on DeviceView()?
                devicesView!.viewUpdate.toggle()
            }
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform reRenderDeviceView in ConnectedDevicesViewModel")
        }
    }
    
    @objc func reRenderCurrDeviceDetailsView(deviceId: String) -> Void {
        if (currDeviceDetailsView != nil && deviceId == currDeviceDetailsView!.detailsDeviceId) {
            withAnimation {
                connectedDevicesViewModel.currDeviceDetailsView!.viewUpdate.toggle()
            }
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("currDeviceDetailsView is nil, unable to perform reRenderCurrDeviceDetailsView in ConnectedDevicesViewModel")
        }
    }
    
    @objc func unpair(fromBackgroundServiceInstance deviceId: String) -> Void {
        backgroundService.unpairDevice(deviceId)
    }
    
    @objc static func staticUnpairFromBackgroundService(deviceId: String) -> Void {
        backgroundService.unpairDevice(deviceId)
    }
    
    @objc func currDeviceDetailsViewDisconnected(fromRemote deviceId: String!) -> Void {
        if (currDeviceDetailsView != nil && deviceId == currDeviceDetailsView!.detailsDeviceId && devicesView != nil) {
            currDeviceDetailsView!.isStilConnected = false
            devicesView!.refreshDiscoveryAndList()
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView OR currDeviceDetailsView is nil, unable to perform devicesView in ConnectedDevicesViewModel")
        }
    }
    
    @objc func removeDeviceFromArrays(deviceId: String) -> Void {
        //backgroundService._devices.removeObject(forKey: deviceId)
        backgroundService._settings.removeObject(forKey: deviceId)
        UserDefaults.standard.setValue(backgroundService._settings, forKey: "savedDevices")
        print("Device remove, stored cert also removed with status \(certificateService.deleteRemoteDeviceSavedCert(deviceId: deviceId))")
    }
    
    @objc static func isDeviceCurrentlyPairedAndConnected(_ deviceId: String) -> Bool {
        let doesExistInDevices: Bool = (backgroundService._devices[deviceId] != nil)
        if doesExistInDevices {
            let device: Device = (backgroundService._devices[deviceId] as! Device)
            return (device.isPaired() && device.isReachable())
        } else {
            return false
        }
    }
    
    @objc func showPingAlert() -> Void {
        if (devicesView != nil) {
            devicesView!.showPingAlertInsideView()
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform showPingAlert in ConnectedDevicesViewModel")
        }
    }
    
    @objc func showFindMyPhoneAlert() -> Void {
        if (devicesView != nil) {
            devicesView!.showFindMyPhoneAlertInsideView()
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform showFindMyPhoneAlert in ConnectedDevicesViewModel")
        }
    }
    
    @objc func showFileReceivedAlert() -> Void {
        if (devicesView != nil) {
            devicesView!.showFileReceivedAlertInsideView()
        } else {
            AudioServicesPlaySystemSound(soundAudioError)
            print("devicesView is nil, unable to perform showFileReceivedAlert in ConnectedDevicesViewModel")
        }
    }
    
    @objc static func getDirectIPList() -> [String] {
        return selfDeviceData.directIPs
    }
}
